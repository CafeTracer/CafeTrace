from sqlalchemy import ForeignKey, Integer, String, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

class Municipio(Base):
    __tablename__ = "municipio"
    __table_args__ = (UniqueConstraint("id_departamento", "nombre", name="uq_municipio"),)
    id_municipio: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    id_departamento: Mapped[int] = mapped_column(ForeignKey("departamento.id_departamento", ondelete="RESTRICT"), nullable=False)
    nombre: Mapped[str] = mapped_column(String(80), nullable=False)
    departamento = relationship("Departamento", back_populates="municipios")
    fincas = relationship("Finca", back_populates="municipio")
