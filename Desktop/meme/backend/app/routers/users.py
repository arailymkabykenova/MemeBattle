"""
Роутер пользователей.
Обрабатывает операции с пользователями.
"""

from typing import List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.database import get_db
from ..services.user_service import UserService
from ..schemas.user import UserCreate, UserUpdate, UserResponse, UserProfileResponse, UserProfileCreate
from ..utils.exceptions import AppException, create_http_exception
from ..core.dependencies import get_current_user
from ..utils.exceptions import ValidationError, UserNotFoundError

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/", response_model=List[dict])
async def get_leaderboard(
    limit: int = 100, 
    db: AsyncSession = Depends(get_db)
):
    """
    Получает топ пользователей по рейтингу.
    
    Args:
        limit: Лимит пользователей
        db: Сессия базы данных
        
    Returns:
        List[dict]: Список пользователей с рейтингом
    """
    try:
        user_service = UserService(db)
        leaderboard = await user_service.get_leaderboard(limit)
        return leaderboard
    except AppException as e:
        raise create_http_exception(e)


@router.get("/check-nickname/{nickname}")
async def check_nickname_availability(
    nickname: str, 
    db: AsyncSession = Depends(get_db)
):
    """
    Проверяет доступность никнейма.
    
    Args:
        nickname: Никнейм для проверки
        db: Сессия базы данных
        
    Returns:
        dict: Результат проверки
    """
    try:
        user_service = UserService(db)
        is_available = await user_service.check_nickname_availability(nickname)
        return {
            "nickname": nickname,
            "available": is_available,
            "message": "Никнейм доступен" if is_available else "Никнейм уже занят"
        }
    except AppException as e:
        raise create_http_exception(e)


@router.get("/me/stats", summary="Получить статистику пользователя", description="Возвращает игровую статистику текущего пользователя")
async def get_my_stats(
    current_user: UserResponse = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Получает статистику текущего пользователя.
    
    Args:
        current_user: Текущий пользователь
        db: Сессия базы данных
        
    Returns:
        dict: Статистика пользователя
    """
    try:
        user_service = UserService(db)
        stats = await user_service.get_user_stats(current_user.id)
        return stats
    except AppException as e:
        raise create_http_exception(e)





@router.get(
    "/{user_id}",
    response_model=UserResponse,
    summary="Получить пользователя по ID",
    description="Возвращает информацию о пользователе по его ID"
)
async def get_user(
    user_id: int,
    db: AsyncSession = Depends(get_db)
) -> UserResponse:
    """
    Получает пользователя по ID.
    
    Args:
        user_id: ID пользователя
        db: Сессия базы данных
        
    Returns:
        UserResponse: Данные пользователя
    """
    try:
        user_service = UserService(db)
        user = await user_service.get_user_by_id(user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Пользователь с ID {user_id} не найден"
            )
        return UserResponse.from_orm_with_age(user)
        
    except UserNotFoundError as e:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ошибка получения пользователя: {str(e)}"
        )


@router.put(
    "/me",
    response_model=UserResponse,
    summary="Обновить профиль пользователя",
    description="Обновляет профиль текущего пользователя"
)
async def update_profile(
    profile_data: UserUpdate,
    current_user: UserResponse = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> UserResponse:
    """
    Обновляет профиль пользователя.
    
    Args:
        profile_data: Данные для обновления
        current_user: Текущий пользователь
        db: Сессия базы данных
        
    Returns:
        UserResponse: Обновленные данные пользователя
    """
    try:
        user_service = UserService(db)
        user = await user_service.update_user_profile(current_user.id, profile_data)
        return UserResponse.from_orm_with_age(user)
        
    except ValidationError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ошибка обновления профиля: {str(e)}"
        )











@router.put("/{user_id}/rating")
async def update_user_rating(
    user_id: int, 
    rating_change: int,
    db: AsyncSession = Depends(get_db)
):
    """
    Обновляет рейтинг пользователя.
    
    Args:
        user_id: ID пользователя
        rating_change: Изменение рейтинга
        db: Сессия базы данных
        
    Returns:
        dict: Обновленный рейтинг
    """
    try:
        user_service = UserService(db)
        result = await user_service.update_user_rating(user_id, rating_change)
        return result
    except AppException as e:
        raise create_http_exception(e)


@router.get("/{user_id}/rank")
async def get_user_rank(
    user_id: int, 
    db: AsyncSession = Depends(get_db)
):
    """
    Получает позицию пользователя в рейтинге.
    
    Args:
        user_id: ID пользователя
        db: Сессия базы данных
        
    Returns:
        dict: Позиция в рейтинге
    """
    try:
        user_service = UserService(db)
        rank = await user_service.get_user_rank(user_id)
        return {
            "user_id": user_id,
            "rank": rank
        }
    except AppException as e:
        raise create_http_exception(e)

 