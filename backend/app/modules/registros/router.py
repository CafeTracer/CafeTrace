from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.core.deps import get_db, require_roles
from app.db.orm_models import RegistroPostcosecha, RegistroVariableDetalle, VariableMonitoreo, AlertaLote
from app.modules.registros.schemas import RegistroCreate, RegistroBatchCreate
from app.core.serializers import orm_to_dict

router = APIRouter(prefix="/registros", tags=["Registros"])

@router.get("")
def list_registros(db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Operario","Supervisor"))):
    return {"data": [orm_to_dict(r) for r in db.execute(select(RegistroPostcosecha)).scalars().all()]}

@router.post("")
def create_registro(payload: RegistroCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Operario"))):
    obj = RegistroPostcosecha(**payload.model_dump())
    db.add(obj); db.commit(); db.refresh(obj)
    return {"data": orm_to_dict(obj)}

@router.put("/{id_registro}")
def update_registro(id_registro: int, payload: RegistroCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Operario"))):
    obj = db.get(RegistroPostcosecha, id_registro)
    if not obj:
        raise HTTPException(404, "Registro no encontrado")
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(obj, k, v)
    db.commit(); db.refresh(obj)
    return {"data": orm_to_dict(obj)}

@router.delete("/{id_registro}")
def delete_registro(id_registro: int, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    obj = db.get(RegistroPostcosecha, id_registro)
    if not obj:
        raise HTTPException(404, "Registro no encontrado")
    db.delete(obj); db.commit()
    return {"data": {"eliminado": True}}

@router.post("/lotes/{id_lote}")
def create_batch(id_lote: int, payload: RegistroBatchCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Operario"))):
    with db.begin():
        registro = RegistroPostcosecha(
            id_lote=id_lote,
            id_usuario=payload.id_usuario,
            id_tipo_actividad=payload.id_tipo_actividad,
            id_estado_lote=payload.id_estado_lote,
            fecha_hora=payload.fecha_hora,
            observacion=payload.observacion,
            ubicacion_registro=payload.ubicacion_registro,
        )
        db.add(registro)
        db.flush()
        alertas = 0
        for item in payload.variables:
            detalle = RegistroVariableDetalle(
                id_registro=registro.id_registro,
                id_variable=item.id_variable,
                valor=item.valor,
                comentario=item.comentario,
            )
            db.add(detalle)
            db.flush()
            variable = db.get(VariableMonitoreo, item.id_variable)
            if variable and variable.requiere_alerta:
                minimo = float(variable.valor_minimo) if variable.valor_minimo is not None else None
                maximo = float(variable.valor_maximo) if variable.valor_maximo is not None else None
                fuera = (minimo is not None and item.valor < minimo) or (maximo is not None and item.valor > maximo)
                if fuera:
                    db.add(AlertaLote(
                        id_detalle=detalle.id_detalle,
                        mensaje=f"Valor fuera de umbral para {variable.nombre}",
                        nivel="Alta",
                    ))
                    alertas += 1
    return {"data": {"id_registro": registro.id_registro, "id_lote": id_lote, "alertas_generadas": alertas}}
