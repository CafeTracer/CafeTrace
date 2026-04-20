from pathlib import Path
root = Path('/mnt/data/postcosecha_backend')
files = {}

files['README.md'] = '''# Backend Postcosecha Café

Repositorio base para un backend REST con **FastAPI + SQLAlchemy + MySQL**, organizado con enfoque **Vertical Slice + Arquitectura Hexagonal ligera**.

## Qué incluye
- Esquema SQL corregido sin redundancia de estado en `lote`.
- CRUD base para:
  - catálogos
  - usuarios
  - fincas
  - lotes
  - registros de postcosecha
  - alertas
- JWT con roles: `Administrador`, `Operario`, `Supervisor`.
- Docker Compose con API + MySQL.
- Alembic inicializado.
- Estructura lista para crecer con JSON más adelante.

## Estructura
```text
app/
  core/          # configuración, seguridad, dependencias, errores
  db/            # sesión, base ORM, modelos
  modules/
    auth/
    catalogos/
    usuarios/
    fincas/
    lotes/
    registros/
    alertas/
  main.py
sql/
  schema.sql
alembic/
docker/
tests/
```

## Cómo levantarlo
```bash
cp .env.example .env
docker compose up --build
```

API: `http://localhost:8000`
Swagger: `http://localhost:8000/docs`

## Roles esperados
- **Administrador**: CRUD total.
- **Operario**: crea y actualiza lotes, fincas y registros.
- **Supervisor**: lectura y atención de alertas.

## Flujo sugerido de trabajo
1. Ejecutar `sql/schema.sql` o levantar con Docker.
2. Crear migraciones con Alembic si cambias modelos.
3. Empezar por `/auth/login`.
4. Poblar catálogos.
5. Crear usuarios, fincas, lotes y luego registros.
6. Añadir payloads JSON más complejos sobre el módulo `registros`.

## Nota académica
El proyecto está pensado como base uniforme para el informe. Algunas operaciones de negocio están implementadas como esqueleto sólido para que ustedes las completen o ajusten según lo que les pida el docente.
'''

files['.env.example'] = '''APP_NAME=Postcosecha Cafe API
APP_ENV=dev
APP_DEBUG=true
API_PREFIX=/api/v1
JWT_SECRET=change-this-secret
JWT_ALGORITHM=HS256
JWT_EXPIRE_MINUTES=60
DATABASE_URL=mysql+pymysql://postcosecha:postcosecha@db:3306/postcosecha_cafe
ROOT_PATH=
RATE_LIMIT_PER_MINUTE=60
'''

files['requirements.txt'] = '''fastapi==0.116.1
uvicorn[standard]==0.35.0
sqlalchemy==2.0.43
pymysql==1.1.1
python-multipart==0.0.20
PyJWT==2.10.1
pwdlib==0.2.1
pydantic==2.11.7
pydantic-settings==2.10.1
alembic==1.16.4
pytest==8.4.1
httpx==0.28.1
'''

files['docker-compose.yml'] = '''services:
  db:
    image: mysql:8.0
    container_name: postcosecha_db
    restart: unless-stopped
    environment:
      MYSQL_DATABASE: postcosecha_cafe
      MYSQL_USER: postcosecha
      MYSQL_PASSWORD: postcosecha
      MYSQL_ROOT_PASSWORD: root
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./sql/schema.sql:/docker-entrypoint-initdb.d/01_schema.sql:ro
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost", "-uroot", "-proot"]
      interval: 10s
      timeout: 5s
      retries: 10

  api:
    build:
      context: .
      dockerfile: docker/Dockerfile
    container_name: postcosecha_api
    restart: unless-stopped
    env_file:
      - .env
    depends_on:
      db:
        condition: service_healthy
    ports:
      - "8000:8000"
    volumes:
      - ./:/app

volumes:
  mysql_data:
'''

files['docker/Dockerfile'] = '''FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
'''

files['sql/schema.sql'] = Path('/mnt/data/Pasted text.txt').read_text() if Path('/mnt/data/Pasted text.txt').exists() else ''

# core
files['app/__init__.py'] = ''
files['app/main.py'] = '''from fastapi import FastAPI
from app.core.config import settings
from app.core.errors import register_exception_handlers
from app.modules.auth.router import router as auth_router
from app.modules.catalogos.router import router as catalogos_router
from app.modules.usuarios.router import router as usuarios_router
from app.modules.fincas.router import router as fincas_router
from app.modules.lotes.router import router as lotes_router
from app.modules.registros.router import router as registros_router
from app.modules.alertas.router import router as alertas_router

app = FastAPI(
    title=settings.app_name,
    debug=settings.app_debug,
    root_path=settings.root_path,
    version="1.0.0"
)

register_exception_handlers(app)

app.include_router(auth_router, prefix=settings.api_prefix)
app.include_router(catalogos_router, prefix=settings.api_prefix)
app.include_router(usuarios_router, prefix=settings.api_prefix)
app.include_router(fincas_router, prefix=settings.api_prefix)
app.include_router(lotes_router, prefix=settings.api_prefix)
app.include_router(registros_router, prefix=settings.api_prefix)
app.include_router(alertas_router, prefix=settings.api_prefix)

@app.get("/")
def health():
    return {"message": "API Postcosecha activa"}
'''

files['app/core/config.py'] = '''from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    app_name: str = "Postcosecha Cafe API"
    app_env: str = "dev"
    app_debug: bool = True
    api_prefix: str = "/api/v1"
    jwt_secret: str = "change-this-secret"
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 60
    database_url: str = "mysql+pymysql://postcosecha:postcosecha@localhost:3306/postcosecha_cafe"
    root_path: str = ""
    rate_limit_per_minute: int = 60

    model_config = SettingsConfigDict(env_file='.env', extra='ignore')

settings = Settings()
'''

files['app/core/security.py'] = '''from datetime import datetime, timedelta, timezone
import jwt
from pwdlib import PasswordHash
from fastapi import HTTPException, status
from app.core.config import settings

password_hasher = PasswordHash.recommended()

ROLE_SCOPES = {
    "Administrador": {"*"},
    "Operario": {
        "catalogos:read", "usuarios:read", "fincas:read", "fincas:write",
        "lotes:read", "lotes:write", "registros:read", "registros:write",
        "alertas:read"
    },
    "Supervisor": {
        "catalogos:read", "usuarios:read", "fincas:read", "lotes:read",
        "registros:read", "alertas:read", "alertas:write"
    }
}


def hash_password(password: str) -> str:
    return password_hasher.hash(password)


def verify_password(password: str, password_hash: str) -> bool:
    return password_hasher.verify(password, password_hash)


def create_access_token(user_id: int, email: str, role: str) -> str:
    expire = datetime.now(timezone.utc) + timedelta(minutes=settings.jwt_expire_minutes)
    payload = {
        "sub": str(user_id),
        "email": email,
        "role": role,
        "scopes": list(ROLE_SCOPES.get(role, set())),
        "exp": expire,
    }
    return jwt.encode(payload, settings.jwt_secret, algorithm=settings.jwt_algorithm)


def decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
    except jwt.PyJWTError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Token inválido") from exc
'''

files['app/core/deps.py'] = '''from typing import Generator
from fastapi import Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from app.db.session import SessionLocal
from app.core.security import decode_token
from app.db.orm_models.usuario import Usuario

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/login")


def get_db() -> Generator[Session, None, None]:
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def get_current_user(token: str = Depends(oauth2_scheme), db: Session = Depends(get_db)) -> Usuario:
    payload = decode_token(token)
    user = db.get(Usuario, int(payload["sub"]))
    if not user or not user.activo:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Usuario inválido")
    return user


def require_roles(*allowed_roles: str):
    def validator(current_user: Usuario = Depends(get_current_user)) -> Usuario:
        if current_user.rol.nombre not in allowed_roles:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="No autorizado")
        return current_user
    return validator
'''

files['app/core/errors.py'] = '''from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from starlette import status


def register_exception_handlers(app: FastAPI):
    @app.exception_handler(RequestValidationError)
    async def validation_handler(_: Request, exc: RequestValidationError):
        return JSONResponse(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            content={
                "error": {
                    "codigo": "VALIDATION_ERROR",
                    "mensaje": "La solicitud no cumple el esquema esperado.",
                    "detalle": exc.errors(),
                }
            },
        )
'''

files['app/core/schemas.py'] = '''from typing import Generic, TypeVar, Optional
from pydantic import BaseModel, Field

T = TypeVar("T")

class MetaPage(BaseModel):
    limit: int = Field(default=50, ge=1, le=100)
    offset: int = Field(default=0, ge=0)
    total: int = Field(default=0, ge=0)

class Envelope(BaseModel, Generic[T]):
    data: T

class ListEnvelope(BaseModel, Generic[T]):
    data: list[T]
    meta: MetaPage

class MessageOut(BaseModel):
    message: str
'''

# db base/session/__init__
files['app/db/__init__.py'] = ''
files['app/db/base.py'] = '''from sqlalchemy.orm import DeclarativeBase

class Base(DeclarativeBase):
    pass
'''
files['app/db/session.py'] = '''from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.core.config import settings

engine = create_engine(settings.database_url, pool_pre_ping=True, pool_recycle=3600)
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)
'''

# ORM models
files['app/db/orm_models/__init__.py'] = '''from .rol import Rol
from .departamento import Departamento
from .municipio import Municipio
from .variedad_cafe import VariedadCafe
from .estado_lote import EstadoLote
from .tipo_actividad import TipoActividad
from .unidad_medida import UnidadMedida
from .variable_monitoreo import VariableMonitoreo
from .usuario import Usuario
from .finca import Finca
from .lote import Lote
from .registro_postcosecha import RegistroPostcosecha
from .registro_variable_detalle import RegistroVariableDetalle
from .evidencia_registro import EvidenciaRegistro
from .alerta_lote import AlertaLote
'''

model_templates = {
'rol.py': '''from sqlalchemy import Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

class Rol(Base):
    __tablename__ = "rol"
    id_rol: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    nombre: Mapped[str] = mapped_column(String(30), unique=True, nullable=False)
    descripcion: Mapped[str | None] = mapped_column(String(150), nullable=True)
    usuarios = relationship("Usuario", back_populates="rol")
''',
'departamento.py': '''from sqlalchemy import Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

class Departamento(Base):
    __tablename__ = "departamento"
    id_departamento: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    nombre: Mapped[str] = mapped_column(String(80), unique=True, nullable=False)
    municipios = relationship("Municipio", back_populates="departamento")
''',
'municipio.py': '''from sqlalchemy import ForeignKey, Integer, String, UniqueConstraint
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
''',
'variedad_cafe.py': '''from sqlalchemy import Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

class VariedadCafe(Base):
    __tablename__ = "variedad_cafe"
    id_variedad: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    nombre: Mapped[str] = mapped_column(String(60), unique=True, nullable=False)
    descripcion: Mapped[str | None] = mapped_column(String(150), nullable=True)
    lotes = relationship("Lote", back_populates="variedad")
''',
'estado_lote.py': '''from sqlalchemy import Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

class EstadoLote(Base):
    __tablename__ = "estado_lote"
    id_estado_lote: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    nombre: Mapped[str] = mapped_column(String(40), unique=True, nullable=False)
    descripcion: Mapped[str | None] = mapped_column(String(150), nullable=True)
    registros = relationship("RegistroPostcosecha", back_populates="estado_lote")
''',
'tipo_actividad.py': '''from sqlalchemy import Integer, String
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

class TipoActividad(Base):
    __tablename__ = "tipo_actividad"
    id_tipo_actividad: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    nombre: Mapped[str] = mapped_column(String(50), unique=True, nullable=False)
    descripcion: Mapped[str | None] = mapped_column(String(150), nullable=True)
    registros = relationship("RegistroPostcosecha", back_populates="tipo_actividad")
''',
'unidad_medida.py': '''from sqlalchemy import Integer, String, UniqueConstraint
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
''',
'variable_monitoreo.py': '''from sqlalchemy import Boolean, DECIMAL, ForeignKey, Integer, String
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
''',
'usuario.py': '''from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, func
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.db.base import Base

class Usuario(Base):
    __tablename__ = "usuario"
    id_usuario: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    id_rol: Mapped[int] = mapped_column(ForeignKey("rol.id_rol", ondelete="RESTRICT"), nullable=False)
    nombre: Mapped[str] = mapped_column(String(100), nullable=False)
    apellido: Mapped[str] = mapped_column(String(100), nullable=False)
    correo: Mapped[str] = mapped_column(String(120), unique=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String(255), nullable=False)
    telefono: Mapped[str | None] = mapped_column(String(20), nullable=True)
    activo: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    fecha_creacion: Mapped[str] = mapped_column(DateTime, server_default=func.current_timestamp(), nullable=False)
    rol = relationship("Rol", back_populates="usuarios")
    registros = relationship("RegistroPostcosecha", back_populates="usuario")
''',
'finca.py': '''from sqlalchemy import DateTime, DECIMAL, ForeignKey, Integer, String, func
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
''',
'lote.py': '''from sqlalchemy import Boolean, Date, DECIMAL, ForeignKey, Integer, String
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
''',
'registro_postcosecha.py': '''from sqlalchemy import DateTime, ForeignKey, Integer, String, func
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
''',
'registro_variable_detalle.py': '''from sqlalchemy import DECIMAL, ForeignKey, Integer, String, UniqueConstraint
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
''',
'evidencia_registro.py': '''from sqlalchemy import DateTime, ForeignKey, Integer, String, func
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
''',
'alerta_lote.py': '''from sqlalchemy import Boolean, DateTime, ForeignKey, Integer, String, func
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
'''
}
for name, content in model_templates.items():
    files[f'app/db/orm_models/{name}'] = content

# module helpers
files['app/modules/__init__.py'] = ''
for module in ['auth','usuarios','fincas','lotes','registros','alertas','catalogos']:
    files[f'app/modules/{module}/__init__.py'] = ''

files['app/modules/auth/schemas.py'] = '''from pydantic import BaseModel, EmailStr

class LoginIn(BaseModel):
    correo: EmailStr
    password: str

class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
'''
files['app/modules/auth/service.py'] = '''from fastapi import HTTPException, status
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.db.orm_models.usuario import Usuario
from app.core.security import verify_password, create_access_token

class AuthService:
    def __init__(self, db: Session):
        self.db = db

    def login(self, username: str, password: str) -> dict:
        user = self.db.execute(select(Usuario).where(Usuario.correo == username)).scalar_one_or_none()
        if not user or not verify_password(password, user.password_hash):
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Credenciales inválidas")
        if not user.activo:
            raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Usuario inactivo")
        token = create_access_token(user.id_usuario, user.correo, user.rol.nombre)
        return {"access_token": token, "token_type": "bearer"}
'''
files['app/modules/auth/router.py'] = '''from fastapi import APIRouter, Depends
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from app.core.deps import get_db, get_current_user
from app.modules.auth.service import AuthService
from app.modules.auth.schemas import TokenOut

router = APIRouter(prefix="/auth", tags=["Auth"])

@router.post("/login", response_model=TokenOut)
def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    return AuthService(db).login(form_data.username, form_data.password)

@router.get("/me")
def me(current_user = Depends(get_current_user)):
    return {
        "data": {
            "id_usuario": current_user.id_usuario,
            "correo": current_user.correo,
            "nombre": current_user.nombre,
            "apellido": current_user.apellido,
            "rol": current_user.rol.nombre,
        }
    }
'''

# generic simple repositories/services for catalogos, usuarios, fincas, lotes, alertas
files['app/modules/catalogos/schemas.py'] = '''from pydantic import BaseModel, Field

class SimpleCatalogCreate(BaseModel):
    nombre: str = Field(min_length=2, max_length=80)
    descripcion: str | None = Field(default=None, max_length=150)

class DepartamentoCreate(BaseModel):
    nombre: str = Field(min_length=2, max_length=80)

class MunicipioCreate(BaseModel):
    id_departamento: int
    nombre: str = Field(min_length=2, max_length=80)

class UnidadMedidaCreate(BaseModel):
    nombre: str = Field(min_length=2, max_length=40)
    simbolo: str = Field(min_length=1, max_length=15)
    descripcion: str | None = Field(default=None, max_length=100)

class VariableMonitoreoCreate(BaseModel):
    nombre: str = Field(min_length=2, max_length=50)
    descripcion: str | None = Field(default=None, max_length=150)
    id_unidad_medida: int
    valor_minimo: float | None = None
    valor_maximo: float | None = None
    requiere_alerta: bool = False
'''
files['app/modules/catalogos/router.py'] = '''from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.core.deps import get_db, require_roles
from app.db.orm_models import Rol, Departamento, Municipio, VariedadCafe, EstadoLote, TipoActividad, UnidadMedida, VariableMonitoreo
from app.modules.catalogos.schemas import DepartamentoCreate, MunicipioCreate, SimpleCatalogCreate, UnidadMedidaCreate, VariableMonitoreoCreate

router = APIRouter(prefix="/catalogos", tags=["Catálogos"])

MODELS = {
    "roles": Rol,
    "departamentos": Departamento,
    "variedades": VariedadCafe,
    "estados-lote": EstadoLote,
    "tipos-actividad": TipoActividad,
}

@router.get("/{catalogo}")
def list_catalog(catalogo: str, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Operario","Supervisor"))):
    model = MODELS.get(catalogo)
    if not model:
        raise HTTPException(404, "Catálogo no soportado")
    rows = db.execute(select(model)).scalars().all()
    return {"data": rows}

@router.post("/departamentos")
def create_departamento(payload: DepartamentoCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    obj = Departamento(nombre=payload.nombre)
    db.add(obj); db.commit(); db.refresh(obj)
    return {"data": obj}

@router.post("/municipios")
def create_municipio(payload: MunicipioCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    obj = Municipio(id_departamento=payload.id_departamento, nombre=payload.nombre)
    db.add(obj); db.commit(); db.refresh(obj)
    return {"data": obj}

@router.post("/roles")
def create_rol(payload: SimpleCatalogCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    obj = Rol(nombre=payload.nombre, descripcion=payload.descripcion)
    db.add(obj); db.commit(); db.refresh(obj)
    return {"data": obj}

@router.post("/variedades")
def create_variedad(payload: SimpleCatalogCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    obj = VariedadCafe(nombre=payload.nombre, descripcion=payload.descripcion)
    db.add(obj); db.commit(); db.refresh(obj)
    return {"data": obj}

@router.post("/estados-lote")
def create_estado(payload: SimpleCatalogCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    obj = EstadoLote(nombre=payload.nombre, descripcion=payload.descripcion)
    db.add(obj); db.commit(); db.refresh(obj)
    return {"data": obj}

@router.post("/tipos-actividad")
def create_tipo(payload: SimpleCatalogCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    obj = TipoActividad(nombre=payload.nombre, descripcion=payload.descripcion)
    db.add(obj); db.commit(); db.refresh(obj)
    return {"data": obj}

@router.post("/unidades-medida")
def create_unidad(payload: UnidadMedidaCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    obj = UnidadMedida(nombre=payload.nombre, simbolo=payload.simbolo, descripcion=payload.descripcion)
    db.add(obj); db.commit(); db.refresh(obj)
    return {"data": obj}

@router.post("/variables")
def create_variable(payload: VariableMonitoreoCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    obj = VariableMonitoreo(**payload.model_dump())
    db.add(obj); db.commit(); db.refresh(obj)
    return {"data": obj}
'''

files['app/modules/usuarios/schemas.py'] = '''from datetime import datetime
from pydantic import BaseModel, EmailStr, Field

class UsuarioCreate(BaseModel):
    id_rol: int
    nombre: str = Field(min_length=2, max_length=100)
    apellido: str = Field(min_length=2, max_length=100)
    correo: EmailStr
    password: str = Field(min_length=8, max_length=128)
    telefono: str | None = Field(default=None, max_length=20)

class UsuarioUpdate(BaseModel):
    id_rol: int | None = None
    nombre: str | None = Field(default=None, min_length=2, max_length=100)
    apellido: str | None = Field(default=None, min_length=2, max_length=100)
    telefono: str | None = Field(default=None, max_length=20)
    activo: bool | None = None

class UsuarioOut(BaseModel):
    id_usuario: int
    id_rol: int
    nombre: str
    apellido: str
    correo: EmailStr
    telefono: str | None
    activo: bool
    fecha_creacion: datetime
'''
files['app/modules/usuarios/router.py'] = '''from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.core.deps import get_db, require_roles
from app.core.security import hash_password
from app.db.orm_models.usuario import Usuario
from app.modules.usuarios.schemas import UsuarioCreate, UsuarioUpdate

router = APIRouter(prefix="/usuarios", tags=["Usuarios"])

@router.get("")
def list_users(db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Supervisor"))):
    return {"data": db.execute(select(Usuario)).scalars().all()}

@router.post("")
def create_user(payload: UsuarioCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    exists = db.execute(select(Usuario).where(Usuario.correo == payload.correo)).scalar_one_or_none()
    if exists:
        raise HTTPException(409, "Correo ya existe")
    obj = Usuario(
        id_rol=payload.id_rol,
        nombre=payload.nombre,
        apellido=payload.apellido,
        correo=payload.correo,
        password_hash=hash_password(payload.password),
        telefono=payload.telefono,
    )
    db.add(obj); db.commit(); db.refresh(obj)
    return {"data": obj}

@router.put("/{id_usuario}")
def update_user(id_usuario: int, payload: UsuarioUpdate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    obj = db.get(Usuario, id_usuario)
    if not obj:
        raise HTTPException(404, "Usuario no encontrado")
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(obj, k, v)
    db.commit(); db.refresh(obj)
    return {"data": obj}

@router.delete("/{id_usuario}")
def disable_user(id_usuario: int, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    obj = db.get(Usuario, id_usuario)
    if not obj:
        raise HTTPException(404, "Usuario no encontrado")
    obj.activo = False
    db.commit()
    return {"data": {"desactivado": True}}
'''

files['app/modules/fincas/schemas.py'] = '''from pydantic import BaseModel, Field

class FincaCreate(BaseModel):
    id_municipio: int
    nombre: str = Field(min_length=2, max_length=100)
    propietario: str = Field(min_length=2, max_length=120)
    direccion: str | None = Field(default=None, max_length=150)
    latitud: float | None = None
    longitud: float | None = None
    area_hectareas: float | None = None
    descripcion: str | None = Field(default=None, max_length=200)

class FincaUpdate(FincaCreate):
    id_municipio: int | None = None
    nombre: str | None = Field(default=None, min_length=2, max_length=100)
    propietario: str | None = Field(default=None, min_length=2, max_length=120)
'''
files['app/modules/fincas/router.py'] = '''from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.core.deps import get_db, require_roles
from app.db.orm_models.finca import Finca
from app.modules.fincas.schemas import FincaCreate, FincaUpdate

router = APIRouter(prefix="/fincas", tags=["Fincas"])

@router.get("")
def list_fincas(db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Operario","Supervisor"))):
    return {"data": db.execute(select(Finca)).scalars().all()}

@router.post("")
def create_finca(payload: FincaCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Operario"))):
    obj = Finca(**payload.model_dump())
    db.add(obj); db.commit(); db.refresh(obj)
    return {"data": obj}

@router.put("/{id_finca}")
def update_finca(id_finca: int, payload: FincaUpdate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Operario"))):
    obj = db.get(Finca, id_finca)
    if not obj:
        raise HTTPException(404, "Finca no encontrada")
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(obj, k, v)
    db.commit(); db.refresh(obj)
    return {"data": obj}

@router.delete("/{id_finca}")
def delete_finca(id_finca: int, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    obj = db.get(Finca, id_finca)
    if not obj:
        raise HTTPException(404, "Finca no encontrada")
    db.delete(obj); db.commit()
    return {"data": {"eliminado": True}}
'''

files['app/modules/lotes/schemas.py'] = '''from datetime import date, datetime
from pydantic import BaseModel, Field

class LoteCreate(BaseModel):
    id_finca: int
    id_variedad: int
    codigo_lote: str = Field(min_length=3, max_length=30)
    fecha_registro: date
    cantidad_kg: float | None = Field(default=None, ge=0)
    observaciones: str | None = Field(default=None, max_length=250)
    activo: bool = True

class LoteUpdate(BaseModel):
    id_finca: int | None = None
    id_variedad: int | None = None
    codigo_lote: str | None = Field(default=None, min_length=3, max_length=30)
    fecha_registro: date | None = None
    cantidad_kg: float | None = Field(default=None, ge=0)
    observaciones: str | None = Field(default=None, max_length=250)
    activo: bool | None = None

class LoteEstadoOut(BaseModel):
    id_lote: int
    codigo_lote: str
    estado_actual: str | None = None
    fecha_estado_actual: datetime | None = None
'''
files['app/modules/lotes/router.py'] = '''from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.core.deps import get_db, require_roles
from app.db.orm_models.lote import Lote
from app.db.orm_models.registro_postcosecha import RegistroPostcosecha
from app.db.orm_models.estado_lote import EstadoLote
from app.modules.lotes.schemas import LoteCreate, LoteUpdate

router = APIRouter(prefix="/lotes", tags=["Lotes"])


def get_estado_actual(db: Session, id_lote: int):
    ultimo = db.execute(
        select(RegistroPostcosecha).where(RegistroPostcosecha.id_lote == id_lote)
        .order_by(RegistroPostcosecha.fecha_hora.desc(), RegistroPostcosecha.id_registro.desc())
    ).scalars().first()
    if not ultimo:
        return None, None
    estado = db.get(EstadoLote, ultimo.id_estado_lote)
    return estado.nombre if estado else None, ultimo.fecha_hora

@router.get("")
def list_lotes(db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Operario","Supervisor"))):
    rows = db.execute(select(Lote)).scalars().all()
    data = []
    for row in rows:
        estado, fecha = get_estado_actual(db, row.id_lote)
        data.append({
            "id_lote": row.id_lote,
            "id_finca": row.id_finca,
            "id_variedad": row.id_variedad,
            "codigo_lote": row.codigo_lote,
            "fecha_registro": row.fecha_registro,
            "cantidad_kg": row.cantidad_kg,
            "observaciones": row.observaciones,
            "activo": row.activo,
            "estado_actual": estado,
            "fecha_estado_actual": fecha,
        })
    return {"data": data}

@router.get("/{id_lote}")
def detail_lote(id_lote: int, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Operario","Supervisor"))):
    row = db.get(Lote, id_lote)
    if not row:
        raise HTTPException(404, "Lote no encontrado")
    estado, fecha = get_estado_actual(db, row.id_lote)
    return {"data": {
        "id_lote": row.id_lote,
        "id_finca": row.id_finca,
        "id_variedad": row.id_variedad,
        "codigo_lote": row.codigo_lote,
        "fecha_registro": row.fecha_registro,
        "cantidad_kg": row.cantidad_kg,
        "observaciones": row.observaciones,
        "activo": row.activo,
        "estado_actual": estado,
        "fecha_estado_actual": fecha,
    }}

@router.post("")
def create_lote(payload: LoteCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Operario"))):
    exists = db.execute(select(Lote).where(Lote.codigo_lote == payload.codigo_lote)).scalar_one_or_none()
    if exists:
        raise HTTPException(409, "Código de lote repetido")
    obj = Lote(**payload.model_dump())
    db.add(obj); db.commit(); db.refresh(obj)
    return {"data": obj}

@router.put("/{id_lote}")
def update_lote(id_lote: int, payload: LoteUpdate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Operario"))):
    obj = db.get(Lote, id_lote)
    if not obj:
        raise HTTPException(404, "Lote no encontrado")
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(obj, k, v)
    db.commit(); db.refresh(obj)
    return {"data": obj}

@router.delete("/{id_lote}")
def delete_lote(id_lote: int, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    obj = db.get(Lote, id_lote)
    if not obj:
        raise HTTPException(404, "Lote no encontrado")
    obj.activo = False
    db.commit()
    return {"data": {"desactivado": True}}
'''

files['app/modules/registros/schemas.py'] = '''from datetime import datetime
from pydantic import BaseModel, Field, model_validator

class RegistroCreate(BaseModel):
    id_lote: int
    id_usuario: int
    id_tipo_actividad: int
    id_estado_lote: int
    fecha_hora: datetime | None = None
    observacion: str | None = Field(default=None, max_length=250)
    ubicacion_registro: str | None = Field(default=None, max_length=120)

class DetalleVariableCreate(BaseModel):
    id_variable: int
    valor: float
    comentario: str | None = Field(default=None, max_length=150)

class RegistroBatchCreate(BaseModel):
    id_usuario: int
    id_tipo_actividad: int
    id_estado_lote: int
    fecha_hora: datetime | None = None
    observacion: str | None = Field(default=None, max_length=250)
    ubicacion_registro: str | None = Field(default=None, max_length=120)
    variables: list[DetalleVariableCreate] = Field(min_length=1, max_length=50)

    @model_validator(mode='after')
    def validate_unique_variables(self):
        ids = [v.id_variable for v in self.variables]
        if len(ids) != len(set(ids)):
            raise ValueError('No se puede repetir la misma variable dentro del mismo registro.')
        return self
'''
files['app/modules/registros/router.py'] = '''from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.core.deps import get_db, require_roles
from app.db.orm_models import RegistroPostcosecha, RegistroVariableDetalle, VariableMonitoreo, AlertaLote
from app.modules.registros.schemas import RegistroCreate, RegistroBatchCreate

router = APIRouter(prefix="/registros", tags=["Registros"])

@router.get("")
def list_registros(db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Operario","Supervisor"))):
    return {"data": db.execute(select(RegistroPostcosecha)).scalars().all()}

@router.post("")
def create_registro(payload: RegistroCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Operario"))):
    obj = RegistroPostcosecha(**payload.model_dump())
    db.add(obj); db.commit(); db.refresh(obj)
    return {"data": obj}

@router.put("/{id_registro}")
def update_registro(id_registro: int, payload: RegistroCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Operario"))):
    obj = db.get(RegistroPostcosecha, id_registro)
    if not obj:
        raise HTTPException(404, "Registro no encontrado")
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(obj, k, v)
    db.commit(); db.refresh(obj)
    return {"data": obj}

@router.delete("/{id_registro}")
def delete_registro(id_registro: int, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador"))):
    obj = db.get(RegistroPostcosecha, id_registro)
    if not obj:
        raise HTTPException(404, "Registro no encontrado")
    db.delete(obj); db.commit()
    return {"data": {"eliminado": True}}

@router.post("/lotes/{id_lote}")
def create_batch(id_lote: int, payload: RegistroBatchCreate, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Operario"))):
    with db.begin():
        registro = RegistroPostcosecha(
            id_lote=id_lote,
            id_usuario=payload.id_usuario,
            id_tipo_actividad=payload.id_tipo_actividad,
            id_estado_lote=payload.id_estado_lote,
            fecha_hora=payload.fecha_hora,
            observacion=payload.observacion,
            ubicacion_registro=payload.ubicacion_registro,
        )
        db.add(registro)
        db.flush()
        alertas = 0
        for item in payload.variables:
            detalle = RegistroVariableDetalle(
                id_registro=registro.id_registro,
                id_variable=item.id_variable,
                valor=item.valor,
                comentario=item.comentario,
            )
            db.add(detalle)
            db.flush()
            variable = db.get(VariableMonitoreo, item.id_variable)
            if variable and variable.requiere_alerta:
                minimo = float(variable.valor_minimo) if variable.valor_minimo is not None else None
                maximo = float(variable.valor_maximo) if variable.valor_maximo is not None else None
                fuera = (minimo is not None and item.valor < minimo) or (maximo is not None and item.valor > maximo)
                if fuera:
                    db.add(AlertaLote(
                        id_detalle=detalle.id_detalle,
                        mensaje=f"Valor fuera de umbral para {variable.nombre}",
                        nivel="Alta",
                    ))
                    alertas += 1
    return {"data": {"id_registro": registro.id_registro, "id_lote": id_lote, "alertas_generadas": alertas}}
'''

files['app/modules/alertas/router.py'] = '''from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session
from app.core.deps import get_db, require_roles
from app.db.orm_models.alerta_lote import AlertaLote

router = APIRouter(prefix="/alertas", tags=["Alertas"])

@router.get("")
def list_alertas(db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Supervisor","Operario"))):
    return {"data": db.execute(select(AlertaLote)).scalars().all()}

@router.patch("/{id_alerta}/atender")
def atender_alerta(id_alerta: int, db: Session = Depends(get_db), _: object = Depends(require_roles("Administrador","Supervisor"))):
    obj = db.get(AlertaLote, id_alerta)
    if not obj:
        raise HTTPException(404, "Alerta no encontrada")
    obj.atendida = True
    db.commit(); db.refresh(obj)
    return {"data": obj}
'''

# placeholders for hex architecture docs
files['docs.txt'] = 'Este repositorio usa vertical slice: cada módulo tiene router + esquema + lógica de caso de uso.\n'

# alembic basic files
files['alembic.ini'] = '''[alembic]
script_location = alembic
sqlalchemy.url = mysql+pymysql://postcosecha:postcosecha@db:3306/postcosecha_cafe
'''
files['alembic/env.py'] = '''from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from alembic import context
from app.db.base import Base
from app.db.orm_models import *

config = context.config
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_offline():
    url = config.get_main_option("sqlalchemy.url")
    context.configure(url=url, target_metadata=target_metadata, literal_binds=True)
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online():
    connectable = engine_from_config(config.get_section(config.config_ini_section), prefix='sqlalchemy.', poolclass=pool.NullPool)
    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)
        with context.begin_transaction():
            context.run_migrations()

if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
'''
files['alembic/versions/0001_init_placeholder.py'] = '''"""placeholder init

Revision ID: 0001_init
Revises: 
Create Date: 2026-04-05
"""
from alembic import op
import sqlalchemy as sa

revision = '0001_init'
down_revision = None
branch_labels = None
depends_on = None

def upgrade():
    pass

def downgrade():
    pass
'''

# tests basic
files['tests/test_health.py'] = '''from fastapi.testclient import TestClient
from app.main import app

client = TestClient(app)

def test_health():
    response = client.get('/')
    assert response.status_code == 200
'''

# write files
for rel, content in files.items():
    path = root / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding='utf-8')

print(f'Wrote {len(files)} files')
