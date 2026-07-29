from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict

BACKEND_DIR = Path(__file__).resolve().parent


class Settings(BaseSettings):
    database_url: str = "sqlite:///./phrasecards_dev.db"
    audio_directory: Path = BACKEND_DIR / "public" / "audio"
    audio_url_path: str = "/audio"
    cors_origins: list[str] = Field(default_factory=list)
    api_key: str = ""
    docs_enabled: bool = True
    tts_language: str = "hu"
    tts_tld: str = "com"

    model_config = SettingsConfigDict(env_file=".env")


settings = Settings()
