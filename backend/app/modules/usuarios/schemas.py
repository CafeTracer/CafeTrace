from datetime import datetime
from pydantic import BaseModel, EmailStr, Field

class UsuarioCreate(BaseModel):
    id_rol: int
    nombre: str = Field(min_length=2, max_length=100)
    apellido: str = Field(min_length=2, max_length=100)
    correo: EmailStr
    password: str = Field(min_length=8, max_length=128)
    telefono: str | None = Field(default=None, max_length=20)

class UsuarioUpdate(BaseModel):
    id_rol: int | None = None
    nombre: str | None = Field(default=None, min_length=2, max_length=100)
    apellido: str | None = Field(default=None, min_length=2, max_length=100)
    telefono: str | None = Field(default=None, max_length=20)
    activo: bool | None = None

class UsuarioOut(BaseModel):
    id_usuario: int
    id_rol: int
    nombre: str
    apellido: str
    correo: EmailStr
    telefono: str | None
    activo: bool
    fecha_creacion: datetime
