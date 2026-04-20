from datetime import datetime
from pydantic import BaseModel, Field, model_validator

class RegistroCreate(BaseModel):
    id_lote: int
    id_usuario: int
    id_tipo_actividad: int
    id_estado_lote: int
    fecha_hora: datetime | None = None
    observacion: str | None = Field(default=None, max_length=250)
    ubicacion_registro: str | None = Field(default=None, max_length=120)

class DetalleVariableCreate(BaseModel):
    id_variable: int
    valor: float
    comentario: str | None = Field(default=None, max_length=150)

class RegistroBatchCreate(BaseModel):
    id_usuario: int
    id_tipo_actividad: int
    id_estado_lote: int
    fecha_hora: datetime | None = None
    observacion: str | None = Field(default=None, max_length=250)
    ubicacion_registro: str | None = Field(default=None, max_length=120)
    variables: list[DetalleVariableCreate] = Field(min_length=1, max_length=50)

    @model_validator(mode='after')
    def validate_unique_variables(self):
        ids = [v.id_variable for v in self.variables]
        if len(ids) != len(set(ids)):
            raise ValueError('No se puede repetir la misma variable dentro del mismo registro.')
        return self
