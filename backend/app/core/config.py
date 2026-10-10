import os
from typing import List
from pathlib import Path
from pydantic import BaseModel, Field

# Automatically locate and load .env from backend/.env or .env in workspace
try:
    from dotenv import load_dotenv
    base_dir = Path(__file__).resolve().parent.parent.parent
    if (base_dir / ".env").exists():
        load_dotenv(dotenv_path=base_dir / ".env")
    elif (base_dir / "backend" / ".env").exists():
        load_dotenv(dotenv_path=base_dir / "backend" / ".env")
    else:
        load_dotenv()
except ImportError:
    pass

try:
    from pydantic_settings import BaseSettings, SettingsConfigDict

    class Settings(BaseSettings):
        ENVIRONMENT: str = "development"
        DEBUG: bool = True
        HOST: str = "0.0.0.0"
        PORT: int = 8000
        ALLOWED_ORIGINS: List[str] = ["*"]

        # Firebase (aligned with mobile google-services.json)
        FIREBASE_PROJECT_ID: str = "invest-2-77a18"
        FIREBASE_CREDENTIALS_PATH: str = "./serviceAccountKey.json"

        # LLM Settings (Server side only)
        OPENAI_API_KEY: str = ""
        ANTHROPIC_API_KEY: str = ""
        GOOGLE_API_KEY: str = ""
        GEMINI_MODEL: str = "gemini-flash-latest"

        # LangSmith Observability
        LANGCHAIN_TRACING_V2: bool = False
        LANGCHAIN_ENDPOINT: str = "https://api.smith.langchain.com"
        LANGCHAIN_API_KEY: str = ""
        LANGCHAIN_PROJECT: str = "climatwin-dev"

        # Redis
        REDIS_URL: str = "redis://localhost:6379/0"

        model_config = SettingsConfigDict(
            env_file=".env",
            env_file_encoding="utf-8",
            extra="ignore",
        )

except ImportError:
    # Graceful fallback when pydantic-settings is not yet installed in local environment
    class Settings(BaseModel):  # type: ignore
        ENVIRONMENT: str = Field(default_factory=lambda: os.getenv("ENVIRONMENT", "development"))
        DEBUG: bool = Field(default_factory=lambda: os.getenv("DEBUG", "true").lower() == "true")
        HOST: str = Field(default_factory=lambda: os.getenv("HOST", "0.0.0.0"))
        PORT: int = Field(default_factory=lambda: int(os.getenv("PORT", "8000")))
        ALLOWED_ORIGINS: List[str] = Field(default_factory=lambda: ["*"])

        FIREBASE_PROJECT_ID: str = Field(default_factory=lambda: os.getenv("FIREBASE_PROJECT_ID", "invest-2-77a18"))
        FIREBASE_CREDENTIALS_PATH: str = Field(default_factory=lambda: os.getenv("FIREBASE_CREDENTIALS_PATH", "./serviceAccountKey.json"))

        OPENAI_API_KEY: str = Field(default_factory=lambda: os.getenv("OPENAI_API_KEY", ""))
        ANTHROPIC_API_KEY: str = Field(default_factory=lambda: os.getenv("ANTHROPIC_API_KEY", ""))
        GOOGLE_API_KEY: str = Field(default_factory=lambda: os.getenv("GOOGLE_API_KEY", ""))
        GEMINI_MODEL: str = Field(default_factory=lambda: os.getenv("GEMINI_MODEL", "gemini-flash-latest"))

        LANGCHAIN_TRACING_V2: bool = Field(default_factory=lambda: os.getenv("LANGCHAIN_TRACING_V2", "false").lower() == "true")
        LANGCHAIN_ENDPOINT: str = Field(default_factory=lambda: os.getenv("LANGCHAIN_ENDPOINT", "https://api.smith.langchain.com"))
        LANGCHAIN_API_KEY: str = Field(default_factory=lambda: os.getenv("LANGCHAIN_API_KEY", ""))
        LANGCHAIN_PROJECT: str = Field(default_factory=lambda: os.getenv("LANGCHAIN_PROJECT", "climatwin-dev"))

        REDIS_URL: str = Field(default_factory=lambda: os.getenv("REDIS_URL", "redis://localhost:6379/0"))


settings = Settings()

# Automatically wire LangSmith tracing environment variables if configured
if settings.LANGCHAIN_TRACING_V2 and settings.LANGCHAIN_API_KEY:
    os.environ["LANGCHAIN_TRACING_V2"] = "true"
    os.environ["LANGCHAIN_ENDPOINT"] = settings.LANGCHAIN_ENDPOINT
    os.environ["LANGCHAIN_API_KEY"] = settings.LANGCHAIN_API_KEY
    os.environ["LANGCHAIN_PROJECT"] = settings.LANGCHAIN_PROJECT

if settings.GOOGLE_API_KEY and not os.getenv("GOOGLE_API_KEY"):
    os.environ["GOOGLE_API_KEY"] = settings.GOOGLE_API_KEY
