from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from database import supabase
from routes.auth import require_docente, require_estudiante
from services.email_service import send_docente_sesion_resumen
from services.notification_service import send_to_multiple
from datetime import datetime, timedelta, timezone
from config import settings

router = APIRouter(prefix="/sessions", tags=["Sesiones"])

COL_TZ = timezone(timedelta(hours=-5))

def now_colombia():
    return datetime.now(COL_TZ)

class SessionCreate(BaseModel):
    curso_id: str

@router.post("/start")
async def start_session(data: SessionCreate, user=Depends(require_docente)):
    curso = supabase.table("cursos").select("*").eq(
        "id", data.curso_id
    ).eq("docente_id", user["sub"]).execute()

    if not curso.data:
        raise HTTPException(status_code=404, detail="Curso no encontrado.")

    active = supabase.table("sesiones").select("id").eq(
        "curso_id", data.curso_id
    ).eq("activa", True).execute()

    if active.data:
        raise HTTPException(status_code=400, detail="Ya hay una sesión activa para este curso.")

    ahora = now_colombia()
    result = supabase.table("sesiones").insert({
        "curso_id": data.curso_id,
        "docente_id": user["sub"],
        "fecha": ahora.strftime("%Y-%m-%d"),
        "hora_inicio": ahora.isoformat(),
        "ventana_minutos": settings.ATTENDANCE_WINDOW_MINUTES,
        "activa": True
    }).execute()

    sesion = result.data[0]
    cierre = ahora + timedelta(minutes=settings.ATTENDANCE_WINDOW_MINUTES)

    # Notifica a estudiantes matriculados
    try:
        matriculas = supabase.table("matriculas").select(
            "estudiantes(fcm_token)"
        ).eq("curso_id", data.curso_id).eq("estado", "aprobado").execute()

        tokens = [
            m["estudiantes"]["fcm_token"]
            for m in matriculas.data
            if m["estudiantes"].get("fcm_token")
        ]

        if tokens:
            send_to_multiple(
                tokens=tokens,
                title="📚 Clase iniciada",
                body=f"La clase de {curso.data[0]['nombre']} ha comenzado. Tienes 15 minutos para registrar asistencia.",
                data={"curso_id": data.curso_id, "sesion_id": sesion["id"]}
            )
    except Exception as e:
        print(f"⚠️ Error enviando notificaciones: {e}")

    return {
        "mensaje": f"Sesión iniciada para '{curso.data[0]['nombre']}'.",
        "sesion_id": sesion["id"],
        "hora_inicio": ahora.strftime("%H:%M:%S"),
        "ventana_cierre": cierre.strftime("%H:%M:%S"),
        "minutos_disponibles": settings.ATTENDANCE_WINDOW_MINUTES
    }

@router.post("/end/{sesion_id}")
async def end_session(sesion_id: str, user=Depends(require_docente)):
    sesion = supabase.table("sesiones").select(
        "*, cursos(nombre)"
    ).eq("id", sesion_id).eq("docente_id", user["sub"]).execute()

    if not sesion.data:
        raise HTTPException(status_code=404, detail="Sesión no encontrada.")

    if not sesion.data[0]["activa"]:
        raise HTTPException(status_code=400, detail="La sesión ya está finalizada.")

    ahora = now_colombia()

    supabase.table("sesiones").update({
        "activa": False,
        "hora_fin": ahora.isoformat()
    }).eq("id", sesion_id).execute()

    asistencia = supabase.table("asistencia").select(
        "*, estudiantes(nombre, codigo)"
    ).eq("sesion_id", sesion_id).execute()

    asistentes = [
        {
            "nombre": a["estudiantes"]["nombre"],
            "codigo": a["estudiantes"]["codigo"],
            "hora": str(a["hora"])
        }
        for a in asistencia.data
    ]

    send_docente_sesion_resumen(
        email=user["email"],
        nombre=user["nombre"],
        curso=sesion.data[0]["cursos"]["nombre"],
        fecha=sesion.data[0]["fecha"],
        total=len(asistentes),
        asistentes=asistentes
    )

    return {
        "mensaje": "Sesión finalizada.",
        "total_asistentes": len(asistentes),
        "asistentes": asistentes
    }

@router.get("/course/{curso_id}")
async def get_course_sessions(curso_id: str, user=Depends(require_docente)):
    result = supabase.table("sesiones").select("*").eq(
        "curso_id", curso_id
    ).eq("docente_id", user["sub"]).order("created_at", desc=True).execute()
    return {"sesiones": result.data}

@router.get("/active/{curso_id}")
async def get_active_session(curso_id: str, user=Depends(require_estudiante)):
    matricula = supabase.table("matriculas").select("id").eq(
        "estudiante_id", user["sub"]
    ).eq("curso_id", curso_id).eq("estado", "aprobado").execute()

    if not matricula.data:
        raise HTTPException(status_code=403, detail="No estás matriculado en este curso.")

    sesion = supabase.table("sesiones").select("*").eq(
        "curso_id", curso_id
    ).eq("activa", True).execute()

    if not sesion.data:
        return {"activa": False, "mensaje": "No hay sesión activa en este momento."}

    s = sesion.data[0]
    hora_inicio = datetime.fromisoformat(s["hora_inicio"])
    if hora_inicio.tzinfo is None:
        hora_inicio = hora_inicio.replace(tzinfo=COL_TZ)

    ahora = now_colombia()
    minutos_transcurridos = int((ahora - hora_inicio).total_seconds() // 60)
    minutos_restantes = max(0, s["ventana_minutos"] - minutos_transcurridos)
    ventana_abierta = minutos_restantes > 0

    ya_registro = supabase.table("asistencia").select("id").eq(
        "estudiante_id", user["sub"]
    ).eq("sesion_id", s["id"]).execute()

    return {
        "activa": True,
        "ventana_abierta": ventana_abierta,
        "sesion_id": s["id"],
        "minutos_restantes": minutos_restantes,
        "ya_registro": bool(ya_registro.data),
        "mensaje": "Sesión activa." if ventana_abierta else "Ventana de asistencia cerrada."
    }