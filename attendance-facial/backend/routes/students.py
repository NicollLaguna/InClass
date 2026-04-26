from fastapi import APIRouter, UploadFile, File, Form, HTTPException
from pathlib import Path
import shutil
import uuid
from face_engine.recognizer import recognizer
from database import supabase
from config import settings

router = APIRouter(prefix="/students", tags=["Estudiantes"])

@router.post("/register")
async def register_student(
    nombre: str = Form(...),
    codigo: str = Form(...),
    foto: UploadFile = File(...)
):
    # Valida imagen
    if not foto.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="El archivo debe ser una imagen.")

    # Verifica duplicado en Supabase
    existing = supabase.table("estudiantes").select("id").eq("codigo", codigo).execute()
    if existing.data:
        raise HTTPException(status_code=400, detail=f"El código {codigo} ya está registrado.")

    # Guarda imagen localmente
    ext = Path(foto.filename).suffix
    filename = f"{codigo}_{uuid.uuid4().hex[:8]}{ext}"
    image_path = Path(settings.FACES_DIR) / filename

    with open(image_path, "wb") as f:
        shutil.copyfileobj(foto.file, f)

    # Registra en motor facial
    success = recognizer.register_student(str(image_path), nombre, codigo)
    if not success:
        image_path.unlink()
        raise HTTPException(status_code=422, detail="No se detectó ningún rostro en la imagen.")

    # Guarda en Supabase
    supabase.table("estudiantes").insert({
        "nombre": nombre,
        "codigo": codigo,
        "foto_url": filename
    }).execute()

    return {
        "mensaje": f"Estudiante {nombre} registrado exitosamente.",
        "codigo": codigo,
        "foto": filename
    }

@router.get("/list")
async def list_students():
    result = supabase.table("estudiantes").select("*").order("nombre").execute()
    return {"total": len(result.data), "estudiantes": result.data}

@router.delete("/{codigo}")
async def delete_student(codigo: str):
    # Elimina del motor facial
    success = recognizer.delete_student(codigo)
    
    # Elimina de Supabase
    result = supabase.table("estudiantes").delete().eq("codigo", codigo).execute()
    
    if not success and not result.data:
        raise HTTPException(status_code=404, detail="Estudiante no encontrado.")
    
    return {"mensaje": f"Estudiante {codigo} eliminado correctamente."}