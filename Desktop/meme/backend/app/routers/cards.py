"""
API endpoints для работы с карточками.
"""

import traceback
from typing import List, Dict, Any, Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.database import get_db
from ..core.dependencies import get_current_user
from ..services.card_service import CardService
from ..services.user_service import UserService
from ..schemas.card import CardResponse, CardListResponse, CardCreate
from ..schemas.user import UserResponse, UserCreate
from ..models.card import CardType
from ..utils.exceptions import ValidationError, UserNotFoundError
from ..external.azure_client import azure_service

router = APIRouter(prefix="/cards", tags=["cards"])


# @router.get("/", response_model=CardListResponse)
# async def get_all_cards(
#     limit: int = Query(default=50, ge=1, le=100, description="Количество карт на страницу"),
#     offset: int = Query(default=0, ge=0, description="Смещение для пагинации"),
#     db: AsyncSession = Depends(get_db)
# ):
#     """
#     Получает список всех карт с пагинацией.
    
#     - **limit**: максимальное количество карт (1-100)
#     - **offset**: смещение для пагинации
#     """
#     card_service = CardService(db)
#     try:
#         return await card_service.get_all_cards(limit=limit, offset=offset)
#     except Exception as e:
#         raise HTTPException(status_code=500, detail=f"Ошибка получения карт: {str(e)}")

@router.get("/", response_model=CardListResponse)
async def get_all_cards(
    limit: int = Query(default=50, ge=1, le=100, description="Количество карт на страницу"),
    offset: int = Query(default=0, ge=0, description="Смещение для пагинации"),
    db: AsyncSession = Depends(get_db)
):
    """
    Получает список всех карт с пагинацией.
    
    - **limit**: максимальное количество карт (1-100)
    - **offset**: смещение для пагинации
    """
    card_service = CardService(db)
    try:
        return await card_service.get_all_cards(limit=limit, offset=offset)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка получения карт: {str(e)}")
    
@router.get("/by-type/{card_type}", response_model=List[CardResponse])
async def get_cards_by_type(
    card_type: CardType,
    limit: int = Query(default=50, ge=1, le=100, description="Максимальное количество карт"),
    db: AsyncSession = Depends(get_db)
):
    """
    Получает карты определенного типа.
    
    - **card_type**: тип карт (starter, standard, unique)
    - **limit**: максимальное количество карт
    """
    card_service = CardService(db)
    try:
        return await card_service.get_cards_by_type(card_type, limit=limit)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка получения карт типа {card_type}: {str(e)}")


@router.post("/assign-starter-cards", response_model=Dict[str, Any])
async def assign_starter_cards(
    count: int = Query(default=10, ge=5, le=20, description="Количество стартовых карт"),
    current_user: UserResponse = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Выдает стартовые карты пользователю.
    
    - **count**: количество карт для выдачи (5-20)
    
    ⚠️ Карты можно получить только один раз!
    """
    card_service = CardService(db)
    try:
        return await card_service.assign_starter_cards_to_user(current_user.id, count)
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except UserNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка выдачи стартовых карт: {str(e)}")


@router.get("/my-cards", response_model=Dict[str, Any])
async def get_my_cards(
    current_user: UserResponse = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Получает все карты текущего пользователя с группировкой по типам.
    """
    card_service = CardService(db)
    try:
        return await card_service.get_user_cards(current_user.id)
    except UserNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка получения карт пользователя: {str(e)}")


@router.get("/azure/status", response_model=Dict[str, Any])
async def get_azure_status(
    db: AsyncSession = Depends(get_db)
):
    """
    Проверяет статус подключения к Azure Blob Storage.
    
    Показывает статистику по загруженным картам в Azure.
    """
    try:
        if not azure_service.is_connected():
            return {
                "connected": False,
                "error": "Azure Blob Storage не подключен. Проверьте AZURE_STORAGE_CONNECTION_STRING в .env"
            }
        
        stats = await azure_service.get_storage_statistics()
        return stats
        
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка проверки Azure: {str(e)}")





@router.post("/azure/load/{card_type}", response_model=Dict[str, Any])
async def load_cards_from_azure(
    card_type: CardType,
    limit: Optional[int] = Query(default=None, description="Максимальное количество карт для загрузки"),
    current_user: UserResponse = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Загружает карты определенного типа из Azure Blob Storage в базу данных.
    
    - **card_type**: Тип карт (starter, standard, unique)
    - **limit**: Максимальное количество карт для загрузки
    
    ⚠️ Требует админских прав (пока что проверка отключена)
    """
    # TODO: Добавить проверку админских прав
    card_service = CardService(db)
    try:
        return await card_service.load_cards_from_azure(card_type, limit)
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка загрузки карт из Azure: {str(e)}")


@router.post("/azure/load-all", response_model=Dict[str, Any])
async def load_all_cards_from_azure(
    current_user: UserResponse = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Загружает все карты из Azure Blob Storage (starter, standard, unique).
    
    Сканирует все папки и загружает найденные карты в базу данных.
    
    ⚠️ Требует админских прав (пока что проверка отключена)
    """
    # TODO: Добавить проверку админских прав
    card_service = CardService(db)
    try:
        return await card_service.load_all_cards_from_azure()
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка загрузки всех карт из Azure: {str(e)}")





@router.get("/for-game-round", response_model=List[CardResponse])
async def get_cards_for_game_round(
    round_count: int = Query(default=3, ge=2, le=10, description="Количество карт для раунда"),
    current_user: UserResponse = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Получает случайные карты пользователя для игрового раунда.
    
    - **round_count**: количество карт для раунда (обычно 3)
    """
    card_service = CardService(db)
    try:
        return await card_service.get_cards_for_game_round(current_user.id, round_count)
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except UserNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка получения карт для игры: {str(e)}")


@router.get("/statistics", response_model=Dict[str, Any])
async def get_card_statistics(
    db: AsyncSession = Depends(get_db)
):
    """
    Получает общую статистику по картам в системе.
    
    Показывает количество карт по типам и готовность системы.
    """
    card_service = CardService(db)
    try:
        return await card_service.get_card_statistics()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка получения статистики: {str(e)}")


@router.post("/admin/create-batch", response_model=List[CardResponse])
async def create_cards_batch(
    cards_data: List[Dict[str, Any]],
    current_user: UserResponse = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Создает пакет карт (только для администраторов).
    
    **Формат данных для карт:**
    ```json
    [
        {
            "name": "Название карты",
            "description": "Описание карты",
            "image_url": "https://example.com/image.jpg", // опционально
            "azure_blob_path": "cards/starter/card1.jpg" // опционально
        }
    ]
    ```
    
    ⚠️ Пока что все карты создаются как STARTER тип.
    """
    # TODO: Добавить проверку роли администратора
    card_service = CardService(db)
    try:
        return await card_service.create_starter_cards_batch(cards_data)
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка создания карт: {str(e)}")


@router.post("/award-winner-card", response_model=CardResponse)
async def award_winner_card(
    user_id: int,
    card_type: CardType = CardType.STANDARD,
    current_user: UserResponse = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Выдает карту победителю игры (только для игровой системы).
    
    - **user_id**: ID пользователя-победителя
    - **card_type**: тип карты для выдачи (по умолчанию standard)
    
    ⚠️ В будущем этот endpoint будет вызываться только игровой системой
    """
    # TODO: Добавить проверку что запрос идет от игровой системы
    card_service = CardService(db)
    try:
        return await card_service.award_card_to_winner(user_id, card_type)
    except ValidationError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except UserNotFoundError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ошибка выдачи карты победителю: {str(e)}")


 