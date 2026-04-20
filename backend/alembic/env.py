from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from alembic import context
from app.db.base import Base
from app.db.orm_models import *
import os

config = context.config
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_online():
    # 1. Intentamos obtener la URL de la variable de entorno
    database_url = os.getenv("DATABASE_URL")
    
    # 2. Si existe la variable (como en el CI), la usamos. 
    # Si no, usamos la del archivo alembic.ini
    if database_url:
        from sqlalchemy import create_engine
        connectable = create_engine(database_url, poolclass=pool.NullPool)
    else:
        connectable = engine_from_config(
            config.get_section(config.config_ini_section),
            prefix='sqlalchemy.',
            poolclass=pool.NullPool,
        )

    with connectable.connect() as connection:
        context.configure(connection=connection, target_metadata=target_metadata)
        with context.begin_transaction():
            context.run_migrations()
