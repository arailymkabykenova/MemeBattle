"""
Репозиторий для работы с пользователями.
Содержит методы для CRUD операций с пользователями.
"""

from typing import Optional, List
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_
from ..models.user import User
from ..schemas.user import UserCreate, UserUpdate


class UserRepository:
    """Репозиторий для работы с пользователями"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def create(self, user_data: UserCreate) -> User:
        """
        Создает нового пользователя.
        
        Args:
            user_data: Данные для создания пользователя
            
        Returns:
            User: Созданный пользователь
        """
        user = User(**user_data.model_dump())
        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)
        return user
    
    async def get_by_id(self, user_id: int) -> Optional[User]:
        """
        Получает пользователя по ID.
        
        Args:
            user_id: ID пользователя
            
        Returns:
            Optional[User]: Пользователь или None
        """
        result = await self.db.execute(
            select(User).where(User.id == user_id)
        )
        return result.scalar_one_or_none()
    
    async def get_by_game_center_id(self, player_id: str) -> Optional[User]:
        """
        Получает пользователя по Game Center Player ID.
        
        Args:
            player_id: Game Center Player ID пользователя
            
        Returns:
            Optional[User]: Пользователь или None
        """
        result = await self.db.execute(
            select(User).where(User.game_center_player_id == player_id)
        )
        return result.scalar_one_or_none()
    
    async def get_by_nickname(self, nickname: str) -> Optional[User]:
        """
        Получает пользователя по никнейму.
        
        Args:
            nickname: Никнейм пользователя
            
        Returns:
            Optional[User]: Пользователь или None
        """
        result = await self.db.execute(
            select(User).where(User.nickname == nickname)
        )
        return result.scalar_one_or_none()
    
    async def update(self, user_id: int, user_data: UserUpdate) -> Optional[User]:
        """
        Обновляет данные пользователя.
        
        Args:
            user_id: ID пользователя
            user_data: Новые данные пользователя
            
        Returns:
            Optional[User]: Обновленный пользователь или None
        """
        user = await self.get_by_id(user_id)
        if not user:
            return None
        
        update_data = user_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(user, field, value)
        
        await self.db.commit()
        await self.db.refresh(user)
        return user
    
    async def update_rating(self, user_id: int, new_rating: int) -> Optional[User]:
        """
        Обновляет рейтинг пользователя.
        
        Args:
            user_id: ID пользователя
            new_rating: Новый рейтинг
            
        Returns:
            Optional[User]: Обновленный пользователь или None
        """
        user = await self.get_by_id(user_id)
        if not user:
            return None
        
        user.rating = new_rating
        await self.db.commit()
        await self.db.refresh(user)
        return user
    
    async def get_top_players(self, limit: int = 100) -> List[User]:
        """
        Получает топ игроков по рейтингу.
        
        Args:
            limit: Количество игроков (по умолчанию 100)
            
        Returns:
            List[User]: Список лучших игроков
        """
        result = await self.db.execute(
            select(User)
            .order_by(User.rating.desc())
            .limit(limit)
        )
        return result.scalars().all()
    
    async def get_user_rank(self, user_id: int) -> Optional[int]:
        """
        Получает позицию пользователя в рейтинге.
        
        Args:
            user_id: ID пользователя
            
        Returns:
            Optional[int]: Позиция в рейтинге или None
        """
        user = await self.get_by_id(user_id)
        if not user:
            return None
        
        result = await self.db.execute(
            select(User)
            .where(User.rating > user.rating)
        )
        higher_rated_count = len(result.scalars().all())
        return higher_rated_count + 1
    
    async def delete(self, user_id: int) -> bool:
        """
        Удаляет пользователя.
        
        Args:
            user_id: ID пользователя
            
        Returns:
            bool: True если удален, False если не найден
        """
        user = await self.get_by_id(user_id)
        if not user:
            return False
        
        await self.db.delete(user)
        await self.db.commit()
        return True 