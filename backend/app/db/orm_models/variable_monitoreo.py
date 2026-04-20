from sqlalchemy import Boolean, DECIMAL, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

class VariableMonitoreo(Base):
    __tablename__ = "variable_monitoreo"
    id_variable: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    nombre: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    descripcion: Mapped[str | None] = mapped_column(String(150), nullable=True)
    id_unidad_medida: Mapped[int] = mapped_column(ForeignKey("unidad_medida.id_unidad_medida", ondelete="RESTRICT"), nullable=False)
    valor_minimo: Mapped[float | None] = mapped_column(DECIMAL(10,2), nullable=True)
    valor_maximo: Mapped[float | None] = mapped_column(DECIMAL(10,2), nullable=True)
    requiere_alerta: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    unidad_medida = relationship("UnidadMedida", back_populates="variables")
    detalles = relationship("RegistroVariableDetalle", back_populates="variable")
