import bcrypt
from jose import JWTError, jwt
from datetime import datetime, timedelta
from config import settings

def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt()).decode('utf-8')

def verify_password(plain: str, hashed: str) -> bool:
    return bcrypt.checkpw(plain.encode('utf-8'), hashed.encode('utf-8'))

def create_token(data: dict, role: str) -> str:
    payload = data.copy()
    payload.update({
        "role": role,
        "exp": datetime.utcnow() + timedelta(hours=settings.JWT_EXPIRATION_HOURS)
    })
    return jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)

def decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
    except JWTError:
        return None