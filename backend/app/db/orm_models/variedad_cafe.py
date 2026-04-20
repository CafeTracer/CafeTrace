from sqlalchemy import Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

class VariedadCafe(Base):
    __tablename__ = "variedad_cafe"
    id_variedad: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    nombre: Mapped[str] = mapped_column(String(60), unique=True, nullable=False)
    descripcion: Mapped[str | None] = mapped_column(String(150), nullable=True)
    lotes = relationship("Lote", back_populates="variedad")
