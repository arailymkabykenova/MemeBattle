"""
Сервис аутентификации Game Center.
Обрабатывает логику входа/регистрации через Game Center.
"""

import jwt
import httpx
import hashlib
import base64
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.exceptions import InvalidSignature

from ..core.config import get_settings
from ..repositories.user_repository import UserRepository
from ..schemas.auth import (
    GameCenterAuthRequest, 
    GameCenterVerificationResponse, 
    TokenResponse,
    UserLoginResponse
)
from ..schemas.user import UserCreate, UserResponse
from ..models.user import User, Gender
from ..utils.exceptions import AuthenticationError, ValidationError, UserNotFoundError


class GameCenterVerificationService:
    """Сервис верификации подписи Game Center от Apple"""
    
    @staticmethod
    async def verify_signature(auth_data: GameCenterAuthRequest) -> GameCenterVerificationResponse:
        """
        Верифицирует подпись Game Center от Apple.
        
        Args:
            auth_data: Данные аутентификации Game Center
            
        Returns:
            GameCenterVerificationResponse: Результат верификации
        """
        try:
            # TODO: Implement actual Apple signature verification
            # Для полной реализации нужно:
            # 1. Загрузить публичный ключ по public_key_url
            # 2. Проверить цепочку сертификатов Apple
            # 3. Верифицировать подпись используя RSA-SHA256
            # 4. Проверить timestamp (не старше 24 часов)
            
            # ВРЕМЕННАЯ ЗАГЛУШКА для разработки
            # В продакшене заменить на реальную верификацию
            is_valid = await GameCenterVerificationService._mock_verification(auth_data)
            
            return GameCenterVerificationResponse(
                player_id=auth_data.player_id,
                is_valid=is_valid,
                error_message=None if is_valid else "Mock verification failed"
            )
            
        except Exception as e:
            return GameCenterVerificationResponse(
                player_id=auth_data.player_id,
                is_valid=False,
                error_message=f"Verification error: {str(e)}"
            )
    
    @staticmethod
    async def _mock_verification(auth_data: GameCenterAuthRequest) -> bool:
        """
        ВРЕМЕННАЯ заглушка верификации для разработки.
        В продакшене заменить на реальную верификацию Apple.
        
        Args:
            auth_data: Данные аутентификации
            
        Returns:
            bool: True если данные валидны
        """
        # Проверяем базовые требования к данным
        if not auth_data.player_id or len(auth_data.player_id) < 5:
            return False
        
        if not auth_data.signature or len(auth_data.signature) < 10:
            return False
        
        if not auth_data.public_key_url or "apple.com" not in auth_data.public_key_url:
            return False
        
        # В разработке принимаем любой разумный timestamp
        if auth_data.timestamp <= 0:
            return False
        
        # В разработке считаем валидными все корректно сформированные запросы
        return True


class AuthService:
    """Сервис аутентификации и авторизации"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.user_repo = UserRepository(db)
        self.verification_service = GameCenterVerificationService()
        self.settings = get_settings()
    
    async def authenticate_game_center(
        self, 
        auth_data: GameCenterAuthRequest
    ) -> UserLoginResponse:
        """
        Аутентифицирует пользователя через Game Center.
        
        Args:
            auth_data: Данные аутентификации Game Center
            
        Returns:
            UserLoginResponse: Результат аутентификации
            
        Raises:
            AuthenticationError: Если аутентификация не удалась
        """
        # Верифицируем подпись Game Center
        verification_result = await self.verification_service.verify_signature(auth_data)
        
        if not verification_result.is_valid:
            raise AuthenticationError(
                f"Game Center verification failed: {verification_result.error_message}"
            )
        
        # Ищем пользователя по Game Center Player ID
        user = await self.user_repo.get_by_game_center_id(auth_data.player_id)
        
        is_new_user = user is None
        
        if is_new_user:
            # Создаем нового пользователя с минимальными данными
            # Полный профиль будет создан отдельным запросом
            user = await self._create_minimal_user(auth_data.player_id)
        
        # Генерируем JWT токен
        access_token = self._create_access_token(user.id)
        
        return UserLoginResponse(
            access_token=access_token,
            token_type="bearer",
            expires_in=self.settings.JWT_EXPIRATION_HOURS * 3600,
            user={
                "id": user.id,
                "game_center_player_id": user.game_center_player_id,
                "nickname": user.nickname,
                "rating": user.rating
            },
            is_new_user=is_new_user
        )
    
    async def complete_user_profile(
        self, 
        user_id: int, 
        profile_data: Dict[str, Any]
    ) -> UserResponse:
        """
        Завершает создание профиля пользователя.
        
        Args:
            user_id: ID пользователя
            profile_data: Данные профиля
            
        Returns:
            UserResponse: Обновленный пользователь
            
        Raises:
            UserNotFoundError: Если пользователь не найден
            ValidationError: Если данные некорректны
        """
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise UserNotFoundError(f"Пользователь с ID {user_id} не найден")
        
        # Проверяем уникальность никнейма
        if "nickname" in profile_data:
            existing_user = await self.user_repo.get_by_nickname(profile_data["nickname"])
            if existing_user and existing_user.id != user_id:
                raise ValidationError(f"Никнейм '{profile_data['nickname']}' уже занят")
        
        # Обновляем профиль
        for field, value in profile_data.items():
            if field == "gender" and isinstance(value, str):
                value = Gender(value)
            setattr(user, field, value)
        
        await self.db.commit()
        await self.db.refresh(user)
        
        return UserResponse.model_validate(user)
    
    def _create_access_token(self, user_id: int) -> str:
        """
        Создает JWT токен доступа.
        
        Args:
            user_id: ID пользователя
            
        Returns:
            str: JWT токен
        """
        payload = {
            "user_id": user_id,
            "exp": datetime.utcnow() + timedelta(hours=self.settings.JWT_EXPIRATION_HOURS),
            "iat": datetime.utcnow(),
            "type": "access"
        }
        
        return jwt.encode(
            payload, 
            self.settings.JWT_SECRET_KEY, 
            algorithm=self.settings.JWT_ALGORITHM
        )
    
    def verify_access_token(self, token: str) -> Dict[str, Any]:
        """
        Верифицирует JWT токен доступа.
        
        Args:
            token: JWT токен
            
        Returns:
            Dict[str, Any]: Payload токена
            
        Raises:
            AuthenticationError: Если токен невалиден
        """
        try:
            payload = jwt.decode(
                token, 
                self.settings.JWT_SECRET_KEY, 
                algorithms=[self.settings.JWT_ALGORITHM]
            )
            
            if payload.get("type") != "access":
                raise AuthenticationError("Неверный тип токена")
            
            return payload
            
        except jwt.ExpiredSignatureError:
            raise AuthenticationError("Токен истек")
        except jwt.InvalidTokenError:
            raise AuthenticationError("Невалидный токен")
    
    async def get_current_user(self, token: str) -> UserResponse:
        """
        Получает текущего пользователя по токену.
        
        Args:
            token: JWT токен
            
        Returns:
            UserResponse: Данные пользователя
            
        Raises:
            AuthenticationError: Если токен невалиден
            UserNotFoundError: Если пользователь не найден
        """
        payload = self.verify_access_token(token)
        user_id = payload.get("user_id")
        
        if not user_id:
            raise AuthenticationError("Токен не содержит ID пользователя")
        
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise UserNotFoundError(f"Пользователь с ID {user_id} не найден")
        
        return UserResponse.model_validate(user)
    
    async def _create_minimal_user(self, player_id: str) -> User:
        """
        Создает пользователя с минимальными данными.
        
        Args:
            player_id: Game Center Player ID
            
        Returns:
            User: Созданный пользователь
        """
        # Генерируем временный никнейм (заменяем недопустимые символы)
        safe_player_id = player_id.replace(":", "").replace("-", "")[-8:]
        temp_nickname = f"Player_{safe_player_id}"
        
        # Проверяем уникальность и корректируем при необходимости
        counter = 1
        base_nickname = temp_nickname
        while await self.user_repo.get_by_nickname(temp_nickname):
            temp_nickname = f"{base_nickname}_{counter}"
            counter += 1
        
        user_data = UserCreate(
            game_center_player_id=player_id,
            nickname=temp_nickname,
            birth_date="2000-01-01",  # Временная дата
            gender=Gender.OTHER  # Временное значение
        )
        
        return await self.user_repo.create(user_data)
    
    async def get_auth_status(self) -> Dict[str, Any]:
        """
        Получает статус системы аутентификации.
        
        Returns:
            Dict[str, Any]: Статус системы
        """
        return {
            "game_center_available": True,
            "jwt_enabled": True,
            "supported_platforms": ["ios"],
            "message": "Система аутентификации Game Center готова"
        } 