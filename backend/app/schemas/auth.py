"""
Pydantic схемы для аутентификации Game Center.
"""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


class GameCenterAuthRequest(BaseModel):
    """Схема запроса аутентификации Game Center"""
    player_id: str = Field(..., description="Game Center Player ID")
    public_key_url: str = Field(..., description="URL публичного ключа Apple")
    signature: str = Field(..., description="Подпись от Apple")
    salt: str = Field(..., description="Соль для верификации")
    timestamp: int = Field(..., description="Временная метка")


class GameCenterUserProfileRequest(BaseModel):
    """Схема для создания профиля пользователя после аутентификации Game Center"""
    player_id: str = Field(..., description="Game Center Player ID")
    nickname: str = Field(..., min_length=2, max_length=50, description="Никнейм пользователя")
    birth_date: str = Field(..., description="Дата рождения в формате YYYY-MM-DD")
    gender: str = Field(..., description="Пол пользователя (male/female/other)")


class TokenResponse(BaseModel):
    """Схема ответа с токеном"""
    access_token: str = Field(..., description="JWT токен доступа")
    token_type: str = Field(default="bearer", description="Тип токена")
    expires_in: int = Field(..., description="Время жизни токена в секундах")
    user_id: int = Field(..., description="ID пользователя")


class TokenRefreshRequest(BaseModel):
    """Схема запроса для обновления токена"""
    refresh_token: str = Field(..., description="Refresh токен")


class UserLoginResponse(BaseModel):
    """Схема ответа при успешном входе"""
    access_token: str
    token_type: str = "bearer"
    expires_in: int
    user: dict
    is_new_user: bool = Field(..., description="Новый ли это пользователь")


class AuthStatusResponse(BaseModel):
    """Схема статуса аутентификации"""
    game_center_available: bool = Field(..., description="Доступна ли аутентификация Game Center")
    jwt_enabled: bool = Field(..., description="Включена ли JWT аутентификация")
    supported_platforms: list[str] = Field(..., description="Поддерживаемые платформы")
    message: str = Field(..., description="Статусное сообщение")


class GameCenterVerificationResponse(BaseModel):
    """Схема ответа верификации Game Center"""
    player_id: str
    is_valid: bool
    error_message: Optional[str] = None
    verification_timestamp: datetime = Field(default_factory=datetime.utcnow)


class LogoutRequest(BaseModel):
    """Схема запроса выхода"""
    token: str = Field(..., description="JWT токен для инвалидации")


class LogoutResponse(BaseModel):
    """Схема ответа при выходе"""
    message: str = Field(default="Успешный выход из системы")
    logged_out_at: datetime = Field(default_factory=datetime.utcnow)


class ErrorResponse(BaseModel):
    """Схема ошибки аутентификации"""
    error: str = Field(..., description="Код ошибки")
    message: str = Field(..., description="Описание ошибки")
    details: Optional[str] = Field(None, description="Детали ошибки") 