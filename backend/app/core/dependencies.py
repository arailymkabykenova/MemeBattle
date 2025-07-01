"""
Зависимости для FastAPI.
Содержит функции для инъекции зависимостей в endpoints.
"""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Optional

from .database import get_db
from .redis import get_redis_client, RedisClient
from ..services.auth_service import AuthService
from ..services.game_service import GameService
from ..schemas.user import UserResponse
from ..utils.exceptions import AuthenticationError, UserNotFoundError

# Настройка HTTP Bearer для JWT токенов
security = HTTPBearer()


async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security),
    db: AsyncSession = Depends(get_db)
) -> UserResponse:
    """
    Получает текущего аутентифицированного пользователя по JWT токену.
    
    Args:
        credentials: JWT токен из Authorization header
        db: Сессия базы данных
        
    Returns:
        UserResponse: Данные текущего пользователя
        
    Raises:
        HTTPException: Если токен невалиден или пользователь не найден
    """
    try:
        auth_service = AuthService(db)
        user = await auth_service.get_current_user(credentials.credentials)
        return user
        
    except (AuthenticationError, UserNotFoundError) as e:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail=str(e),
            headers={"WWW-Authenticate": "Bearer"},
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ошибка аутентификации: {e}"
        )


async def get_current_active_user(
    current_user: UserResponse = Depends(get_current_user)
) -> UserResponse:
    """
    Получает текущего активного пользователя.
    
    В будущем здесь можно добавить проверки:
    - Заблокирован ли пользователь
    - Завершен ли профиль
    - Есть ли необходимые права
    
    Args:
        current_user: Текущий пользователь из get_current_user
        
    Returns:
        UserResponse: Данные активного пользователя
        
    Raises:
        HTTPException: Если пользователь неактивен
    """
    # Пока что просто возвращаем пользователя
    # В будущем можно добавить дополнительные проверки
    return current_user


async def get_optional_current_user(
    db: AsyncSession = Depends(get_db),
    credentials: Optional[HTTPAuthorizationCredentials] = Depends(security)
) -> Optional[UserResponse]:
    """
    Получает текущего пользователя, если токен предоставлен.
    Не выбрасывает исключение, если токен отсутствует.
    
    Используется для endpoints, где аутентификация опциональна.
    
    Args:
        db: Сессия базы данных
        credentials: Опциональный JWT токен
        
    Returns:
        Optional[UserResponse]: Данные пользователя или None
    """
    if not credentials:
        return None
    
    try:
        auth_service = AuthService(db)
        user = await auth_service.get_current_user(credentials.credentials)
        return user
        
    except (AuthenticationError, UserNotFoundError):
        return None
    except Exception:
        return None


async def get_user_from_token(token: str, db: AsyncSession) -> Optional[UserResponse]:
    """
    Получает пользователя по JWT токену (для WebSocket).
    
    Args:
        token: JWT токен
        db: Сессия базы данных
        
    Returns:
        Optional[UserResponse]: Данные пользователя или None
        
    Raises:
        AuthenticationError: Если токен невалиден
        UserNotFoundError: Если пользователь не найден
    """
    auth_service = AuthService(db)
    user = await auth_service.get_current_user(token)
    return user


async def get_game_service(
    db: AsyncSession = Depends(get_db),
    redis_client: RedisClient = Depends(get_redis_client)
) -> GameService:
    """
    Получает экземпляр GameService с Redis клиентом.
    
    Args:
        db: Сессия базы данных
        redis_client: Redis клиент
        
    Returns:
        GameService: Экземпляр игрового сервиса
    """
    return GameService(db, redis_client) 