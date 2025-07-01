"""
Сервис для управления игровой логикой.
Отвечает за раунды, выбор карт, голосование и подсчет результатов.
Включает обработку таймаутов и отключений игроков.
"""

from typing import Optional, List, Dict, Any, Tuple
from datetime import datetime, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, or_, update, delete
from sqlalchemy.orm import selectinload
import asyncio
import random

from ..models.game import (
    Game, GameRound, PlayerChoice, Vote, Room, RoomParticipant,
    GameStatus, RoomStatus, ParticipantStatus, ConnectionStatus
)
from ..models.user import User, UserCard
from ..schemas.game import (
    GameResponse, GameRoundResponse, PlayerChoiceCreate, PlayerChoiceResponse,
    VoteCreate, VoteResponse, RoundResultResponse, GameStateResponse
)
from ..services.card_service import CardService
from ..services.player_manager import PlayerManager
from ..services.ai_service import AIService
from ..core.redis import RedisClient
from ..tasks.ai_tasks import generate_situation_for_round_task
from ..utils.exceptions import ValidationError, NotFoundError, PermissionError


class GameService:
    """Сервис для управления игровым процессом"""
    
    def __init__(self, db: AsyncSession, redis_client: Optional[RedisClient] = None):
        self.db = db
        self.card_service = CardService(db)
        self.player_manager = PlayerManager(db)
        self.ai_service = AIService(db)
        self.redis_client = redis_client
        
        # Таймауты для разных фаз игры
        self.CARD_SELECTION_TIMEOUT = 50  # Начальное время на выбор карт
        self.VOTING_TIMEOUT = 30         # Время на голосование
        self.RESULTS_DISPLAY_TIME = 5    # Время показа результатов
    
    async def get_game_by_room(self, room_id: int) -> Optional[Game]:
        """Получает активную игру в комнате"""
        result = await self.db.execute(
            select(Game).where(
                and_(
                    Game.room_id == room_id,
                    Game.status != GameStatus.FINISHED
                )
            ).order_by(Game.created_at.desc())
        )
        return result.scalar()
    
    async def get_game_state(self, game_id: int) -> Optional[Dict[str, Any]]:
        """
        Получает состояние игры с кэшированием.
        
        Args:
            game_id: ID игры
            
        Returns:
            Optional[Dict]: Состояние игры или None
        """
        # Сначала пытаемся получить из кэша
        if self.redis_client:
            cached_state = await self.redis_client.get_game_state(game_id)
            if cached_state:
                return cached_state
        
        # Если в кэше нет, получаем из БД
        game = await self._get_game_or_404(game_id)
        
        # Получаем текущий раунд
        current_round = None
        if game.current_round > 0:
            round_result = await self.db.execute(
                select(GameRound).where(
                    and_(
                        GameRound.game_id == game_id,
                        GameRound.round_number == game.current_round
                    )
                )
            )
            current_round = round_result.scalar()
        
        # Получаем активных игроков
        active_players = await self.player_manager.get_active_players(game.room_id)
        
        # Формируем состояние игры
        game_state = {
            "game_id": game.id,
            "room_id": game.room_id,
            "status": game.status.value,
            "current_round": game.current_round,
            "total_rounds": 7,
            "active_players_count": len(active_players),
            "current_round_data": {
                "round_id": current_round.id if current_round else None,
                "situation_text": current_round.situation_text if current_round else None,
                "duration_seconds": current_round.duration_seconds if current_round else None,
                "started_at": current_round.started_at.isoformat() if current_round else None,
                "selection_deadline": current_round.selection_deadline.isoformat() if current_round else None,
                "voting_deadline": current_round.voting_deadline.isoformat() if current_round else None
            } if current_round else None,
            "active_players": active_players,
            "last_updated": datetime.utcnow().isoformat()
        }
        
        # Сохраняем в кэш на 5 минут
        if self.redis_client:
            await self.redis_client.cache_game_state(game_id, game_state, expire=300)
        
        return game_state
    
    async def start_round(self, game_id: int, situation_text: Optional[str] = None) -> GameRoundResponse:
        """
        Начинает новый раунд игры с установкой таймаутов.
        
        Args:
            game_id: ID игры
            situation_text: Текст ситуационной карточки (если None, генерируется через Celery)
            
        Returns:
            GameRoundResponse: Созданный раунд
        """
        game = await self._get_game_or_404(game_id)
        
        # Проверяем что игра может начать раунд
        if game.status not in [GameStatus.STARTING, GameStatus.ROUND_RESULTS]:
            raise ValidationError("Нельзя начать новый раунд в текущем состоянии игры")
        
        # Очищаем неактивных игроков перед началом раунда
        await self.player_manager.cleanup_inactive_players(game.room_id)
        
        # Проверяем что достаточно игроков для продолжения
        active_players = await self.player_manager.get_active_players(game.room_id)
        if len(active_players) < 3:
            # Автоматически завершаем игру
            return await self.end_game(game_id, reason="Недостаточно игроков для продолжения (минимум 3)")
        
        # Вычисляем длительность раунда: 50 -> 45 -> 40 -> 35 -> 30 -> 30 -> 30...
        if game.current_round <= 5:
            duration = self.CARD_SELECTION_TIMEOUT - (game.current_round - 1) * 5  # 50, 45, 40, 35, 30
        else:
            duration = 30  # С 6-го раунда и далее остается 30 секунд
        current_time = datetime.utcnow()
        
        # ИСПРАВЛЕНО: Увеличиваем номер раунда перед созданием
        next_round_number = game.current_round + 1
        
        # Если ситуация не передана, используем placeholder и запускаем Celery задачу
        if situation_text is None:
            # Получаем комнату для определения age_group и языка
            room_result = await self.db.execute(
                select(Room).where(Room.id == game.room_id)
            )
            room = room_result.scalar()
            
            # Используем placeholder ситуацию
            situation_text = f"Генерация ситуации для раунда {next_round_number}..."
            
            # Запускаем фоновую задачу Celery для генерации ситуации
            generate_situation_for_round_task.delay(
                game_id=game_id,
                room_id=game.room_id,
                round_number=next_round_number,
                age_group=room.age_group or "adults",
                language="ru"  # Можно добавить в Room поле language
            )
            
            # Публикуем событие о начале генерации ситуации
            if self.redis_client:
                await self.redis_client.publish_game_event(
                    room_id=game.room_id,
                    event_type="situation_generating",
                    event_data={
                        "game_id": game_id,
                        "round_number": next_round_number
                    }
                )
        
        # Создаем раунд с таймаутами
        game_round = GameRound(
            game_id=game_id,
            round_number=next_round_number,
            situation_text=situation_text,
            duration_seconds=duration,
            started_at=current_time,
            selection_deadline=current_time + timedelta(seconds=duration),
            voting_deadline=current_time + timedelta(seconds=duration + self.VOTING_TIMEOUT)
        )
        self.db.add(game_round)
        
        # Обновляем статус игры и номер текущего раунда
        game.status = GameStatus.CARD_SELECTION
        game.current_round = next_round_number
        
        await self.db.commit()
        await self.db.refresh(game_round)
        
        # Инвалидируем кэш состояния игры
        if self.redis_client:
            await self.redis_client.delete(f"game_state:{game_id}")
        
        # Публикуем событие о начале раунда
        if self.redis_client:
            await self.redis_client.publish_game_event(
                room_id=game.room_id,
                event_type="round_started",
                event_data={
                    "game_id": game_id,
                    "round_id": game_round.id,
                    "round_number": next_round_number,
                    "situation_text": situation_text,
                    "duration_seconds": duration
                }
            )
        
        # Запускаем фоновую задачу для обработки таймаута
        asyncio.create_task(self._handle_selection_timeout(game_round.id))
        
        return GameRoundResponse(
            id=game_round.id,
            game_id=game_round.game_id,
            round_number=game_round.round_number,
            situation_text=game_round.situation_text,
            duration_seconds=game_round.duration_seconds,
            created_at=game_round.created_at,
            started_at=game_round.started_at,
            time_remaining=duration
        )
    
    async def submit_card_choice(
        self, 
        round_id: int, 
        user_id: int, 
        choice_data: PlayerChoiceCreate
    ) -> PlayerChoiceResponse:
        """
        Игрок выбирает карту для раунда с обновлением активности.
        
        Args:
            round_id: ID раунда
            user_id: ID игрока
            choice_data: Выбор карты
            
        Returns:
            PlayerChoiceResponse: Выбор игрока
        """
        # Получаем раунд и проверяем статус
        game_round = await self._get_round_or_404(round_id)
        game = await self._get_game_or_404(game_round.game_id)
        
        if game.status != GameStatus.CARD_SELECTION:
            raise ValidationError("Время выбора карт истекло")
        
        # Проверяем дедлайн
        if datetime.utcnow() > game_round.selection_deadline:
            raise ValidationError("Время на выбор карты истекло")
        
        # Проверяем что игрок участвует в игре
        await self._validate_player_in_game(game.room_id, user_id)
        
        # Обновляем активность игрока
        await self.player_manager.update_player_activity(user_id, game.room_id)
        
        # Проверяем что игрок еще не выбрал карту
        existing_choice = await self.db.execute(
            select(PlayerChoice).where(
                and_(
                    PlayerChoice.round_id == round_id,
                    PlayerChoice.user_id == user_id
                )
            )
        )
        if existing_choice.scalar():
            raise ValidationError("Вы уже выбрали карту для этого раунда")
        
        # Проверяем что у игрока есть эта карта
        user_has_card = await self.db.execute(
            select(UserCard).where(
                and_(
                    UserCard.user_id == user_id,
                    UserCard.card_type == choice_data.card_type,
                    UserCard.card_number == choice_data.card_number
                )
            )
        )
        if not user_has_card.scalar():
            raise ValidationError("У вас нет этой карты")
        
        # Создаем выбор
        player_choice = PlayerChoice(
            round_id=round_id,
            user_id=user_id,
            card_type=choice_data.card_type,
            card_number=choice_data.card_number
        )
        self.db.add(player_choice)
        await self.db.commit()
        await self.db.refresh(player_choice)
        
        # Инвалидируем кэш состояния игры
        if self.redis_client:
            await self.redis_client.delete(f"game_state:{game.id}")
        
        # Публикуем событие о выборе карты
        if self.redis_client:
            await self.redis_client.publish_game_event(
                room_id=game.room_id,
                event_type="player_choice_submitted",
                event_data={
                    "game_id": game.id,
                    "round_id": round_id,
                    "user_id": user_id,
                    "card_type": choice_data.card_type,
                    "card_number": choice_data.card_number
                }
            )
        
        # Получаем никнейм игрока
        user_result = await self.db.execute(
            select(User.nickname).where(User.id == user_id)
        )
        nickname = user_result.scalar() or "Неизвестно"
        
        # Проверяем все ли активные игроки сделали выбор
        await self._check_all_players_chose_cards(game_round.game_id, round_id)
        
        return PlayerChoiceResponse(
            id=player_choice.id,
            round_id=player_choice.round_id,
            user_id=player_choice.user_id,
            user_nickname=nickname,
            card_type=player_choice.card_type,
            card_number=player_choice.card_number,
            submitted_at=player_choice.submitted_at,
            vote_count=0
        )
    
    async def start_voting(self, round_id: int) -> Dict[str, Any]:
        """
        Начинает фазу голосования.
        
        Args:
            round_id: ID раунда
            
        Returns:
            Dict: Информация о начале голосования
        """
        game_round = await self._get_round_or_404(round_id)
        game = await self._get_game_or_404(game_round.game_id)
        
        if game.status != GameStatus.CARD_SELECTION:
            raise ValidationError("Голосование можно начать только после выбора карт")
        
        # Получаем все выборы игроков
        choices_result = await self.db.execute(
            select(PlayerChoice).where(PlayerChoice.round_id == round_id)
        )
        choices = choices_result.scalars().all()
        
        if len(choices) < 3:
            raise ValidationError("Для голосования нужно минимум 3 выбора")
        
        # Обновляем статус игры
        game.status = GameStatus.VOTING
        await self.db.commit()
        
        # Инвалидируем кэш состояния игры
        if self.redis_client:
            await self.redis_client.delete(f"game_state:{game.id}")
        
        # Публикуем событие о начале голосования
        if self.redis_client:
            await self.redis_client.publish_game_event(
                room_id=game.room_id,
                event_type="voting_started",
                event_data={
                    "game_id": game.id,
                    "round_id": round_id,
                    "voting_deadline": game_round.voting_deadline.isoformat(),
                    "total_choices": len(choices)
                }
            )
        
        # Запускаем фоновую задачу для обработки таймаута голосования
        asyncio.create_task(self._handle_voting_timeout(round_id))
        
        return {
            "success": True,
            "round_id": round_id,
            "voting_started": datetime.utcnow(),
            "voting_deadline": game_round.voting_deadline,
            "total_choices": len(choices),
            "message": "Голосование началось!"
        }
    
    async def submit_vote(
        self, 
        round_id: int, 
        user_id: int, 
        vote_data: VoteCreate
    ) -> VoteResponse:
        """
        Игрок голосует за карту с обновлением активности.
        
        Args:
            round_id: ID раунда
            user_id: ID голосующего
            vote_data: Данные голоса
            
        Returns:
            VoteResponse: Голос игрока
        """
        game_round = await self._get_round_or_404(round_id)
        game = await self._get_game_or_404(game_round.game_id)
        
        if game.status != GameStatus.VOTING:
            raise ValidationError("Время голосования истекло")
        
        # Проверяем дедлайн
        if datetime.utcnow() > game_round.voting_deadline:
            raise ValidationError("Время на голосование истекло")
        
        # Проверяем что игрок участвует в игре
        await self._validate_player_in_game(game.room_id, user_id)
        
        # Обновляем активность игрока
        await self.player_manager.update_player_activity(user_id, game.room_id)
        
        # Проверяем что игрок еще не голосовал
        existing_vote = await self.db.execute(
            select(Vote).where(
                and_(
                    Vote.round_id == round_id,
                    Vote.voter_id == user_id
                )
            )
        )
        if existing_vote.scalar():
            raise ValidationError("Вы уже проголосовали в этом раунде")
        
        # Проверяем что выбор существует
        choice_result = await self.db.execute(
            select(PlayerChoice).where(PlayerChoice.id == vote_data.choice_id)
        )
        choice = choice_result.scalar()
        if not choice or choice.round_id != round_id:
            raise ValidationError("Выбор карты не найден")
        
        # Нельзя голосовать за свою карту
        if choice.user_id == user_id:
            raise ValidationError("Нельзя голосовать за свою карту")
        
        # Создаем голос
        vote = Vote(
            round_id=round_id,
            voter_id=user_id,
            choice_id=vote_data.choice_id
        )
        self.db.add(vote)
        await self.db.commit()
        await self.db.refresh(vote)
        
        # Инвалидируем кэш состояния игры
        if self.redis_client:
            await self.redis_client.delete(f"game_state:{game.id}")
        
        # Публикуем событие о голосе
        if self.redis_client:
            await self.redis_client.publish_game_event(
                room_id=game.room_id,
                event_type="vote_submitted",
                event_data={
                    "game_id": game.id,
                    "round_id": round_id,
                    "voter_id": user_id,
                    "choice_id": vote_data.choice_id
                }
            )
        
        # Получаем никнейм голосующего
        user_result = await self.db.execute(
            select(User.nickname).where(User.id == user_id)
        )
        nickname = user_result.scalar() or "Неизвестно"
        
        # Проверяем все ли активные игроки проголосовали
        await self._check_all_players_voted(game_round.game_id, round_id)
        
        return VoteResponse(
            id=vote.id,
            round_id=vote.round_id,
            voter_id=vote.voter_id,
            voter_nickname=nickname,
            choice_id=vote.choice_id,
            created_at=vote.created_at
        )
    
    async def calculate_round_results(self, round_id: int) -> RoundResultResponse:
        """
        Подсчитывает результаты раунда (оптимизированная версия).
        
        Args:
            round_id: ID раунда
            
        Returns:
            RoundResultResponse: Результаты раунда
        """
        game_round = await self._get_round_or_404(round_id)
        game = await self._get_game_or_404(game_round.game_id)
        
        # Оптимизированный запрос для подсчета голосов
        vote_counts_query = await self.db.execute(
            select(
                PlayerChoice.id,
                PlayerChoice.user_id,
                PlayerChoice.card_type,
                PlayerChoice.card_number,
                PlayerChoice.submitted_at,
                User.nickname,
                func.coalesce(func.count(Vote.id), 0).label('vote_count')
            )
            .select_from(PlayerChoice)
            .join(User, PlayerChoice.user_id == User.id)
            .outerjoin(Vote, PlayerChoice.id == Vote.choice_id)
            .where(PlayerChoice.round_id == round_id)
            .group_by(
                PlayerChoice.id, 
                PlayerChoice.user_id,
                PlayerChoice.card_type,
                PlayerChoice.card_number,
                PlayerChoice.submitted_at,
                User.nickname
            )
            .order_by(func.count(Vote.id).desc())
        )
        
        choices_data = []
        winner_choice = None
        max_votes = -1
        
        # Обрабатываем результаты одним проходом
        for row in vote_counts_query:
            choice_id, user_id, card_type, card_number, submitted_at, nickname, vote_count = row
            
            # Получаем URL карты (кэшируем в будущем)
            card_url = None
            if self.card_service.azure_service:
                card_url = self.card_service.azure_service.get_card_url(card_type, card_number)
            
            choice_response = PlayerChoiceResponse(
                id=choice_id,
                round_id=round_id,
                user_id=user_id,
                user_nickname=nickname,
                card_type=card_type,
                card_number=card_number,
                card_url=card_url,
                submitted_at=submitted_at,
                vote_count=vote_count
            )
            
            choices_data.append(choice_response)
            
            # Определяем победителя
            if vote_count > max_votes:
                max_votes = vote_count
                winner_choice = choice_response
        
        # Простой запрос для голосов (только если нужно показать детали)
        votes_data = []
        if len(choices_data) > 0:  # Показываем голоса только если есть выборы
            votes_query = await self.db.execute(
                select(Vote.id, Vote.voter_id, Vote.choice_id, Vote.created_at, User.nickname)
                .join(User, Vote.voter_id == User.id)
                .where(Vote.round_id == round_id)
                .order_by(Vote.created_at)
            )
            
            for vote_id, voter_id, choice_id, created_at, nickname in votes_query:
                votes_data.append(VoteResponse(
                    id=vote_id,
                    round_id=round_id,
                    voter_id=voter_id,
                    voter_nickname=nickname,
                    choice_id=choice_id,
                    created_at=created_at
                ))
        
        # Атомарно обновляем статус
        await self.db.execute(
            update(Game)
            .where(Game.id == game.id)
            .values(status=GameStatus.ROUND_RESULTS)
        )
        
        await self.db.execute(
            update(GameRound)
            .where(GameRound.id == round_id)
            .values(finished_at=datetime.utcnow())
        )
        
        # ИСПРАВЛЕНО: Карта выдается только в конце игры, а не после каждого раунда
        # if winner_choice and max_votes > 0:
        #     asyncio.create_task(self._award_winner_card_async(winner_choice.user_id))
        
        # 🏆 НОВОЕ: Награждаем победителя раунда очками
        if winner_choice and max_votes > 0:
            await self._award_round_points(winner_choice.user_id, winner_choice.user_nickname)
        
        await self.db.commit()
        
        # Инвалидируем кэш состояния игры
        if self.redis_client:
            await self.redis_client.delete(f"game_state:{game.id}")
        
        # Публикуем событие о результатах раунда
        if self.redis_client:
            await self.redis_client.publish_game_event(
                room_id=game.room_id,
                event_type="round_results_calculated",
                event_data={
                    "game_id": game.id,
                    "round_id": round_id,
                    "round_number": game_round.round_number,
                    "winner_user_id": winner_choice.user_id if winner_choice else None,
                    "winner_nickname": winner_choice.user_nickname if winner_choice else None,
                    "max_votes": max_votes,
                    "total_choices": len(choices_data),
                    "next_round_starts_in": self.RESULTS_DISPLAY_TIME
                }
            )
        
        print(f"🎯 Раунд {game_round.round_number} завершен. Победитель: {winner_choice.user_nickname if winner_choice else 'Никто'} ({max_votes} голосов)")
        
        # ИСПРАВЛЕНО: Автоматический переход к следующему раунду
        await self._schedule_next_round(game.id, game_round.round_number)
        
        return RoundResultResponse(
            round_id=round_id,
            round_number=game_round.round_number,
            situation_text=game_round.situation_text,
            winner_choice=winner_choice,
            all_choices=choices_data,
            votes=votes_data,
            next_round_starts_in=self.RESULTS_DISPLAY_TIME
        )
    
    async def get_choices_for_voting(self, round_id: int, user_id: int) -> List[PlayerChoiceResponse]:
        """
        Получает все выборы карт в раунде кроме выбора текущего пользователя.
        Используется для голосования.
        
        Args:
            round_id: ID раунда
            user_id: ID текущего пользователя
            
        Returns:
            List[PlayerChoiceResponse]: Выборы карт для голосования
        """
        game_round = await self._get_round_or_404(round_id)
        
        # Получаем все выборы кроме выбора текущего пользователя
        choices_result = await self.db.execute(
            select(PlayerChoice, User.nickname)
            .join(User, PlayerChoice.user_id == User.id)
            .where(
                and_(
                    PlayerChoice.round_id == round_id,
                    PlayerChoice.user_id != user_id  # Исключаем свой выбор
                )
            )
            .order_by(PlayerChoice.submitted_at)
        )
        
        choices_data = []
        for choice, nickname in choices_result:
            # Получаем URL карты из Azure
            card_url = self.card_service.azure_service.get_card_url(
                choice.card_type, choice.card_number
            ) if self.card_service.azure_service else None
            
            # Получаем количество голосов для этого выбора
            votes_count = await self.db.execute(
                select(func.count(Vote.id))
                .where(Vote.choice_id == choice.id)
            )
            vote_count = votes_count.scalar() or 0
            
            choice_response = PlayerChoiceResponse(
                id=choice.id,
                round_id=choice.round_id,
                user_id=choice.user_id,
                user_nickname=nickname,
                card_type=choice.card_type,
                card_number=choice.card_number,
                card_url=card_url,
                submitted_at=choice.submitted_at,
                vote_count=vote_count
            )
            
            choices_data.append(choice_response)
        
        return choices_data
    
    async def get_round_cards_for_user(self, round_id: int, user_id: int) -> List[Dict[str, Any]]:
        """
        Получает 3 случайные карты пользователя для раунда.
        
        Args:
            round_id: ID раунда
            user_id: ID пользователя
            
        Returns:
            List[Dict]: Список из 3 карт с URL
        """
        import random
        from ..models.user import UserCard
        
        # Получаем раунд и проверяем игру
        game_round = await self._get_round_or_404(round_id)
        game = await self._get_game_or_404(game_round.game_id)
        
        # Проверяем что игрок участвует в игре
        await self._validate_player_in_game(game.room_id, user_id)
        
        # Получаем все карты пользователя
        user_cards_result = await self.db.execute(
            select(UserCard).where(UserCard.user_id == user_id)
        )
        user_cards = user_cards_result.scalars().all()
        
        if len(user_cards) < 3:
            raise ValidationError("У пользователя недостаточно карт для игры")
        
        # Выбираем 3 случайные карты
        selected_cards = random.sample(list(user_cards), 3)
        
        # Формируем ответ с URL карт
        result_cards = []
        for card in selected_cards:
            card_url = None
            if self.card_service and self.card_service.azure_service:
                card_url = self.card_service.azure_service.get_card_url(
                    card.card_type, card.card_number
                )
            
            result_cards.append({
                "card_type": card.card_type,
                "card_number": card.card_number,
                "card_url": card_url
            })
        
        return result_cards
    
    async def end_game(self, game_id: int, reason: str) -> Dict[str, Any]:
        """
        Завершает игру.
        
        Args:
            game_id: ID игры
            reason: Причина завершения игры
            
        Returns:
            Dict: Результаты игры
        """
        game = await self._get_game_or_404(game_id)
        
        # Получаем статистику игроков (количество побед в раундах)
        player_stats = await self.db.execute(
            select(
                User.id,
                User.nickname,
                func.count(Vote.id).label('round_wins')
            )
            .join(PlayerChoice, User.id == PlayerChoice.user_id)
            .join(GameRound, PlayerChoice.round_id == GameRound.id)
            .outerjoin(Vote, Vote.choice_id == PlayerChoice.id)
            .where(GameRound.game_id == game_id)
            .group_by(User.id, User.nickname)
            .order_by(func.count(Vote.id).desc())
        )
        
        leaderboard = []
        winner_id = None
        
        for user_id, nickname, round_wins in player_stats:
            leaderboard.append({
                "user_id": user_id,
                "nickname": nickname,
                "round_wins": round_wins,
                "place": len(leaderboard) + 1
            })
            
            if winner_id is None:
                winner_id = user_id
        
        # Обновляем игру
        game.status = GameStatus.FINISHED
        game.winner_id = winner_id
        game.finished_at = datetime.utcnow()
        
        # Обновляем комнату
        room_result = await self.db.execute(
            select(Room).where(Room.id == game.room_id)
        )
        room = room_result.scalar()
        if room:
            room.status = RoomStatus.FINISHED
        
        await self.db.commit()
        
        # Инвалидируем кэш состояния игры
        if self.redis_client:
            await self.redis_client.delete(f"game_state:{game_id}")
        
        # Публикуем событие о завершении игры
        if self.redis_client:
            await self.redis_client.publish_game_event(
                room_id=game.room_id,
                event_type="game_ended",
                event_data={
                    "game_id": game_id,
                    "winner_id": winner_id,
                    "winner_nickname": leaderboard[0]["nickname"] if leaderboard else None,
                    "total_rounds": game.current_round,
                    "leaderboard": leaderboard,
                    "reason": reason
                }
            )
        
        # ИСПРАВЛЕНО: Награждаем победителя игры (не раунда) стандартной картой
        if winner_id and leaderboard and leaderboard[0]["round_wins"] > 0:
            asyncio.create_task(self._award_winner_card_async(winner_id))
            
            # 🏆 НОВОЕ: Дополнительные очки за победу в игре
            winner_nickname = leaderboard[0]["nickname"]
            await self._award_game_victory_points(winner_id, winner_nickname, leaderboard[0]["round_wins"])
        
        return {
            "success": True,
            "game_id": game_id,
            "winner_id": winner_id,
            "winner_nickname": leaderboard[0]["nickname"] if leaderboard else None,
            "total_rounds": game.current_round,
            "leaderboard": leaderboard,
            "message": f"Игра завершена! Причина: {reason}"
        }
    
    # === Вспомогательные методы ===
    
    async def _get_game_or_404(self, game_id: int) -> Game:
        """Получает игру или выбрасывает 404"""
        result = await self.db.execute(select(Game).where(Game.id == game_id))
        game = result.scalar()
        if not game:
            raise NotFoundError("Игра не найдена")
        return game
    
    async def _get_round_or_404(self, round_id: int) -> GameRound:
        """Получает раунд или выбрасывает 404"""
        result = await self.db.execute(select(GameRound).where(GameRound.id == round_id))
        round_obj = result.scalar()
        if not round_obj:
            raise NotFoundError("Раунд не найден")
        return round_obj
    
    async def _validate_player_in_game(self, room_id: int, user_id: int):
        """Проверяет что игрок участвует в игре"""
        participant = await self.db.execute(
            select(RoomParticipant).where(
                and_(
                    RoomParticipant.room_id == room_id,
                    RoomParticipant.user_id == user_id,
                    RoomParticipant.status == ParticipantStatus.ACTIVE
                )
            )
        )
        if not participant.scalar():
            raise PermissionError("Вы не участвуете в этой игре")
    
    async def _check_all_players_chose_cards(self, game_id: int, round_id: int):
        """Проверяет выбрали ли все активные игроки карты"""
        # Получаем игру
        game = await self._get_game_or_404(game_id)
        
        # Получаем активных игроков
        active_players = await self.player_manager.get_active_players(game.room_id)
        connected_players = [p for p in active_players if p["is_connected"]]
        
        # Количество сделанных выборов
        choices_made = await self.db.execute(
            select(func.count(PlayerChoice.id))
            .where(PlayerChoice.round_id == round_id)
        )
        choices_count = choices_made.scalar() or 0
        
        # Если все подключенные игроки выбрали - начинаем голосование
        if choices_count >= len(connected_players) and len(connected_players) > 1:
            await self.start_voting(round_id)
    
    async def _check_all_players_voted(self, game_id: int, round_id: int):
        """Проверяет проголосовали ли все активные игроки"""
        # Получаем игру
        game = await self._get_game_or_404(game_id)
        
        # Получаем активных игроков  
        active_players = await self.player_manager.get_active_players(game.room_id)
        connected_players = [p for p in active_players if p["is_connected"]]
        
        # Количество игроков которые должны голосовать (исключая отключенных)
        players_should_vote = len(connected_players)
        
        # Количество голосов
        votes_made = await self.db.execute(
            select(func.count(Vote.id))
            .where(Vote.round_id == round_id)
        )
        votes_count = votes_made.scalar() or 0
        
        print(f"🗳️ Голосование: {votes_count}/{players_should_vote} игроков проголосовало")
        
        # Если все подключенные игроки проголосовали - подсчитываем результаты
        if votes_count >= players_should_vote and players_should_vote > 1:
            print(f"✅ Все игроки проголосовали! Переходим к результатам раунда {round_id}")
            # Не вызываем calculate_round_results напрямую - ставим в очередь
            asyncio.create_task(self._calculate_results_async(round_id))
    
    async def _award_winner_card_async(self, user_id: int):
        """Асинхронно награждает победителя раунда стандартной картой"""
        try:
            # Получаем случайную стандартную карту, которой у игрока еще нет
            available_cards = await self.card_service.get_available_standard_cards_for_user(user_id)
            
            if available_cards:
                # Выбираем случайную карту
                card_number = random.choice(available_cards)
                
                # Добавляем карту игроку
                user_card = UserCard(
                    user_id=user_id,
                    card_type="standard",
                    card_number=card_number
                )
                self.db.add(user_card)
                await self.db.commit()
                
                print(f"Награжден игрок {user_id} картой standard:{card_number}")
                
        except Exception as e:
            # Логируем ошибку, но не прерываем игру
            print(f"Ошибка награждения карты: {e}")
    
    async def _award_winner_card(self, user_id: int):
        """Награждает победителя раунда стандартной картой (синхронная версия для совместимости)"""
        try:
            # Получаем случайную стандартную карту, которой у игрока еще нет
            available_cards = await self.card_service.get_available_standard_cards_for_user(user_id)
            
            if available_cards:
                # Выбираем случайную карту
                card_number = random.choice(available_cards)
                
                # Добавляем карту игроку
                user_card = UserCard(
                    user_id=user_id,
                    card_type="standard",
                    card_number=card_number
                )
                self.db.add(user_card)
                
        except Exception as e:
            # Логируем ошибку, но не прерываем игру
            print(f"Ошибка награждения карты: {e}")
            pass
    
    async def _award_round_points(self, user_id: int, user_nickname: str):
        """
        Награждает победителя раунда очками.
        
        Args:
            user_id: ID игрока
            user_nickname: Никнейм игрока для логирования
        """
        try:
            # Получаем пользователя
            user_result = await self.db.execute(
                select(User).where(User.id == user_id)
            )
            user = user_result.scalar()
            
            if user:
                # Даем +1 очко за победу в раунде
                old_rating = user.rating
                user.rating += 1.0
                
                print(f"🏆 {user_nickname} (ID: {user_id}) получает +1 очко! Рейтинг: {old_rating} → {user.rating}")
                
                # Обновляем в базе данных
                await self.db.execute(
                    update(User)
                    .where(User.id == user_id)
                    .values(rating=user.rating)
                )
                
        except Exception as e:
            print(f"Ошибка награждения очков игроку {user_id}: {e}")
    
    async def _award_game_victory_points(self, user_id: int, user_nickname: str, round_wins: int):
        """
        Награждает победителя игры дополнительными очками.
        
        Args:
            user_id: ID игрока
            user_nickname: Никнейм игрока
            round_wins: Количество побед в раундах
        """
        try:
            # Получаем пользователя
            user_result = await self.db.execute(
                select(User).where(User.id == user_id)
            )
            user = user_result.scalar()
            
            if user:
                # Дополнительные очки за победу в игре
                bonus_points = 5.0
                old_rating = user.rating
                user.rating += bonus_points
                
                print(f"🎉 ПОБЕДИТЕЛЬ ИГРЫ: {user_nickname} (ID: {user_id})")
                print(f"🏆 Побед в раундах: {round_wins}")
                print(f"🎯 Бонус за победу в игре: +{bonus_points} очков")
                print(f"⭐ Общий рейтинг: {old_rating} → {user.rating}")
                
                # Обновляем в базе данных
                await self.db.execute(
                    update(User)
                    .where(User.id == user_id)
                    .values(rating=user.rating)
                )
                
        except Exception as e:
            print(f"Ошибка награждения очков за победу в игре игроку {user_id}: {e}")
    
    async def _handle_selection_timeout(self, round_id: int):
        """Обрабатывает таймаут выбора карт"""
        try:
            game_round = await self._get_round_or_404(round_id)
            
            # Ждем до дедлайна
            await asyncio.sleep((game_round.selection_deadline - datetime.utcnow()).total_seconds())
            
            # Проверяем что раунд все еще в стадии выбора карт
            await self.db.refresh(game_round)
            game = await self._get_game_or_404(game_round.game_id)
            
            if game.status != GameStatus.CARD_SELECTION:
                return  # Раунд уже перешел в другую стадию
            
            # Получаем игроков которые не выбрали карты
            active_players = await self.player_manager.get_active_players(game.room_id)
            
            choices_result = await self.db.execute(
                select(PlayerChoice.user_id).where(PlayerChoice.round_id == round_id)
            )
            players_with_choices = {user_id for (user_id,) in choices_result}
            
            # Обрабатываем пропущенные действия
            for player in active_players:
                if player["user_id"] not in players_with_choices:
                    await self.player_manager.handle_missed_action(
                        player["user_id"], game.room_id, "card_selection"
                    )
            
            # Принудительно начинаем голосование если есть хотя бы 3 выбора
            choices_count = await self.db.execute(
                select(func.count(PlayerChoice.id)).where(PlayerChoice.round_id == round_id)
            )
            
            if choices_count.scalar() >= 3:
                await self.start_voting(round_id)
            else:
                # Недостаточно выборов - завершаем игру
                await self.end_game(game_round.game_id, reason="Недостаточно игроков выбрали карты (минимум 3)")
                
        except Exception as e:
            print(f"Ошибка в обработке таймаута выбора карт: {e}")
    
    async def _handle_voting_timeout(self, round_id: int):
        """Обрабатывает таймаут голосования"""
        try:
            game_round = await self._get_round_or_404(round_id)
            
            # Ждем до дедлайна голосования
            await asyncio.sleep((game_round.voting_deadline - datetime.utcnow()).total_seconds())
            
            # Проверяем что раунд все еще в стадии голосования
            await self.db.refresh(game_round)
            game = await self._get_game_or_404(game_round.game_id)
            
            if game.status != GameStatus.VOTING:
                return  # Раунд уже перешел в другую стадию
            
            # Получаем игроков которые не проголосовали
            active_players = await self.player_manager.get_active_players(game.room_id)
            
            votes_result = await self.db.execute(
                select(Vote.voter_id).where(Vote.round_id == round_id)
            )
            players_with_votes = {user_id for (user_id,) in votes_result}
            
            # Обрабатываем пропущенные действия
            for player in active_players:
                if player["user_id"] not in players_with_votes:
                    await self.player_manager.handle_missed_action(
                        player["user_id"], game.room_id, "voting"
                    )
            
            # Принудительно подсчитываем результаты
            game_round.auto_advanced = True
            await self.db.commit()
            
            await self._calculate_results_async(round_id)
                
        except Exception as e:
            print(f"Ошибка в обработке таймаута голосования: {e}")
    
    async def _calculate_results_async(self, round_id: int):
        """Асинхронно подсчитывает результаты раунда"""
        try:
            await self.calculate_round_results(round_id)
        except Exception as e:
            print(f"Ошибка в подсчете результатов: {e}")
            
    async def _generate_situation_for_round(self, game: Game) -> str:
        """
        Генерирует ситуационную карточку для раунда через AI.
        
        Args:
            game: Игра для которой генерируется ситуация
            
        Returns:
            str: Текст ситуационной карточки
        """
        try:
            # Получаем комнату и её age_group
            room_result = await self.db.execute(
                select(Room).where(Room.id == game.room_id)
            )
            room = room_result.scalar()
            
            if not room:
                raise ValidationError("Комната не найдена")
            
            # Получаем данные игроков комнаты (для fallback если age_group не установлен)
            players_data = await self.db.execute(
                select(User.birth_date, User.gender)
                .join(RoomParticipant, RoomParticipant.user_id == User.id)
                .where(
                    and_(
                        RoomParticipant.room_id == game.room_id,
                        RoomParticipant.status == ParticipantStatus.ACTIVE
                    )
                )
            )
            
            player_ages = []
            player_genders = []
            
            for birth_date, gender in players_data:
                player_ages.append(birth_date)
                player_genders.append(gender)
            
            # Вычисляем следующий номер раунда
            next_round = game.current_round + 1
            
            # Генерируем ситуацию через AI
            # Если у комнаты есть age_group, используем его, иначе вычисляем по игрокам
            situation = await self.ai_service.generate_situation_card(
                round_number=next_round,
                player_ages=player_ages if not room.age_group else None,
                player_genders=player_genders if not room.age_group else None,
                age_group=room.age_group  # Передаем age_group комнаты
            )
            
            return situation
            
        except Exception as e:
            print(f"Ошибка генерации AI ситуации: {e}")
            # Если AI недоступен, используем fallback
            return f"Опишите самую смешную ситуацию из вашей жизни (раунд {game.current_round + 1})"
    
    async def _schedule_next_round(self, game_id: int, current_round: int):
        """Планирует следующий раунд или завершение игры"""
        try:
            # Ждем время отображения результатов
            await asyncio.sleep(self.RESULTS_DISPLAY_TIME)
            
            # Проверяем текущее состояние игры
            game = await self._get_game_or_404(game_id)
            
            if current_round >= 7:
                # Игра завершена - определяем общего победителя
                await self.end_game(game_id, "Все 7 раундов завершены")
            else:
                # Начинаем следующий раунд (ситуация сгенерируется автоматически через AI)
                await self.start_round(game_id)
                
        except Exception as e:
            print(f"Ошибка в планировании следующего раунда: {e}")
            # В случае ошибки завершаем игру
            try:
                await self.end_game(game_id, f"Ошибка перехода к раунду {current_round + 1}")
            except:
                pass 