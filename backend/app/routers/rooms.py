"""
API роутер для управления игровыми комнатами.
"""

from typing import List, Dict, Any, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_

from ..core.database import get_db
from ..core.dependencies import get_current_user
from ..models.user import User
from ..schemas.game import (
    RoomCreate, RoomResponse, RoomDetailResponse, RoomJoinByCode,
    QuickMatchRequest, QuickMatchResponse
)
from ..services.room_service import RoomService
from ..utils.exceptions import AppException, create_http_exception

router = APIRouter(prefix="/rooms", tags=["rooms"])


@router.post("/", response_model=RoomResponse, status_code=status.HTTP_201_CREATED)
async def create_room(
    room_data: RoomCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Создает новую игровую комнату.
    
    - **max_players**: Максимум игроков (3-8)
    - **is_public**: Публичная комната (видна в списке доступных)
    - **generate_code**: Генерировать код для приглашений
    
    Для приватных комнат автоматически генерируется код.
    """
    try:
        room_service = RoomService(db)
        return await room_service.create_room(current_user.id, room_data)
    except AppException as e:
        raise create_http_exception(e)


@router.get("/available", response_model=List[RoomResponse])
async def get_available_rooms(
    limit: int = 20,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Получает список доступных публичных комнат для присоединения.
    
    - **limit**: Максимальное количество комнат (по умолчанию 20)
    
    Показывает только публичные комнаты со свободными местами.
    """
    try:
        room_service = RoomService(db)
        return await room_service.get_available_rooms(limit)
    except AppException as e:
        raise create_http_exception(e)


@router.get("/my-room", response_model=Optional[RoomDetailResponse])
async def get_my_current_room(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Получает текущую активную комнату пользователя.
    
    Возвращает None если пользователь не в комнате.
    """
    try:
        room_service = RoomService(db)
        return await room_service.get_user_current_room(current_user.id)
    except AppException as e:
        raise create_http_exception(e)


@router.get("/{room_id}", response_model=RoomDetailResponse)
async def get_room_details(
    room_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Получает детальную информацию о комнате.
    
    - **room_id**: ID комнаты
    
    🔒 Для приватных комнат доступ только участникам.
    """
    try:
        room_service = RoomService(db)
        return await room_service.get_room_details(room_id, current_user.id)
    except AppException as e:
        raise create_http_exception(e)


@router.post("/{room_id}/join", response_model=RoomDetailResponse)
async def join_room(
    room_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Присоединяется к игровой комнате по ID.
    
    - **room_id**: ID комнаты для присоединения
    """
    try:
        room_service = RoomService(db)
        return await room_service.join_room(room_id, current_user.id)
    except AppException as e:
        raise create_http_exception(e)


@router.post("/join-by-code", response_model=RoomDetailResponse)
async def join_room_by_code(
    join_data: RoomJoinByCode,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Присоединяется к игровой комнате по 6-значному коду.
    
    - **room_code**: 6-значный код комнаты (например: ABC123)
    
    Позволяет присоединиться к любой комнате (публичной или приватной)
    если у вас есть код.
    """
    try:
        room_service = RoomService(db)
        return await room_service.join_room_by_code(join_data.room_code, current_user.id)
    except AppException as e:
        raise create_http_exception(e)


@router.post("/quick-match", response_model=QuickMatchResponse)
async def quick_match(
    request: QuickMatchRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Быстрый поиск игры (matchmaking).
    
    - **preferred_players**: Предпочитаемое количество игроков (3-8)
    - **max_wait_time**: Максимальное время ожидания в секундах (10-120)
    
    Система найдет подходящую комнату или создаст новую.
    Присоединяет только к публичным комнатам.
    """
    try:
        room_service = RoomService(db)
        return await room_service.quick_match(current_user.id, request)
    except AppException as e:
        raise create_http_exception(e)


@router.post("/{room_id}/leave")
async def leave_room(
    room_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    Покидает игровую комнату.
    
    - **room_id**: ID комнаты для выхода
    
    Если создатель покидает комнату в ожидании, комната отменяется.
    """
    try:
        room_service = RoomService(db)
        return await room_service.leave_room(room_id, current_user.id)
    except AppException as e:
        raise create_http_exception(e)


@router.post("/{room_id}/start-game")
async def start_game(
    room_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    Начинает игру в комнате.
    
    Только создатель комнаты может начать игру.
            Требуется минимум 2 игрока.
    
    - **room_id**: ID комнаты
    """
    try:
        room_service = RoomService(db)
        return await room_service.start_game(room_id, current_user.id)
    except AppException as e:
        raise create_http_exception(e)


# === Статистика и мониторинг ===

@router.get("/stats/summary")
async def get_rooms_stats(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    Получает статистику по комнатам.
    """
    try:
        # Простая статистика - можно расширить
        from sqlalchemy import select, func
        from ..models.game import Room, RoomStatus
        
        # Количество активных комнат (публичных и приватных)
        active_rooms_result = await db.execute(
            select(func.count(Room.id))
            .where(Room.status == RoomStatus.WAITING)
        )
        active_rooms = active_rooms_result.scalar() or 0
        
        # Количество играющих комнат
        playing_rooms_result = await db.execute(
            select(func.count(Room.id))
            .where(Room.status == RoomStatus.PLAYING)
        )
        playing_rooms = playing_rooms_result.scalar() or 0
        
        # Количество публичных комнат
        public_rooms_result = await db.execute(
            select(func.count(Room.id))
            .where(
                and_(
                    Room.status == RoomStatus.WAITING,
                    Room.is_public == True
                )
            )
        )
        public_rooms = public_rooms_result.scalar() or 0
        
        return {
            "active_rooms": active_rooms,
            "playing_rooms": playing_rooms,
            "public_rooms": public_rooms,
            "private_rooms": active_rooms - public_rooms,
            "total_rooms": active_rooms + playing_rooms
        }
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ошибка получения статистики: {str(e)}"
        ) 