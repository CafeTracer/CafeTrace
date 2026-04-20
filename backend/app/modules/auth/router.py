from fastapi import APIRouter, Depends
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from app.core.deps import get_db, get_current_user
from app.modules.auth.service import AuthService
from app.modules.auth.schemas import TokenOut

router = APIRouter(prefix="/auth", tags=["Auth"])

@router.post("/login", response_model=TokenOut)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    return AuthService(db).login(form_data.username, form_data.password)

@router.get("/me")
def me(current_user = Depends(get_current_user)):
    return {
        "data": {
            "id_usuario": current_user.id_usuario,
            "correo": current_user.correo,
            "nombre": current_user.nombre,
            "apellido": current_user.apellido,
            "rol": current_user.rol.nombre,
        }
    }
