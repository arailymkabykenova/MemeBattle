"""
Конфигурация приложения.
Здесь определяются все настройки приложения с использованием Pydantic Settings.
"""

from typing import Optional
from pydantic import BaseModel
import os
from dotenv import load_dotenv

# Загружаем переменные окружения из .env файла
load_dotenv()


class Settings(BaseModel):
    """Настройки приложения"""
    
    # Основные настройки приложения
    app_name: str = "Meme Card Game API"
    debug: bool = True  # Changed to True for development
    version: str = "1.0.0"
    
    # База данных (пока заглушка)
    database_url: Optional[str] = None
    
    # Redis настройки
    redis_url: Optional[str] = None
    redis_host: str = "localhost"
    redis_port: int = 6379
    redis_db: int = 0
    redis_password: Optional[str] = None
    
    # Game Center аутентификация
    # Настройки для верификации подписей Apple (если потребуется)
    apple_team_id: Optional[str] = None
    
    # Azure Storage
    azure_storage_connection_string: Optional[str] = None
    azure_container_name: Optional[str] = None
    
    # Azure OpenAI
    azure_openai_endpoint: Optional[str] = None
    azure_openai_key: Optional[str] = None
    azure_openai_deployment_name: Optional[str] = None
    azure_openai_api_version: str = "2024-02-15-preview"
    
    # Автоматическая загрузка карт
    auto_load_cards_from_azure: bool = True
    
    # JWT настройки (читаются из переменных окружения)
    jwt_secret_key: str
    jwt_algorithm: str = "HS256"
    jwt_expiration_hours: int = 168  # 7 дней
    
    # CORS настройки
    cors_origins: list[str] = ["*"]  # В продакшене указать конкретные домены


def load_settings() -> Settings:
    """Загружает настройки из переменных окружения"""
    
    # Проверяем критически важные переменные окружения
    jwt_secret = os.getenv("JWT_SECRET_KEY")
    if not jwt_secret:
        print("⚠️  ВНИМАНИЕ: JWT_SECRET_KEY не установлен! Используется fallback ключ.")
        print("   Для продакшена обязательно установите безопасный JWT_SECRET_KEY в .env")
        jwt_secret = "fallback-secret-key-for-development-only-NOT-SECURE"
    
    database_url = os.getenv("DATABASE_URL")
    if not database_url:
        print("⚠️  ВНИМАНИЕ: DATABASE_URL не установлен!")
        print("   Установите DATABASE_URL в .env файле")
    
    return Settings(
        app_name=os.getenv("APP_NAME", "Meme Card Game API"),
        debug=os.getenv("DEBUG", "true").lower() == "true",
        version=os.getenv("VERSION", "1.0.0"),
        database_url=database_url,
        redis_url=os.getenv("REDIS_URL"),
        redis_host=os.getenv("REDIS_HOST", "localhost"),
        redis_port=int(os.getenv("REDIS_PORT", "6379")),
        redis_db=int(os.getenv("REDIS_DB", "0")),
        redis_password=os.getenv("REDIS_PASSWORD"),
        apple_team_id=os.getenv("APPLE_TEAM_ID"),
        azure_storage_connection_string=os.getenv("AZURE_STORAGE_CONNECTION_STRING"),
        azure_container_name=os.getenv("AZURE_CONTAINER_NAME"),
        azure_openai_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
        azure_openai_key=os.getenv("AZURE_OPENAI_KEY"),
        azure_openai_deployment_name=os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME"),
        azure_openai_api_version=os.getenv("AZURE_OPENAI_API_VERSION", "2024-02-15-preview"),
        auto_load_cards_from_azure=os.getenv("AUTO_LOAD_CARDS_FROM_AZURE", "true").lower() == "true",
        jwt_secret_key=jwt_secret,
        jwt_algorithm=os.getenv("JWT_ALGORITHM", "HS256"),
        jwt_expiration_hours=int(os.getenv("JWT_EXPIRATION_HOURS", "168")),
        cors_origins=os.getenv("CORS_ORIGINS", "*").split(",") if os.getenv("CORS_ORIGINS") != "*" else ["*"]
    )


# Создаем глобальный экземпляр настроек
settings = load_settings()


def get_settings() -> Settings:
    """Возвращает глобальный экземпляр настроек"""
    return settings 