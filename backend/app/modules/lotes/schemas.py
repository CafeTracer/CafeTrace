from datetime import date, datetime
from pydantic import BaseModel, Field

class LoteCreate(BaseModel):
    id_finca: int
    id_variedad: int
    codigo_lote: str = Field(min_length=3, max_length=30)
    fecha_registro: date
    cantidad_kg: float | None = Field(default=None, ge=0)
    observaciones: str | None = Field(default=None, max_length=250)
    activo: bool = True

class LoteUpdate(BaseModel):
    id_finca: int | None = None
    id_variedad: int | None = None
    codigo_lote: str | None = Field(default=None, min_length=3, max_length=30)
    fecha_registro: date | None = None
    cantidad_kg: float | None = Field(default=None, ge=0)
    observaciones: str | None = Field(default=None, max_length=250)
    activo: bool | None = None

class LoteEstadoOut(BaseModel):
    id_lote: int
    codigo_lote: str
    estado_actual: str | None = None
    fecha_estado_actual: datetime | None = None
