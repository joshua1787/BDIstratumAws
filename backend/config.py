# In ~/Stratum_JD_AWS/backend/config.py

from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import Optional
from pathlib import Path # Import Path

class Settings(BaseSettings):
    # Database settings
    DB_USER: Optional[str] = None
    DB_PASSWORD: Optional[str] = None
    DB_HOST: Optional[str] = None
    DB_PORT: Optional[int] = None
    DB_NAME: Optional[str] = None

    DATABASE_URL: Optional[str] = None

    # AWS Settings
    AWS_REGION: str = "us-east-1" 
    DB_CREDENTIALS_SECRET_ARN: Optional[str] = None

    # For local .env file loading
    model_config = SettingsConfigDict(
        env_file = Path(__file__).resolve().parent / ".env", # Explicitly point to .env in the same directory as this config.py
        env_file_encoding='utf-8',
        extra='ignore'
    )

settings = Settings()

# Optional: Add a print here to confirm if settings are loaded right after instantiation
# print(f"DEBUG (config.py): DB_CREDENTIALS_SECRET_ARN from settings object: {settings.DB_CREDENTIALS_SECRET_ARN}")
# print(f"DEBUG (config.py): DB_HOST from settings object: {settings.DB_HOST}")