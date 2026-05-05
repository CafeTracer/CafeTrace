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
    "municipios": Municipio,
    "variables": VariableMonitoreo,
}

@router.get("/{catalogo}")
def list_catalog(
    catalogo: str,
    id_departamento: int | None = None,
    db: Session = Depends(get_db),
    _: object = Depends(require_roles("Administrador","Operario","Supervisor")),
):
    # Normalize and perform case-insensitive lookup to be resilient to client variations
    catalogo_key = (catalogo or '').strip().lower()
    model = next((m for k, m in MODELS.items() if k.lower() == catalogo_key), None)

    # Fallbacks: singular/plural and hyphen/underscore variants
    if model is None:
        if catalogo_key.endswith('s'):
            base = catalogo_key[:-1]
            model = next((m for k, m in MODELS.items() if k.lower() == base), None)
    if model is None:
        alt = catalogo_key.replace('-', '_')
        model = next((m for k, m in MODELS.items() if k.lower() == alt), None)

    if model is None:
        print(f"DEBUG: unknown catalogo requested: '{catalogo}' (normalized='{catalogo_key}'). Available: {list(MODELS.keys())}")
        raise HTTPException(404, "Catálogo no soportado")

    # Special-case: allow filtering municipios by departamento via query param
    if catalogo == "municipios":
        if id_departamento is not None:
            rows = db.execute(select(Municipio).where(Municipio.id_departamento == id_departamento)).scalars().all()
        else:
            rows = db.execute(select(Municipio)).scalars().all()
        return {"data": [orm_to_dict(r) for r in rows]}

    # Default: return all rows for the requested model
    rows = db.execute(select(model)).scalars().all()
    return {"data": [orm_to_dict(r) for r in rows]}


@router.get('/municipios')
def list_municipios(
    id_departamento: int | None = None,
    db: Session = Depends(get_db),
    _: object = Depends(require_roles("Administrador","Operario","Supervisor")),
):
    if id_departamento is not None:
        rows = db.execute(select(Municipio).where(Municipio.id_departamento == id_departamento)).scalars().all()
    else:
        rows = db.execute(select(Municipio)).scalars().all()
    return {"data": [orm_to_dict(r) for r in rows]}


@router.get('/variables')
def list_variables(
    db: Session = Depends(get_db),
    _: object = Depends(require_roles("Administrador","Operario","Supervisor")),
):
    rows = db.execute(select(VariableMonitoreo)).scalars().all()
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
