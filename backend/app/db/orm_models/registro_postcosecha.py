from sqlalchemy import DateTime, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

class RegistroPostcosecha(Base):
    __tablename__ = "registro_postcosecha"
    id_registro: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    id_lote: Mapped[int] = mapped_column(ForeignKey("lote.id_lote", ondelete="RESTRICT"), nullable=False)
    id_usuario: Mapped[int] = mapped_column(ForeignKey("usuario.id_usuario", ondelete="RESTRICT"), nullable=False)
    id_tipo_actividad: Mapped[int] = mapped_column(ForeignKey("tipo_actividad.id_tipo_actividad", ondelete="RESTRICT"), nullable=False)
    id_estado_lote: Mapped[int] = mapped_column(ForeignKey("estado_lote.id_estado_lote", ondelete="RESTRICT"), nullable=False)
    fecha_hora: Mapped[str] = mapped_column(DateTime, server_default=func.current_timestamp(), nullable=False)
    observacion: Mapped[str | None] = mapped_column(String(250), nullable=True)
    ubicacion_registro: Mapped[str | None] = mapped_column(String(120), nullable=True)
    creado_en: Mapped[str] = mapped_column(DateTime, server_default=func.current_timestamp(), nullable=False)
    lote = relationship("Lote", back_populates="registros")
    usuario = relationship("Usuario", back_populates="registros")
    tipo_actividad = relationship("TipoActividad", back_populates="registros")
    estado_lote = relationship("EstadoLote", back_populates="registros")
    detalles = relationship("RegistroVariableDetalle", back_populates="registro", cascade="all, delete-orphan")
    evidencias = relationship("EvidenciaRegistro", back_populates="registro", cascade="all, delete-orphan")
