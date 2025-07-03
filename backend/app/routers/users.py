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


@router.post("/", response_model=UserResponse, status_code=201)
async def create_user(
    user_data: UserProfileCreate,
    current_user: UserResponse = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Заполняет профиль текущего пользователя.
    
    Args:
        user_data: Данные профиля пользователя
        current_user: Текущий аутентифицированный пользователь
        db: Сессия базы данных
        
    Returns:
        UserResponse: Обновленный пользователь
    """
    import traceback
    try:
        user_service = UserService(db)
        # Используем complete_profile вместо create_user_profile
        user = await user_service.complete_user_profile(current_user.id, user_data)
        return user
    except Exception as e:
        print("EXCEPTION:", e)
        traceback.print_exc()
        raise


# Специфичные роуты должны быть ВЫШЕ параметрических!

@router.get(
    "/me",
    response_model=UserResponse,
    summary="Получить текущего пользователя",
    description="Возвращает информацию о текущем авторизованном пользователе"
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


@router.get(
    "/me/cards",
    summary="Получить карты пользователя",
    description="Возвращает список карт текущего пользователя"
)
async def get_my_cards(
    current_user: UserResponse = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Получает карты текущего пользователя.
    
    Args:
        current_user: Текущий пользователь
        db: Сессия базы данных
        
    Returns:
        List: Список карт пользователя
    """
    try:
        user_service = UserService(db)
        cards = await user_service.get_user_cards(current_user.id)
        return {
            "user_id": current_user.id,
            "cards": cards,
            "total": len(cards)
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ошибка получения карт: {str(e)}"
        )


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
        Dict: Статистика пользователя
    """
    try:
        user_service = UserService(db)
        stats = await user_service.get_user_stats(current_user.id)
        return {
            "user_id": current_user.id,
            "stats": stats
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ошибка получения статистики: {str(e)}"
        )


@router.get("/cards-for-game", response_model=List[Dict[str, Any]])
async def get_cards_for_game(
    count: int = Query(default=3, ge=2, le=10, description="Количество карт для игрового раунда"),
    current_user: UserResponse = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Получает случайные карты пользователя для игрового раунда.
    
    🎯 Используется в игровой логике для выбора карт
    
    - **count**: количество карт (обычно 3)
    """
    user_service = UserService(db)
    try:
        return await user_service.get_user_cards_for_game(current_user.id, count)
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except UserNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка получения карт для игры: {str(e)}")


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


@router.get(
    "/me",
    response_model=UserResponse,
    summary="Получить текущего пользователя",
    description="Возвращает информацию о текущем авторизованном пользователе"
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


@router.get(
    "/me/cards",
    summary="Получить карты пользователя",
    description="Возвращает список карт текущего пользователя"
)
async def get_my_cards(
    current_user: UserResponse = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Получает карты текущего пользователя.
    
    Args:
        current_user: Текущий пользователь
        db: Сессия базы данных
        
    Returns:
        List: Список карт пользователя
    """
    try:
        user_service = UserService(db)
        cards = await user_service.get_user_cards(current_user.id)
        return {
            "user_id": current_user.id,
            "cards": cards,
            "total": len(cards)
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ошибка получения карт: {str(e)}"
        )


@router.get("/{user_id}", response_model=UserProfileResponse)
async def get_user_profile(
    user_id: int, 
    db: AsyncSession = Depends(get_db)
):
    """
    Получает профиль пользователя по ID.
    
    Args:
        user_id: ID пользователя
        db: Сессия базы данных
        
    Returns:
        UserProfileResponse: Профиль пользователя
    """
    try:
        user_service = UserService(db)
        user = await user_service.get_user_profile(user_id)
        return user
    except AppException as e:
        raise create_http_exception(e)


@router.put("/{user_id}", response_model=UserResponse)
async def update_user(
    user_id: int, 
    user_data: UserUpdate, 
    db: AsyncSession = Depends(get_db)
):
    """
    Обновляет профиль пользователя.
    
    Args:
        user_id: ID пользователя
        user_data: Новые данные пользователя
        db: Сессия базы данных
        
    Returns:
        UserResponse: Обновленный пользователь
    """
    try:
        user_service = UserService(db)
        user = await user_service.update_user_profile(user_id, user_data)
        return user
    except AppException as e:
        raise create_http_exception(e)


@router.get("/{user_id}/cards")
async def get_user_cards(
    user_id: int, 
    db: AsyncSession = Depends(get_db)
):
    """
    Получает все карты пользователя.
    
    Args:
        user_id: ID пользователя
        db: Сессия базы данных
        
    Returns:
        List[dict]: Список карт пользователя
    """
    try:
        user_service = UserService(db)
        cards = await user_service.get_user_cards(user_id)
        return {"cards": cards, "total": len(cards)}
    except AppException as e:
        raise create_http_exception(e)


@router.post("/assign-starter-cards", response_model=Dict[str, Any])
async def assign_starter_cards(
    count: int = Query(default=10, ge=5, le=20, description="Количество стартовых карт (5-20)"),
    current_user: UserResponse = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Выдает стартовые карты пользователю из Azure.
    
    🎯 Гибридный подход: изображения из Azure, связи в PostgreSQL
    
    - **count**: количество карт (5-20, по умолчанию 10)
    
    ⚠️ Карты можно получить только один раз!
    """
    user_service = UserService(db)
    try:
        return await user_service.assign_starter_cards(current_user.id, count)
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except UserNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка выдачи стартовых карт: {str(e)}")


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
        UserResponse: Пользователь с обновленным рейтингом
    """
    try:
        user_service = UserService(db)
        user = await user_service.update_user_rating(user_id, rating_change)
        return user
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
        return {"user_id": user_id, "rank": rank}
    except AppException as e:
        raise create_http_exception(e)

 