from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.core.deps import get_db, require_roles
from app.db.orm_models.finca import Finca
from app.modules.fincas.schemas import FincaCreate, FincaUpdate
from app.core.serializers import orm_to_dict

router = APIRouter(prefix="/fincas", tags=["Fincas"])

@router.get("")
def list_fincas(db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Operario","Supervisor"))):
    return {"data": [orm_to_dict(f) for f in db.execute(select(Finca)).scalars().all()]}

@router.post("")
def create_finca(payload: FincaCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Operario"))):
    obj = Finca(**payload.model_dump())
    db.add(obj); db.commit(); db.refresh(obj)
    return {"data": orm_to_dict(obj)}

@router.put("/{id_finca}")
def update_finca(id_finca: int, payload: FincaUpdate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Operario"))):
    obj = db.get(Finca, id_finca)
    if not obj:
        raise HTTPException(404, "Finca no encontrada")
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(obj, k, v)
    db.commit(); db.refresh(obj)
    return {"data": orm_to_dict(obj)}

@router.delete("/{id_finca}")
def delete_finca(id_finca: int, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    obj = db.get(Finca, id_finca)
    if not obj:
        raise HTTPException(404, "Finca no encontrada")
    db.delete(obj); db.commit()
    return {"data": {"eliminado": True}}
