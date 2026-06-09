from fastapi import APIRouter, HTTPException, Depends
from database import supabase
from routes.auth import require_estudiante
from face_engine.recognizer import get_recognizer
from services.email_service import send_estudiante_asistencia
from datetime import datetime, timedelta, timezone
import cv2
import base64
import numpy as np
from config import settings

router = APIRouter(prefix="/attendance", tags=["Asistencia"])

COL_TZ = timezone(timedelta(hours=-5))

def now_colombia():
    return datetime.now(COL_TZ)

@router.post("/recognize/{sesion_id}")
async def recognize_from_frame(sesion_id: str, payload: dict, user=Depends(require_estudiante)):
    # Verifica que la sesión existe y está activa
    sesion = supabase.table("sesiones").select(
        "*, cursos(nombre, docente_id), docentes(nombre, email)"
    ).eq("id", sesion_id).eq("activa", True).execute()

    if not sesion.data:
        raise HTTPException(status_code=404, detail="Sesión no encontrada o inactiva.")

    s = sesion.data[0]

    # Verifica ventana de 15 minutos
    hora_inicio = datetime.fromisoformat(s["hora_inicio"])
    if hora_inicio.tzinfo is None:
        hora_inicio = hora_inicio.replace(tzinfo=COL_TZ)

    ahora = now_colombia()
    minutos_transcurridos = int((ahora - hora_inicio).total_seconds() // 60)

    if minutos_transcurridos > s["ventana_minutos"]:
        raise HTTPException(status_code=400, detail="La ventana de asistencia de 15 minutos ha cerrado.")

    # Verifica que el estudiante está matriculado
    matricula = supabase.table("matriculas").select("id").eq(
        "estudiante_id", user["sub"]
    ).eq("curso_id", s["curso_id"]).eq("estado", "aprobado").execute()

    if not matricula.data:
        raise HTTPException(status_code=403, detail="No estás matriculado en este curso.")

    # Verifica que no haya registrado asistencia ya
    ya_registro = supabase.table("asistencia").select("id").eq(
        "estudiante_id", user["sub"]
    ).eq("sesion_id", sesion_id).execute()

    if ya_registro.data:
        raise HTTPException(status_code=400, detail="Ya registraste asistencia en esta sesión.")

    # Decodifica el frame
    try:
        image_data = base64.b64decode(payload["frame"])
        np_arr = np.frombuffer(image_data, np.uint8)
        frame = cv2.imdecode(np_arr, cv2.IMREAD_COLOR)
    except Exception:
        raise HTTPException(status_code=400, detail="Frame inválido.")

    # Reconocimiento facial
    results = get_recognizer().recognize_face(frame)

    # Busca el estudiante autenticado entre los reconocidos
    estudiante_info = supabase.table("estudiantes").select("*").eq(
        "id", user["sub"]
    ).execute()

    if not estudiante_info.data:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado.")

    est = estudiante_info.data[0]
    reconocido = None

    for result in results:
        if result["codigo"] == est["codigo"] and result["confianza"] and result["confianza"] >= settings.MIN_CONFIDENCE:
            reconocido = result
            break

    if not reconocido:
        score, face_detected = get_recognizer().get_best_match_for(frame, est["codigo"])
        porcentaje = int(score * 100)

        if not face_detected:
            motivo = "No se detectó ningún rostro. Asegúrate de estar frente a la cámara."
        else:
            motivo = "El rostro no coincide con el registrado. Intenta con mejor iluminación y sin objetos que cubran tu rostro."

        supabase.table("intentos_reconocimiento").insert({
            "sesion_id": sesion_id,
            "exitoso": False,
            "confianza": score if face_detected else None,
            "motivo_fallo": motivo
        }).execute()

        raise HTTPException(status_code=422, detail=motivo)

    hora = ahora.strftime("%H:%M:%S")
    fecha = ahora.strftime("%Y-%m-%d")

    # Registra asistencia
    supabase.table("asistencia").insert({
        "estudiante_id": user["sub"],
        "sesion_id": sesion_id,
        "hora": hora,
        "fecha": fecha,
        "confianza": reconocido["confianza"]
    }).execute()

    # Log intento exitoso
    supabase.table("intentos_reconocimiento").insert({
        "sesion_id": sesion_id,
        "exitoso": True,
        "confianza": reconocido["confianza"]
    }).execute()

    # Obtiene info del docente
    docente_info = supabase.table("docentes").select("nombre").eq(
        "id", s["cursos"]["docente_id"]
    ).execute()
    nombre_docente = docente_info.data[0]["nombre"] if docente_info.data else "Docente"
    # Email confirmación al estudiante
    send_estudiante_asistencia(
        email=est["email"],
        nombre=est["nombre"],
        curso=s["cursos"]["nombre"],
        docente=nombre_docente,
        fecha=fecha,
        hora=hora,
        confianza=reconocido["confianza"]
    )

    return {
        "mensaje": f"✅ Asistencia registrada exitosamente.",
        "nombre": est["nombre"],
        "codigo": est["codigo"],
        "curso": s["cursos"]["nombre"],
        "hora": hora,
        "confianza": f"{int(reconocido['confianza'] * 100)}%"
    }

@router.get("/history")
async def attendance_history(user=Depends(require_estudiante)):
    """Historial de asistencia del estudiante autenticado."""
    result = supabase.table("asistencia").select(
        "*, sesiones(fecha, cursos(nombre))"
    ).eq("estudiante_id", user["sub"]).order("created_at", desc=True).execute()
    return {"total": len(result.data), "registros": result.data}