from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.core.deps import get_db, require_roles
from app.db.orm_models.lote import Lote
from app.db.orm_models.registro_postcosecha import RegistroPostcosecha
from app.db.orm_models.estado_lote import EstadoLote
from app.modules.lotes.schemas import LoteCreate, LoteUpdate
from app.core.serializers import orm_to_dict

router = APIRouter(prefix="/lotes", tags=["Lotes"])


def get_estado_actual(db: Session, id_lote: int):
    ultimo = db.execute(
        select(RegistroPostcosecha).where(RegistroPostcosecha.id_lote == id_lote)
        .order_by(RegistroPostcosecha.fecha_hora.desc(), RegistroPostcosecha.id_registro.desc())
    ).scalars().first()
    if not ultimo:
        return None, None
    estado = db.get(EstadoLote, ultimo.id_estado_lote)
    return estado.nombre if estado else None, ultimo.fecha_hora

@router.get("")
def list_lotes(db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Operario","Supervisor"))):
    rows = db.execute(select(Lote)).scalars().all()
    data = []
    for row in rows:
        estado, fecha = get_estado_actual(db, row.id_lote)
        data.append({
            "id_lote": row.id_lote,
            "id_finca": row.id_finca,
            "nombre_finca": row.finca.nombre if row.finca else None,
            "id_variedad": row.id_variedad,
            "nombre_variedad": row.variedad.nombre if row.variedad else None,
            "codigo_lote": row.codigo_lote,
            "fecha_registro": row.fecha_registro,
            "cantidad_kg": row.cantidad_kg,
            "observaciones": row.observaciones,
            "activo": row.activo,
            "estado_actual": estado,
            "fecha_estado_actual": fecha,
        })
    return {"data": data}

@router.get("/{id_lote}")
def detail_lote(id_lote: int, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Operario","Supervisor"))):
    row = db.get(Lote, id_lote)
    if not row:
        raise HTTPException(404, "Lote no encontrado")
    estado, fecha = get_estado_actual(db, row.id_lote)
    return {"data": {
        "id_lote": row.id_lote,
        "id_finca": row.id_finca,
        "nombre_finca": row.finca.nombre if row.finca else None,
        "id_variedad": row.id_variedad,
        "nombre_variedad": row.variedad.nombre if row.variedad else None,
        "codigo_lote": row.codigo_lote,
        "fecha_registro": row.fecha_registro,
        "cantidad_kg": row.cantidad_kg,
        "observaciones": row.observaciones,
        "activo": row.activo,
        "estado_actual": estado,
        "nombre_estado": estado,
        "fecha_estado_actual": fecha,
    }}

@router.get("/{id_lote}/registros")
def list_registros_lote(id_lote: int, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Operario","Supervisor"))):
    lote = db.get(Lote, id_lote)
    if not lote:
        raise HTTPException(404, "Lote no encontrado")
    registros = db.execute(select(RegistroPostcosecha).where(RegistroPostcosecha.id_lote == id_lote)).scalars().all()
    return {"data": [orm_to_dict(r) for r in registros]}

@router.post("")
def create_lote(payload: LoteCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Operario"))):
    exists = db.execute(select(Lote).where(Lote.codigo_lote == payload.codigo_lote)).scalar_one_or_none()
    if exists:
        raise HTTPException(409, "Código de lote repetido")
    obj = Lote(**payload.model_dump())
    db.add(obj); db.commit(); db.refresh(obj)
    return {"data": orm_to_dict(obj)}

@router.put("/{id_lote}")
def update_lote(id_lote: int, payload: LoteUpdate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Operario"))):
    obj = db.get(Lote, id_lote)
    if not obj:
        raise HTTPException(404, "Lote no encontrado")
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(obj, k, v)
    db.commit(); db.refresh(obj)
    return {"data": orm_to_dict(obj)}

@router.delete("/{id_lote}")
def delete_lote(id_lote: int, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    obj = db.get(Lote, id_lote)
    if not obj:
        raise HTTPException(404, "Lote no encontrado")
    obj.activo = False
    db.commit()
    return {"data": {"desactivado": True}}
