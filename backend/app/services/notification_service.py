"""
Notification Service.
Сервис для отправки уведомлений в реальном времени через WebSocket.
"""

from typing import Optional, Dict, Any
from datetime import datetime
import logging

from ..websocket.connection_manager import connection_manager

logger = logging.getLogger(__name__)


class NotificationService:
    """Сервис для отправки уведомлений в реальном времени"""
    
    @staticmethod
    async def notify_room_update(room_id: int, update_type: str, data: Dict[str, Any]):
        """
        Уведомляет всех в комнате об обновлении.
        
        Args:
            room_id: ID комнаты
            update_type: Тип обновления
            data: Данные обновления
        """
        message = {
            "type": f"room_{update_type}",
            "room_id": room_id,
            "data": data,
            "timestamp": datetime.utcnow().isoformat()
        }
        
        await connection_manager.broadcast_to_room(message, room_id)
        logger.debug(f"Notified room {room_id} about {update_type}")
    
    @staticmethod
    async def notify_game_update(game_id: int, update_type: str, data: Dict[str, Any]):
        """
        Уведомляет всех в игре об обновлении.
        
        Args:
            game_id: ID игры
            update_type: Тип обновления
            data: Данные обновления
        """
        message = {
            "type": f"game_{update_type}",
            "game_id": game_id,
            "data": data,
            "timestamp": datetime.utcnow().isoformat()
        }
        
        await connection_manager.broadcast_to_game(message, game_id)
        logger.debug(f"Notified game {game_id} about {update_type}")
    
    @staticmethod
    async def notify_user(user_id: int, notification_type: str, data: Dict[str, Any]):
        """
        Отправляет персональное уведомление пользователю.
        
        Args:
            user_id: ID пользователя
            notification_type: Тип уведомления
            data: Данные уведомления
        """
        message = {
            "type": notification_type,
            "data": data,
            "timestamp": datetime.utcnow().isoformat()
        }
        
        await connection_manager.send_personal_message(message, user_id)
        logger.debug(f"Sent {notification_type} notification to user {user_id}")
    
    @staticmethod
    async def notify_round_started(game_id: int, round_data: Dict[str, Any]):
        """
        Уведомляет о начале нового раунда.
        
        Args:
            game_id: ID игры
            round_data: Данные раунда (номер, время, ситуация)
        """
        await NotificationService.notify_game_update(game_id, "round_started", {
            "round_id": round_data.get("round_id"),
            "round_number": round_data.get("round_number"),
            "situation_text": round_data.get("situation_text"),
            "duration_seconds": round_data.get("duration_seconds"),
            "message": f"Раунд {round_data.get('round_number')} начался!"
        })
    
    @staticmethod
    async def notify_voting_started(game_id: int, round_id: int, choices: list):
        """
        Уведомляет о начале голосования.
        
        Args:
            game_id: ID игры
            round_id: ID раунда
            choices: Список выборов игроков
        """
        await NotificationService.notify_game_update(game_id, "voting_started", {
            "round_id": round_id,
            "choices": choices,
            "message": "Голосование началось! Выберите лучшую карту."
        })
    
    @staticmethod
    async def notify_round_results(game_id: int, results: Dict[str, Any]):
        """
        Уведомляет о результатах раунда.
        
        Args:
            game_id: ID игры
            results: Результаты раунда
        """
        await NotificationService.notify_game_update(game_id, "round_results", results)
    
    @staticmethod
    async def notify_game_ended(game_id: int, winner_data: Optional[Dict[str, Any]], reason: str):
        """
        Уведомляет о завершении игры.
        
        Args:
            game_id: ID игры
            winner_data: Данные победителя
            reason: Причина завершения
        """
        await NotificationService.notify_game_update(game_id, "ended", {
            "winner": winner_data,
            "reason": reason,
            "message": f"Игра завершена! {reason}"
        })
    
    @staticmethod
    async def notify_player_joined(room_id: int, user_data: Dict[str, Any]):
        """
        Уведомляет о присоединении игрока к комнате.
        
        Args:
            room_id: ID комнаты
            user_data: Данные присоединившегося игрока
        """
        await NotificationService.notify_room_update(room_id, "player_joined", {
            "user": user_data,
            "message": f"{user_data.get('nickname')} присоединился к комнате"
        })
    
    @staticmethod
    async def notify_player_left(room_id: int, user_data: Dict[str, Any]):
        """
        Уведомляет о выходе игрока из комнаты.
        
        Args:
            room_id: ID комнаты
            user_data: Данные ушедшего игрока
        """
        await NotificationService.notify_room_update(room_id, "player_left", {
            "user": user_data,
            "message": f"{user_data.get('nickname')} покинул комнату"
        })
    
    @staticmethod
    async def notify_timeout_warning(game_id: int, action_type: str, seconds_left: int):
        """
        Уведомляет о приближающемся таймауте.
        
        Args:
            game_id: ID игры
            action_type: Тип действия (choice/voting)
            seconds_left: Оставшееся время в секундах
        """
        await NotificationService.notify_game_update(game_id, "timeout_warning", {
            "action_type": action_type,
            "seconds_left": seconds_left,
            "message": f"Осталось {seconds_left} секунд!"
        })
    
    @staticmethod
    async def notify_player_disconnected(room_id: int, user_id: int, nickname: str):
        """
        Уведомляет об отключении игрока.
        
        Args:
            room_id: ID комнаты
            user_id: ID игрока
            nickname: Никнейм игрока
        """
        await NotificationService.notify_room_update(room_id, "player_disconnected", {
            "user_id": user_id,
            "nickname": nickname,
            "message": f"{nickname} отключился"
        })
    
    @staticmethod
    async def notify_player_reconnected(room_id: int, user_id: int, nickname: str):
        """
        Уведомляет о переподключении игрока.
        
        Args:
            room_id: ID комнаты
            user_id: ID игрока
            nickname: Никнейм игрока
        """
        await NotificationService.notify_room_update(room_id, "player_reconnected", {
            "user_id": user_id,
            "nickname": nickname,
            "message": f"{nickname} переподключился"
        })
    
    @staticmethod
    def get_connected_users_count(room_id: int) -> int:
        """
        Получает количество подключенных пользователей в комнате.
        
        Args:
            room_id: ID комнаты
            
        Returns:
            int: Количество подключенных пользователей
        """
        return len(connection_manager.get_room_users(room_id))
    
    @staticmethod
    def is_user_connected(user_id: int) -> bool:
        """
        Проверяет подключен ли пользователь.
        
        Args:
            user_id: ID пользователя
            
        Returns:
            bool: True если подключен
        """
        return connection_manager.is_user_connected(user_id) 