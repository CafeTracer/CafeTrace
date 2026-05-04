from typing import Optional
from pydantic import BaseModel, EmailStr

class LoginIn(BaseModel):
    correo: EmailStr
    password: str

class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    id_usuario: Optional[int] = None
    id_rol: Optional[int] = None
    rol: Optional[str] = None
