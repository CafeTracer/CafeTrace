from sqlalchemy import DECIMAL, ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

class RegistroVariableDetalle(Base):
    __tablename__ = "registro_variable_detalle"
    __table_args__ = (UniqueConstraint("id_registro", "id_variable", name="uq_detalle_registro_variable"),)
    id_detalle: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    id_registro: Mapped[int] = mapped_column(ForeignKey("registro_postcosecha.id_registro", ondelete="CASCADE"), nullable=False)
    id_variable: Mapped[int] = mapped_column(ForeignKey("variable_monitoreo.id_variable", ondelete="RESTRICT"), nullable=False)
    valor: Mapped[float] = mapped_column(DECIMAL(10,2), nullable=False)
    comentario: Mapped[str | None] = mapped_column(String(150), nullable=True)
    registro = relationship("RegistroPostcosecha", back_populates="detalles")
    variable = relationship("VariableMonitoreo", back_populates="detalles")
    alertas = relationship("AlertaLote", back_populates="detalle", cascade="all, delete-orphan")
