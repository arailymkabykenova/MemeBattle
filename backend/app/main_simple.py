"""
Упрощенная версия FastAPI приложения для тестирования.
"""

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
import traceback
from .core.config import settings


def create_application() -> FastAPI:
    """
    Создает и настраивает FastAPI приложение.
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
        }
        
        return JSONResponse(
            status_code=500,
            content={"detail": str(exc) if settings.debug else "Внутренняя ошибка сервера"}
        )
    
    return app


# Создаем приложение
app = create_application()


@app.on_event("startup")
async def startup_event():
    """События при запуске приложения"""
    print("🚀 Запуск Meme Card Game API (упрощенная версия)...")
    print("⚠️  База данных инициализация пропущена (упрощенная версия)")
    print("✅ Приложение готово к работе!")


@app.on_event("shutdown")
async def shutdown_event():
    """События при остановке приложения"""
    print("🛑 Остановка Meme Card Game API...")
    print("✅ Приложение остановлено!")


@app.get("/")
async def root():
    """
    Проверка работы API.
    """
    return {
        "message": "Meme Card Game API (упрощенная версия)",
        "version": "1.0.0",
        "status": "running",
        "endpoints": {
            "health": "/health",
            "docs": "/docs"
        }
    }


@app.get("/health")
async def health_check():
    """
    Проверка состояния приложения.
    """
    return {
        "status": "healthy",
        "app_name": settings.app_name,
        "version": settings.version,
        "database": "not_configured",
        "redis": "not_configured",
        "azure": "not_configured"
    }


@app.get("/test")
async def test_endpoint():
    """
    Тестовый endpoint.
    """
    return {
        "message": "Тест успешен!",
        "timestamp": "2024-01-01T00:00:00Z"
    } 