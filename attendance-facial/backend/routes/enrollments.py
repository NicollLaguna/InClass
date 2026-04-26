from fastapi import APIRouter, HTTPException, Depends
from database import supabase
from routes.auth import require_docente
from services.email_service import send_estudiante_matricula_aprobada, send_estudiante_matricula_rechazada
from services.notification_service import send_notification
from datetime import datetime

router = APIRouter(prefix="/enrollments", tags=["Matrículas"])

@router.get("/pending/{curso_id}")
async def get_pending(curso_id: str, user=Depends(require_docente)):
    result = supabase.table("matriculas").select(
        "*, estudiantes(id, nombre, codigo, email)"
    ).eq("curso_id", curso_id).eq("estado", "pendiente").execute()
    return {"solicitudes": result.data}

@router.post("/approve/{matricula_id}")
async def approve_enrollment(matricula_id: str, user=Depends(require_docente)):
    matricula = supabase.table("matriculas").select(
        "*, estudiantes(id, nombre, email), cursos(nombre)"
    ).eq("id", matricula_id).execute()

    if not matricula.data:
        raise HTTPException(status_code=404, detail="Matrícula no encontrada.")

    data = matricula.data[0]

    supabase.table("matriculas").update({
        "estado": "aprobado",
        "fecha_respuesta": datetime.now().isoformat()
    }).eq("id", matricula_id).execute()

    # Email
    send_estudiante_matricula_aprobada(
        email=data["estudiantes"]["email"],
        nombre=data["estudiantes"]["nombre"],
        curso=data["cursos"]["nombre"]
    )

    # Notificación push
    try:
        est_fcm = supabase.table("estudiantes").select("fcm_token").eq(
            "id", data["estudiantes"]["id"]
        ).execute()

        if est_fcm.data and est_fcm.data[0].get("fcm_token"):
            send_notification(
                token=est_fcm.data[0]["fcm_token"],
                title="✅ Matrícula aprobada",
                body=f"Tu matrícula en {data['cursos']['nombre']} fue aprobada.",
            )
    except Exception as e:
        print(f"⚠️ Error notificación: {e}")

    return {"mensaje": "Matrícula aprobada exitosamente."}

@router.post("/reject/{matricula_id}")
async def reject_enrollment(matricula_id: str, user=Depends(require_docente)):
    matricula = supabase.table("matriculas").select(
        "*, estudiantes(id, nombre, email), cursos(nombre)"
    ).eq("id", matricula_id).execute()

    if not matricula.data:
        raise HTTPException(status_code=404, detail="Matrícula no encontrada.")

    data = matricula.data[0]

    supabase.table("matriculas").update({
        "estado": "rechazado",
        "fecha_respuesta": datetime.now().isoformat()
    }).eq("id", matricula_id).execute()

    # Email
    send_estudiante_matricula_rechazada(
        email=data["estudiantes"]["email"],
        nombre=data["estudiantes"]["nombre"],
        curso=data["cursos"]["nombre"]
    )

    # Notificación push
    try:
        est_fcm = supabase.table("estudiantes").select("fcm_token").eq(
            "id", data["estudiantes"]["id"]
        ).execute()

        if est_fcm.data and est_fcm.data[0].get("fcm_token"):
            send_notification(
                token=est_fcm.data[0]["fcm_token"],
                title="❌ Matrícula rechazada",
                body=f"Tu solicitud para {data['cursos']['nombre']} fue rechazada.",
            )
    except Exception as e:
        print(f"⚠️ Error notificación: {e}")

    return {"mensaje": "Matrícula rechazada."}