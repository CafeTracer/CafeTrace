from pydantic import BaseModel, Field

class SimpleCatalogCreate(BaseModel):
    nombre: str = Field(min_length=2, max_length=80)
    descripcion: str | None = Field(default=None, max_length=150)

class DepartamentoCreate(BaseModel):
    nombre: str = Field(min_length=2, max_length=80)

class MunicipioCreate(BaseModel):
    id_departamento: int
    nombre: str = Field(min_length=2, max_length=80)

class UnidadMedidaCreate(BaseModel):
    nombre: str = Field(min_length=2, max_length=40)
    simbolo: str = Field(min_length=1, max_length=15)
    descripcion: str | None = Field(default=None, max_length=100)

class VariableMonitoreoCreate(BaseModel):
    nombre: str = Field(min_length=2, max_length=50)
    descripcion: str | None = Field(default=None, max_length=150)
    id_unidad_medida: int
    valor_minimo: float | None = None
    valor_maximo: float | None = None
    requiere_alerta: bool = False
