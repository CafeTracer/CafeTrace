# ☕ Backend Postcosecha Café

Backend REST para la gestión de trazabilidad en la postcosecha del café, desarrollado con:

* **FastAPI**
* **SQLAlchemy**
* **MySQL**
* **Docker**
* **JWT con control de roles**

Organizado bajo un enfoque de **Vertical Slice + Arquitectura Hexagonal ligera**.

---

# 📌 Descripción del Proyecto

Este sistema permite registrar y consultar información relacionada con:

* Usuarios y roles
* Fincas
* Lotes de café
* Actividades de postcosecha
* Variables monitoreadas
* Alertas por valores fuera de rango

Su objetivo es garantizar **trazabilidad completa del proceso productivo**, permitiendo auditoría, control y generación de reportes históricos.

---

# 🧱 Estructura del Proyecto

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

---

# ⚙️ Configuración del Entorno

## 1. Requisitos

Antes de iniciar, asegúrate de tener instalado:

* Python 3.10+
* Docker + Docker Compose
* Git

---

# 🚀 Opción 1: Levantar con Docker (RECOMENDADO)

## 1. Clonar el repositorio

```bash
git clone <URL_DEL_REPO>
cd postcosecha_backend
```

## 2. Crear archivo de entorno

```bash
cp .env.example .env
```

(En Windows PowerShell)

```powershell
copy .env.example .env
```

## 3. Levantar contenedores

```bash
docker compose up --build
```

---

## 🔍 Verificación

Abrir en navegador:

* API → http://localhost:8000
* Swagger → http://localhost:8000/docs

Si Swagger carga, el backend está funcionando ✅

---

## 🧪 Revisar base de datos

Entrar al contenedor:

```bash
docker exec -it postcosecha_db mysql -uroot -proot
```

Luego:

```sql
USE postcosecha_cafe;
SHOW TABLES;
```

---

## 🔄 Reiniciar base de datos (IMPORTANTE)

Si haces cambios en `schema.sql`:

```bash
docker compose down -v
docker compose up --build
```

---

# 🧠 Opción 2: Ejecutar sin Docker (modo desarrollo)

## 1. Crear entorno virtual

```bash
python -m venv .venv
```

## 2. Activar entorno

Windows PowerShell:

```powershell
.\.venv\Scripts\Activate.ps1
```

CMD:

```cmd
.\.venv\Scripts\activate.bat
```

Linux / Mac:

```bash
source .venv/bin/activate
```

---

## 3. Instalar dependencias

```bash
pip install -r requirements.txt
```

Si no existe:

```bash
pip install fastapi uvicorn sqlalchemy pymysql pydantic python-jose passlib[bcrypt] python-multipart alembic
```

---

## 4. Ejecutar servidor

```bash
uvicorn app.main:app --reload
```

---

## 🔍 Verificación

* http://127.0.0.1:8000
* http://127.0.0.1:8000/docs

---

# 🔐 Autenticación

El sistema usa **JWT (Bearer Token)**.

## Login

```http
POST /api/v1/auth/login
```

Tipo: `application/x-www-form-urlencoded`

Campos:

```text
username=correo
password=contraseña
```

Respuesta:

```json
{
  "access_token": "TOKEN",
  "token_type": "bearer"
}
```

---

# 👤 Crear usuario administrador (IMPORTANTE)

El sistema requiere al menos un usuario administrador.

## 1. Generar hash de contraseña

```bash
python -c "from pwdlib import PasswordHash; print(PasswordHash.recommended().hash('Admin123*'))"
```

## 2. Insertar en base de datos

```sql
INSERT INTO usuario (
    id_rol,
    nombre,
    apellido,
    correo,
    password_hash,
    telefono,
    activo
) VALUES (
    1,
    'Admin',
    'Principal',
    'admin@postcosecha.com',
    'HASH_GENERADO',
    '3000000000',
    TRUE
);
```

---

# 🔄 Flujo de uso del sistema

Orden recomendado:

1. Login (`/auth/login`)
2. Autorizar en Swagger
3. Consultar catálogos
4. Crear usuario
5. Crear finca
6. Crear lote
7. Crear registro de postcosecha
8. Registrar variables
9. Consultar alertas

---

# 🧩 Roles del sistema

| Rol           | Permisos                      |
| ------------- | ----------------------------- |
| Administrador | CRUD completo                 |
| Operario      | Crear y actualizar datos      |
| Supervisor    | Lectura y atención de alertas |

---

# 📡 Endpoints principales

* `/auth/login`
* `/usuarios`
* `/fincas`
* `/lotes`
* `/registros`
* `/alertas`
* `/catalogos/*`

---

# 📦 Respuestas del backend

Formato estándar:

```json
{
  "data": ...
}
```

Errores:

* 401 → No autenticado
* 403 → Sin permisos
* 404 → No encontrado
* 422 → Error de validación

---

# ⚠️ Notas importantes

* El estado del lote puede variar según implementación (derivado o almacenado).
* Las alertas dependen de valores fuera de rango en variables.
* La base de datos se inicializa automáticamente con Docker.

---

# 🛠️ Comandos útiles

## Ver logs

```bash
docker compose logs -f
```

## Solo API

```bash
docker compose logs -f api
```

## Detener

```bash
docker compose down
```

---

# 🎯 Resumen

Este backend permite:

* Gestionar trazabilidad de postcosecha
* Registrar eventos productivos
* Controlar variables críticas
* Generar alertas automáticas
* Consultar historial completo

Todo expuesto mediante una API REST lista para integrarse con aplicaciones móviles o web.

---

