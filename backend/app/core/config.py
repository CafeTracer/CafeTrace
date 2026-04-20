from pydantic_settings import BaseSettings, SettingsConfigDict

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
