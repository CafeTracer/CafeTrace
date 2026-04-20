from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.core.deps import get_db, require_roles
from app.db.orm_models import Rol, Departamento, Municipio, VariedadCafe, EstadoLote, TipoActividad, UnidadMedida, VariableMonitoreo
from app.modules.catalogos.schemas import DepartamentoCreate, MunicipioCreate, SimpleCatalogCreate, UnidadMedidaCreate, VariableMonitoreoCreate
from app.core.serializers import orm_to_dict

router = APIRouter(prefix="/catalogos", tags=["Catálogos"])

MODELS = {
    "roles": Rol,
    "departamentos": Departamento,
    "variedades": VariedadCafe,
    "estados-lote": EstadoLote,
    "tipos-actividad": TipoActividad,
}

@router.get("/{catalogo}")
def list_catalog(catalogo: str, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Operario","Supervisor"))):
    model = MODELS.get(catalogo)
    if not model:
        raise HTTPException(404, "Catálogo no soportado")
    rows = db.execute(select(model)).scalars().all()
    return {"data": [orm_to_dict(r) for r in rows]}

@router.post("/departamentos")
def create_departamento(payload: DepartamentoCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    obj = Departamento(nombre=payload.nombre)
    db.add(obj); db.commit(); db.refresh(obj)
    return {"data": orm_to_dict(obj)}

@router.post("/municipios")
def create_municipio(payload: MunicipioCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    obj = Municipio(id_departamento=payload.id_departamento, nombre=payload.nombre)
    db.add(obj); db.commit(); db.refresh(obj)
    return {"data": orm_to_dict(obj)}

@router.post("/roles")
def create_rol(payload: SimpleCatalogCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    obj = Rol(nombre=payload.nombre, descripcion=payload.descripcion)
    db.add(obj); db.commit(); db.refresh(obj)
    return {"data": orm_to_dict(obj)}

@router.post("/variedades")
def create_variedad(payload: SimpleCatalogCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    obj = VariedadCafe(nombre=payload.nombre, descripcion=payload.descripcion)
    db.add(obj); db.commit(); db.refresh(obj)
    return {"data": orm_to_dict(obj)}

@router.post("/estados-lote")
def create_estado(payload: SimpleCatalogCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    obj = EstadoLote(nombre=payload.nombre, descripcion=payload.descripcion)
    db.add(obj); db.commit(); db.refresh(obj)
    return {"data": orm_to_dict(obj)}

@router.post("/tipos-actividad")
def create_tipo(payload: SimpleCatalogCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    obj = TipoActividad(nombre=payload.nombre, descripcion=payload.descripcion)
    db.add(obj); db.commit(); db.refresh(obj)
    return {"data": orm_to_dict(obj)}

@router.post("/unidades-medida")
def create_unidad(payload: UnidadMedidaCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    obj = UnidadMedida(nombre=payload.nombre, simbolo=payload.simbolo, descripcion=payload.descripcion)
    db.add(obj); db.commit(); db.refresh(obj)
    return {"data": orm_to_dict(obj)}

@router.post("/variables")
def create_variable(payload: VariableMonitoreoCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    obj = VariableMonitoreo(**payload.model_dump())
    db.add(obj); db.commit(); db.refresh(obj)
    return {"data": orm_to_dict(obj)}
