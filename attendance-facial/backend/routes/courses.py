from fastapi import APIRouter, HTTPException, Depends
from pydantic import BaseModel
from database import supabase
from routes.auth import require_docente, require_estudiante, get_current_user
import random
import string

router = APIRouter(prefix="/courses", tags=["Cursos"])

class CourseCreate(BaseModel):
    nombre: str
    descripcion: str = ""

class JoinCourse(BaseModel):
    codigo_acceso: str

def generate_access_code():
    return ''.join(random.choices(string.ascii_uppercase + string.digits, k=8))

# ── Docente: crear curso ───────────────────────────────

@router.post("/create")
async def create_course(data: CourseCreate, user=Depends(require_docente)):
    codigo_acceso = generate_access_code()
    # Asegura que sea único
    while supabase.table("cursos").select("id").eq("codigo_acceso", codigo_acceso).execute().data:
        codigo_acceso = generate_access_code()

    result = supabase.table("cursos").insert({
        "nombre": data.nombre,
        "descripcion": data.descripcion,
        "docente_id": user["sub"],
        "codigo_acceso": codigo_acceso
    }).execute()

    return {
        "mensaje": f"Curso '{data.nombre}' creado exitosamente.",
        "codigo_acceso": codigo_acceso,
        "curso": result.data[0]
    }

# ── Docente: listar sus cursos ─────────────────────────

@router.get("/my-courses")
async def get_my_courses(user=Depends(require_docente)):
    result = supabase.table("cursos").select("*").eq("docente_id", user["sub"]).execute()
    return {"cursos": result.data}

# ── Docente: listar estudiantes del curso ──────────────

@router.get("/{curso_id}/students")
async def get_course_students(curso_id: str, user=Depends(require_docente)):
    result = supabase.table("matriculas").select(
        "*, estudiantes(id, nombre, codigo, email)"
    ).eq("curso_id", curso_id).eq("estado", "aprobado").execute()
    return {"estudiantes": result.data}

# ── Estudiante: unirse a curso con código ──────────────

@router.post("/join")
async def join_course(data: JoinCourse, user=Depends(require_estudiante)):
    # Busca el curso
    curso = supabase.table("cursos").select("*").eq(
        "codigo_acceso", data.codigo_acceso
    ).eq("activo", True).execute()

    if not curso.data:
        raise HTTPException(status_code=404, detail="Código de acceso inválido.")

    curso_id = curso.data[0]["id"]

    # Verifica si ya está matriculado
    existing = supabase.table("matriculas").select("id", "estado").eq(
        "estudiante_id", user["sub"]
    ).eq("curso_id", curso_id).execute()

    if existing.data:
        estado = existing.data[0]["estado"]
        if estado == "aprobado":
            raise HTTPException(status_code=400, detail="Ya estás matriculado en este curso.")
        elif estado == "pendiente":
            raise HTTPException(status_code=400, detail="Tu solicitud ya está pendiente de aprobación.")

    # Crea solicitud
    supabase.table("matriculas").insert({
        "estudiante_id": user["sub"],
        "curso_id": curso_id,
        "estado": "pendiente"
    }).execute()

    return {"mensaje": f"Solicitud enviada para '{curso.data[0]['nombre']}'. Espera aprobación del docente."}

# ── Estudiante: ver sus cursos aprobados ───────────────

@router.get("/my-enrollments")
async def get_my_enrollments(user=Depends(require_estudiante)):
    result = supabase.table("matriculas").select(
        "*, cursos(id, nombre, descripcion, docente_id)"
    ).eq("estudiante_id", user["sub"]).eq("estado", "aprobado").execute()
    return {"cursos": result.data}