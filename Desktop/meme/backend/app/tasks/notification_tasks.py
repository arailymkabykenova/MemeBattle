"""
Задачи уведомлений для Celery.
"""

from celery import shared_task
from typing import List, Dict, Any
import json

from ..websocket.connection_manager import connection_manager


@shared_task
def send_notification_to_user(user_id: int, message: str, notification_type: str = "info"):
    """
    Отправляет уведомление конкретному пользователю.
    
    Args:
        user_id: ID пользователя
        message: Текст уведомления
        notification_type: Тип уведомления (info, warning, error)
    """
    try:
        notification_data = {
            "type": "notification",
            "message": message,
            "notification_type": notification_type,
            "timestamp": "2024-01-01T00:00:00Z"  # В реальном приложении использовался бы datetime.utcnow()
        }
        
        # В реальном приложении здесь была бы отправка через WebSocket
        print(f"Sending notification to user {user_id}: {message}")
        return f"Notification sent to user {user_id}"
        
    except Exception as e:
        print(f"Error sending notification to user {user_id}: {e}")
        return f"Notification failed: {e}"


@shared_task
def send_notification_to_room(room_id: int, message: str, notification_type: str = "info"):
    """
    Отправляет уведомление всем пользователям в комнате.
    
    Args:
        room_id: ID комнаты
        message: Текст уведомления
        notification_type: Тип уведомления
    """
    try:
        notification_data = {
            "type": "room_notification",
            "room_id": room_id,
            "message": message,
            "notification_type": notification_type,
            "timestamp": "2024-01-01T00:00:00Z"
        }
        
        print(f"Sending notification to room {room_id}: {message}")
        return f"Notification sent to room {room_id}"
        
    except Exception as e:
        print(f"Error sending notification to room {room_id}: {e}")
        return f"Room notification failed: {e}"


@shared_task
def send_bulk_notifications(user_ids: List[int], message: str, notification_type: str = "info"):
    """
    Отправляет уведомления группе пользователей.
    
    Args:
        user_ids: Список ID пользователей
        message: Текст уведомления
        notification_type: Тип уведомления
    """
    try:
        success_count = 0
        for user_id in user_ids:
            try:
                # В реальном приложении здесь была бы отправка
                print(f"Sending bulk notification to user {user_id}: {message}")
                success_count += 1
            except Exception as e:
                print(f"Failed to send notification to user {user_id}: {e}")
        
        return f"Bulk notifications sent: {success_count}/{len(user_ids)}"
        
    except Exception as e:
        print(f"Error in bulk notifications: {e}")
        return f"Bulk notifications failed: {e}"


@shared_task
def send_game_invitation(from_user_id: int, to_user_id: int, room_id: int):
    """
    Отправляет приглашение в игру.
    
    Args:
        from_user_id: ID пользователя, который приглашает
        to_user_id: ID пользователя, которого приглашают
        room_id: ID комнаты
    """
    try:
        invitation_data = {
            "type": "game_invitation",
            "from_user_id": from_user_id,
            "room_id": room_id,
            "timestamp": "2024-01-01T00:00:00Z"
        }
        
        print(f"Sending game invitation from user {from_user_id} to user {to_user_id}")
        return f"Game invitation sent to user {to_user_id}"
        
    except Exception as e:
        print(f"Error sending game invitation: {e}")
        return f"Game invitation failed: {e}"


@shared_task
def send_achievement_notification(user_id: int, achievement_type: str, achievement_data: Dict[str, Any]):
    """
    Отправляет уведомление о достижении.
    
    Args:
        user_id: ID пользователя
        achievement_type: Тип достижения
        achievement_data: Данные достижения
    """
    try:
        achievement_notification = {
            "type": "achievement",
            "achievement_type": achievement_type,
            "achievement_data": achievement_data,
            "timestamp": "2024-01-01T00:00:00Z"
        }
        
        print(f"Sending achievement notification to user {user_id}: {achievement_type}")
        return f"Achievement notification sent to user {user_id}"
        
    except Exception as e:
        print(f"Error sending achievement notification: {e}")
        return f"Achievement notification failed: {e}" 