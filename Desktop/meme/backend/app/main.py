"""
Основное FastAPI приложение.
Здесь инициализируется приложение и подключаются роутеры.
"""

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import traceback
from .core.config import settings
from .core.database import init_database
from .core.redis import init_redis, close_redis, get_redis_client
# Импортируем роутеры по отдельности для избежания циклических импортов
from .routers import auth
from .routers import users
from .routers import cards
from .routers import rooms
from .routers import games
from .websocket import routes as websocket_routes
from .websocket.connection_manager import init_connection_manager
from .core.logging import auth_logger


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
    
    # Добавляем обработчик ошибок
    @app.exception_handler(Exception)
    async def global_exception_handler(request: Request, exc: Exception):
        """Глобальный обработчик исключений"""
        error_details = {
            "error_type": type(exc).__name__,
            "error_message": str(exc),
            "path": request.url.path,
            "method": request.method,
            "traceback": traceback.format_exc()
        }
        
        auth_logger.error(
            f"Unhandled exception in {request.method} {request.url.path}",
            extra=error_details
        )
        
        return JSONResponse(
            status_code=500,
            content={"detail": str(exc) if settings.debug else "Внутренняя ошибка сервера"}
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
    
    try:
        await init_database()
        print("✅ База данных инициализирована!")
    except Exception as e:
        print(f"⚠️  Ошибка инициализации базы данных: {e}")
        print("   Приложение запустится без базы данных")
    
    try:
        await init_redis()
        print("✅ Redis инициализирован!")
        
        # Инициализируем ConnectionManager с Redis клиентом
        redis_client = get_redis_client()
        await init_connection_manager(redis_client)
    except Exception as e:
        print(f"⚠️  Ошибка инициализации Redis: {e}")
        print("   Приложение запустится без Redis")
    
    # Автоматическая загрузка карт из Azure в БД
    if settings.auto_load_cards_from_azure:
        try:
            from .services.card_service import CardService
            from .core.database import async_session_maker
            
            async with async_session_maker() as db:
                card_service = CardService(db)
                
                # Проверяем, есть ли карты в БД
                stats = await card_service.get_card_statistics()
                total_cards = stats.get("total_cards", 0)
                
                if total_cards == 0:
                    print("📦 Загрузка карт из Azure в базу данных...")
                    result = await card_service.load_all_cards_from_azure()
                    loaded = result.get("total_loaded", 0)
                    print(f"✅ Загружено {loaded} карт из Azure!")
                else:
                    print(f"✅ В базе данных уже есть {total_cards} карт")
                    
        except Exception as e:
            print(f"⚠️  Ошибка загрузки карт из Azure: {e}")
            print("   Карты можно загрузить вручную через /cards/azure/load-all")
    else:
        print("⏭️  Автоматическая загрузка карт отключена")
    
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
                "fields": ["id", "nickname", "birth_date", "gender", "rating", "created_at"],
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