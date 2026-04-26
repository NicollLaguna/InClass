from pydantic import BaseModel
from datetime import datetime
from typing import Optional

class StudentCreate(BaseModel):
    nombre: str
    codigo: str

class StudentResponse(BaseModel):
    id: str
    nombre: str
    codigo: str
    foto_url: Optional[str] = None

class AttendanceRecord(BaseModel):
    estudiante_id: str
    nombre: str
    codigo: str
    fecha: str
    hora: str

class SessionCreate(BaseModel):
    curso: str
    docente: str

class RecognitionResult(BaseModel):
    reconocido: bool
    nombre: Optional[str] = None
    codigo: Optional[str] = None
    confianza: Optional[float] = None
    mensaje: str