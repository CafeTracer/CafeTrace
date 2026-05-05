from fastapi import FastAPI
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

