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
    debug: bool = False
    version: str = "1.0.0"
    
    # База данных (пока заглушка)
    database_url: Optional[str] = None
    
    # Redis (пока заглушка)
    redis_url: Optional[str] = None
    
    # Firebase (пока заглушка)
    firebase_project_id: Optional[str] = None
    firebase_private_key: Optional[str] = None
    firebase_client_email: Optional[str] = None
    firebase_service_account_path: Optional[str] = None
    firebase_service_account_json: Optional[str] = None
    
    # Azure Storage
    azure_storage_connection_string: Optional[str] = None
    azure_container_name: Optional[str] = None
    
    # Azure OpenAI
    azure_openai_endpoint: Optional[str] = None
    azure_openai_key: Optional[str] = None
    azure_openai_deployment_name: Optional[str] = None
    azure_openai_api_version: str = "2024-02-15-preview"
    
    # JWT настройки (читаются из переменных окружения)
    JWT_SECRET_KEY: str
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRATION_HOURS: int = 168  # 7 дней
    
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
        debug=os.getenv("DEBUG", "false").lower() == "true",
        version=os.getenv("VERSION", "1.0.0"),
        database_url=database_url,
        redis_url=os.getenv("REDIS_URL"),
        firebase_project_id=os.getenv("FIREBASE_PROJECT_ID"),
        firebase_private_key=os.getenv("FIREBASE_PRIVATE_KEY"),
        firebase_client_email=os.getenv("FIREBASE_CLIENT_EMAIL"),
        firebase_service_account_path=os.getenv("FIREBASE_SERVICE_ACCOUNT_PATH"),
        firebase_service_account_json=os.getenv("FIREBASE_SERVICE_ACCOUNT_JSON"),
        azure_storage_connection_string=os.getenv("AZURE_STORAGE_CONNECTION_STRING"),
        azure_container_name=os.getenv("AZURE_CONTAINER_NAME"),
        azure_openai_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
        azure_openai_key=os.getenv("AZURE_OPENAI_KEY"),
        azure_openai_deployment_name=os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME"),
        azure_openai_api_version=os.getenv("AZURE_OPENAI_API_VERSION", "2024-02-15-preview"),
        JWT_SECRET_KEY=jwt_secret,
        JWT_ALGORITHM=os.getenv("JWT_ALGORITHM", "HS256"),
        JWT_EXPIRATION_HOURS=int(os.getenv("JWT_EXPIRATION_HOURS", "168")),
        cors_origins=os.getenv("CORS_ORIGINS", "*").split(",") if os.getenv("CORS_ORIGINS") != "*" else ["*"]
    )


# Создаем глобальный экземпляр настроек
settings = load_settings()


def get_settings() -> Settings:
    """Возвращает глобальный экземпляр настроек"""
    return settings 