import os
from typing import List
from pydantic import BaseModel, Field

try:
    from pydantic_settings import BaseSettings, SettingsConfigDict

    class Settings(BaseSettings):
        ENVIRONMENT: str = "development"
        DEBUG: bool = True
        HOST: str = "0.0.0.0"
        PORT: int = 8000
        ALLOWED_ORIGINS: List[str] = ["*"]

        # Firebase
        FIREBASE_PROJECT_ID: str = "climatwin-dev"
        FIREBASE_CREDENTIALS_PATH: str = "./serviceAccountKey.json"

        # LLM Settings (Server side only)
        OPENAI_API_KEY: str = ""
        ANTHROPIC_API_KEY: str = ""
        GOOGLE_API_KEY: str = ""

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

        FIREBASE_PROJECT_ID: str = Field(default_factory=lambda: os.getenv("FIREBASE_PROJECT_ID", "climatwin-dev"))
        FIREBASE_CREDENTIALS_PATH: str = Field(default_factory=lambda: os.getenv("FIREBASE_CREDENTIALS_PATH", "./serviceAccountKey.json"))

        OPENAI_API_KEY: str = Field(default_factory=lambda: os.getenv("OPENAI_API_KEY", ""))
        ANTHROPIC_API_KEY: str = Field(default_factory=lambda: os.getenv("ANTHROPIC_API_KEY", ""))
        GOOGLE_API_KEY: str = Field(default_factory=lambda: os.getenv("GOOGLE_API_KEY", ""))

        LANGCHAIN_TRACING_V2: bool = Field(default_factory=lambda: os.getenv("LANGCHAIN_TRACING_V2", "false").lower() == "true")
        LANGCHAIN_ENDPOINT: str = Field(default_factory=lambda: os.getenv("LANGCHAIN_ENDPOINT", "https://api.smith.langchain.com"))
        LANGCHAIN_API_KEY: str = Field(default_factory=lambda: os.getenv("LANGCHAIN_API_KEY", ""))
        LANGCHAIN_PROJECT: str = Field(default_factory=lambda: os.getenv("LANGCHAIN_PROJECT", "climatwin-dev"))

        REDIS_URL: str = Field(default_factory=lambda: os.getenv("REDIS_URL", "redis://localhost:6379/0"))


settings = Settings()
