from sqlalchemy import Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

class UnidadMedida(Base):
    __tablename__ = "unidad_medida"
    __table_args__ = (UniqueConstraint("nombre", "simbolo", name="uq_unidad_medida"),)
    id_unidad_medida: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    nombre: Mapped[str] = mapped_column(String(40), nullable=False)
    simbolo: Mapped[str] = mapped_column(String(15), nullable=False)
    descripcion: Mapped[str | None] = mapped_column(String(100), nullable=True)
    variables = relationship("VariableMonitoreo", back_populates="unidad_medida")
