from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.core.deps import get_db, require_roles
from app.core.security import hash_password
from app.db.orm_models.usuario import Usuario
from app.modules.usuarios.schemas import UsuarioCreate, UsuarioUpdate
from app.core.serializers import orm_to_dict

router = APIRouter(prefix="/usuarios", tags=["Usuarios"])

@router.get("")
def list_users(db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Supervisor"))):
    return {"data": [orm_to_dict(u) for u in db.execute(select(Usuario)).scalars().all()]}

@router.post("")
def create_user(payload: UsuarioCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    exists = db.execute(select(Usuario).where(Usuario.correo == payload.correo)).scalar_one_or_none()
    if exists:
        raise HTTPException(409, "Correo ya existe")
    obj = Usuario(
        id_rol=payload.id_rol,
        nombre=payload.nombre,
        apellido=payload.apellido,
        correo=payload.correo,
        password_hash=hash_password(payload.password),
        telefono=payload.telefono,
    )
    db.add(obj); db.commit(); db.refresh(obj)
    return {"data": orm_to_dict(obj)}

@router.put("/{id_usuario}")
def update_user(id_usuario: int, payload: UsuarioUpdate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    obj = db.get(Usuario, id_usuario)
    if not obj:
        raise HTTPException(404, "Usuario no encontrado")
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(obj, k, v)
    db.commit(); db.refresh(obj)
    return {"data": orm_to_dict(obj)}

@router.delete("/{id_usuario}")
def disable_user(id_usuario: int, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    obj = db.get(Usuario, id_usuario)
    if not obj:
        raise HTTPException(404, "Usuario no encontrado")
    obj.activo = False
    db.commit()
    return {"data": {"desactivado": True}}
