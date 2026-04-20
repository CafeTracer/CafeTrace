from pydantic import BaseModel, Field

class FincaCreate(BaseModel):
    id_municipio: int
    nombre: str = Field(min_length=2, max_length=100)
    propietario: str = Field(min_length=2, max_length=120)
    direccion: str | None = Field(default=None, max_length=150)
    latitud: float | None = None
    longitud: float | None = None
    area_hectareas: float | None = None
    descripcion: str | None = Field(default=None, max_length=200)

class FincaUpdate(FincaCreate):
    id_municipio: int | None = None
    nombre: str | None = Field(default=None, min_length=2, max_length=100)
    propietario: str | None = Field(default=None, min_length=2, max_length=120)
