from datetime import datetime, timedelta, timezone
import jwt
from pwdlib import PasswordHash
from fastapi import HTTPException, status
from app.core.config import settings

password_hasher = PasswordHash.recommended()

ROLE_SCOPES = {
    "Administrador": {"*"},
    "Operario": {
        "catalogos:read", "usuarios:read", "fincas:read", "fincas:write",
        "lotes:read", "lotes:write", "registros:read", "registros:write",
        "alertas:read"
    },
    "Supervisor": {
        "catalogos:read", "usuarios:read", "fincas:read", "lotes:read",
        "registros:read", "alertas:read", "alertas:write"
    }
}


def hash_password(password: str) -> str:
    return password_hasher.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    return password_hasher.verify(password, password_hash)


def create_access_token(user_id: int, email: str, role: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.jwt_expire_minutes)
    payload = {
        "sub": str(user_id),
        "email": email,
        "role": role,
        "scopes": list(ROLE_SCOPES.get(role, set())),
        "exp": expire,
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
    except jwt.PyJWTError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token inválido") from exc
