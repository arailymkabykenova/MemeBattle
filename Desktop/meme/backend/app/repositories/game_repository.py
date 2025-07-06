"""
Репозиторий для работы с играми и игровыми раундами.
"""

from typing import List, Optional, Dict, Any
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_, func, desc
from sqlalchemy.orm import selectinload

from ..models.game import Game, GameRound, PlayerChoice, Vote, GameStatus
from ..models.user import User
from ..models.card import Card


class GameRepository:
    """Репозиторий для работы с играми."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def create_game(self, room_id: int) -> Game:
        """
        Создает новую игру.
        
        Args:
            room_id: ID комнаты
            
        Returns:
            Game: Созданная игра
        """
        game = Game(
            room_id=room_id,
            status=GameStatus.STARTING,
            current_round=1
        )
        self.db.add(game)
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        await self.db.refresh(game)
        return game
    
    async def get_game_by_id(self, game_id: int) -> Optional[Game]:
        """
        Получает игру по ID.
        
        Args:
            game_id: ID игры
            
        Returns:
            Optional[Game]: Игра или None
        """
        result = await self.db.execute(
            select(Game).where(Game.id == game_id)
        )
        return result.scalar_one_or_none()
    
    async def get_active_game_by_room(self, room_id: int) -> Optional[Game]:
        """
        Получает активную игру в комнате.
        
        Args:
            room_id: ID комнаты
            
        Returns:
            Optional[Game]: Активная игра или None
        """
        result = await self.db.execute(
            select(Game).where(
                and_(
                    Game.room_id == room_id,
                    Game.status.in_([GameStatus.STARTING, GameStatus.PLAYING, GameStatus.VOTING])
                )
            )
        )
        return result.scalar_one_or_none()
    
    async def update_game_status(self, game_id: int, status: GameStatus) -> Optional[Game]:
        """
        Обновляет статус игры.
        
        Args:
            game_id: ID игры
            status: Новый статус
            
        Returns:
            Optional[Game]: Обновленная игра или None
        """
        game = await self.get_game_by_id(game_id)
        if not game:
            return None
        
        game.status = status
        if status == GameStatus.FINISHED:
            game.finished_at = datetime.utcnow()
        
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        await self.db.refresh(game)
        return game
    
    async def update_current_round(self, game_id: int, round_number: int) -> Optional[Game]:
        """
        Обновляет текущий раунд игры.
        
        Args:
            game_id: ID игры
            round_number: Номер раунда
            
        Returns:
            Optional[Game]: Обновленная игра или None
        """
        game = await self.get_game_by_id(game_id)
        if not game:
            return None
        
        game.current_round = round_number
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        await self.db.refresh(game)
        return game
    
    async def set_game_winner(self, game_id: int, winner_id: int) -> Optional[Game]:
        """
        Устанавливает победителя игры.
        
        Args:
            game_id: ID игры
            winner_id: ID победителя
            
        Returns:
            Optional[Game]: Обновленная игра или None
        """
        game = await self.get_game_by_id(game_id)
        if not game:
            return None
        
        game.winner_id = winner_id
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        await self.db.refresh(game)
        return game
    
    async def get_games_by_room(self, room_id: int, limit: int = 10) -> List[Game]:
        """
        Получает игры в комнате.
        
        Args:
            room_id: ID комнаты
            limit: Максимальное количество игр
            
        Returns:
            List[Game]: Список игр
        """
        result = await self.db.execute(
            select(Game)
            .where(Game.room_id == room_id)
            .order_by(desc(Game.created_at))
            .limit(limit)
        )
        return result.scalars().all()
    
    async def get_user_games(self, user_id: int, limit: int = 20) -> List[Dict[str, Any]]:
        """
        Получает игры пользователя с деталями.
        
        Args:
            user_id: ID пользователя
            limit: Максимальное количество игр
            
        Returns:
            List[Dict]: Список игр с деталями
        """
        # Подзапрос для проверки участия пользователя
        from ..models.game import RoomParticipant
        
        result = await self.db.execute(
            select(Game, User.nickname.label('winner_nickname'))
            .outerjoin(User, Game.winner_id == User.id)
            .join(RoomParticipant, Game.room_id == RoomParticipant.room_id)
            .where(RoomParticipant.user_id == user_id)
            .order_by(desc(Game.created_at))
            .limit(limit)
        )
        
        games = []
        for game, winner_nickname in result:
            games.append({
                "id": game.id,
                "room_id": game.room_id,
                "status": game.status,
                "current_round": game.current_round,
                "winner_nickname": winner_nickname,
                "created_at": game.created_at,
                "finished_at": game.finished_at
            })
        
        return games


class GameRoundRepository:
    """Репозиторий для работы с игровыми раундами."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def create_round(
        self, 
        game_id: int, 
        round_number: int, 
        situation_text: str,
        duration_seconds: int = 50
    ) -> GameRound:
        """
        Создает новый раунд.
        
        Args:
            game_id: ID игры
            round_number: Номер раунда
            situation_text: Текст ситуации
            duration_seconds: Длительность раунда в секундах
            
        Returns:
            GameRound: Созданный раунд
        """
        round_obj = GameRound(
            game_id=game_id,
            round_number=round_number,
            situation_text=situation_text,
            duration_seconds=duration_seconds,
            started_at=datetime.utcnow()
        )
        self.db.add(round_obj)
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        await self.db.refresh(round_obj)
        return round_obj
    
    async def get_round_by_id(self, round_id: int) -> Optional[GameRound]:
        """
        Получает раунд по ID.
        
        Args:
            round_id: ID раунда
            
        Returns:
            Optional[GameRound]: Раунд или None
        """
        result = await self.db.execute(
            select(GameRound).where(GameRound.id == round_id)
        )
        return result.scalar_one_or_none()
    
    async def get_current_round(self, game_id: int) -> Optional[GameRound]:
        """
        Получает текущий раунд игры.
        
        Args:
            game_id: ID игры
            
        Returns:
            Optional[GameRound]: Текущий раунд или None
        """
        result = await self.db.execute(
            select(GameRound)
            .where(GameRound.game_id == game_id)
            .order_by(desc(GameRound.round_number))
            .limit(1)
        )
        return result.scalar_one_or_none()
    
    async def finish_round(self, round_id: int) -> Optional[GameRound]:
        """
        Завершает раунд.
        
        Args:
            round_id: ID раунда
            
        Returns:
            Optional[GameRound]: Завершенный раунд или None
        """
        round_obj = await self.get_round_by_id(round_id)
        if not round_obj:
            return None
        
        round_obj.finished_at = datetime.utcnow()
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        await self.db.refresh(round_obj)
        return round_obj
    
    async def get_rounds_by_game(self, game_id: int) -> List[GameRound]:
        """
        Получает все раунды игры.
        
        Args:
            game_id: ID игры
            
        Returns:
            List[GameRound]: Список раундов
        """
        result = await self.db.execute(
            select(GameRound)
            .where(GameRound.game_id == game_id)
            .order_by(GameRound.round_number)
        )
        return result.scalars().all()


class PlayerChoiceRepository:
    """Репозиторий для работы с выборами игроков."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def create_choice(
        self, 
        round_id: int, 
        user_id: int, 
        card_type: str, 
        card_number: int
    ) -> PlayerChoice:
        """
        Создает выбор карты игроком.
        
        Args:
            round_id: ID раунда
            user_id: ID игрока
            card_type: Тип карты
            card_number: Номер карты
            
        Returns:
            PlayerChoice: Созданный выбор
        """
        choice = PlayerChoice(
            round_id=round_id,
            user_id=user_id,
            card_type=card_type,
            card_number=card_number
        )
        self.db.add(choice)
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        await self.db.refresh(choice)
        return choice
    
    async def get_choice_by_user_and_round(
        self, 
        user_id: int, 
        round_id: int
    ) -> Optional[PlayerChoice]:
        """
        Получает выбор игрока в раунде.
        
        Args:
            user_id: ID игрока
            round_id: ID раунда
            
        Returns:
            Optional[PlayerChoice]: Выбор или None
        """
        result = await self.db.execute(
            select(PlayerChoice).where(
                and_(
                    PlayerChoice.user_id == user_id,
                    PlayerChoice.round_id == round_id
                )
            )
        )
        return result.scalar_one_or_none()
    
    async def get_choices_by_round(self, round_id: int) -> List[PlayerChoice]:
        """
        Получает все выборы в раунде.
        
        Args:
            round_id: ID раунда
            
        Returns:
            List[PlayerChoice]: Список выборов
        """
        result = await self.db.execute(
            select(PlayerChoice)
            .where(PlayerChoice.round_id == round_id)
            .order_by(PlayerChoice.submitted_at)
        )
        return result.scalars().all()
    
    async def get_choices_for_voting(self, round_id: int, exclude_user_id: int) -> List[PlayerChoice]:
        """
        Получает выборы для голосования (исключая определенного игрока).
        
        Args:
            round_id: ID раунда
            exclude_user_id: ID игрока для исключения
            
        Returns:
            List[PlayerChoice]: Список выборов для голосования
        """
        result = await self.db.execute(
            select(PlayerChoice)
            .where(
                and_(
                    PlayerChoice.round_id == round_id,
                    PlayerChoice.user_id != exclude_user_id
                )
            )
            .order_by(PlayerChoice.submitted_at)
        )
        return result.scalars().all()


class VoteRepository:
    """Репозиторий для работы с голосами."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def create_vote(self, round_id: int, voter_id: int, card_id: int) -> Vote:
        """
        Создает голос.
        
        Args:
            round_id: ID раунда
            voter_id: ID голосующего
            card_id: ID карты
            
        Returns:
            Vote: Созданный голос
        """
        vote = Vote(
            round_id=round_id,
            voter_id=voter_id,
            card_id=card_id
        )
        self.db.add(vote)
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        await self.db.refresh(vote)
        return vote
    
    async def get_vote_by_user_and_round(
        self, 
        voter_id: int, 
        round_id: int
    ) -> Optional[Vote]:
        """
        Получает голос пользователя в раунде.
        
        Args:
            voter_id: ID голосующего
            round_id: ID раунда
            
        Returns:
            Optional[Vote]: Голос или None
        """
        result = await self.db.execute(
            select(Vote).where(
                and_(
                    Vote.voter_id == voter_id,
                    Vote.round_id == round_id
                )
            )
        )
        return result.scalar_one_or_none()
    
    async def get_votes_by_round(self, round_id: int) -> List[Vote]:
        """
        Получает все голоса в раунде.
        
        Args:
            round_id: ID раунда
            
        Returns:
            List[Vote]: Список голосов
        """
        result = await self.db.execute(
            select(Vote)
            .where(Vote.round_id == round_id)
            .order_by(Vote.created_at)
        )
        return result.scalars().all()
    
    async def get_vote_counts_by_round(self, round_id: int) -> List[Dict[str, Any]]:
        """
        Получает количество голосов по картам в раунде.
        
        Args:
            round_id: ID раунда
            
        Returns:
            List[Dict]: Список с количеством голосов
        """
        result = await self.db.execute(
            select(
                Vote.card_id,
                func.count(Vote.id).label('vote_count')
            )
            .where(Vote.round_id == round_id)
            .group_by(Vote.card_id)
            .order_by(desc(func.count(Vote.id)))
        )
        
        return [
            {"card_id": card_id, "vote_count": vote_count}
            for card_id, vote_count in result
        ] 