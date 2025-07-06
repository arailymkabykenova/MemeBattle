"""
Репозиторий для работы с карточками.
Содержит методы для CRUD операций с карточками.
"""

from typing import Optional, List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_
from ..models.card import Card, CardType
from ..models.user import UserCard
from ..schemas.card import CardCreate, CardUpdate
import random


class CardRepository:
    """Репозиторий для работы с карточками"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def create(self, card_data: CardCreate) -> Card:
        """
        Создает новую карточку.
        
        Args:
            card_data: Данные для создания карточки
            
        Returns:
            Card: Созданная карточка
        """
        card = Card(**card_data.model_dump())
        self.db.add(card)
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        await self.db.refresh(card)
        return card
    
    async def get_by_id(self, card_id: int) -> Optional[Card]:
        """
        Получает карточку по ID.
        
        Args:
            card_id: ID карточки
            
        Returns:
            Optional[Card]: Карточка или None
        """
        result = await self.db.execute(
            select(Card).where(Card.id == card_id)
        )
        return result.scalar_one_or_none()
    
    async def get_by_azure_path(self, azure_path: str) -> Optional[Card]:
        """
        Получает карточку по пути в Azure Blob Storage.
        
        Args:
            azure_path: Путь к файлу в Azure
            
        Returns:
            Optional[Card]: Карточка или None
        """
        result = await self.db.execute(
            select(Card).where(Card.azure_blob_path == azure_path)
        )
        return result.scalar_one_or_none()
    
    async def get_all(self, limit: int = 100, offset: int = 0) -> List[Card]:
        """
        Получает все карточки с пагинацией.
        
        Args:
            limit: Максимальное количество карточек
            offset: Смещение для пагинации
            
        Returns:
            List[Card]: Список карточек
        """
        query = select(Card).order_by(Card.created_at.desc()).limit(limit).offset(offset)
        result = await self.db.execute(query)
        return result.scalars().all()
    
    async def get_by_type(self, card_type: CardType, limit: Optional[int] = None) -> List[Card]:
        """
        Получает карточки по типу.
        
        Args:
            card_type: Тип карточки
            limit: Максимальное количество карточек
            
        Returns:
            List[Card]: Список карточек
        """
        query = select(Card).where(Card.card_type == card_type)
        
        if limit:
            query = query.limit(limit)
        
        result = await self.db.execute(query)
        return result.scalars().all()
    
    async def get_random_cards(self, card_type: CardType, count: int) -> List[Card]:
        """
        Получает случайные карточки определенного типа.
        
        Args:
            card_type: Тип карточки
            count: Количество карточек
            
        Returns:
            List[Card]: Список случайных карточек
        """
        result = await self.db.execute(
            select(Card)
            .where(Card.card_type == card_type)
            .order_by(func.random())
            .limit(count)
        )
        return result.scalars().all()
    
    async def get_user_cards(self, user_id: int) -> List[Dict[str, Any]]:
        """
        Получает все карточки пользователя (гибридный подход).
        
        Args:
            user_id: ID пользователя
            
        Returns:
            List[Dict[str, Any]]: Список карточек пользователя с данными из Azure
        """
        result = await self.db.execute(
            select(UserCard)
            .where(UserCard.user_id == user_id)
            .order_by(UserCard.obtained_at.desc())
        )
        user_cards = result.scalars().all()
        
        # Обогащаем данными из Azure
        cards_data = []
        for user_card in user_cards:
            cards_data.append({
                "user_id": user_card.user_id,
                "card_type": user_card.card_type,
                "card_number": user_card.card_number,
                "obtained_at": user_card.obtained_at
            })
        
        return cards_data
    
    async def get_user_cards_by_type(self, user_id: int, card_type: CardType) -> List[Card]:
        """
        Получает карточки пользователя определенного типа.
        
        Args:
            user_id: ID пользователя
            card_type: Тип карточки
            
        Returns:
            List[Card]: Список карточек пользователя определенного типа
        """
        result = await self.db.execute(
            select(Card)
            .select_from(UserCard)
            .join(Card, UserCard.card_id == Card.id)
            .where(
                and_(
                    UserCard.user_id == user_id,
                    Card.card_type == card_type
                )
            )
            .order_by(UserCard.obtained_at.desc())
        )
        return result.scalars().all()
    
    async def assign_card_to_user(self, user_id: int, card_type: str, card_number: int) -> UserCard:
        """
        Присваивает карточку пользователю (гибридный подход).
        
        Args:
            user_id: ID пользователя
            card_type: Тип карточки (starter, standard, unique)
            card_number: Номер карточки в Azure папке
            
        Returns:
            UserCard: Связь пользователя и карточки
        """
        user_card = UserCard(user_id=user_id, card_type=card_type, card_number=card_number)
        self.db.add(user_card)
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        await self.db.refresh(user_card)
        return user_card
    
    async def assign_multiple_cards_to_user(self, user_id: int, cards_data: List[Dict[str, Any]]) -> List[UserCard]:
        """
        Присваивает несколько карточек пользователю (гибридный подход).
        
        Args:
            user_id: ID пользователя
            cards_data: Список словарей с card_type и card_number
            
        Returns:
            List[UserCard]: Список связей пользователя и карточек
        """
        user_cards = []
        for card_data in cards_data:
            user_card = UserCard(
                user_id=user_id, 
                card_type=card_data["card_type"], 
                card_number=card_data["card_number"]
            )
            self.db.add(user_card)
            user_cards.append(user_card)
        
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        for user_card in user_cards:
            await self.db.refresh(user_card)
        
        return user_cards
    
    async def user_has_card(self, user_id: int, card_id: int) -> bool:
        """
        Проверяет, есть ли у пользователя карточка.
        
        Args:
            user_id: ID пользователя
            card_id: ID карточки
            
        Returns:
            bool: True если карточка есть, False если нет
        """
        result = await self.db.execute(
            select(UserCard).where(
                and_(
                    UserCard.user_id == user_id,
                    UserCard.card_id == card_id
                )
            )
        )
        return result.scalar_one_or_none() is not None
    
    async def get_cards_for_round(self, user_id: int, count: int = 3) -> List[Card]:
        """
        Получает карточки пользователя для раунда игры.
        
        Args:
            user_id: ID пользователя
            count: Количество карточек (по умолчанию 3)
            
        Returns:
            List[Card]: Список карточек для игры
        """
        user_cards = await self.get_user_cards(user_id)
        if len(user_cards) < count:
            return user_cards
        
        return random.sample(user_cards, count)
    
    async def update(self, card_id: int, card_data: CardUpdate) -> Optional[Card]:
        """
        Обновляет данные карточки.
        
        Args:
            card_id: ID карточки
            card_data: Новые данные карточки
            
        Returns:
            Optional[Card]: Обновленная карточка или None
        """
        card = await self.get_by_id(card_id)
        if not card:
            return None
        
        update_data = card_data.model_dump(exclude_unset=True)
        for field, value in update_data.items():
            setattr(card, field, value)
        
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        await self.db.refresh(card)
        return card
    
    async def delete(self, card_id: int) -> bool:
        """
        Удаляет карточку.
        
        Args:
            card_id: ID карточки
            
        Returns:
            bool: True если удалена, False если не найдена
        """
        card = await self.get_by_id(card_id)
        if not card:
            return False
        
        await self.db.delete(card)
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        return True
    
    async def get_total_count(self) -> int:
        """
        Получает общее количество карточек.
        
        Returns:
            int: Общее количество карточек
        """
        result = await self.db.execute(select(func.count(Card.id)))
        return result.scalar()
    
    async def get_count_by_type(self, card_type: CardType) -> int:
        """
        Получает количество карточек определенного типа.
        
        Args:
            card_type: Тип карточки
            
        Returns:
            int: Количество карточек данного типа
        """
        result = await self.db.execute(
            select(func.count(Card.id)).where(Card.card_type == card_type)
        )
        return result.scalar() 