"""
API роутер для игровой логики.
"""

from typing import List, Dict, Any, Optional
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from ..core.database import get_db
from ..core.dependencies import get_current_user
from ..models.user import User
from ..schemas.game import (
    GameResponse, GameRoundResponse, PlayerChoiceCreate, PlayerChoiceResponse,
    VoteCreate, VoteResponse, RoundResultResponse, GameStateResponse,
    SituationGenerateRequest, SituationResponse
)
from ..services.game_service import GameService
from ..services.room_service import RoomService
from ..utils.exceptions import AppException, create_http_exception

router = APIRouter(prefix="/games", tags=["games"])


# === СПЕЦИФИЧНЫЕ МАРШРУТЫ (ДОЛЖНЫ БЫТЬ ВЫШЕ ПАРАМЕТРИЗОВАННЫХ) ===

@router.get("/my-cards-for-game")
async def get_my_cards_for_game(
    count: int = 3,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> List[Dict[str, Any]]:
    """
    Получает случайные карты текущего пользователя для игры.
    
    - **count**: Количество карт (по умолчанию 3)
    
    Возвращает случайные карты из коллекции игрока.
    """
    try:
        game_service = GameService(db)
        return await game_service.card_service.get_user_cards_for_game(current_user.id, count)
    except AppException as e:
        raise create_http_exception(e)


@router.post("/situations/generate", response_model=SituationResponse)
async def generate_situation(
    request: SituationGenerateRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Генерирует ситуационную карточку для раунда.
    
    - **topic**: Тема ситуации (опционально)
    - **difficulty**: Сложность (easy/medium/hard)
    - **age_group**: Возрастная группа игроков
    
    В будущем будет использовать OpenAI API.
    Пока возвращает тестовые ситуации.
    """
    try:
        # TODO: Интеграция с AI Service для OpenAI генерации
        # Пока возвращаем тестовые ситуации
        
        test_situations = [
            "Вы застряли в лифте с коллегой, которого не переносите. Что делаете?",
            "Вы случайно отправили сообщение не тому человеку. В сообщении критика вашего босса. Ваши действия?",
            "На собеседовании вас спросили о навыке, которого у вас нет, но он указан в резюме. Как реагируете?",
            "Вы заметили, что ваш друг изменяет своему партнеру. Что делаете?",
            "В ресторане вам принесли счет с чужим заказом (намного дороже). Официант не замечает ошибку. Ваши действия?",
            "Вы случайно подслушали разговор о том, что планируют уволить вашего коллеги. Что делаете?",
            "Ваш сосед постоянно слушает громкую музыку по ночам. Как решаете проблему?",
            "На первом свидании вы поняли, что вам скучно. Но человек явно заинтересован. Как поступите?",
            "Вы нашли кошелек с большой суммой денег и документами. Что делаете?",
            "В самолете рядом сидит человек, который не прекращает говорить. Ваша реакция?"
        ]
        
        import random
        
        situation_text = random.choice(test_situations)
        
        return SituationResponse(
            situation_text=situation_text,
            topic=request.topic,
            estimated_difficulty="medium",
            generated_at=datetime.utcnow()
        )
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ошибка генерации ситуации: {str(e)}"
        )


@router.get("/rooms/{room_id}/current-game", response_model=Optional[GameResponse])
async def get_current_game_in_room(
    room_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Получает текущую активную игру в комнате.
    
    - **room_id**: ID комнаты
    """
    try:
        game_service = GameService(db)
        game = await game_service.get_game_by_room(room_id)
        
        if not game:
            return None
            
        return GameResponse(
            id=game.id,
            room_id=game.room_id,
            status=game.status,
            current_round=game.current_round,
            winner_id=game.winner_id,
            created_at=game.created_at,
            finished_at=game.finished_at
        )
    except AppException as e:
        raise create_http_exception(e)


# === ПАРАМЕТРИЗОВАННЫЕ МАРШРУТЫ ===

@router.get("/{game_id}", response_model=GameResponse)
async def get_game(
    game_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Получает информацию об игре.
    
    - **game_id**: ID игры
    """
    try:
        game_service = GameService(db)
        game = await game_service._get_game_or_404(game_id)
        
        return GameResponse(
            id=game.id,
            room_id=game.room_id,
            status=game.status,
            current_round=game.current_round,
            winner_id=game.winner_id,
            created_at=game.created_at,
            finished_at=game.finished_at
        )
    except AppException as e:
        raise create_http_exception(e)


@router.post("/{game_id}/rounds", response_model=GameRoundResponse)
async def start_round(
    game_id: int,
    situation_text: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Начинает новый раунд игры.
    
    - **game_id**: ID игры
    - **situation_text**: Текст ситуационной карточки
    
    Только участники игры могут начинать раунды.
    """
    try:
        game_service = GameService(db)
        return await game_service.start_round(game_id, situation_text)
    except AppException as e:
        raise create_http_exception(e)


@router.post("/rounds/{round_id}/choices", response_model=PlayerChoiceResponse)
async def submit_card_choice(
    round_id: int,
    choice_data: PlayerChoiceCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Игрок выбирает карту для раунда.
    
    - **round_id**: ID раунда
    - **card_type**: Тип карты (starter/standard/unique)
    - **card_number**: Номер карты в Azure папке
    
    Игрок должен владеть выбранной картой.
    """
    try:
        game_service = GameService(db)
        return await game_service.submit_card_choice(round_id, current_user.id, choice_data)
    except AppException as e:
        raise create_http_exception(e)


@router.post("/rounds/{round_id}/voting/start")
async def start_voting(
    round_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    Начинает фазу голосования (обычно автоматически).
    
    - **round_id**: ID раунда
    
    Голосование начинается когда все игроки выбрали карты.
    """
    try:
        game_service = GameService(db)
        return await game_service.start_voting(round_id)
    except AppException as e:
        raise create_http_exception(e)


@router.post("/rounds/{round_id}/votes", response_model=VoteResponse)
async def submit_vote(
    round_id: int,
    vote_data: VoteCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Игрок голосует за карту.
    
    - **round_id**: ID раунда
    - **choice_id**: ID выбора карты за который голосуем
    
    Нельзя голосовать за свою карту.
    """
    try:
        game_service = GameService(db)
        return await game_service.submit_vote(round_id, current_user.id, vote_data)
    except AppException as e:
        raise create_http_exception(e)


@router.get("/rounds/{round_id}/results", response_model=RoundResultResponse)
async def get_round_results(
    round_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Получает результаты раунда.
    
    - **round_id**: ID раунда
    
    Показывает все выборы, голоса и победителя раунда.
    """
    try:
        game_service = GameService(db)
        return await game_service.calculate_round_results(round_id)
    except AppException as e:
        raise create_http_exception(e)


@router.get("/rounds/{round_id}/choices")
async def get_round_choices_for_voting(
    round_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> List[PlayerChoiceResponse]:
    """
    Получает все выборы карт в раунде для голосования.
    
    - **round_id**: ID раунда
    
    Возвращает все выборы карт кроме выбора текущего пользователя.
    Используется для отображения карт, за которые можно голосовать.
    """
    try:
        game_service = GameService(db)
        return await game_service.get_choices_for_voting(round_id, current_user.id)
    except AppException as e:
        raise create_http_exception(e)


@router.post("/{game_id}/end")
async def end_game(
    game_id: int,
    reason: str = "Игра завершена досрочно",
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    Завершает игру досрочно.
    
    - **game_id**: ID игры
    - **reason**: Причина завершения игры
    
    Только создатель комнаты может завершить игру досрочно.
    """
    try:
        game_service = GameService(db)
        return await game_service.end_game(game_id, reason)
    except AppException as e:
        raise create_http_exception(e)


# === УПРАВЛЕНИЕ СОСТОЯНИЕМ ИГРОКОВ ===

@router.post("/rooms/{room_id}/ping")
async def ping_player(
    room_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    Отправляет ping от игрока для обновления статуса активности.
    
    - **room_id**: ID комнаты
    
    Должен вызываться каждые 10-15 секунд для поддержания активности.
    """
    try:
        game_service = GameService(db)
        success = await game_service.player_manager.update_player_activity(current_user.id, room_id)
        
        return {
            "success": success,
            "player_id": current_user.id,
            "timestamp": datetime.utcnow(),
            "message": "Активность обновлена" if success else "Игрок не найден в комнате"
        }
    except AppException as e:
        raise create_http_exception(e)


@router.get("/rooms/{room_id}/players-status")
async def get_players_status(
    room_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> List[Dict[str, Any]]:
    """
    Получает статус всех игроков в комнате.
    
    - **room_id**: ID комнаты
    
    Показывает статус подключения, активность и статистику каждого игрока.
    """
    try:
        game_service = GameService(db)
        return await game_service.player_manager.get_active_players(room_id)
    except AppException as e:
        raise create_http_exception(e)


@router.post("/rooms/{room_id}/check-timeouts")
async def check_players_timeout(
    room_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    Проверяет игроков на таймаут и обновляет их статус.
    
    - **room_id**: ID комнаты
    
    Возвращает список игроков с таймаутом.
    """
    try:
        game_service = GameService(db)
        timeout_players = await game_service.player_manager.check_players_timeout(room_id)
        
        return {
            "timeout_players": timeout_players,
            "count": len(timeout_players),
            "checked_at": datetime.utcnow()
        }
    except AppException as e:
        raise create_http_exception(e)


@router.get("/rounds/{round_id}/action-status")
async def get_action_status(
    round_id: int,
    action_type: str,  # "card_selection" или "voting"
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> Dict[str, Any]:
    """
    Получает статус выполнения действия в раунде.
    
    - **round_id**: ID раунда
    - **action_type**: Тип действия ("card_selection" или "voting")
    
    Показывает кто уже выполнил действие, кто ждет, кто отключен.
    """
    try:
        game_service = GameService(db)
        game_round = await game_service._get_round_or_404(round_id)
        game = await game_service._get_game_or_404(game_round.game_id)
        
        # Получаем статистику по игрокам
        player_stats = await game_service.player_manager.get_players_for_action(game.room_id, action_type)
        
        # Получаем выполненные действия
        if action_type == "card_selection":
            completed_result = await db.execute(
                select(PlayerChoice.user_id, User.nickname)
                .join(User, PlayerChoice.user_id == User.id)
                .where(PlayerChoice.round_id == round_id)
            )
        else:  # voting
            completed_result = await db.execute(
                select(Vote.voter_id, User.nickname)
                .join(User, Vote.voter_id == User.id)
                .where(Vote.round_id == round_id)
            )
        
        completed_players = [
            {"user_id": user_id, "nickname": nickname}
            for user_id, nickname in completed_result
        ]
        
        return {
            "round_id": round_id,
            "action_type": action_type,
            "player_stats": player_stats,
            "completed_players": completed_players,
            "completion_rate": f"{len(completed_players)}/{player_stats['total_active']}",
            "all_completed": len(completed_players) >= player_stats["connected"],
            "deadline": game_round.selection_deadline if action_type == "card_selection" else game_round.voting_deadline,
            "time_remaining": (
                (game_round.selection_deadline if action_type == "card_selection" else game_round.voting_deadline) - datetime.utcnow()
            ).total_seconds() if game_round.selection_deadline else None
        }
    except AppException as e:
        raise create_http_exception(e) 


@router.get("/rounds/{round_id}/all-choices")
async def get_all_choices_for_round(
    round_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
) -> List[PlayerChoiceResponse]:
    """
    Получает все выборы карт в раунде (для тестов/админки).
    - **round_id**: ID раунда
    Возвращает все выборы карт без фильтрации по user_id.
    """
    try:
        game_service = GameService(db)
        return await game_service.get_all_choices_for_round(round_id)
    except AppException as e:
        raise create_http_exception(e) 