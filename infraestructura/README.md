# CaféTrace — Infraestructura y CI/CD

## Estructura de archivos

```
.github/workflows/
├── deploy.yml        # Pipeline principal: test → build → deploy (push a main)
└── pr_checks.yml     # Checks rápidos en cada PR

backend/
└── Dockerfile        # Multi-stage: builder + runtime liviano

infra/
├── nginx/nginx.conf          # Reverse proxy + SSL
├── prometheus/prometheus.yml # Scraping de métricas
└── grafana/
    ├── datasources/          # Prometheus como fuente de datos
    └── dashboards/           # Dashboards provisionados automáticamente

docker-compose.yml            # Desarrollo local (con hot reload)
docker-compose.prod.yml       # Producción en EC2
.env.example                  # Plantilla de variables de entorno
```

---

## Setup de desarrollo local (Jorge)

```bash
# 1. Copiar variables de entorno
cp .env.example .env

# 2. Levantar backend + BD + Adminer
docker compose up --build

# 3. Verificar
curl http://localhosthttp://127.0.0.1:8000/
# → {"status": "ok"}

# Adminer (UI para inspeccionar BD): http://localhost:8080
# Sistema: PostgreSQL | Servidor: db | Usuario: cafetrace | Contraseña: cafetrace123
```

---

## Setup de producción en EC2 (una sola vez)

```bash
# 1. Conectarse a EC2
ssh -i cafetrace.pem ubuntu@3.19.102.214

# 2. Instalar Docker
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-plugin awscli
sudo usermod -aG docker ubuntu
newgrp docker

# 3. Clonar repositorio
git clone https://github.com/CafeTracer/CafeTrace.git ~/cafetrace
cd ~/cafetrace

# 4. Crear .env con los valores reales
cp .env.example .env
nano .env   # completar todos los valores

# 5. Crear repositorio ECR en AWS (una sola vez)
aws ecr create-repository --repository-name cafetrace/backend --region us-east-1

# 6. Instalar Certbot para SSL
sudo apt-get install -y certbot
sudo certbot certonly --standalone -d {DOMINIO_O_IP}
# Nota: Let's Encrypt no emite certificados para IPs puras.
# Para IP directa, usar certificado autofirmado o un dominio gratuito (ej. duckdns.org)

# 7. Levantar todos los servicios
docker compose -f docker-compose.prod.yml up -d

# 8. Verificar
docker compose -f docker-compose.prod.yml ps
curl http://localhost:8000/health
```

---

## Secrets requeridos en GitHub

Ir a: `Settings del repositorio → Secrets and variables → Actions → New repository secret`

| Secret | Descripción |
|---|---|
| `AWS_ACCESS_KEY_ID` | Clave de acceso AWS (IAM user con permisos ECR + EC2) |
| `AWS_SECRET_ACCESS_KEY` | Clave secreta AWS |
| `EC2_HOST` | IP elástica de la instancia EC2 |
| `EC2_USER` | Usuario SSH (normalmente `ubuntu`) |
| `EC2_PRIVATE_KEY` | Contenido completo del archivo `.pem` |
| `SECRET_KEY` | Clave JWT de producción (generar con `openssl rand -hex 32`) |
| `DATABASE_URL` | URL completa de conexión a PostgreSQL |
| `BACKEND_URL` | URL del backend en producción, ej: `https://CafeTrace.duckdns.org` — usada por el build de Flutter para apuntar al EC2 |

---

## Flujo del pipeline

```
Push a main
    │
    ▼
[test] pytest + cobertura ≥70%
    │ ✓
    ▼
[build] docker build → push a ECR (:latest + :sha)
    │ ✓
    ▼
[deploy] SSH a EC2 → docker compose pull api → up --no-deps api
    │
    ▼
Health check: curl localhost:8000/health
    ├─ 200 → ✅ Deploy exitoso
    └─ Otro → ❌ Rollback automático
```

---

## Comandos útiles en producción

```bash
# Ver logs del backend en tiempo real
docker compose -f docker-compose.prod.yml logs -f api

# Actualizar solo el backend (sin tocar BD ni monitoreo)
docker compose -f docker-compose.prod.yml pull api
docker compose -f docker-compose.prod.yml up -d --no-deps api

# Ver estado de todos los servicios
docker compose -f docker-compose.prod.yml ps

# Acceder a la BD en producción
docker compose -f docker-compose.prod.yml exec db psql -U cafetrace -d cafetrace_db

# Grafana: https://{IP}/grafana  (usuario: admin, contraseña: valor de GRAFANA_PASSWORD)
```

---

## Nota sobre SSL con IP directa

Let's Encrypt no emite certificados para IPs. Opciones para el proyecto académico:

1. **DuckDNS** (gratis): registrar un dominio gratuito tipo `cafetrace.duckdns.org` que apunte a la Elastic IP → usar ese dominio con Certbot.
2. **Certificado autofirmado**: funciona para pruebas pero el navegador/Flutter mostrará advertencia. En Flutter se puede deshabilitar la verificación SSL en dev.
3. **Sin SSL por ahora**: usar HTTP durante desarrollo y activar HTTPS en la entrega final.
