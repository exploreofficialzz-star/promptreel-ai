from pydantic_settings import BaseSettings
from functools import lru_cache
from typing import Optional


class Settings(BaseSettings):
    # ── App ───────────────────────────────────────────────────────────────────
    APP_NAME: str = "PromptReel AI"
    APP_VERSION: str = "1.1.0"
    DEBUG: bool = False
    ENVIRONMENT: str = "production"

    # ── Database ──────────────────────────────────────────────────────────────
    DATABASE_URL: str = "postgresql+asyncpg://user:password@localhost/promptreel"

    # ── Security ──────────────────────────────────────────────────────────────
    SECRET_KEY: str = "CHANGE-ME-IN-PRODUCTION-USE-STRONG-RANDOM-KEY"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # ── AI API Keys ───────────────────────────────────────────────────────────
    OPENAI_API_KEY: Optional[str] = None
    ANTHROPIC_API_KEY: Optional[str] = None
    GEMINI_API_KEY: Optional[str] = None
    GROK_API_KEY: Optional[str] = None
    MISTRAL_API_KEY: Optional[str] = None
    DEEPSEEK_API_KEY: Optional[str] = None
    GROQ_API_KEY: Optional[str] = None
    TOGETHER_API_KEY: Optional[str] = None
    OPENROUTER_API_KEY: Optional[str] = None

    # ── Model Names ───────────────────────────────────────────────────────────
    # Studio tier
    OPENAI_MODEL_STUDIO: str = "gpt-4o"
    ANTHROPIC_MODEL_STUDIO: str = "claude-3-5-sonnet-20241022"

    # Creator tier
    OPENAI_MODEL_CREATOR: str = "gpt-4o-mini"
    GEMINI_MODEL_CREATOR: str = "gemini-1.5-pro-latest"
    GROK_MODEL_CREATOR: str = "grok-2-1212"
    MISTRAL_MODEL_CREATOR: str = "mistral-large-latest"

    # Free tier
    GEMINI_MODEL_FREE: str = "gemini-2.0-flash"
    DEEPSEEK_MODEL_FREE: str = "deepseek-chat"
    GROQ_MODEL_FREE: str = "llama-3.3-70b-versatile"
    GROQ_MODEL_FREE_FAST: str = "llama-3.1-8b-instant"
    GROQ_MODEL_FREE_MIX: str = "mixtral-8x7b-32768"
    GROQ_MODEL_FREE_GEMMA: str = "gemma2-9b-it"
    TOGETHER_MODEL_FREE: str = "Qwen/Qwen2.5-72B-Instruct-Turbo"
    OPENROUTER_MODEL_FREE: str = "mistralai/mistral-7b-instruct:free"
    OPENROUTER_MODEL_FREE2: str = "meta-llama/llama-3.1-8b-instruct:free"
    OPENROUTER_MODEL_FREE3: str = "google/gemma-2-9b-it:free"

    # ── Flutterwave ───────────────────────────────────────────────────────────
    FLUTTERWAVE_SECRET_KEY: Optional[str] = None
    FLUTTERWAVE_PUBLIC_KEY: Optional[str] = None
    FLUTTERWAVE_WEBHOOK_HASH: Optional[str] = None

    # ── Plan Prices USD ───────────────────────────────────────────────────────
    CREATOR_PRICE_USD: float = 15.00
    STUDIO_PRICE_USD: float = 35.00

    # ── Rate Limits ───────────────────────────────────────────────────────────
    FREE_DAILY_LIMIT: int = 3
    FREE_MAX_DURATION: int = 5

    # ── CORS ──────────────────────────────────────────────────────────────────
    CORS_ORIGINS: list[str] = [
        "http://localhost:3000",
        "http://localhost:8080",
        "https://promptreel.ai",
        "https://app.promptreel.ai",
    ]

    FRONTEND_URL: str = "https://app.promptreel.ai"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache()
def get_settings() -> Settings:
    return Settings()


settings = get_settings()

PLAN_TIER = {
    "free":    "free",
    "creator": "creator",
    "studio":  "studio",
    }
