"""
Репозиторий для работы с пользователями.
Содержит методы для CRUD операций с пользователями.
"""

from typing import Optional, List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, desc
from ..models.user import User
from ..schemas.user import UserCreate, UserUpdate, UserProfileCreate


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
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
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
    
    async def get_by_device_id(self, device_id: str) -> Optional[User]:
        """
        Получает пользователя по Device ID.
        
        Args:
            device_id: Device ID пользователя
            
        Returns:
            Optional[User]: Пользователь или None
        """
        result = await self.db.execute(
            select(User).where(User.device_id == device_id)
        )
        return result.scalar_one_or_none()
    
    async def get_or_create_by_device_id(self, device_id: str) -> User:
        """
        Получает пользователя по Device ID или создает нового.
        
        Args:
            device_id: Device ID пользователя
            
        Returns:
            User: Пользователь (существующий или новый)
        """
        user = await self.get_by_device_id(device_id)
        if user:
            return user
        
        # Создаем нового пользователя
        user = User(device_id=device_id)
        self.db.add(user)
        await self.db.flush()
        await self.db.refresh(user)
        return user
    
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
    
    async def get_by_game_center_id(self, game_center_player_id: str) -> Optional[User]:
        """
        Получает пользователя по Game Center Player ID.
        
        Args:
            game_center_player_id: Game Center Player ID
            
        Returns:
            Optional[User]: Пользователь или None
        """
        result = await self.db.execute(
            select(User).where(User.game_center_player_id == game_center_player_id)
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
        
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        await self.db.refresh(user)
        return user
    
    async def complete_profile(self, user_id: int, profile_data: UserProfileCreate) -> Optional[User]:
        """
        Заполняет профиль пользователя.
        
        Args:
            user_id: ID пользователя
            profile_data: Данные профиля
            
        Returns:
            Optional[User]: Обновленный пользователь или None
        """
        user = await self.get_by_id(user_id)
        if not user:
            return None
        
        # Обновляем поля профиля
        user.nickname = profile_data.nickname
        user.birth_date = profile_data.birth_date
        user.gender = profile_data.gender
        
        await self.db.flush()
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        await self.db.refresh(user)
        return user
    
    async def get_leaderboard(self, limit: int = 100) -> List[Dict[str, Any]]:
        """
        Получает топ пользователей по рейтингу.
        
        Args:
            limit: Максимальное количество пользователей
            
        Returns:
            List[Dict[str, Any]]: Список пользователей с рейтингом
        """
        result = await self.db.execute(
            select(User)
            .order_by(desc(User.rating))
            .limit(limit)
        )
        users = result.scalars().all()
        
        leaderboard = []
        for i, user in enumerate(users, 1):
            leaderboard.append({
                "rank": i,
                "user_id": user.id,
                "nickname": user.nickname,
                "rating": user.rating,
                "created_at": user.created_at.isoformat() if user.created_at else None
            })
        
        return leaderboard
    
    async def get_user_rank(self, user_id: int) -> Optional[int]:
        """
        Получает позицию пользователя в рейтинге.
        
        Args:
            user_id: ID пользователя
            
        Returns:
            Optional[int]: Позиция в рейтинге или None
        """
        # Подзапрос для получения рейтинга пользователя
        user_rating_subquery = (
            select(User.rating)
            .where(User.id == user_id)
            .scalar_subquery()
        )
        
        # Основной запрос для подсчета пользователей с более высоким рейтингом
        result = await self.db.execute(
            select(func.count(User.id))
            .where(User.rating > user_rating_subquery)
        )
        
        rank = result.scalar()
        return rank + 1 if rank is not None else None
    
    async def update_rating(self, user_id: int, rating_change: int) -> Optional[User]:
        """
        Обновляет рейтинг пользователя.
        
        Args:
            user_id: ID пользователя
            rating_change: Изменение рейтинга
            
        Returns:
            Optional[User]: Обновленный пользователь или None
        """
        user = await self.get_by_id(user_id)
        if not user:
            return None
        
        user.rating += rating_change
        if user.rating < 0:
            user.rating = 0
        
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        await self.db.refresh(user)
        return user
    
    async def get_all(self, limit: int = 100, offset: int = 0) -> List[User]:
        """
        Получает всех пользователей с пагинацией.
        
        Args:
            limit: Максимальное количество пользователей
            offset: Смещение для пагинации
            
        Returns:
            List[User]: Список пользователей
        """
        query = select(User).order_by(User.created_at.desc()).limit(limit).offset(offset)
        result = await self.db.execute(query)
        return result.scalars().all()
    
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
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        return True
    
    async def get_total_count(self) -> int:
        """
        Получает общее количество пользователей.
        
        Returns:
            int: Общее количество пользователей
        """
        result = await self.db.execute(select(func.count(User.id)))
        return result.scalar()
    
    async def get_top_players(self, limit: int = 100) -> List[User]:
        """
        Получает топ пользователей по рейтингу.
        
        Args:
            limit: Максимальное количество пользователей
            
        Returns:
            List[User]: Список пользователей отсортированных по рейтингу
        """
        result = await self.db.execute(
            select(User)
            .order_by(desc(User.rating))
            .limit(limit)
        )
        return result.scalars().all()
