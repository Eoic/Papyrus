"""Application configuration using Pydantic Settings."""

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # Application
    app_name: str = "Papyrus Server API"
    app_version: str = "1.0.0"
    debug: bool = False

    # Server
    host: str = "0.0.0.0"
    port: int = 8080
    api_prefix: str = "/v1"

    # CORS
    cors_origins: list[str] = ["*"]

    # Database
    database_url: str = "postgresql+asyncpg://papyrus:papyrus@localhost:5432/papyrus"

    # Security
    secret_key: str = "change-me-in-production-use-openssl-rand-hex-32"
    algorithm: str = "HS256"
    access_token_expire_minutes: int = 60
    refresh_token_expire_days: int = 30

    # Rate Limiting
    rate_limit_auth: int = 5  # requests per minute
    rate_limit_general: int = 100  # requests per minute
    rate_limit_upload: int = 10  # requests per minute
    rate_limit_batch: int = 20  # requests per minute


@lru_cache
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
