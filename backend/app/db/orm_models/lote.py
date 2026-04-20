from sqlalchemy import Boolean, Date, DECIMAL, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

class Lote(Base):
    __tablename__ = "lote"
    id_lote: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    id_finca: Mapped[int] = mapped_column(ForeignKey("finca.id_finca", ondelete="RESTRICT"), nullable=False)
    id_variedad: Mapped[int] = mapped_column(ForeignKey("variedad_cafe.id_variedad", ondelete="RESTRICT"), nullable=False)
    codigo_lote: Mapped[str] = mapped_column(String(30), unique=True, nullable=False)
    fecha_registro: Mapped[str] = mapped_column(Date, nullable=False)
    cantidad_kg: Mapped[float | None] = mapped_column(DECIMAL(10,2), nullable=True)
    observaciones: Mapped[str | None] = mapped_column(String(250), nullable=True)
    activo: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    finca = relationship("Finca", back_populates="lotes")
    variedad = relationship("VariedadCafe", back_populates="lotes")
    registros = relationship("RegistroPostcosecha", back_populates="lote")
