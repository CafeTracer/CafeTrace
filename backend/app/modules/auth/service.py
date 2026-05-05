from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.db.orm_models.usuario import Usuario
from app.core.security import verify_password, create_access_token

class AuthService:
    def __init__(self, db: Session):
        self.db = db

    def login(self, username: str, password: str) -> dict:
        user = self.db.execute(select(Usuario).where(Usuario.correo == username)).scalar_one_or_none()
        if not user or not verify_password(password, user.password_hash):
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Credenciales inválidas")
        if not user.activo:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Usuario inactivo")
        token = create_access_token(user.id_usuario, user.correo, user.rol.nombre)
        return {
            "access_token": token,
            "token_type": "bearer",
            "id_usuario": user.id_usuario,
            "id_rol": user.id_rol,
            "rol": user.rol.nombre,
        }
