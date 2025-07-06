"""
WebSocket Connection Manager.
Управляет соединениями игроков, комнатами и отправкой сообщений.
"""

from typing import Dict, List, Optional, Set, Callable, Any
import json
import asyncio
from datetime import datetime
from fastapi import WebSocket, WebSocketDisconnect
import logging

from ..models.user import User
from ..core.redis import RedisClient

logger = logging.getLogger(__name__)


class ConnectionManager:
    """Менеджер WebSocket соединений"""
    
    def __init__(self, redis_client: Optional[RedisClient] = None):
        # Активные соединения: {user_id: WebSocket}
        self.active_connections: Dict[int, WebSocket] = {}
        
        # Пользователи в комнатах: {room_id: {user_id}}
        self.room_users: Dict[int, Set[int]] = {}
        
        # Пользователи в играх: {game_id: {user_id}}
        self.game_users: Dict[int, Set[int]] = {}
        
        # Маппинг пользователя к комнате: {user_id: room_id}
        self.user_room: Dict[int, int] = {}
        
        # Маппинг пользователя к игре: {user_id: game_id}  
        self.user_game: Dict[int, int] = {}
        
        # Redis клиент для подписки на события
        self.redis_client = redis_client
        
        # Обработчики Redis событий для комнат: {room_id: callback}
        self.redis_event_handlers: Dict[int, Callable] = {}
    
    async def connect(self, websocket: WebSocket, user: User, room_id: Optional[int] = None, db_session = None):
        """
        Подключает пользователя к WebSocket.
        
        Args:
            websocket: WebSocket соединение
            user: Объект пользователя
            room_id: ID комнаты (опционально, только для справки)
            db_session: Сессия базы данных для синхронизации состояния
        """
        await websocket.accept()
        
        # Закрываем предыдущее соединение если есть
        if user.id in self.active_connections:
            try:
                await self.active_connections[user.id].close()
            except:
                pass
        
        # Сохраняем новое соединение
        self.active_connections[user.id] = websocket
        
        # Синхронизируем состояние с базой данных
        current_room_id = None
        print(f"🔍 DEBUG: Starting room sync for user {user.id}, db_session: {db_session is not None}")
        if db_session:
            try:
                from ..services.room_service import RoomService
                room_service = RoomService(db_session)
                print(f"🔍 DEBUG: Checking current room for user {user.id}")
                current_room = await room_service.get_user_current_room(user.id)
                print(f"🔍 DEBUG: current_room for user {user.id}: {current_room}")
                if current_room:
                    current_room_id = current_room.id
                    # Добавляем пользователя в WebSocket комнату без уведомлений
                    await self._sync_join_room(user.id, current_room_id)
                    print(f"🔍 DEBUG: User {user.id} synced to existing room {current_room_id}")
                else:
                    print(f"🔍 DEBUG: User {user.id} has no current room in database")
            except Exception as e:
                print(f"🔍 DEBUG: Failed to sync user room state for user {user.id}: {e}")
        else:
            print(f"🔍 DEBUG: No db_session provided for user {user.id}, skipping room sync")
        
        logger.info(f"User {user.id} ({user.nickname}) connected to WebSocket")
        
        # Отправляем подтверждение подключения
        print(f"🔍 DEBUG: Sending connection_established with room_id: {current_room_id}")
        await self.send_personal_message({
            "type": "connection_established",
            "user_id": user.id,
            "nickname": user.nickname,
            "timestamp": datetime.utcnow().isoformat(),
            "room_id": current_room_id
        }, user.id)
    
    async def disconnect(self, user_id: int):
        """
        Отключает пользователя от WebSocket.
        
        Args:
            user_id: ID пользователя
        """
        if user_id in self.active_connections:
            # Уведомляем комнату об отключении
            if user_id in self.user_room:
                room_id = self.user_room[user_id]
                await self.broadcast_to_room({
                    "type": "player_disconnected",
                    "user_id": user_id,
                    "timestamp": datetime.utcnow().isoformat()
                }, room_id, exclude_user=user_id)
            
            # Удаляем соединение
            del self.active_connections[user_id]
            
            # Удаляем из комнаты
            if user_id in self.user_room:
                room_id = self.user_room[user_id]
                self.room_users[room_id].discard(user_id)
                del self.user_room[user_id]
            
            # Удаляем из игры
            if user_id in self.user_game:
                game_id = self.user_game[user_id]
                self.game_users[game_id].discard(user_id)
                del self.user_game[user_id]
            
            logger.info(f"User {user_id} disconnected from WebSocket")
    
    async def _sync_join_room(self, user_id: int, room_id: int):
        """
        Добавляет пользователя в комнату БЕЗ уведомлений (для синхронизации).
        
        Args:
            user_id: ID пользователя
            room_id: ID комнаты
        """
        # Удаляем из предыдущей комнаты
        if user_id in self.user_room:
            old_room_id = self.user_room[user_id]
            self.room_users[old_room_id].discard(user_id)
        
        # Добавляем в новую комнату
        if room_id not in self.room_users:
            self.room_users[room_id] = set()
        
        self.room_users[room_id].add(user_id)
        self.user_room[user_id] = room_id

    async def join_room(self, user_id: int, room_id: int):
        """
        Добавляет пользователя в комнату.
        
        Args:
            user_id: ID пользователя
            room_id: ID комнаты
        """
        # Используем внутренний метод для добавления
        await self._sync_join_room(user_id, room_id)
        
        # Уведомляем комнату о новом игроке
        await self.broadcast_to_room({
            "type": "player_joined_room",
            "user_id": user_id,
            "room_id": room_id,
            "timestamp": datetime.utcnow().isoformat()
        }, room_id, exclude_user=user_id)
        
        logger.info(f"User {user_id} joined room {room_id}")
    
    async def join_game(self, user_id: int, game_id: int):
        """
        Добавляет пользователя в игру.
        
        Args:
            user_id: ID пользователя
            game_id: ID игры
        """
        if game_id not in self.game_users:
            self.game_users[game_id] = set()
        
        self.game_users[game_id].add(user_id)
        self.user_game[user_id] = game_id
        
        logger.info(f"User {user_id} joined game {game_id}")
    
    async def leave_room(self, user_id: int):
        """
        Удаляет пользователя из комнаты.
        
        Args:
            user_id: ID пользователя
        """
        if user_id in self.user_room:
            room_id = self.user_room[user_id]
            self.room_users[room_id].discard(user_id)
            del self.user_room[user_id]
            
            # Уведомляем комнату
            await self.broadcast_to_room({
                "type": "player_left_room",
                "user_id": user_id,
                "room_id": room_id,
                "timestamp": datetime.utcnow().isoformat()
            }, room_id)
            
            logger.info(f"User {user_id} left room {room_id}")
    
    async def send_personal_message(self, message: dict, user_id: int):
        """
        Отправляет личное сообщение пользователю.
        
        Args:
            message: Сообщение для отправки
            user_id: ID получателя
        """
        if user_id in self.active_connections:
            try:
                websocket = self.active_connections[user_id]
                await websocket.send_text(json.dumps(message, default=str))
            except Exception as e:
                logger.error(f"Failed to send message to user {user_id}: {e}")
                # Удаляем неактивное соединение
                await self.disconnect(user_id)
    
    async def broadcast_to_room(self, message: dict, room_id: int, exclude_user: Optional[int] = None):
        """
        Отправляет сообщение всем в комнате.
        
        Args:
            message: Сообщение для отправки
            room_id: ID комнаты
            exclude_user: ID пользователя которого исключить
        """
        if room_id in self.room_users:
            users = self.room_users[room_id].copy()
            if exclude_user:
                users.discard(exclude_user)
            
            # Отправляем всем активным пользователям
            for user_id in users:
                await self.send_personal_message(message, user_id)
            
            logger.debug(f"Broadcasted message to room {room_id}, {len(users)} users")
    
    async def broadcast_to_game(self, message: dict, game_id: int, exclude_user: Optional[int] = None):
        """
        Отправляет сообщение всем в игре.
        
        Args:
            message: Сообщение для отправки
            game_id: ID игры
            exclude_user: ID пользователя которого исключить
        """
        if game_id in self.game_users:
            users = self.game_users[game_id].copy()
            if exclude_user:
                users.discard(exclude_user)
            
            # Отправляем всем активным пользователям
            for user_id in users:
                await self.send_personal_message(message, user_id)
            
            logger.debug(f"Broadcasted message to game {game_id}, {len(users)} users")
    
    def get_room_users(self, room_id: int) -> List[int]:
        """Получает список пользователей в комнате"""
        return list(self.room_users.get(room_id, set()))
    
    def get_game_users(self, game_id: int) -> List[int]:
        """Получает список пользователей в игре"""
        return list(self.game_users.get(game_id, set()))
    
    def is_user_connected(self, user_id: int) -> bool:
        """Проверяет подключен ли пользователь"""
        return user_id in self.active_connections
    
    def get_user_room(self, user_id: int) -> Optional[int]:
        """Получает ID комнаты пользователя"""
        return self.user_room.get(user_id)
    
    def get_user_game(self, user_id: int) -> Optional[int]:
        """Получает ID игры пользователя"""
        return self.user_game.get(user_id)
    
    async def ping_user(self, user_id: int) -> bool:
        """
        Отправляет ping пользователю для проверки соединения.
        
        Args:
            user_id: ID пользователя
            
        Returns:
            bool: True если пользователь ответил, False если нет
        """
        if user_id not in self.active_connections:
            return False
        
        try:
            await self.send_personal_message({
                "type": "ping",
                "timestamp": datetime.utcnow().isoformat()
            }, user_id)
            return True
        except:
            await self.disconnect(user_id)
            return False
    
    def get_stats(self) -> dict:
        """Получает статистику соединений"""
        return {
            "total_connections": len(self.active_connections),
            "total_rooms": len(self.room_users),
            "total_games": len(self.game_users),
            "rooms_with_users": {room_id: len(users) for room_id, users in self.room_users.items()},
            "games_with_users": {game_id: len(users) for game_id, users in self.game_users.items()}
        }
    
    async def subscribe_to_room_events(self, room_id: int):
        """
        Подписывается на Redis события для комнаты.
        
        Args:
            room_id: ID комнаты
        """
        if not self.redis_client or room_id in self.redis_event_handlers:
            return
        
        # Создаем обработчик событий для комнаты
        async def handle_redis_event(event_data: dict):
            """Обрабатывает Redis события для комнаты"""
            try:
                event_type = event_data.get("event_type")
                event_data_content = event_data.get("event_data", {})
                
                # Формируем WebSocket сообщение в зависимости от типа события
                ws_message = {
                    "type": event_type,
                    "timestamp": datetime.utcnow().isoformat(),
                    **event_data_content
                }
                
                # Отправляем сообщение всем пользователям в комнате
                await self.broadcast_to_room(ws_message, room_id)
                
                logger.info(f"Redis event '{event_type}' broadcasted to room {room_id}")
                
            except Exception as e:
                logger.error(f"Error handling Redis event for room {room_id}: {e}")
        
        # Сохраняем обработчик
        self.redis_event_handlers[room_id] = handle_redis_event
        
        # Подписываемся на Redis события
        await self.redis_client.subscribe_to_room_events(room_id, handle_redis_event)
        
        logger.info(f"Subscribed to Redis events for room {room_id}")
    
    async def unsubscribe_from_room_events(self, room_id: int):
        """
        Отписывается от Redis событий для комнаты.
        
        Args:
            room_id: ID комнаты
        """
        if room_id in self.redis_event_handlers:
            # В будущем можно добавить отписку от Redis канала
            del self.redis_event_handlers[room_id]
            logger.info(f"Unsubscribed from Redis events for room {room_id}")
    
    async def handle_redis_event(self, event_data: dict):
        """
        Обрабатывает входящие Redis события.
        
        Args:
            event_data: Данные события из Redis
        """
        try:
            room_id = event_data.get("room_id")
            if not room_id or room_id not in self.redis_event_handlers:
                return
            
            # Вызываем обработчик для комнаты
            handler = self.redis_event_handlers[room_id]
            await handler(event_data)
            
        except Exception as e:
            logger.error(f"Error handling Redis event: {e}")


# Глобальный экземпляр менеджера (будет инициализирован с Redis в main.py)
connection_manager: Optional[ConnectionManager] = None

def get_connection_manager() -> ConnectionManager:
    """Получает глобальный экземпляр ConnectionManager"""
    if connection_manager is None:
        raise RuntimeError("ConnectionManager not initialized. Call init_connection_manager() first.")
    return connection_manager

async def init_connection_manager(redis_client: RedisClient):
    """Инициализирует глобальный ConnectionManager с Redis клиентом"""
    global connection_manager
    connection_manager = ConnectionManager(redis_client)
    logger.info("ConnectionManager initialized with Redis client") 