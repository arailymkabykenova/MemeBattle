"""
Redis подключение и клиент для кэширования и сессий.
"""

import redis.asyncio as redis
from typing import Optional, Any, Dict, List
import json
import time
from datetime import timedelta

from .config import settings


class RedisClient:
    """Клиент для работы с Redis."""
    
    def __init__(self, redis_connection: redis.Redis):
        """
        Инициализирует клиент с готовым подключением.
        
        Args:
            redis_connection: Готовое подключение к Redis
        """
        self.redis = redis_connection
    
    async def set(self, key: str, value: Any, expire: Optional[int] = None) -> bool:
        """
        Устанавливает значение в Redis.
        
        Args:
            key: Ключ
            value: Значение (будет сериализовано в JSON)
            expire: Время жизни в секундах
            
        Returns:
            bool: True если успешно
        """
        try:
            serialized_value = json.dumps(value, ensure_ascii=False)
            return await self.redis.set(key, serialized_value, ex=expire)
        except Exception as e:
            print(f"Redis set error: {e}")
            return False
    
    async def get(self, key: str) -> Optional[Any]:
        """
        Получает значение из Redis.
        
        Args:
            key: Ключ
            
        Returns:
            Optional[Any]: Значение или None
        """
        try:
            value = await self.redis.get(key)
            if value:
                return json.loads(value)
            return None
        except Exception as e:
            print(f"Redis get error: {e}")
            return None
    
    async def delete(self, key: str) -> bool:
        """
        Удаляет ключ из Redis.
        
        Args:
            key: Ключ
            
        Returns:
            bool: True если удален
        """
        try:
            return bool(await self.redis.delete(key))
        except Exception as e:
            print(f"Redis delete error: {e}")
            return False
    
    async def exists(self, key: str) -> bool:
        """
        Проверяет существование ключа.
        
        Args:
            key: Ключ
            
        Returns:
            bool: True если существует
        """
        try:
            return bool(await self.redis.exists(key))
        except Exception as e:
            print(f"Redis exists error: {e}")
            return False
    
    async def expire(self, key: str, seconds: int) -> bool:
        """
        Устанавливает время жизни ключа.
        
        Args:
            key: Ключ
            seconds: Время жизни в секундах
            
        Returns:
            bool: True если успешно
        """
        try:
            return bool(await self.redis.expire(key, seconds))
        except Exception as e:
            print(f"Redis expire error: {e}")
            return False
    
    async def ttl(self, key: str) -> int:
        """
        Получает оставшееся время жизни ключа.
        
        Args:
            key: Ключ
            
        Returns:
            int: Время жизни в секундах (-1 если бессрочно, -2 если не существует)
        """
        try:
            return await self.redis.ttl(key)
        except Exception as e:
            print(f"Redis ttl error: {e}")
            return -2
    
    # Специфичные методы для игрового приложения
    
    async def cache_user_session(self, user_id: int, session_data: Dict[str, Any], expire: int = 3600) -> bool:
        """
        Кэширует сессию пользователя.
        
        Args:
            user_id: ID пользователя
            session_data: Данные сессии
            expire: Время жизни в секундах (по умолчанию 1 час)
            
        Returns:
            bool: True если успешно
        """
        key = f"user_session:{user_id}"
        return await self.set(key, session_data, expire)
    
    async def get_user_session(self, user_id: int) -> Optional[Dict[str, Any]]:
        """
        Получает сессию пользователя.
        
        Args:
            user_id: ID пользователя
            
        Returns:
            Optional[Dict]: Данные сессии или None
        """
        key = f"user_session:{user_id}"
        return await self.get(key)
    
    async def cache_room_state(self, room_id: int, room_data: Dict[str, Any], expire: int = 300) -> bool:
        """
        Кэширует состояние комнаты.
        
        Args:
            room_id: ID комнаты
            room_data: Данные комнаты
            expire: Время жизни в секундах (по умолчанию 5 минут)
            
        Returns:
            bool: True если успешно
        """
        key = f"room_state:{room_id}"
        return await self.set(key, room_data, expire)
    
    async def get_room_state(self, room_id: int) -> Optional[Dict[str, Any]]:
        """
        Получает состояние комнаты.
        
        Args:
            room_id: ID комнаты
            
        Returns:
            Optional[Dict]: Данные комнаты или None
        """
        key = f"room_state:{room_id}"
        return await self.get(key)
    
    async def cache_game_state(self, game_id: int, game_data: Dict[str, Any], expire: int = 600) -> bool:
        """
        Кэширует состояние игры.
        
        Args:
            game_id: ID игры
            game_data: Данные игры
            expire: Время жизни в секундах (по умолчанию 10 минут)
            
        Returns:
            bool: True если успешно
        """
        key = f"game_state:{game_id}"
        return await self.set(key, game_data, expire)
    
    async def get_game_state(self, game_id: int) -> Optional[Dict[str, Any]]:
        """
        Получает состояние игры.
        
        Args:
            game_id: ID игры
            
        Returns:
            Optional[Dict]: Данные игры или None
        """
        key = f"game_state:{game_id}"
        return await self.get(key)
    
    async def cache_leaderboard(self, leaderboard_data: List[Dict[str, Any]], expire: int = 1800) -> bool:
        """
        Кэширует таблицу лидеров.
        
        Args:
            leaderboard_data: Данные лидерборда
            expire: Время жизни в секундах (по умолчанию 30 минут)
            
        Returns:
            bool: True если успешно
        """
        key = "leaderboard:top_100"
        return await self.set(key, leaderboard_data, expire)
    
    async def get_leaderboard(self) -> Optional[List[Dict[str, Any]]]:
        """
        Получает таблицу лидеров.
        
        Returns:
            Optional[List]: Данные лидерборда или None
        """
        key = "leaderboard:top_100"
        return await self.get(key)
    
    async def increment_user_activity(self, user_id: int) -> int:
        """
        Увеличивает счетчик активности пользователя.
        
        Args:
            user_id: ID пользователя
            
        Returns:
            int: Новое значение счетчика
        """
        try:
            key = f"user_activity:{user_id}"
            return await self.redis.incr(key)
        except Exception as e:
            print(f"Redis increment error: {e}")
            return 0
    
    async def get_user_activity(self, user_id: int) -> int:
        """
        Получает счетчик активности пользователя.
        
        Args:
            user_id: ID пользователя
            
        Returns:
            int: Значение счетчика
        """
        try:
            key = f"user_activity:{user_id}"
            value = await self.redis.get(key)
            return int(value) if value else 0
        except Exception as e:
            print(f"Redis get activity error: {e}")
            return 0
    
    async def set_user_online(self, user_id: int, room_id: Optional[int] = None) -> bool:
        """
        Отмечает пользователя как онлайн.
        
        Args:
            user_id: ID пользователя
            room_id: ID комнаты (опционально)
            
        Returns:
            bool: True если успешно
        """
        try:
            key = f"user_online:{user_id}"
            data = {
                "user_id": user_id,
                "room_id": room_id,
                "timestamp": int(time.time())
            }
            return await self.set(key, data, 300)  # 5 минут
        except Exception as e:
            print(f"Redis set online error: {e}")
            return False
    
    async def is_user_online(self, user_id: int) -> bool:
        """
        Проверяет онлайн ли пользователь.
        
        Args:
            user_id: ID пользователя
            
        Returns:
            bool: True если онлайн
        """
        return await self.exists(f"user_online:{user_id}")
    
    # Pub/Sub методы для WebSocket масштабирования
    
    async def publish_game_event(self, room_id: int, event_type: str, event_data: Dict[str, Any]) -> bool:
        """
        Публикует игровое событие в Redis для синхронизации между серверами.
        
        Args:
            room_id: ID комнаты
            event_type: Тип события
            event_data: Данные события
            
        Returns:
            bool: True если успешно
        """
        try:
            channel = f"game_events:room:{room_id}"
            message = {
                "room_id": room_id,
                "event_type": event_type,
                "event_data": event_data,
                "timestamp": int(time.time())
            }
            subscribers_count = await self.redis.publish(channel, json.dumps(message, ensure_ascii=False))
            return subscribers_count > 0
        except Exception as e:
            print(f"Redis publish error: {e}")
            return False
    
    async def subscribe_to_room_events(self, room_id: int, callback) -> bool:
        """
        Подписывается на события комнаты.
        
        Args:
            room_id: ID комнаты
            callback: Функция обратного вызова для обработки событий
            
        Returns:
            bool: True если успешно
        """
        try:
            channel = f"game_events:room:{room_id}"
            pubsub = self.redis.pubsub()
            await pubsub.subscribe(channel)
            
            # Запускаем слушатель в фоне
            async def listener():
                async for message in pubsub.listen():
                    if message["type"] == "message":
                        try:
                            event_data = json.loads(message["data"])
                            await callback(event_data)
                        except Exception as e:
                            print(f"Error processing Redis message: {e}")
            
            # Запускаем в фоне (в реальном приложении используйте asyncio.create_task)
            import asyncio
            asyncio.create_task(listener())
            return True
        except Exception as e:
            print(f"Redis subscribe error: {e}")
            return False


# Глобальные переменные для управления подключением
redis_pool: Optional[redis.ConnectionPool] = None
redis_client: Optional[RedisClient] = None


async def init_redis():
    """Инициализирует подключение к Redis на уровне приложения."""
    global redis_pool, redis_client
    
    try:
        # Создаем пул соединений
        redis_pool = redis.ConnectionPool.from_url(
            settings.redis_url or "redis://localhost:6379",
            encoding="utf-8",
            decode_responses=True,
            max_connections=20
        )
        
        # Создаем подключение из пула
        redis_connection = redis.Redis(connection_pool=redis_pool)
        
        # Проверяем подключение
        await redis_connection.ping()
        
        # Создаем клиент
        redis_client = RedisClient(redis_connection)
        
        print("✅ Redis подключен успешно")
        
    except Exception as e:
        print(f"❌ Ошибка подключения к Redis: {e}")
        redis_pool = None
        redis_client = None


async def close_redis():
    """Закрывает подключение к Redis на уровне приложения."""
    global redis_pool, redis_client
    
    if redis_pool:
        await redis_pool.disconnect()
        redis_pool = None
        redis_client = None
        print("🔌 Redis подключение закрыто")


async def get_redis_client() -> RedisClient:
    """
    Dependency Injection функция для получения Redis клиента.
    
    Returns:
        RedisClient: Инициализированный клиент
        
    Raises:
        RuntimeError: Если Redis не инициализирован
    """
    if redis_client is None:
        raise RuntimeError("Redis не инициализирован. Убедитесь что init_redis() был вызван.")
    return redis_client 