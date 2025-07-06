"""
Настройка базы данных.
Модуль для подключения к PostgreSQL через SQLAlchemy.
"""

from typing import AsyncGenerator
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import DeclarativeBase
from .config import settings


class Base(DeclarativeBase):
    """Базовый класс для всех моделей SQLAlchemy"""
    pass


# Создаем движок базы данных
def create_database_engine():
    """
    Создает движок базы данных.
    Если DATABASE_URL не задан, возвращает None (для тестирования)
    """
    if not settings.database_url:
        return None
    
    return create_async_engine(
        settings.database_url,
        echo=settings.debug,  # Логирование SQL запросов в режиме отладки
        pool_pre_ping=True,   # Проверка соединения перед использованием
        pool_recycle=300,     # Переиспользование соединений каждые 5 минут
    )


# Глобальный движок (будет None если DATABASE_URL не задан)
engine = create_database_engine()

# Создаем фабрику сессий
async_session_maker = async_sessionmaker(
    engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autoflush=False,
    autocommit=False,
) if engine else None


async def get_async_session() -> AsyncGenerator[AsyncSession, None]:
    """
    Dependency для получения асинхронной сессии базы данных.
    
    Yields:
        AsyncSession: Сессия базы данных
        
    Raises:
        RuntimeError: Если база данных не настроена
    """
    if not async_session_maker:
        raise RuntimeError(
            "База данных не настроена. Установите DATABASE_URL в переменных окружения."
        )
    
    async with async_session_maker() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise
        finally:
            await session.close()


# Алиас для совместимости с FastAPI
async def get_db() -> AsyncGenerator[AsyncSession, None]:
    """
    FastAPI dependency для получения сессии базы данных.
    
    Yields:
        AsyncSession: Сессия базы данных
    """
    async for session in get_async_session():
        yield session


async def init_database():
    """
    Инициализация базы данных.
    Создает все таблицы если их нет.
    """
    if not engine:
        print("⚠️  База данных не настроена. Пропускаем инициализацию.")
        return
    
    async with engine.begin() as conn:
        # Импортируем все модели чтобы они были зарегистрированы
        from ..models import user, card  # noqa
        
        # Создаем все таблицы
        await conn.run_sync(Base.metadata.create_all)
        print("✅ База данных инициализирована!") 