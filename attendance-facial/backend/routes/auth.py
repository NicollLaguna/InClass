from fastapi import APIRouter, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from pydantic import BaseModel, field_validator
import re
from database import supabase
from services.auth_service import hash_password, verify_password, create_token, decode_token
from services.email_service import send_docente_bienvenida, send_estudiante_bienvenida
from fastapi.openapi.utils import get_openapi

# Configura Bearer token en Swagger
def custom_openapi(app):
    if app.openapi_schema:
        return app.openapi_schema
    openapi_schema = get_openapi(
        title=app.title,
        version=app.version,
        routes=app.routes,
    )
    openapi_schema["components"]["securitySchemes"] = {
        "BearerAuth": {
            "type": "http",
            "scheme": "bearer",
            "bearerFormat": "JWT",
        }
    }
    for path in openapi_schema["paths"].values():
        for method in path.values():
            method["security"] = [{"BearerAuth": []}]
    app.openapi_schema = openapi_schema
    return app.openapi_schema
router = APIRouter(prefix="/auth", tags=["Autenticación"])
security = HTTPBearer()

# ── Validador de contraseña ────────────────────────────

def validate_password(password: str) -> str:
    if len(password) < 8:
        raise ValueError("La contraseña debe tener mínimo 8 caracteres.")
    if not re.search(r'[A-Z]', password):
        raise ValueError("La contraseña debe tener al menos una mayúscula.")
    if not re.search(r'[a-z]', password):
        raise ValueError("La contraseña debe tener al menos una minúscula.")
    if not re.search(r'\d', password):
        raise ValueError("La contraseña debe tener al menos un número.")
    if not re.search(r'[!@#$%^&*(),.?\":{}|<>]', password):
        raise ValueError("La contraseña debe tener al menos un carácter especial (!@#$%...).")
    return password

# ── Schemas ────────────────────────────────────────────

class DocenteRegister(BaseModel):
    nombre: str
    email: str
    password: str

    @field_validator('password')
    @classmethod
    def password_strength(cls, v):
        return validate_password(v)

    @field_validator('nombre')
    @classmethod
    def nombre_valido(cls, v):
        if len(v.strip()) < 3:
            raise ValueError("El nombre debe tener mínimo 3 caracteres.")
        return v.strip()

    @field_validator('email')
    @classmethod
    def email_valido(cls, v):
        if not re.match(r'^[\w\.-]+@[\w\.-]+\.\w+$', v):
            raise ValueError("Email inválido.")
        return v.lower().strip()

class EstudianteRegister(BaseModel):
    nombre: str
    codigo: str
    email: str
    password: str

    @field_validator('password')
    @classmethod
    def password_strength(cls, v):
        return validate_password(v)

    @field_validator('codigo')
    @classmethod
    def codigo_valido(cls, v):
        if not v.isdigit() or len(v) != 12:
            raise ValueError("El código debe tener exactamente 12 dígitos numéricos.")
        return v

    @field_validator('nombre')
    @classmethod
    def nombre_valido(cls, v):
        if len(v.strip()) < 3:
            raise ValueError("El nombre debe tener mínimo 3 caracteres.")
        return v.strip()

    @field_validator('email')
    @classmethod
    def email_valido(cls, v):
        if not re.match(r'^[\w\.-]+@[\w\.-]+\.\w+$', v):
            raise ValueError("Email inválido.")
        return v.lower().strip()

class LoginRequest(BaseModel):
    email: str
    password: str
    role: str

# ── Dependencias JWT ───────────────────────────────────

def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(security)):
    payload = decode_token(credentials.credentials)
    if not payload:
        raise HTTPException(status_code=401, detail="Token inválido o expirado.")
    return payload

def require_docente(user=Depends(get_current_user)):
    if user.get("role") != "docente":
        raise HTTPException(status_code=403, detail="Acceso solo para docentes.")
    return user

def require_estudiante(user=Depends(get_current_user)):
    if user.get("role") != "estudiante":
        raise HTTPException(status_code=403, detail="Acceso solo para estudiantes.")
    return user

# ── Registro docente ───────────────────────────────────

@router.post("/docente/register")
async def register_docente(data: DocenteRegister):
    # Verifica duplicado email
    existing = supabase.table("docentes").select("id").eq("email", data.email).execute()
    if existing.data:
        raise HTTPException(status_code=400, detail="El email ya está registrado.")

    # Verifica duplicado nombre
    existing_nombre = supabase.table("docentes").select("id").eq("nombre", data.nombre).execute()
    if existing_nombre.data:
        raise HTTPException(status_code=400, detail="Ya existe un docente con ese nombre.")

    supabase.table("docentes").insert({
        "nombre": data.nombre,
        "email": data.email,
        "password_hash": hash_password(data.password)
    }).execute()

    send_docente_bienvenida(data.email, data.nombre)

    return {"mensaje": f"Docente {data.nombre} registrado exitosamente."}

# ── Registro estudiante ────────────────────────────────

@router.post("/estudiante/register")
async def register_estudiante(data: EstudianteRegister):
    # Verifica duplicado email
    existing_email = supabase.table("estudiantes").select("id").eq("email", data.email).execute()
    if existing_email.data:
        raise HTTPException(status_code=400, detail="El email ya está registrado.")

    # Verifica duplicado código
    existing_codigo = supabase.table("estudiantes").select("id").eq("codigo", data.codigo).execute()
    if existing_codigo.data:
        raise HTTPException(status_code=400, detail="El código ya está registrado.")

    # Verifica duplicado nombre
    existing_nombre = supabase.table("estudiantes").select("id").eq("nombre", data.nombre).execute()
    if existing_nombre.data:
        raise HTTPException(status_code=400, detail="Ya existe un estudiante con ese nombre.")

    supabase.table("estudiantes").insert({
        "nombre": data.nombre,
        "codigo": data.codigo,
        "email": data.email,
        "password_hash": hash_password(data.password)
    }).execute()

    send_estudiante_bienvenida(data.email, data.nombre, data.codigo)

    return {"mensaje": f"Estudiante {data.nombre} registrado exitosamente."}

# ── Login ──────────────────────────────────────────────

@router.post("/login")
async def login(data: LoginRequest):
    if data.role not in ["docente", "estudiante"]:
        raise HTTPException(status_code=400, detail="Rol inválido.")

    tabla = "docentes" if data.role == "docente" else "estudiantes"
    result = supabase.table(tabla).select("*").eq("email", data.email.lower()).execute()

    if not result.data:
        raise HTTPException(status_code=401, detail="Credenciales incorrectas.")

    user = result.data[0]

    if not verify_password(data.password, user["password_hash"]):
        raise HTTPException(status_code=401, detail="Credenciales incorrectas.")

    if not user.get("activo", True):
        raise HTTPException(status_code=403, detail="Cuenta desactivada.")

    token = create_token(
        {"sub": user["id"], "email": user["email"], "nombre": user["nombre"]},
        role=data.role
    )

    return {
        "token": token,
        "role": data.role,
        "nombre": user["nombre"],
        "email": user["email"],
        "id": user["id"]
    }

# ── Verificar token ────────────────────────────────────

@router.get("/me")
async def get_me(user=Depends(get_current_user)):
    return user

class FcmTokenUpdate(BaseModel):
    fcm_token: str
    role: str

@router.post("/fcm-token")
async def update_fcm_token(data: FcmTokenUpdate, user=Depends(get_current_user)):
    tabla = "docentes" if data.role == "docente" else "estudiantes"
    supabase.table(tabla).update(
        {"fcm_token": data.fcm_token}
    ).eq("id", user["sub"]).execute()
    return {"mensaje": "Token FCM actualizado."}

