"""
Сервис для работы с пользователями.
Содержит бизнес-логику для управления пользователями.
"""

from typing import Optional, List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from ..repositories.user_repository import UserRepository
from ..repositories.card_repository import CardRepository
from ..models.user import User, UserCard
from ..models.card import CardType
from ..schemas.user import UserCreate, UserUpdate, UserResponse, UserProfileResponse, UserProfileCreate
from ..utils.exceptions import UserNotFoundError, DuplicateNicknameError, ValidationError
from ..external.azure_client import azure_service


class UserService:
    """Сервис для работы с пользователями"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.user_repo = UserRepository(db)
        self.card_repo = CardRepository(db)
    
    async def create_user_profile(self, user_data: UserCreate) -> UserResponse:
        """
        Создает профиль пользователя.
        
        Args:
            user_data: Данные для создания пользователя
            
        Returns:
            UserResponse: Созданный пользователь
            
        Raises:
            DuplicateNicknameError: Если никнейм уже занят
            ValidationError: Если данные невалидны
        """
        # Проверяем уникальность никнейма
        existing_user = await self.user_repo.get_by_nickname(user_data.nickname)
        if existing_user:
            raise DuplicateNicknameError(f"Никнейм '{user_data.nickname}' уже занят")
        
        # Создаем пользователя
        user = await self.user_repo.create(user_data)
        
        # Выдаем стартовые карты
        await self.assign_starter_cards(user.id)
        
        return UserResponse.model_validate(user)
    
    async def complete_user_profile(self, user_id: int, profile_data: UserProfileCreate) -> UserResponse:
        """
        Заполняет профиль пользователя (никнейм, дата рождения, пол).
        
        Args:
            user_id: ID пользователя
            profile_data: Данные профиля
            
        Returns:
            UserResponse: Обновленный пользователь
            
        Raises:
            UserNotFoundError: Если пользователь не найден
            ValidationError: Если профиль уже заполнен или данные невалидны
        """
        user = await self.user_repo.complete_profile(user_id, profile_data)
        if not user:
            raise UserNotFoundError(f"Пользователь с ID {user_id} не найден")
        
        return UserResponse.from_orm_with_age(user)
    
    async def get_user_profile(self, user_id: int) -> UserProfileResponse:
        """
        Получает профиль пользователя с дополнительной информацией.
        
        Args:
            user_id: ID пользователя
            
        Returns:
            UserProfileResponse: Профиль пользователя
            
        Raises:
            UserNotFoundError: Если пользователь не найден
        """
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise UserNotFoundError(f"Пользователь с ID {user_id} не найден")
        
        # Получаем статистику карт пользователя
        user_cards = await self.card_repo.get_user_cards(user_id)
        cards_count = len(user_cards)
        
        # Получаем позицию в рейтинге
        rank = await self.user_repo.get_user_rank(user_id)
        
        return UserProfileResponse(
            id=user.id,
            game_center_player_id=user.game_center_player_id,
            nickname=user.nickname,
            birth_date=user.birth_date,
            gender=user.gender,
            rating=user.rating,
            created_at=user.created_at,
            age=user.age,
            cards_count=cards_count,
            rank=rank or 0
        )
    
    async def get_user_by_game_center_id(self, player_id: str) -> Optional[UserResponse]:
        """
        Получает пользователя по Game Center Player ID.
        
        Args:
            player_id: Game Center Player ID
            
        Returns:
            Optional[UserResponse]: Пользователь или None
        """
        user = await self.user_repo.get_by_game_center_id(player_id)
        if not user:
            return None
        
        return UserResponse.model_validate(user)
    
    async def update_user_profile(self, user_id: int, user_data: UserUpdate) -> UserResponse:
        """
        Обновляет профиль пользователя.
        
        Args:
            user_id: ID пользователя
            user_data: Новые данные пользователя
            
        Returns:
            UserResponse: Обновленный пользователь
            
        Raises:
            UserNotFoundError: Если пользователь не найден
            DuplicateNicknameError: Если никнейм уже занят
        """
        # Проверяем существование пользователя
        existing_user = await self.user_repo.get_by_id(user_id)
        if not existing_user:
            raise UserNotFoundError(f"Пользователь с ID {user_id} не найден")
        
        # Проверяем уникальность никнейма, если он изменяется
        if user_data.nickname and user_data.nickname != existing_user.nickname:
            nickname_user = await self.user_repo.get_by_nickname(user_data.nickname)
            if nickname_user:
                raise DuplicateNicknameError(f"Никнейм '{user_data.nickname}' уже занят")
        
        # Обновляем пользователя
        updated_user = await self.user_repo.update(user_id, user_data)
        return UserResponse.model_validate(updated_user)
    
    async def assign_starter_cards(self, user_id: int, count: int = 10) -> Dict[str, Any]:
        """
        Выдает стартовые карты пользователю из Azure (гибридный подход).
        
        Args:
            user_id: ID пользователя
            count: количество карт для выдачи (по умолчанию 10)
            
        Returns:
            Dict с информацией о выданных картах
        """
        import random
        
        # Проверяем что пользователь существует
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise UserNotFoundError(f"Пользователь с ID {user_id} не найден")
        
        # Проверяем, не получал ли уже стартовые карты
        existing_cards = await self.db.execute(
            select(UserCard).where(
                UserCard.user_id == user_id,
                UserCard.card_type == "starter"
            )
        )
        if existing_cards.scalars().first():
            raise ValidationError("Пользователь уже получил стартовые карты")
        
        # Получаем доступные стартовые карты из Azure с деталями
        azure_starter_cards = await azure_service.list_cards_in_folder_with_details("starter")
        if len(azure_starter_cards) < count:
            raise ValidationError(f"В Azure недостаточно стартовых карт. Доступно: {len(azure_starter_cards)}, требуется: {count}")
        
        # Выбираем случайные карты
        selected_cards = random.sample(azure_starter_cards, count)
        
        # Добавляем в базу данных
        assigned_cards = []
        for card in selected_cards:
            card_number = card["card_number"]
            card_url = card["url"]
            
            user_card = UserCard(
                user_id=user_id,
                card_type="starter",
                card_number=card_number
            )
            self.db.add(user_card)
            assigned_cards.append({
                "card_type": "starter",
                "card_number": card_number,
                "card_url": card_url,
                "card_name": card["card_name"]
            })
        
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        
        return {
            "success": True,
            "message": f"Выдано {count} стартовых карт",
            "assigned_cards": assigned_cards,
            "total_cards": count
        }
    
    async def get_user_cards(self, user_id: int) -> Dict[str, Any]:
        """
        Получает все карты пользователя с изображениями из Azure.
        
        Args:
            user_id: ID пользователя
            
        Returns:
            Dict с картами, сгруппированными по типам
        """
        # Проверяем что пользователь существует
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise UserNotFoundError(f"Пользователь с ID {user_id} не найден")
        
        # Получаем карты пользователя из БД
        result = await self.db.execute(
            select(UserCard).where(UserCard.user_id == user_id)
        )
        user_cards = result.scalars().all()
        
        # Группируем по типам и обогащаем данными из Azure
        grouped_cards = {
            "starter_cards": [],
            "standard_cards": [],
            "unique_cards": [],
            "total_cards": len(user_cards)
        }
        
        # Получаем данные из Azure для каждого типа
        azure_cards_cache = {}
        for card_type in ["starter", "standard", "unique"]:
            azure_cards_cache[card_type] = await azure_service.list_cards_in_folder_with_details(card_type)
        
        # Обогащаем карты пользователя данными из Azure
        for user_card in user_cards:
            azure_cards = azure_cards_cache.get(user_card.card_type, [])
            
            # Находим соответствующую карту в Azure
            azure_card = next(
                (card for card in azure_cards if card["card_number"] == user_card.card_number),
                None
            )
            
            card_data = {
                "user_id": user_card.user_id,
                "card_type": user_card.card_type,
                "card_number": user_card.card_number,
                "obtained_at": user_card.obtained_at,
                "card_url": azure_card["url"] if azure_card else None
            }
            
            # Добавляем в соответствующую группу
            if user_card.card_type == "starter":
                grouped_cards["starter_cards"].append(card_data)
            elif user_card.card_type == "standard":
                grouped_cards["standard_cards"].append(card_data)
            elif user_card.card_type == "unique":
                grouped_cards["unique_cards"].append(card_data)
        
        return grouped_cards
    
    async def get_user_cards_for_game(self, user_id: int, count: int = 3) -> List[Dict[str, Any]]:
        """
        Получает случайные карты пользователя для игрового раунда.
        
        Args:
            user_id: ID пользователя
            count: количество карт для раунда
            
        Returns:
            List карт с изображениями из Azure
        """
        import random
        
        # Получаем все карты пользователя
        result = await self.db.execute(
            select(UserCard).where(UserCard.user_id == user_id)
        )
        user_cards = result.scalars().all()
        
        if len(user_cards) < count:
            raise ValidationError(f"У пользователя недостаточно карт для игры. Есть: {len(user_cards)}, нужно: {count}")
        
        # Выбираем случайные карты
        selected_cards = random.sample(list(user_cards), count)
        
        # Обогащаем данными из Azure
        cards_for_game = []
        for user_card in selected_cards:
            azure_cards = await azure_service.list_cards_in_folder_with_details(user_card.card_type)
            azure_card = next(
                (card for card in azure_cards if card["card_number"] == user_card.card_number),
                None
            )
            
            cards_for_game.append({
                "user_id": user_card.user_id,
                "card_type": user_card.card_type,
                "card_number": user_card.card_number,

                "card_url": azure_card["url"] if azure_card else None
            })
        
        return cards_for_game
    
    async def update_user_rating(self, user_id: int, rating_change: int) -> UserResponse:
        """
        Обновляет рейтинг пользователя.
        
        Args:
            user_id: ID пользователя
            rating_change: Изменение рейтинга (может быть отрицательным)
            
        Returns:
            UserResponse: Пользователь с обновленным рейтингом
            
        Raises:
            UserNotFoundError: Если пользователь не найден
        """
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise UserNotFoundError(f"Пользователь с ID {user_id} не найден")
        
        new_rating = max(0, user.rating + rating_change)  # Рейтинг не может быть отрицательным
        
        updated_user = await self.user_repo.update_rating(user_id, new_rating)
        return UserResponse.model_validate(updated_user)
    
    async def get_leaderboard(self, limit: int = 100) -> List[dict]:
        """
        Получает топ игроков по рейтингу.
        
        Args:
            limit: Количество игроков (по умолчанию 100)
            
        Returns:
            List[dict]: Список лучших игроков
        """
        top_players = await self.user_repo.get_top_players(limit)
        
        return [
            {
                "rank": idx + 1,
                "id": player.id,
                "nickname": player.nickname,
                "rating": player.rating,
                "age": player.age
            }
            for idx, player in enumerate(top_players)
        ]
    
    async def get_user_rank(self, user_id: int) -> Optional[int]:
        """
        Получает позицию пользователя в рейтинге.
        
        Args:
            user_id: ID пользователя
            
        Returns:
            Optional[int]: Позиция в рейтинге или None
        """
        return await self.user_repo.get_user_rank(user_id)
    
    async def get_user_by_id(self, user_id: int) -> Optional[User]:
        """
        Получает пользователя по ID.
        
        Args:
            user_id: ID пользователя
            
        Returns:
            Optional[User]: Пользователь или None
        """
        return await self.user_repo.get_by_id(user_id)
    
    async def get_user_stats(self, user_id: int) -> Dict[str, Any]:
        """
        Получает статистику пользователя.
        
        Args:
            user_id: ID пользователя
            
        Returns:
            Dict[str, Any]: Статистика пользователя
        """
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise UserNotFoundError(f"Пользователь с ID {user_id} не найден")
        
        # Получаем карты пользователя
        user_cards = await self.card_repo.get_user_cards(user_id)
        cards_count = len(user_cards)
        
        # Получаем позицию в рейтинге
        rank = await self.user_repo.get_user_rank(user_id)
        
        # Базовая статистика
        stats = {
            "total_cards": cards_count,
            "rating": user.rating,
            "rank": rank or 0,
            "profile_complete": user.is_profile_complete,
            "created_at": user.created_at.isoformat() if user.created_at else None
        }
        
        return stats
    
    async def check_nickname_availability(self, nickname: str) -> bool:
        """
        Проверяет доступность никнейма.
        
        Args:
            nickname: Никнейм для проверки
            
        Returns:
            bool: True если доступен, False если занят
        """
        existing_user = await self.user_repo.get_by_nickname(nickname)
        return existing_user is None 