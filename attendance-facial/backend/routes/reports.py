from fastapi import APIRouter, HTTPException, Depends
from fastapi.responses import FileResponse
from database import supabase
from routes.auth import require_docente
from utils.report_generator import generate_report
import os

router = APIRouter(prefix="/reports", tags=["Reportes"])

@router.get("/generate/{sesion_id}")
async def generate_attendance_report(sesion_id: str, user=Depends(require_docente)):
    # Verifica que la sesión pertenece al docente
    sesion = supabase.table("sesiones").select(
        "*, cursos(nombre)"
    ).eq("id", sesion_id).eq("docente_id", user["sub"]).execute()

    if not sesion.data:
        raise HTTPException(status_code=404, detail="Sesión no encontrada.")

    s = sesion.data[0]

    # Obtiene registros de asistencia
    asistencia = supabase.table("asistencia").select(
        "*, estudiantes(nombre, codigo)"
    ).eq("sesion_id", sesion_id).execute()

    if not asistencia.data:
        raise HTTPException(status_code=404, detail="No hay registros de asistencia.")

    registros = [
        {
            "nombre": a["estudiantes"]["nombre"],
            "codigo": a["estudiantes"]["codigo"],
            "hora": str(a["hora"]),
            "fecha": str(a["fecha"])
        }
        for a in asistencia.data
    ]

    filepath = generate_report(
        registros=registros,
        curso=s["cursos"]["nombre"],
        fecha=str(s["fecha"]),
        docente=user["nombre"]
    )

    return FileResponse(
        path=filepath,
        filename=os.path.basename(filepath),
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    )

@router.get("/history/{curso_id}")
async def get_course_history(curso_id: str, user=Depends(require_docente)):
    """Historial completo de asistencia de un curso."""
    # Verifica que el curso pertenece al docente
    curso = supabase.table("cursos").select("id").eq(
        "id", curso_id
    ).eq("docente_id", user["sub"]).execute()

    if not curso.data:
        raise HTTPException(status_code=404, detail="Curso no encontrado.")

    result = supabase.table("asistencia").select(
        "*, estudiantes(nombre, codigo), sesiones(fecha, hora_inicio)"
    ).eq("sesiones.curso_id", curso_id).order("created_at", desc=True).execute()

    return {"total": len(result.data), "registros": result.data}