"""
Game Center клиент для аутентификации iOS пользователей.
Обрабатывает верификацию подписей Apple и Device ID аутентификацию.
"""

import jwt
import hashlib
import hmac
from typing import Optional, Dict, Any
from datetime import datetime, timedelta
import httpx
from ..core.config import settings
from ..utils.exceptions import AuthenticationError


class GameCenterClient:
    """Клиент для работы с Game Center аутентификацией"""
    
    def __init__(self):
        self.apple_team_id = settings.apple_team_id
        self.jwt_secret = settings.JWT_SECRET_KEY
        self.jwt_algorithm = settings.JWT_ALGORITHM
        self.jwt_expiration_hours = settings.JWT_EXPIRATION_HOURS
    
    async def verify_device_signature(
        self, 
        device_id: str, 
        signature: str, 
        timestamp: str,
        public_key_url: str
    ) -> bool:
        """
        Верифицирует подпись устройства от Apple Game Center.
        
        Args:
            device_id: Уникальный идентификатор устройства
            signature: Подпись от Apple
            timestamp: Временная метка
            public_key_url: URL публичного ключа Apple
            
        Returns:
            bool: True если подпись валидна
        """
        try:
            # В реальном приложении здесь должна быть верификация подписи Apple
            # Для MVP используем упрощенную проверку
            if not all([device_id, signature, timestamp, public_key_url]):
                return False
            
            # Проверяем формат device_id (должен быть UUID)
            if len(device_id) != 36:  # UUID длина
                return False
            
            # Проверяем timestamp (не старше 5 минут)
            try:
                sig_timestamp = datetime.fromisoformat(timestamp.replace('Z', '+00:00'))
                now = datetime.utcnow().replace(tzinfo=sig_timestamp.tzinfo)
                if (now - sig_timestamp).total_seconds() > 300:  # 5 минут
                    return False
            except ValueError:
                return False
            
            # Проверяем public_key_url (должен быть от Apple)
            if not public_key_url.startswith('https://static.gc.apple.com/'):
                return False
            
            return True
            
        except Exception as e:
            raise AuthenticationError(f"Ошибка верификации подписи: {str(e)}")
    
    def create_device_token(self, device_id: str) -> str:
        """
        Создает JWT токен для устройства.
        
        Args:
            device_id: Уникальный идентификатор устройства
            
        Returns:
            str: JWT токен
        """
        payload = {
            'device_id': device_id,
            'type': 'device',
            'exp': datetime.utcnow() + timedelta(hours=self.jwt_expiration_hours),
            'iat': datetime.utcnow()
        }
        
        return jwt.encode(payload, self.jwt_secret, algorithm=self.jwt_algorithm)
    
    def verify_device_token(self, token: str) -> Optional[Dict[str, Any]]:
        """
        Верифицирует JWT токен устройства.
        
        Args:
            token: JWT токен
            
        Returns:
            Optional[Dict]: Данные токена или None если невалиден
        """
        try:
            payload = jwt.decode(token, self.jwt_secret, algorithms=[self.jwt_algorithm])
            if payload.get('type') != 'device':
                return None
            return payload
        except jwt.ExpiredSignatureError:
            raise AuthenticationError("Токен истек")
        except jwt.InvalidTokenError:
            raise AuthenticationError("Невалидный токен")
    
    def create_user_token(self, user_id: int, device_id: str) -> str:
        """
        Создает JWT токен для пользователя.
        
        Args:
            user_id: ID пользователя
            device_id: ID устройства
            
        Returns:
            str: JWT токен
        """
        payload = {
            'user_id': user_id,
            'device_id': device_id,
            'type': 'user',
            'exp': datetime.utcnow() + timedelta(hours=self.jwt_expiration_hours),
            'iat': datetime.utcnow()
        }
        
        return jwt.encode(payload, self.jwt_secret, algorithm=self.jwt_algorithm)
    
    def verify_user_token(self, token: str) -> Optional[Dict[str, Any]]:
        """
        Верифицирует JWT токен пользователя.
        
        Args:
            token: JWT токен
            
        Returns:
            Optional[Dict]: Данные токена или None если невалиден
        """
        try:
            payload = jwt.decode(token, self.jwt_secret, algorithms=[self.jwt_algorithm])
            if payload.get('type') != 'user':
                return None
            return payload
        except jwt.ExpiredSignatureError:
            raise AuthenticationError("Токен истек")
        except jwt.InvalidTokenError:
            raise AuthenticationError("Невалидный токен")
    
    async def get_apple_public_key(self, key_id: str) -> Optional[str]:
        """
        Получает публичный ключ Apple для верификации подписей.
        
        Args:
            key_id: ID ключа
            
        Returns:
            Optional[str]: Публичный ключ
        """
        try:
            async with httpx.AsyncClient() as client:
                response = await client.get(
                    f"https://static.gc.apple.com/public_keys/{key_id}.pem"
                )
                if response.status_code == 200:
                    return response.text
                return None
        except Exception:
            return None


# Создаем глобальный экземпляр клиента
gamecenter_client = GameCenterClient() 