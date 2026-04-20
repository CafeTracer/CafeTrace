from sqlalchemy import DateTime, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

class EvidenciaRegistro(Base):
    __tablename__ = "evidencia_registro"
    id_evidencia: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    id_registro: Mapped[int] = mapped_column(ForeignKey("registro_postcosecha.id_registro", ondelete="CASCADE"), nullable=False)
    nombre_archivo: Mapped[str] = mapped_column(String(120), nullable=False)
    ruta_archivo: Mapped[str] = mapped_column(String(255), nullable=False)
    tipo_archivo: Mapped[str] = mapped_column(String(30), nullable=False)
    fecha_subida: Mapped[str] = mapped_column(DateTime, server_default=func.current_timestamp(), nullable=False)
    registro = relationship("RegistroPostcosecha", back_populates="evidencias")
