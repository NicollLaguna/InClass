from dotenv import load_dotenv
import os

load_dotenv()

class Settings:
    APP_NAME: str = "InClass - Control de Asistencia"
    APP_VERSION: str = "2.0.0"

    # Supabase
    SUPABASE_URL: str = os.getenv("SUPABASE_URL", "")
    SUPABASE_KEY: str = os.getenv("SUPABASE_KEY", "")

    # JWT
    JWT_SECRET: str = os.getenv("JWT_SECRET", "inclass_secret_key_2024")
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRATION_HOURS: int = 24

    # Resend email
    RESEND_API_KEY: str = os.getenv("RESEND_API_KEY", "")
    EMAIL_FROM: str = os.getenv("EMAIL_FROM", "InClass <onboarding@resend.dev>")

    # Rutas locales
    FACES_DIR: str = "data/faces"
    REPORTS_DIR: str = "data/reports"

    # Reconocimiento facial
    TOLERANCE: float = 0.4
    MIN_CONFIDENCE: float = 0.80
    PHOTOS_PER_STUDENT: int = 5

    # Sesión
    ATTENDANCE_WINDOW_MINUTES: int = 15

settings = Settings()