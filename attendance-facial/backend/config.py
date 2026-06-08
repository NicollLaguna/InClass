from dotenv import load_dotenv
import os
from pathlib import Path

load_dotenv()

# Obtener ruta del proyecto
BASE_DIR = Path(__file__).parent.parent

class Settings:
    """Configuración centralizada de la aplicación"""
    
    # ── Información de la app ────────────────────────────
    APP_NAME: str = "InClass - Control de Asistencia"
    APP_VERSION: str = "2.0.0"

    # ── Supabase ──────────────────────────────────────────
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "")
    SUPABASE_KEY: str = os.getenv("SUPABASE_KEY", "")

    # ── JWT (Autenticación) ───────────────────────────────
    JWT_SECRET: str = os.getenv("JWT_SECRET", "inclass_secret_key_2024")
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRATION_HOURS: int = 720  # 30 días

    # ── Email (Gmail SMTP) ────────────────────────────────
    SMTP_HOST: str     = os.getenv("SMTP_HOST", "smtp.gmail.com")
    SMTP_PORT: int     = int(os.getenv("SMTP_PORT", "587"))
    SMTP_USER: str     = os.getenv("SMTP_USER", "")
    SMTP_PASSWORD: str = os.getenv("SMTP_PASSWORD", "")
    EMAIL_FROM: str    = os.getenv("EMAIL_FROM", "")

    # ── Rutas locales ─────────────────────────────────────
    FACES_DIR: str = "data/faces"
    REPORTS_DIR: str = "data/reports"
    EMBEDDINGS_DB_PATH: str = "data/embeddings.pkl"

    # ── Reconocimiento facial (Buffalo_l) ─────────────────
    TOLERANCE: float = 0.4
    MIN_CONFIDENCE: float = float(os.getenv("MIN_CONFIDENCE", "0.45"))
    PHOTOS_PER_STUDENT: int = 5
    FACE_QUALITY_THRESHOLD: float = 0.9  # Nuevo: umbral de calidad de detección

    # ── Base de datos vectorial (Pinecone) ───────────────
    USE_PINECONE: bool = os.getenv("USE_PINECONE", "false").lower() == "true"
    PINECONE_API_KEY: str = os.getenv("PINECONE_API_KEY", "")
    PINECONE_ENV: str = os.getenv("PINECONE_ENV", "gcp-starter")
    PINECONE_INDEX_NAME: str = "facial-recognition"
    PINECONE_DIMENSION: int = 512  # Dimensión de embeddings buffalo_l

    # ── Sesión ────────────────────────────────────────────
    ATTENDANCE_WINDOW_MINUTES: int = 15

    # ── Logging ───────────────────────────────────────────
    LOG_LEVEL: str = os.getenv("LOG_LEVEL", "INFO")


settings = Settings()