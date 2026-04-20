from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.core.deps import get_db, require_roles
from app.db.orm_models.alerta_lote import AlertaLote
from app.core.serializers import orm_to_dict

router = APIRouter(prefix="/alertas", tags=["Alertas"])

@router.get("")
def list_alertas(db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Supervisor","Operario"))):
    return {"data": [orm_to_dict(a) for a in db.execute(select(AlertaLote)).scalars().all()]}

@router.patch("/{id_alerta}/atender")
def atender_alerta(id_alerta: int, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Supervisor"))):
    obj = db.get(AlertaLote, id_alerta)
    if not obj:
        raise HTTPException(404, "Alerta no encontrada")
    obj.atendida = True
    db.commit(); db.refresh(obj)
    return {"data": orm_to_dict(obj)}
