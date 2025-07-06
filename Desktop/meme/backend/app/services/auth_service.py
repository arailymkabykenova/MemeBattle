"""
Сервис для аутентификации пользователей.
Содержит бизнес-логику для аутентификации и управления токенами.
"""

from typing import Optional, Tuple
from datetime import datetime, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from jose import JWTError, jwt

from ..repositories.user_repository import UserRepository
from ..services.user_service import UserService
from ..schemas.user import UserResponse, UserProfileCreate
from ..schemas.auth import AuthResponse
from ..core.config import settings
from ..utils.exceptions import AuthenticationError, UserNotFoundError, ValidationError


class AuthService:
    """Сервис для аутентификации пользователей"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.user_repo = UserRepository(db)
        self.user_service = UserService(db)
    
    async def authenticate_device(self, device_id: str) -> AuthResponse:
        """
        Аутентифицирует пользователя по Device ID.
        Если пользователь не существует, создает нового.
        
        Args:
            device_id: Device ID пользователя
            
        Returns:
            AuthResponse: Результат аутентификации с токеном
            
        Raises:
            AuthenticationError: Если произошла ошибка аутентификации
        """
        try:
            # Получаем или создаем пользователя
            user = await self.user_repo.get_or_create_by_device_id(device_id)
            
            # Создаем JWT токен
            access_token = self._create_access_token(user.id, device_id)
            
            # Определяем, новый ли это пользователь
            is_new_user = not user.is_profile_complete
            
            user_response = UserResponse.model_validate(user)
            return AuthResponse(
                access_token=access_token,
                token_type="bearer",
                user=user_response.model_dump(),
                is_new_user=is_new_user
            )
            
        except Exception as e:
            raise AuthenticationError(f"Ошибка аутентификации: {str(e)}")
    
    async def complete_user_profile(self, user_id: int, profile_data: UserProfileCreate) -> UserResponse:
        """
        Завершает создание профиля пользователя и выдает стартовые карты.
        
        Args:
            user_id: ID пользователя
            profile_data: Данные профиля
            
        Returns:
            UserResponse: Обновленный пользователь
            
        Raises:
            UserNotFoundError: Если пользователь не найден
            ValidationError: Если данные невалидны
        """
        # Проверяем уникальность никнейма
        existing_user = await self.user_repo.get_by_nickname(profile_data.nickname)
        if existing_user and existing_user.id != user_id:
            raise ValidationError(f"Никнейм '{profile_data.nickname}' уже занят")
        
        # Обновляем профиль
        user = await self.user_repo.complete_profile(user_id, profile_data)
        if not user:
            raise UserNotFoundError(f"Пользователь с ID {user_id} не найден")
        
        # Flush чтобы изменения были видны в рамках транзакции
        await self.db.flush()
        
        # 🎴 ВЫДАЕМ СТАРТОВЫЕ КАРТЫ после заполнения профиля
        try:
            await self.user_service.assign_starter_cards(user_id, count=10)
            print(f"✅ Пользователю {user_id} выдано 10 стартовых карт")
        except Exception as e:
            print(f"⚠️ Ошибка выдачи стартовых карт пользователю {user_id}: {e}")
            # Не прерываем процесс, если карты не выдались
        
        return UserResponse.model_validate(user)
    
    async def verify_token(self, token: str) -> Optional[UserResponse]:
        """
        Проверяет JWT токен и возвращает пользователя.
        
        Args:
            token: JWT токен
            
        Returns:
            Optional[UserResponse]: Пользователь или None
        """
        try:
            payload = jwt.decode(
                token, 
                settings.jwt_secret_key, 
                algorithms=[settings.jwt_algorithm]
            )
            user_id: int = int(payload.get("sub"))
            device_id: str = payload.get("device_id")
            
            if user_id is None or device_id is None:
                return None
            
            # Получаем пользователя
            user = await self.user_repo.get_by_id(user_id)
            if not user or user.device_id != device_id:
                return None
            
            return UserResponse.model_validate(user)
            
        except JWTError:
            return None
    
    def _create_access_token(self, user_id: int, device_id: str) -> str:
        """
        Создает JWT токен доступа.
        
        Args:
            user_id: ID пользователя
            device_id: Device ID пользователя
            
        Returns:
            str: JWT токен
        """
        expire = datetime.utcnow() + timedelta(hours=settings.jwt_expiration_hours)
        
        to_encode = {
            "sub": str(user_id),
            "device_id": device_id,
            "exp": expire,
            "type": "access"
        }
        
        return jwt.encode(
            to_encode, 
            settings.jwt_secret_key, 
            algorithm=settings.jwt_algorithm
        )
    
    async def get_current_user(self, token: str) -> UserResponse:
        """
        Получает текущего пользователя по токену.
        
        Args:
            token: JWT токен
            
        Returns:
            UserResponse: Текущий пользователь
            
        Raises:
            AuthenticationError: Если токен невалиден
        """
        user = await self.verify_token(token)
        if not user:
            raise AuthenticationError("Невалидный токен")
        
        return user
    
    async def logout_user(self, token: str) -> bool:
        """
        Выход пользователя из системы.
        В будущем здесь можно добавить токен в черный список.
        
        Args:
            token: JWT токен
            
        Returns:
            bool: True если выход успешен
        """
        # Пока что просто проверяем валидность токена
        user = await self.verify_token(token)
        return user is not None
