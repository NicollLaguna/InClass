from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from typing import List
from pathlib import Path
import tempfile
from face_engine.recognizer import get_recognizer
from database import supabase

router = APIRouter(prefix="/students", tags=["Estudiantes"])

@router.post("/register")
async def register_student(
    nombre: str = Form(...),
    codigo: str = Form(...),
    fotos: List[UploadFile] = File(...)
):
    if not fotos:
        raise HTTPException(status_code=400, detail="Envía al menos una foto.")

    for f in fotos:
        if not f.content_type.startswith("image/"):
            raise HTTPException(status_code=400, detail="Todos los archivos deben ser imágenes.")

    existing = supabase.table("estudiantes").select("id").eq("codigo", codigo).execute()
    if not existing.data:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado. Completa el registro de cuenta primero.")

    # Guarda fotos en temporales
    tmp_paths = []
    for foto in fotos:
        ext = Path(foto.filename).suffix or ".jpg"
        with tempfile.NamedTemporaryFile(suffix=ext, delete=False) as tmp:
            tmp.write(await foto.read())
            tmp_paths.append(tmp.name)

    # Registra promediando los embeddings de todas las fotos
    embedding = get_recognizer().register_student(tmp_paths, nombre, codigo)

    for p in tmp_paths:
        Path(p).unlink(missing_ok=True)

    if embedding is None:
        raise HTTPException(status_code=422, detail="No se detectó ningún rostro en las imágenes.")

    supabase.table("estudiantes").update({
        "embedding": embedding
    }).eq("codigo", codigo).execute()

    return {
        "mensaje": f"Estudiante {nombre} registrado con {len(fotos)} foto(s).",
        "codigo": codigo,
        "fotos_procesadas": len(fotos)
    }

@router.get("/list")
async def list_students():
    result = supabase.table("estudiantes").select("*").order("nombre").execute()
    return {"total": len(result.data), "estudiantes": result.data}

@router.delete("/{codigo}")
async def delete_student(codigo: str):
    success = get_recognizer().delete_student(codigo)
    result = supabase.table("estudiantes").delete().eq("codigo", codigo).execute()
    if not success and not result.data:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado.")
    return {"mensaje": f"Estudiante {codigo} eliminado correctamente."}
