"""
Celery приложение для фоновых задач.
"""

from celery import Celery
from .config import settings

# Создаем Celery приложение
celery_app = Celery(
    "meme_game",
    broker=settings.redis_url or "redis://localhost:6379/0",
    backend=settings.redis_url or "redis://localhost:6379/0",
    include=[
        "app.tasks.ai_tasks",
        "app.tasks.cleanup_tasks", 
        "app.tasks.notification_tasks"
    ]
)

# Конфигурация Celery
celery_app.conf.update(
    # Основные настройки
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    
    # Настройки задач
    task_track_started=True,
    task_time_limit=30 * 60,  # 30 минут
    task_soft_time_limit=25 * 60,  # 25 минут
    
    # Настройки worker
    worker_prefetch_multiplier=1,
    worker_max_tasks_per_child=1000,
    
    # Настройки результатов
    result_expires=3600,  # 1 час
    
    # Настройки очередей
    task_default_queue="default",
    task_routes={
        "app.tasks.ai_tasks.*": {"queue": "ai"},
        "app.tasks.cleanup_tasks.*": {"queue": "cleanup"},
        "app.tasks.notification_tasks.*": {"queue": "notifications"},
    },
    
    # Настройки retry
    task_acks_late=True,
    worker_disable_rate_limits=False,
    
    # Настройки мониторинга
    worker_send_task_events=True,
    task_send_sent_event=True,
)

# Автоматическое обнаружение задач
celery_app.autodiscover_tasks()


@celery_app.task(bind=True)
def debug_task(self):
    """Тестовая задача для проверки работы Celery."""
    print(f"Request: {self.request!r}")
    return "Celery is working!" 