"""
WebSocket Routes.
Определяет WebSocket эндпоинты для игрового взаимодействия.
"""

import json
import logging
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession

from .connection_manager import get_connection_manager
from .game_handler import GameEventHandler
from ..core.database import get_db
from ..core.dependencies import get_user_from_token
from ..models.user import User

logger = logging.getLogger(__name__)

router = APIRouter()


@router.websocket("/ws")
async def websocket_endpoint(
    websocket: WebSocket,
    token: str = Query(..., description="JWT токен для аутентификации"),
    room_id: Optional[int] = Query(None, description="ID комнаты для автоматического присоединения")
):
    """
    WebSocket эндпоинт для игрового взаимодействия.
    
    Query параметры:
    - **token**: JWT токен для аутентификации
    - **room_id**: ID комнаты для автоматического присоединения (опционально)
    
    Поддерживаемые типы сообщений:
    - `ping`: Поддержание активности
    - `join_room`: Присоединение к комнате
    - `leave_room`: Выход из комнаты  
    - `start_game`: Начало игры
    - `submit_card_choice`: Выбор карты
    - `submit_vote`: Голосование
    - `get_game_state`: Получение состояния игры
    """
    # Аутентификация пользователя
    try:
        # Получаем сессию БД напрямую
        from ..core.database import async_session_maker
        async with async_session_maker() as db:
            user = await get_user_from_token(token, db)
            if not user:
                logger.error(f"Invalid token for WebSocket connection")
                await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Invalid token")
                return
            
            # Получаем ConnectionManager
            connection_manager = get_connection_manager()
            
            # Подключаем пользователя с синхронизацией состояния из БД
            logger.info(f"Connecting user {user.id} to WebSocket with db session")
            await connection_manager.connect(websocket, user, room_id, db)
            logger.info(f"User {user.id} connected to WebSocket")
            
            # Подписываемся на Redis события для комнаты, если пользователь в комнате
            if room_id:
                await connection_manager.subscribe_to_room_events(room_id)
            
            # Создаем обработчик игровых событий
            game_handler = GameEventHandler(db)
            
            try:
                while True:
                    # Ожидаем сообщение от клиента
                    data = await websocket.receive_text()
                    
                    try:
                        message = json.loads(data)
                        action_type = message.get("action")
                        action_data = message.get("data", {})
                        
                        if not action_type:
                            await websocket.send_text(json.dumps({
                                "success": False,
                                "error": "action field is required"
                            }))
                            continue
                        
                        # Обрабатываем действие
                        result = await game_handler.handle_player_action(action_type, action_data, user.id)
                        
                        # Отправляем результат обратно клиенту
                        await websocket.send_text(json.dumps(result, default=str))
                        
                    except json.JSONDecodeError:
                        await websocket.send_text(json.dumps({
                            "success": False,
                            "error": "Invalid JSON format"
                        }))
                    except Exception as e:
                        logger.error(f"Error handling WebSocket message: {e}")
                        await websocket.send_text(json.dumps({
                            "success": False,
                            "error": str(e)
                        }))
                        
            except WebSocketDisconnect:
                logger.info(f"WebSocket disconnected for user {user.id}")
            except Exception as e:
                logger.error(f"WebSocket error for user {user.id}: {e}")
            finally:
                # Отключаем пользователя
                connection_manager = get_connection_manager()
                await connection_manager.disconnect(user.id)
                
    except Exception as e:
        logger.error(f"Authentication failed: {e}")
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION, reason="Authentication failed")
        return


@router.get("/ws/stats")
async def get_websocket_stats():
    """
    Получает статистику WebSocket соединений.
    
    Возвращает информацию о:
    - Общем количестве подключений
    - Количестве активных комнат
    - Количестве активных игр
    - Распределении пользователей по комнатам/играм
    """
    connection_manager = get_connection_manager()
    return connection_manager.get_stats()


@router.post("/ws/broadcast/{room_id}")
async def broadcast_to_room(
    room_id: int,
    message: dict,
    db: AsyncSession = Depends(get_db)
):
    """
    Отправляет сообщение всем в комнате (для тестирования).
    
    - **room_id**: ID комнаты
    - **message**: Сообщение для отправки
    
    Только для разработки и тестирования.
    """
    message["timestamp"] = datetime.utcnow().isoformat()
    
    connection_manager = get_connection_manager()
    await connection_manager.broadcast_to_room(message, room_id)
    
    return {
        "success": True,
        "message": "Message broadcasted",
        "recipients": len(connection_manager.get_room_users(room_id))
    } 