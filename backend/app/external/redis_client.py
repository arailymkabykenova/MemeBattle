"""
Redis клиент для кэширования и управления сессиями.
Обеспечивает высокопроизводительное кэширование данных.
"""

import redis.asyncio as redis
import json
import pickle
from typing import Any, Optional, Dict, List
from datetime import timedelta
from ..core.config import settings
from ..utils.exceptions import RedisError


class RedisClient:
    """Клиент для работы с Redis"""
    
    def __init__(self):
        self.redis_url = settings.redis_url
        self.redis_host = settings.redis_host
        self.redis_port = settings.redis_port
        self.redis_db = settings.redis_db
        self.redis_password = settings.redis_password
        self.client: Optional[redis.Redis] = None
    
    async def connect(self):
        """Подключается к Redis"""
        try:
            if self.redis_url:
                self.client = redis.from_url(
                    self.redis_url,
                    decode_responses=True
                )
            else:
                self.client = redis.Redis(
                    host=self.redis_host,
                    port=self.redis_port,
                    db=self.redis_db,
                    password=self.redis_password,
                    decode_responses=True
                )
            
            # Проверяем подключение
            await self.client.ping()
            
        except Exception as e:
            raise RedisError(f"Ошибка подключения к Redis: {str(e)}")
    
    async def disconnect(self):
        """Отключается от Redis"""
        if self.client:
            await self.client.close()
            self.client = None
    
    async def set(self, key: str, value: Any, expire: Optional[int] = None) -> bool:
        """
        Устанавливает значение в Redis.
        
        Args:
            key: Ключ
            value: Значение
            expire: Время жизни в секундах
            
        Returns:
            bool: True если успешно
        """
        try:
            if isinstance(value, (dict, list)):
                value = json.dumps(value)
            
            result = await self.client.set(key, value, ex=expire)
            return bool(result)
            
        except Exception as e:
            raise RedisError(f"Ошибка установки значения: {str(e)}")
    
    async def get(self, key: str) -> Optional[Any]:
        """
        Получает значение из Redis.
        
        Args:
            key: Ключ
            
        Returns:
            Optional[Any]: Значение или None
        """
        try:
            value = await self.client.get(key)
            if value is None:
                return None
            
            # Пытаемся распарсить JSON
            try:
                return json.loads(value)
            except json.JSONDecodeError:
                return value
                
        except Exception as e:
            raise RedisError(f"Ошибка получения значения: {str(e)}")
    
    async def delete(self, key: str) -> bool:
        """
        Удаляет ключ из Redis.
        
        Args:
            key: Ключ
            
        Returns:
            bool: True если удален
        """
        try:
            result = await self.client.delete(key)
            return bool(result)
            
        except Exception as e:
            raise RedisError(f"Ошибка удаления ключа: {str(e)}")
    
    async def exists(self, key: str) -> bool:
        """
        Проверяет существование ключа.
        
        Args:
            key: Ключ
            
        Returns:
            bool: True если существует
        """
        try:
            result = await self.client.exists(key)
            return bool(result)
            
        except Exception as e:
            raise RedisError(f"Ошибка проверки ключа: {str(e)}")
    
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
            result = await self.client.expire(key, seconds)
            return bool(result)
            
        except Exception as e:
            raise RedisError(f"Ошибка установки времени жизни: {str(e)}")
    
    async def ttl(self, key: str) -> int:
        """
        Получает оставшееся время жизни ключа.
        
        Args:
            key: Ключ
            
        Returns:
            int: Время жизни в секундах (-1 если бесконечно, -2 если не существует)
        """
        try:
            return await self.client.ttl(key)
            
        except Exception as e:
            raise RedisError(f"Ошибка получения TTL: {str(e)}")
    
    async def hset(self, name: str, key: str, value: Any) -> bool:
        """
        Устанавливает значение в хеш.
        
        Args:
            name: Имя хеша
            key: Ключ в хеше
            value: Значение
            
        Returns:
            bool: True если успешно
        """
        try:
            if isinstance(value, (dict, list)):
                value = json.dumps(value)
            
            result = await self.client.hset(name, key, value)
            return bool(result)
            
        except Exception as e:
            raise RedisError(f"Ошибка установки значения в хеш: {str(e)}")
    
    async def hget(self, name: str, key: str) -> Optional[Any]:
        """
        Получает значение из хеша.
        
        Args:
            name: Имя хеша
            key: Ключ в хеше
            
        Returns:
            Optional[Any]: Значение или None
        """
        try:
            value = await self.client.hget(name, key)
            if value is None:
                return None
            
            # Пытаемся распарсить JSON
            try:
                return json.loads(value)
            except json.JSONDecodeError:
                return value
                
        except Exception as e:
            raise RedisError(f"Ошибка получения значения из хеша: {str(e)}")
    
    async def hgetall(self, name: str) -> Dict[str, Any]:
        """
        Получает все значения из хеша.
        
        Args:
            name: Имя хеша
            
        Returns:
            Dict[str, Any]: Все значения
        """
        try:
            values = await self.client.hgetall(name)
            result = {}
            
            for key, value in values.items():
                try:
                    result[key] = json.loads(value)
                except json.JSONDecodeError:
                    result[key] = value
            
            return result
            
        except Exception as e:
            raise RedisError(f"Ошибка получения всех значений из хеша: {str(e)}")
    
    async def lpush(self, name: str, *values: Any) -> int:
        """
        Добавляет значения в начало списка.
        
        Args:
            name: Имя списка
            *values: Значения
            
        Returns:
            int: Длина списка после добавления
        """
        try:
            serialized_values = []
            for value in values:
                if isinstance(value, (dict, list)):
                    serialized_values.append(json.dumps(value))
                else:
                    serialized_values.append(str(value))
            
            return await self.client.lpush(name, *serialized_values)
            
        except Exception as e:
            raise RedisError(f"Ошибка добавления в список: {str(e)}")
    
    async def rpop(self, name: str) -> Optional[Any]:
        """
        Удаляет и возвращает последний элемент списка.
        
        Args:
            name: Имя списка
            
        Returns:
            Optional[Any]: Значение или None
        """
        try:
            value = await self.client.rpop(name)
            if value is None:
                return None
            
            # Пытаемся распарсить JSON
            try:
                return json.loads(value)
            except json.JSONDecodeError:
                return value
                
        except Exception as e:
            raise RedisError(f"Ошибка получения из списка: {str(e)}")
    
    async def llen(self, name: str) -> int:
        """
        Получает длину списка.
        
        Args:
            name: Имя списка
            
        Returns:
            int: Длина списка
        """
        try:
            return await self.client.llen(name)
            
        except Exception as e:
            raise RedisError(f"Ошибка получения длины списка: {str(e)}")
    
    async def sadd(self, name: str, *values: Any) -> int:
        """
        Добавляет значения в множество.
        
        Args:
            name: Имя множества
            *values: Значения
            
        Returns:
            int: Количество добавленных элементов
        """
        try:
            serialized_values = []
            for value in values:
                if isinstance(value, (dict, list)):
                    serialized_values.append(json.dumps(value))
                else:
                    serialized_values.append(str(value))
            
            return await self.client.sadd(name, *serialized_values)
            
        except Exception as e:
            raise RedisError(f"Ошибка добавления в множество: {str(e)}")
    
    async def smembers(self, name: str) -> List[Any]:
        """
        Получает все элементы множества.
        
        Args:
            name: Имя множества
            
        Returns:
            List[Any]: Все элементы
        """
        try:
            values = await self.client.smembers(name)
            result = []
            
            for value in values:
                try:
                    result.append(json.loads(value))
                except json.JSONDecodeError:
                    result.append(value)
            
            return result
            
        except Exception as e:
            raise RedisError(f"Ошибка получения элементов множества: {str(e)}")
    
    async def srem(self, name: str, *values: Any) -> int:
        """
        Удаляет значения из множества.
        
        Args:
            name: Имя множества
            *values: Значения для удаления
            
        Returns:
            int: Количество удаленных элементов
        """
        try:
            serialized_values = []
            for value in values:
                if isinstance(value, (dict, list)):
                    serialized_values.append(json.dumps(value))
                else:
                    serialized_values.append(str(value))
            
            return await self.client.srem(name, *serialized_values)
            
        except Exception as e:
            raise RedisError(f"Ошибка удаления из множества: {str(e)}")
    
    async def incr(self, key: str, amount: int = 1) -> int:
        """
        Увеличивает значение счетчика.
        
        Args:
            key: Ключ счетчика
            amount: Величина увеличения
            
        Returns:
            int: Новое значение
        """
        try:
            return await self.client.incrby(key, amount)
            
        except Exception as e:
            raise RedisError(f"Ошибка увеличения счетчика: {str(e)}")
    
    async def decr(self, key: str, amount: int = 1) -> int:
        """
        Уменьшает значение счетчика.
        
        Args:
            key: Ключ счетчика
            amount: Величина уменьшения
            
        Returns:
            int: Новое значение
        """
        try:
            return await self.client.decrby(key, amount)
            
        except Exception as e:
            raise RedisError(f"Ошибка уменьшения счетчика: {str(e)}")


# Создаем глобальный экземпляр клиента
redis_client = RedisClient() 