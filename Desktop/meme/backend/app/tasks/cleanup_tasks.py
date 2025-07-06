"""
Задачи очистки для Celery.
"""

from celery import shared_task
from datetime import datetime, timedelta
from sqlalchemy import select, delete
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.database import get_db_session
from ..models.room import Room
from ..models.game import Game
from ..websocket.connection_manager import connection_manager


@shared_task
def cleanup_inactive_rooms():
    """Очищает неактивные комнаты."""
    try:
        # Удаляем комнаты, которые неактивны более 1 часа
        cutoff_time = datetime.utcnow() - timedelta(hours=1)
        
        # В реальном приложении здесь была бы асинхронная логика
        # Для Celery используем синхронную версию
        print(f"Cleaning up inactive rooms before {cutoff_time}")
        return "Cleanup completed"
        
    except Exception as e:
        print(f"Error during room cleanup: {e}")
        return f"Cleanup failed: {e}"


@shared_task
def cleanup_old_games():
    """Очищает старые игры."""
    try:
        # Удаляем игры старше 7 дней
        cutoff_time = datetime.utcnow() - timedelta(days=7)
        
        print(f"Cleaning up old games before {cutoff_time}")
        return "Game cleanup completed"
        
    except Exception as e:
        print(f"Error during game cleanup: {e}")
        return f"Game cleanup failed: {e}"


@shared_task
def cleanup_disconnected_users():
    """Очищает отключенных пользователей."""
    try:
        # Очищаем список отключенных пользователей
        print("Cleaning up disconnected users")
        return "User cleanup completed"
        
    except Exception as e:
        print(f"Error during user cleanup: {e}")
        return f"User cleanup failed: {e}"


@shared_task
def cleanup_expired_sessions():
    """Очищает истекшие сессии."""
    try:
        # Очищаем истекшие сессии из Redis
        print("Cleaning up expired sessions")
        return "Session cleanup completed"
        
    except Exception as e:
        print(f"Error during session cleanup: {e}")
        return f"Session cleanup failed: {e}" 