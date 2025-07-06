"""
Game Event Handler для WebSocket.
Обрабатывает игровые события и уведомления в реальном времени.
"""

from typing import Dict, Any, Optional
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
import logging

from .connection_manager import get_connection_manager
from ..services.game_service import GameService
from ..services.room_service import RoomService
from ..services.player_manager import PlayerManager
from ..models.game import GameStatus, RoomStatus
from ..utils.exceptions import AppException

logger = logging.getLogger(__name__)


class GameEventHandler:
    """Обработчик игровых событий для WebSocket"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.game_service = GameService(db)
        self.room_service = RoomService(db)
        self.player_manager = PlayerManager(db)
    
    async def handle_player_action(self, action_type: str, data: dict, user_id: int) -> dict:
        """
        Обрабатывает действие игрока и уведомляет других.
        
        Args:
            action_type: Тип действия
            data: Данные действия
            user_id: ID игрока
            
        Returns:
            dict: Результат обработки
        """
        try:
            if action_type == "ping":
                return await self._handle_ping(user_id, data)
            elif action_type == "join_room":
                return await self._handle_join_room(user_id, data)
            elif action_type == "leave_room":
                return await self._handle_leave_room(user_id, data)
            elif action_type == "start_game":
                return await self._handle_start_game(user_id, data)
            elif action_type == "start_round":
                return await self._handle_start_round(user_id, data)
            elif action_type == "submit_card_choice":
                return await self._handle_card_choice(user_id, data)
            elif action_type == "submit_vote":
                return await self._handle_vote(user_id, data)
            elif action_type == "get_game_state":
                return await self._handle_get_game_state(user_id, data)
            elif action_type == "get_round_cards":
                return await self._handle_get_round_cards(user_id, data)
            elif action_type == "get_choices_for_voting":
                return await self._handle_get_choices_for_voting(user_id, data)
            else:
                return {"success": False, "error": f"Unknown action: {action_type}"}
                
        except AppException as e:
            logger.error(f"Game action error: {e}")
            return {"success": False, "error": str(e)}
        except Exception as e:
            logger.error(f"Unexpected error in game action: {e}")
            return {"success": False, "error": "Internal server error"}
    
    async def _handle_ping(self, user_id: int, data: dict) -> dict:
        """Обрабатывает ping от игрока"""
        connection_manager = get_connection_manager()
        room_id = connection_manager.get_user_room(user_id)
        if room_id:
            await self.player_manager.update_player_activity(user_id, room_id)
        
        return {
            "success": True,
            "type": "pong",
            "timestamp": datetime.utcnow().isoformat(),
            "room_id": room_id
        }
    
    async def _handle_join_room(self, user_id: int, data: dict) -> dict:
        """Обрабатывает присоединение к комнате"""
        connection_manager = get_connection_manager()
        room_id = data.get("room_id")
        room_code = data.get("room_code")
        
        # Проверяем не в комнате ли уже пользователь в WebSocket состоянии
        current_websocket_room = connection_manager.get_user_room(user_id)
        if current_websocket_room and current_websocket_room == room_id:
            return {"success": False, "error": "Вы уже подключены к этой комнате через WebSocket"}
        
        try:
            if room_code:
                # 🔒 Присоединение по коду (для приватных комнат)
                room_details = await self.room_service.join_room_by_code(room_code, user_id)
                room_id = room_details.id
            elif room_id:
                # 🌐 Присоединение по ID (только для публичных комнат)
                room_details = await self.room_service.join_room(room_id, user_id)
            else:
                return {"success": False, "error": "room_id (для публичных комнат) или room_code (для приватных) обязателен"}
            
            # Обновляем WebSocket состояние только если не было синхронизировано
            if not current_websocket_room:
                await connection_manager.join_room(user_id, room_id)
            
            # Уведомляем о состоянии комнаты
            await self._broadcast_room_state(room_id)
            
            return {
                "success": True,
                "message": f"Присоединились к комнате {room_id}",
                "room": room_details.model_dump()
            }
            
        except Exception as e:
            logger.error(f"Error joining room: {e}")
            return {"success": False, "error": str(e)}
    
    async def _handle_leave_room(self, user_id: int, data: dict) -> dict:
        """Обрабатывает выход из комнаты"""
        room_id = connection_manager.get_user_room(user_id)
        if not room_id:
            return {"success": False, "error": "Not in any room"}
        
        try:
            # Покидаем комнату в базе данных
            result = await self.room_service.leave_room(room_id, user_id)
            
            # Обновляем WebSocket состояние
            await connection_manager.leave_room(user_id)
            
            # Уведомляем о состоянии комнаты если комната не отменена
            if not result.get("room_cancelled", False):
                await self._broadcast_room_state(room_id)
            
            return result
            
        except Exception as e:
            logger.error(f"Error leaving room: {e}")
            return {"success": False, "error": str(e)}
    
    async def _handle_start_game(self, user_id: int, data: dict) -> dict:
        """Обрабатывает начало игры"""
        room_id = connection_manager.get_user_room(user_id)
        if not room_id:
            return {"success": False, "error": "Not in any room"}
        
        try:
            # Начинаем игру
            result = await self.room_service.start_game(room_id, user_id)
            
            if result["success"]:
                game_id = result["game_id"]
                
                # Добавляем всех игроков в WebSocket игру
                room_users = connection_manager.get_room_users(room_id)
                for player_id in room_users:
                    await connection_manager.join_game(player_id, game_id)
                
                # Уведомляем о начале игры
                await connection_manager.broadcast_to_room({
                    "type": "game_started",
                    "game_id": game_id,
                    "room_id": room_id,
                    "timestamp": datetime.utcnow().isoformat(),
                    "message": "Игра началась! Ожидайте первый раунд..."
                }, room_id)
            
            return result
            
        except Exception as e:
            logger.error(f"Error starting game: {e}")
            return {"success": False, "error": str(e)}
    
    async def _handle_start_round(self, user_id: int, data: dict) -> dict:
        """Обрабатывает начало нового раунда"""
        room_id = connection_manager.get_user_room(user_id)
        if not room_id:
            return {"success": False, "error": "Not in any room"}
        
        # Получаем дополнительный текст ситуации если передан (для тестирования)
        situation_text = data.get("situation_text")  # Может быть None
        
        try:
            # Получаем активную игру
            game = await self.game_service.get_game_by_room(room_id)
            if not game:
                return {"success": False, "error": "No active game in room"}
            
            # Начинаем раунд (AI сгенерирует ситуацию если situation_text=None)
            round_result = await self.game_service.start_round(game.id, situation_text)
            
            # Уведомляем всех игроков о начале раунда
            await connection_manager.broadcast_to_game({
                "type": "round_started",
                "game_id": game.id,
                "round_id": round_result.id,
                "round_number": round_result.round_number,
                "situation_text": round_result.situation_text,
                "duration_seconds": round_result.duration_seconds,
                "timestamp": datetime.utcnow().isoformat(),
                "message": f"Раунд {round_result.round_number} начался! Выберите карту."
            }, game.id)
            
            return {
                "success": True,
                "round": {
                    "id": round_result.id,
                    "round_number": round_result.round_number,
                    "situation_text": round_result.situation_text,
                    "duration_seconds": round_result.duration_seconds,
                    "started_at": round_result.started_at.isoformat() if round_result.started_at else None
                }
            }
            
        except Exception as e:
            logger.error(f"Error starting round: {e}")
            return {"success": False, "error": str(e)}
    
    async def _handle_card_choice(self, user_id: int, data: dict) -> dict:
        """Обрабатывает выбор карты игроком"""
        round_id = data.get("round_id")
        if not round_id:
            return {"success": False, "error": "round_id required"}
        
        from ..schemas.game import PlayerChoiceCreate
        choice_data = PlayerChoiceCreate(
            card_type=data.get("card_type"),
            card_number=data.get("card_number")
        )
        
        # Выполняем выбор карты
        result = await self.game_service.submit_card_choice(round_id, user_id, choice_data)
        
        # Получаем игру и комнату
        game_round = await self.game_service._get_round_or_404(round_id)
        game = await self.game_service._get_game_or_404(game_round.game_id)
        
        # Уведомляем других игроков о выборе (без деталей карты)
        await connection_manager.broadcast_to_game({
            "type": "player_chose_card",
            "user_id": user_id,
            "round_id": round_id,
            "timestamp": datetime.utcnow().isoformat(),
            "message": f"Игрок выбрал карту"
        }, game.id, exclude_user=user_id)
        
        # Проверяем не началось ли голосование
        await self._check_and_notify_voting_start(game.id, round_id)
        
        return {
            "success": True,
            "choice": {
                "id": result.id,
                "card_type": result.card_type,
                "card_number": result.card_number,
                "submitted_at": result.submitted_at.isoformat()
            }
        }
    
    async def _handle_vote(self, user_id: int, data: dict) -> dict:
        """Обрабатывает голосование игрока"""
        round_id = data.get("round_id")
        choice_id = data.get("choice_id")
        
        if not round_id or not choice_id:
            return {"success": False, "error": "round_id and choice_id required"}
        
        from ..schemas.game import VoteCreate
        vote_data = VoteCreate(choice_id=choice_id)
        
        # Выполняем голосование
        result = await self.game_service.submit_vote(round_id, user_id, vote_data)
        
        # Получаем игру
        game_round = await self.game_service._get_round_or_404(round_id)
        game = await self.game_service._get_game_or_404(game_round.game_id)
        
        # Уведомляем других игроков о голосе
        await connection_manager.broadcast_to_game({
            "type": "player_voted",
            "user_id": user_id,
            "round_id": round_id,
            "timestamp": datetime.utcnow().isoformat(),
            "message": f"Игрок проголосовал"
        }, game.id, exclude_user=user_id)
        
        # Проверяем не завершилось ли голосование
        await self._check_and_notify_results(game.id, round_id)
        
        return {
            "success": True,
            "vote": {
                "id": result.id,
                "choice_id": result.choice_id,
                "created_at": result.created_at.isoformat()
            }
        }
    
    async def _handle_get_game_state(self, user_id: int, data: dict) -> dict:
        """Получает полное состояние игры"""
        connection_manager = get_connection_manager()
        room_id = connection_manager.get_user_room(user_id)
        if not room_id:
            return {"success": False, "error": "Not in any room"}
        
        # Получаем текущую игру
        game = await self.game_service.get_game_by_room(room_id)
        if not game:
            return {"success": False, "error": "No active game in room"}
        
        # TODO: Создать детальное состояние игры
        # Включая текущий раунд, выборы, голоса, etc.
        
        return {
            "success": True,
            "game_state": {
                "game_id": game.id,
                "room_id": room_id,
                "status": game.status,
                "current_round": game.current_round,
                # Добавить больше деталей когда понадобится
            }
        }
    
    async def _handle_get_round_cards(self, user_id: int, data: dict) -> dict:
        """Получает 3 случайные карты для раунда"""
        round_id = data.get("round_id")
        if not round_id:
            return {"success": False, "error": "round_id required"}
        
        try:
            # Получаем карты для раунда
            cards = await self.game_service.get_round_cards_for_user(round_id, user_id)
            
            return {
                "success": True,
                "round_id": round_id,
                "cards": [
                    {
                        "card_type": card["card_type"],
                        "card_number": card["card_number"],
                        "card_url": card["card_url"]
                    } for card in cards
                ]
            }
            
        except Exception as e:
            logger.error(f"Error getting round cards: {e}")
            return {"success": False, "error": str(e)}
    
    async def _handle_get_choices_for_voting(self, user_id: int, data: dict) -> dict:
        """Получает все выборы карт для голосования (кроме своего)"""
        round_id = data.get("round_id")
        if not round_id:
            return {"success": False, "error": "round_id required"}
        
        try:
            # Получаем выборы карт для голосования
            choices = await self.game_service.get_choices_for_voting(round_id, user_id)
            
            return {
                "success": True,
                "round_id": round_id,
                "choices": [
                    {
                        "id": choice.id,
                        "user_id": choice.user_id,
                        "user_nickname": choice.user_nickname,
                        "card_type": choice.card_type,
                        "card_number": choice.card_number,
                        "card_url": choice.card_url,
                        "vote_count": choice.vote_count
                    } for choice in choices
                ]
            }
            
        except Exception as e:
            logger.error(f"Error getting choices for voting: {e}")
            return {"success": False, "error": str(e)}
    
    async def _broadcast_room_state(self, room_id: int):
        """Отправляет состояние комнаты всем участникам"""
        try:
            room_details = await self.room_service.get_room_details(room_id)
            
            await connection_manager.broadcast_to_room({
                "type": "room_state_updated",
                "room": room_details.model_dump(),  # Конвертируем Pydantic модель в словарь
                "timestamp": datetime.utcnow().isoformat()
            }, room_id)
            
        except Exception as e:
            logger.error(f"Failed to broadcast room state: {e}")
    
    async def _check_and_notify_voting_start(self, game_id: int, round_id: int):
        """Проверяет и уведомляет о начале голосования"""
        try:
            game = await self.game_service._get_game_or_404(game_id)
            
            # Если игра перешла в режим голосования
            if game.status == GameStatus.VOTING:
                await connection_manager.broadcast_to_game({
                    "type": "voting_started",
                    "game_id": game_id,
                    "round_id": round_id,
                    "timestamp": datetime.utcnow().isoformat(),
                    "message": "Голосование началось!"
                }, game_id)
                
        except Exception as e:
            logger.error(f"Failed to check voting start: {e}")
    
    async def _check_and_notify_results(self, game_id: int, round_id: int):
        """Проверяет и уведомляет о результатах раунда"""
        try:
            game = await self.game_service._get_game_or_404(game_id)
            
            # Если игра перешла к показу результатов
            if game.status == GameStatus.ROUND_RESULTS:
                # Получаем результаты
                results = await self.game_service.calculate_round_results(round_id)
                
                await connection_manager.broadcast_to_game({
                    "type": "round_results",
                    "game_id": game_id,
                    "round_id": round_id,
                    "results": {
                        "winner": {
                            "user_id": results.winner_choice.user_id if results.winner_choice else None,
                            "nickname": results.winner_choice.user_nickname if results.winner_choice else None,
                            "card_type": results.winner_choice.card_type if results.winner_choice else None,
                            "card_number": results.winner_choice.card_number if results.winner_choice else None,
                            "vote_count": results.winner_choice.vote_count if results.winner_choice else 0
                        },
                        "next_round_starts_in": results.next_round_starts_in
                    },
                    "timestamp": datetime.utcnow().isoformat(),
                    "message": f"Раунд {results.round_number} завершен!"
                }, game_id)
                
        except Exception as e:
            logger.error(f"Failed to check round results: {e}")
    
    async def notify_timeout_warning(self, game_id: int, round_id: int, action_type: str, seconds_left: int):
        """Уведомляет о приближающемся таймауте"""
        await connection_manager.broadcast_to_game({
            "type": "timeout_warning",
            "game_id": game_id,
            "round_id": round_id,
            "action_type": action_type,
            "seconds_left": seconds_left,
            "timestamp": datetime.utcnow().isoformat(),
            "message": f"Осталось {seconds_left} секунд на {action_type}!"
        }, game_id)
    
    async def notify_player_timeout(self, game_id: int, user_id: int, action_type: str):
        """Уведомляет об исключении игрока за таймаут"""
        await connection_manager.broadcast_to_game({
            "type": "player_timeout",
            "game_id": game_id,
            "user_id": user_id,
            "action_type": action_type,
            "timestamp": datetime.utcnow().isoformat(),
            "message": f"Игрок исключен за неактивность"
        }, game_id)
    
    async def notify_game_ended(self, game_id: int, reason: str, winner_id: Optional[int] = None):
        """Уведомляет о завершении игры"""
        await connection_manager.broadcast_to_game({
            "type": "game_ended",
            "game_id": game_id,
            "reason": reason,
            "winner_id": winner_id,
            "timestamp": datetime.utcnow().isoformat(),
            "message": f"Игра завершена! {reason}"
        }, game_id) 