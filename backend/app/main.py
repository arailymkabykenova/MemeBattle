"""
Основное FastAPI приложение.
Здесь инициализируется приложение и подключаются роутеры.
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .core.config import settings
from .core.database import init_database
from .core.redis import init_redis, close_redis, get_redis_client
from .routers import users, auth, cards, rooms, games
from .websocket import routes as websocket_routes
from .websocket.connection_manager import init_connection_manager


def create_application() -> FastAPI:
    """
    Создает и настраивает FastAPI приложение.
    
    Returns:
        FastAPI: Настроенное приложение
    """
    app = FastAPI(
        title=settings.app_name,
        version=settings.version,
        debug=settings.debug,
        description="Backend API для iOS игры с мем-карточками",
        docs_url="/docs",
        redoc_url="/redoc"
    )
    
    # Настройка CORS
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origins,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
    
    # Подключаем роутеры
    app.include_router(auth.router)
    app.include_router(users.router)
    app.include_router(cards.router)
    app.include_router(rooms.router)  # Добавляем роутер игровых комнат
    app.include_router(games.router)
    app.include_router(websocket_routes.router, prefix="/websocket", tags=["WebSocket"])  # WebSocket роуты
    
    return app


# Создаем приложение
app = create_application()


@app.on_event("startup")
async def startup_event():
    """События при запуске приложения"""
    print("🚀 Запуск Meme Card Game API...")
    await init_database()
    await init_redis()
    
    # Инициализируем ConnectionManager с Redis клиентом
    redis_client = get_redis_client()
    await init_connection_manager(redis_client)
    
    print("✅ Приложение готово к работе!")


@app.on_event("shutdown")
async def shutdown_event():
    """События при остановке приложения"""
    print("🛑 Остановка Meme Card Game API...")
    await close_redis()
    print("✅ Приложение остановлено!")


@app.get("/")
async def root():
    """
    Проверка работы API.
    
    Returns:
        dict: Приветственное сообщение
    """
    return {
        "message": "Meme Card Game API",
        "version": "1.0.0",
        "status": "running",
        "endpoints": {
            "auth": "/auth",
            "users": "/users", 
            "cards": "/cards",
            "rooms": "/rooms",
            "games": "/games",
            "websocket": "/websocket/ws",
            "docs": "/docs"
        }
    }


@app.get("/health")
async def health_check():
    """
    Проверка состояния приложения.
    
    Returns:
        dict: Статус здоровья
    """
    from .core.redis import redis_client
    
    # Проверяем Redis
    redis_status = "connected" if redis_client else "disconnected"
    
    return {
        "status": "healthy",
        "app_name": settings.app_name,
        "version": settings.version,
        "database": "connected",  # TODO: добавить реальную проверку DB
        "redis": redis_status,
        "azure": "configured"     # TODO: добавить проверку Azure
    }


@app.get("/models/info")
async def models_info():
    """
    Информация о созданных моделях.
    
    Returns:
        dict: Информация о моделях базы данных
    """
    from .models import User, Card, UserCard
    from .models.user import Gender
    from .models.card import CardType
    
    return {
        "message": "Модели базы данных созданы",
        "models": {
            "users": {
                "table_name": User.__tablename__,
                "fields": ["id", "game_center_player_id", "nickname", "birth_date", "gender", "rating", "created_at"],
                "gender_options": [g.value for g in Gender]
            },
            "cards": {
                "table_name": Card.__tablename__, 
                "fields": ["id", "name", "image_url", "card_type", "is_unique", "created_at"],
                "card_types": [t.value for t in CardType]
            },
            "user_cards": {
                "table_name": UserCard.__tablename__,
                "fields": ["id", "user_id", "card_id", "obtained_at"]
            }
        },
        "database_status": "configured" if settings.database_url else "not_configured"
    } 