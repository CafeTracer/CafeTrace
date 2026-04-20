from sqlalchemy import DateTime, DECIMAL, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

class Finca(Base):
    __tablename__ = "finca"
    id_finca: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    id_municipio: Mapped[int] = mapped_column(ForeignKey("municipio.id_municipio", ondelete="RESTRICT"), nullable=False)
    nombre: Mapped[str] = mapped_column(String(100), nullable=False)
    propietario: Mapped[str] = mapped_column(String(120), nullable=False)
    direccion: Mapped[str | None] = mapped_column(String(150), nullable=True)
    latitud: Mapped[float | None] = mapped_column(DECIMAL(10,7), nullable=True)
    longitud: Mapped[float | None] = mapped_column(DECIMAL(10,7), nullable=True)
    area_hectareas: Mapped[float | None] = mapped_column(DECIMAL(10,2), nullable=True)
    descripcion: Mapped[str | None] = mapped_column(String(200), nullable=True)
    fecha_creacion: Mapped[str] = mapped_column(DateTime, server_default=func.current_timestamp(), nullable=False)
    municipio = relationship("Municipio", back_populates="fincas")
    lotes = relationship("Lote", back_populates="finca")
