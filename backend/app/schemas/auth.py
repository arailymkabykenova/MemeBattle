"""
Pydantic схемы для аутентификации Game Center.
"""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field


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


class AuthResponse(BaseModel):
    """Схема ответа аутентификации"""
    access_token: str = Field(..., description="JWT токен доступа")
    token_type: str = Field(default="bearer", description="Тип токена")
    user: dict = Field(..., description="Данные пользователя")
    is_new_user: bool = Field(..., description="Новый ли это пользователь")


class AuthStatusResponse(BaseModel):
    """Схема статуса аутентификации"""
    game_center_available: bool = Field(..., description="Доступна ли аутентификация Game Center")
    jwt_enabled: bool = Field(..., description="Включена ли JWT аутентификация")
    supported_platforms: list[str] = Field(..., description="Поддерживаемые платформы")
    message: str = Field(..., description="Статусное сообщение")


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