from sqlalchemy import Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

class TipoActividad(Base):
    __tablename__ = "tipo_actividad"
    id_tipo_actividad: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    nombre: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    descripcion: Mapped[str | None] = mapped_column(String(150), nullable=True)
    registros = relationship("RegistroPostcosecha", back_populates="tipo_actividad")
