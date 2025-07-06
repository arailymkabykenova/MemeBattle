"""
Роутер аутентификации.
Обрабатывает вход в систему по ID устройства.
"""

from fastapi import APIRouter, Depends, HTTPException, status, Body, Request
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Dict
import traceback
import logging
import sys

from ..core.database import get_db
from ..services.auth_service import AuthService
from ..schemas.user import DeviceAuthRequest, AuthResponse, UserResponse, UserProfileCreate
from ..utils.exceptions import AuthenticationError, UserNotFoundError, ValidationError
from ..core.logging import auth_logger
from ..core.dependencies import get_current_user

router = APIRouter(prefix="/auth", tags=["Authentication"])


@router.post(
    "/device",
    response_model=AuthResponse,
    summary="Аутентификация по ID устройства",
    description="""
    Принимает device_id. Если пользователь существует, возвращает токен.
    Если нет - создает нового пользователя.
    """
)
async def authenticate_device(
    request: DeviceAuthRequest,
    db: AsyncSession = Depends(get_db)
) -> AuthResponse:
    """
    Аутентифицирует пользователя по ID устройства.
    
    Args:
        request: Данные запроса с device_id
        db: Сессия базы данных
        
    Returns:
        AuthResponse: Результат аутентификации
    """
    try:
        auth_service = AuthService(db)
        return await auth_service.authenticate_device(request.device_id)
        
    except AuthenticationError as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e)
        )
    except Exception as e:
        auth_logger.error(
            "Authentication failed",
            extra={
            "error_type": type(e).__name__,
                "error_message": str(e),
            "device_id": request.device_id,
                "traceback": traceback.format_exc()
            }
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ошибка аутентификации: {e}"
        )


@router.post(
    "/complete-profile",
    response_model=UserResponse,
    summary="Заполнение профиля пользователя",
    description="""
    Заполняет профиль пользователя после первой аутентификации.
    Требуется: никнейм, дата рождения, пол.
    Профиль можно заполнить только один раз.
    """
)
async def complete_profile(
    profile_data: UserProfileCreate,
    current_user: UserResponse = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> UserResponse:
    """
    Заполняет профиль пользователя.
    
    Args:
        profile_data: Данные профиля
        current_user: Текущий пользователь
        db: Сессия базы данных
        
    Returns:
        UserResponse: Обновленный профиль пользователя
    """
    try:
        auth_service = AuthService(db)
        user = await auth_service.complete_user_profile(current_user.id, profile_data)
        return user
        
    except ValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        auth_logger.error(
            "Profile completion failed",
            extra={
                "error_type": type(e).__name__,
                "error_message": str(e),
                "user_id": current_user.id,
                "traceback": traceback.format_exc()
            }
        )
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ошибка заполнения профиля: {e}"
        )


@router.post(
    "/logout",
    status_code=status.HTTP_204_NO_CONTENT,
    summary="Выход из системы (пока заглушка)",
    description="""
    Выход пользователя из системы.
    В будущем здесь можно будет добавить токен в черный список (в Redis).
    """
)
async def logout(
    current_user: UserResponse = Depends(get_current_user)
) -> None:
    """
    Выход из системы.
    Пока что просто заглушка.
    
    Args:
        current_user: Текущий пользователь
    """
    # В будущем здесь можно добавить токен в черный список
    pass


@router.get(
    "/me",
    response_model=UserResponse,
    summary="Получить текущего пользователя",
    description="""
    Проверяет токен и возвращает данные текущего пользователя.
    """
)
async def get_me(
    current_user: UserResponse = Depends(get_current_user)
) -> UserResponse:
    """
    Получает текущего пользователя.
    
    Args:
        current_user: Текущий пользователь из зависимости
        
    Returns:
        UserResponse: Данные текущего пользователя
    """
    return current_user


# -------------------
# Закомментированный старый код
# -------------------

# @router.post("/login-game-center", response_model=UserLoginResponse) ...
# @router.post("/complete-profile", response_model=UserResponse) ...
# @router.get("/docs/ios-integration") ...
# @router.get("/verify-token") ...