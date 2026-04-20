from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

class AlertaLote(Base):
    __tablename__ = "alerta_lote"
    id_alerta: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    id_detalle: Mapped[int] = mapped_column(ForeignKey("registro_variable_detalle.id_detalle", ondelete="CASCADE"), nullable=False)
    mensaje: Mapped[str] = mapped_column(String(200), nullable=False)
    nivel: Mapped[str] = mapped_column(String(20), nullable=False)
    atendida: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)
    fecha_alerta: Mapped[str] = mapped_column(DateTime, server_default=func.current_timestamp(), nullable=False)
    detalle = relationship("RegistroVariableDetalle", back_populates="alertas")
