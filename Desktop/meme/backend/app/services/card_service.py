"""
Сервис для работы с карточками.
Управляет выдачей карт, стартовыми наборами и игровой логикой карт.
"""

import random
from typing import List, Optional, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, not_

from ..repositories.card_repository import CardRepository
from ..repositories.user_repository import UserRepository
from ..models.card import Card, CardType
from ..schemas.card import CardCreate, CardResponse, CardListResponse
from ..utils.exceptions import ValidationError, UserNotFoundError, NotFoundError
from ..external.azure_client import azure_service, AzureBlobService
from ..models.user import UserCard


class CardService:
    """Сервис для работы с карточками"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.card_repo = CardRepository(db)
        self.user_repo = UserRepository(db)
        self.azure_service = None
        
        # Инициализируем Azure сервис если возможно
        try:
            self.azure_service = AzureBlobService()
        except Exception:
            # Azure SDK может быть не установлен
            pass
    
    async def create_starter_cards_batch(self, cards_data: List[Dict[str, Any]]) -> List[CardResponse]:
        """
        Создает пакет стартовых карт (для первоначального наполнения).
        
        Args:
            cards_data: Список данных карт для создания
            
        Returns:
            List[CardResponse]: Созданные карты
        """
        created_cards = []
        
        for card_data in cards_data:
            card = CardCreate(
                name=card_data["name"],
                image_url=card_data.get("image_url", f"https://placeholder.example.com/{card_data['name']}.jpg"),
                card_type=CardType.STARTER,
                description=card_data.get("description", ""),
                azure_blob_path=card_data.get("azure_blob_path")
            )
            
            created_card = await self.card_repo.create(card)
            created_cards.append(CardResponse.model_validate(created_card))
        
        return created_cards
    
    async def get_all_cards(self, limit: int = 100, offset: int = 0) -> CardListResponse:
        """
        Получает список всех карт с пагинацией.
        
        Args:
            limit: Максимальное количество карт
            offset: Смещение для пагинации
            
        Returns:
            CardListResponse: Список карт с метаданными
        """
        cards = await self.card_repo.get_all(limit=limit, offset=offset)
        total_count = await self.card_repo.get_total_count()
        
        return CardListResponse(
            cards=[CardResponse.model_validate(card) for card in cards],
            total=total_count,
            limit=limit,
            offset=offset,
            has_more=offset + len(cards) < total_count
        )
    
    async def get_cards_by_type(self, card_type: CardType, limit: int = 50) -> List[CardResponse]:
        """
        Получает карты определенного типа.
        
        Args:
            card_type: Тип карт
            limit: Максимальное количество
            
        Returns:
            List[CardResponse]: Список карт указанного типа
        """
        cards = await self.card_repo.get_by_type(card_type, limit=limit)
        return [CardResponse.model_validate(card) for card in cards]
    
    async def assign_starter_cards_to_user(self, user_id: int, count: int = 10) -> Dict[str, Any]:
        """
        Выдает стартовые карты новому пользователю.
        
        Args:
            user_id: ID пользователя
            count: Количество карт (по умолчанию 10)
            
        Returns:
            Dict[str, Any]: Информация о выданных картах
            
        Raises:
            UserNotFoundError: Если пользователь не найден
            ValidationError: Если недостаточно стартовых карт
        """
        # Проверяем существование пользователя
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise UserNotFoundError(f"Пользователь с ID {user_id} не найден")
        
        # Проверяем не выданы ли уже стартовые карты
        user_cards = await self.card_repo.get_user_cards(user_id)
        if user_cards:
            raise ValidationError("Пользователю уже выданы карты")
        
        # Получаем случайные стартовые карты
        starter_cards = await self.card_repo.get_random_cards(CardType.STARTER, count)
        
        if len(starter_cards) < count:
            raise ValidationError(
                f"Недостаточно стартовых карт в системе. "
                f"Доступно: {len(starter_cards)}, требуется: {count}"
            )
        
        # Присваиваем карты пользователю (гибридный подход)
        cards_data = []
        for card in starter_cards:
            # Извлекаем номер карты из Azure пути или используем ID как fallback
            card_number = getattr(card, 'card_number', card.id)
            cards_data.append({
                "card_type": "starter",
                "card_number": card_number
            })
        
        await self.card_repo.assign_multiple_cards_to_user(user_id, cards_data)
        
        return {
            "message": f"Выдано {len(cards_data)} стартовых карт",
            "cards_assigned": len(cards_data),
            "cards": [CardResponse.model_validate(card) for card in starter_cards]
        }
    
    async def award_card_to_winner(self, user_id: int, card_type: CardType = CardType.STANDARD) -> CardResponse:
        """
        Выдает карту победителю игры.
        
        Args:
            user_id: ID пользователя-победителя
            card_type: Тип карты для выдачи
            
        Returns:
            CardResponse: Выданная карта
            
        Raises:
            UserNotFoundError: Если пользователь не найден
            ValidationError: Если нет доступных карт для выдачи
        """
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise UserNotFoundError(f"Пользователь с ID {user_id} не найден")
        
        # Получаем случайную карту указанного типа
        available_cards = await self.card_repo.get_random_cards(card_type, 1)
        
        if not available_cards:
            raise ValidationError(f"Нет доступных карт типа {card_type.value}")
        
        card = available_cards[0]
        
        # Присваиваем карту пользователю (гибридный подход)
        card_number = getattr(card, 'card_number', card.id)
        await self.card_repo.assign_card_to_user(user_id, card.card_type.value, card_number)
        
        return CardResponse.model_validate(card)
    
    async def get_user_cards(self, user_id: int) -> Dict[str, Any]:
        """
        Получает все карты пользователя с группировкой по типам.
        
        Args:
            user_id: ID пользователя
            
        Returns:
            Dict[str, Any]: Карты пользователя, сгруппированные по типам
            
        Raises:
            UserNotFoundError: Если пользователь не найден
        """
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise UserNotFoundError(f"Пользователь с ID {user_id} не найден")
        
        user_cards = await self.card_repo.get_user_cards(user_id)
        
        # Группируем карты по типам
        grouped_cards = {
            "starter": [],
            "standard": [],
            "unique": []
        }
        
        for card_data in user_cards:
            # Создаем простую структуру карты для гибридного подхода
            card_info = {
                "id": f"{card_data['card_type']}_{card_data['card_number']}",
                "name": f"{card_data['card_type'].title()} Card {card_data['card_number']}",
                "image_url": f"azure://{card_data['card_type']}/{card_data['card_number']}.jpg",
                "card_type": card_data['card_type'],
                "description": f"{card_data['card_type'].title()} card number {card_data['card_number']}",
                "created_at": card_data['obtained_at'],
                "is_starter_card": card_data['card_type'] == 'starter',
                "is_standard_card": card_data['card_type'] == 'standard',
                "is_unique_card": card_data['card_type'] == 'unique'
            }
            grouped_cards[card_data['card_type']].append(card_info)
        
        return {
            "user_id": user_id,
            "total_cards": len(user_cards),
            "cards_by_type": grouped_cards,
            "statistics": {
                "starter_count": len(grouped_cards["starter"]),
                "standard_count": len(grouped_cards["standard"]),
                "unique_count": len(grouped_cards["unique"])
            }
        }
    
    async def get_cards_for_game_round(self, user_id: int, round_count: int = 3) -> List[CardResponse]:
        """
        Получает карты пользователя для игрового раунда.
        
        Args:
            user_id: ID пользователя
            round_count: Количество карт для раунда (обычно 3)
            
        Returns:
            List[CardResponse]: Случайные карты пользователя для раунда
            
        Raises:
            UserNotFoundError: Если пользователь не найден
            ValidationError: Если у пользователя недостаточно карт
        """
        user = await self.user_repo.get_by_id(user_id)
        if not user:
            raise UserNotFoundError(f"Пользователь с ID {user_id} не найден")
        
        user_cards = await self.card_repo.get_user_cards(user_id)
        
        if len(user_cards) < round_count:
            raise ValidationError(
                f"У пользователя недостаточно карт для игры. "
                f"Есть: {len(user_cards)}, требуется: {round_count}"
            )
        
        # Выбираем случайные карты из коллекции пользователя
        selected_cards = random.sample(user_cards, round_count)
        
        # Создаем CardResponse объекты для гибридного подхода
        card_responses = []
        for card_data in selected_cards:
            card_info = {
                "id": f"{card_data['card_type']}_{card_data['card_number']}",
                "name": f"{card_data['card_type'].title()} Card {card_data['card_number']}",
                "image_url": f"azure://{card_data['card_type']}/{card_data['card_number']}.jpg",
                "card_type": card_data['card_type'],
                "description": f"{card_data['card_type'].title()} card number {card_data['card_number']}",
                "created_at": card_data['obtained_at'],
                "is_starter_card": card_data['card_type'] == 'starter',
                "is_standard_card": card_data['card_type'] == 'standard',
                "is_unique_card": card_data['card_type'] == 'unique'
            }
            card_responses.append(CardResponse.model_validate(card_info))
        
        return card_responses
    
    async def get_card_statistics(self) -> Dict[str, Any]:
        """
        Получает общую статистику по картам в системе.
        
        Returns:
            Dict[str, Any]: Статистика карт
        """
        total_cards = await self.card_repo.get_total_count()
        
        starter_count = await self.card_repo.get_count_by_type(CardType.STARTER)
        standard_count = await self.card_repo.get_count_by_type(CardType.STANDARD)
        unique_count = await self.card_repo.get_count_by_type(CardType.UNIQUE)
        
        stats = {
            "total_cards": total_cards,
            "cards_by_type": {
                "starter": starter_count,
                "standard": standard_count,
                "unique": unique_count
            },
            "card_types": [t.value for t in CardType],
            "system_ready": starter_count >= 10,  # Минимум для выдачи стартовых карт
            "azure_connected": self.azure_service is not None
        }
        
        # Статистика из Azure
        if self.azure_service:
            try:
                azure_stats = await self.azure_service.get_storage_statistics()
                stats.update(azure_stats)
            except Exception:
                pass
        
        return stats
    
    async def load_cards_from_azure(self, card_type: CardType, limit: Optional[int] = None) -> Dict[str, Any]:
        """
        Загружает карты из Azure Blob Storage в базу данных.
        
        Args:
            card_type: Тип карт для загрузки
            limit: Максимальное количество карт (опционально)
            
        Returns:
            Dict[str, Any]: Результат загрузки
            
        Raises:
            ValidationError: Если Azure не подключен
        """
        if not self.azure_service:
            raise ValidationError("Azure Blob Storage не подключен")
        
        # Получаем карты из Azure
        azure_cards = await self.azure_service.list_cards_in_folder_with_details(card_type.value)
        
        if limit:
            azure_cards = azure_cards[:limit]
        
        # Создаем карты в базе данных
        created_cards = []
        for azure_card in azure_cards:
            card_data = CardCreate(
                name=azure_card.get("card_name", f"Card {azure_card['card_number']}"),
                image_url=azure_card["url"],
                card_type=card_type,
                description=f"Загружено из Azure: {azure_card['filename']}",
                azure_blob_path=azure_card["blob_path"]
            )
            
            try:
                db_card = await self.card_repo.create(card_data)
                created_cards.append(CardResponse.model_validate(db_card))
            except Exception as e:
                print(f"Ошибка создания карты {azure_card['card_name']}: {e}")
                continue
        
        return {
            "card_type": card_type.value,
            "azure_cards_found": len(azure_cards),
            "cards_created": len(created_cards),
            "created_cards": created_cards
        }
    
    async def load_all_cards_from_azure(self) -> Dict[str, Any]:
        """
        Загружает все карты всех типов из Azure.
        
        Returns:
            Dict[str, Any]: Результат загрузки всех типов карт
        """
        if not self.azure_service:
            raise ValidationError("Azure Blob Storage не подключен")
        
        results = {}
        total_loaded = 0
        
        for card_type in [CardType.STARTER, CardType.STANDARD, CardType.UNIQUE]:
            try:
                result = await self.load_cards_from_azure(card_type)
                results[card_type.value] = result
                total_loaded += result["cards_created"]
            except Exception as e:
                results[card_type.value] = {
                    "error": str(e),
                    "cards_created": 0
                }
        
        return {
            "success": True,
            "total_loaded": total_loaded,
            "results_by_type": results,
            "azure_storage_info": await self.azure_service.get_storage_statistics()
        }
    
    async def assign_starter_cards(self, user_id: int, count: int = 10) -> List[Dict[str, Any]]:
        """
        Назначает пользователю стартовые карточки.
        
        Args:
            user_id: ID пользователя
            count: Количество карт для назначения
            
        Returns:
            List[Dict]: Список назначенных карт с метаданными
        """
        if not self.azure_service:
            raise ValidationError("Azure сервис недоступен")
        
        # Получаем доступные стартовые карты из Azure
        starter_cards = await self.azure_service.list_cards_in_folder("starter")
        if not starter_cards:
            raise ValidationError("Стартовые карты не найдены в Azure")
        
        # Получаем уже назначенные стартовые карты пользователя
        existing_cards = await self.db.execute(
            select(UserCard.card_number).where(
                and_(
                    UserCard.user_id == user_id,
                    UserCard.card_type == "starter"
                )
            )
        )
        existing_numbers = {row[0] for row in existing_cards}
        
        # Фильтруем доступные карты (исключаем уже имеющиеся)
        available_cards = [num for num in starter_cards if num not in existing_numbers]
        
        if not available_cards:
            raise ValidationError("Все стартовые карты уже назначены")
        
        # Выбираем случайные карты
        cards_to_assign = random.sample(
            available_cards, 
            min(count, len(available_cards))
        )
        
        # Создаем записи в базе данных
        assigned_cards = []
        for card_number in cards_to_assign:
            user_card = UserCard(
                user_id=user_id,
                card_type="starter",
                card_number=card_number
            )
            self.db.add(user_card)
            
            # Добавляем метаданные карты
            card_info = {
                "card_type": "starter",
                "card_number": card_number,
                "card_url": self.azure_service.get_card_url("starter", card_number),
                "assigned_at": user_card.obtained_at
            }
            assigned_cards.append(card_info)
        
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        return assigned_cards
    
    async def get_user_cards_for_game(self, user_id: int, count: int = 3) -> List[Dict[str, Any]]:
        """
        Получает случайные карты пользователя для игрового раунда.
        
        Args:
            user_id: ID пользователя
            count: Количество карт для возврата
            
        Returns:
            List[Dict]: Случайные карты пользователя
        """
        # Получаем все карты пользователя через репозиторий
        user_cards = await self.card_repo.get_user_cards(user_id)
        
        if not user_cards:
            raise ValidationError("У пользователя нет карт")
        
        # Выбираем случайные карты
        selected_cards = random.sample(
            user_cards, 
            min(count, len(user_cards))
        )
        
        # Преобразуем в формат для игры (гибридный подход)
        game_cards = []
        for card_data in selected_cards:
            card_info = {
                "id": f"{card_data['card_type']}_{card_data['card_number']}",
                "name": f"{card_data['card_type'].title()} Card {card_data['card_number']}",
                "card_type": card_data['card_type'],
                "image_url": f"https://memegamestorage.blob.core.windows.net/memes/{card_data['card_type']}/{card_data['card_number']}.jpg",
                "is_unique": card_data['card_type'] == 'unique'
            }
            
            game_cards.append(card_info)
        
        return game_cards
    
    async def get_available_standard_cards_for_user(self, user_id: int) -> List[int]:
        """
        Получает номера стандартных карт, которых у пользователя еще нет.
        Используется для награждения победителей раундов.
        
        Args:
            user_id: ID пользователя
            
        Returns:
            List[int]: Номера доступных стандартных карт
        """
        if not self.azure_service:
            return []
        
        # Получаем все стандартные карты из Azure
        all_standard_cards = await self.azure_service.list_cards_in_folder("standard")
        
        # Получаем уже имеющиеся стандартные карты пользователя
        existing_cards = await self.db.execute(
            select(UserCard.card_number).where(
                and_(
                    UserCard.user_id == user_id,
                    UserCard.card_type == "standard"
                )
            )
        )
        existing_numbers = {row[0] for row in existing_cards}
        
        # Возвращаем доступные карты
        available_cards = [num for num in all_standard_cards if num not in existing_numbers]
        return available_cards
    
    async def check_system_readiness(self) -> Dict[str, Any]:
        """
        Проверяет готовность карточной системы.
        
        Returns:
            Dict: Статус готовности системы
        """
        readiness = {
            "ready": False,
            "azure_connected": False,
            "has_starter_cards": False,
            "has_standard_cards": False,
            "has_unique_cards": False,
            "min_cards_available": False,
            "issues": []
        }
        
        # Проверяем Azure соединение
        if self.azure_service:
            try:
                readiness["azure_connected"] = await self.azure_service.is_connected()
                
                if readiness["azure_connected"]:
                    # Проверяем наличие карт по типам
                    starter_cards = await self.azure_service.list_cards_in_folder("starter")
                    standard_cards = await self.azure_service.list_cards_in_folder("standard")
                    unique_cards = await self.azure_service.list_cards_in_folder("unique")
                    
                    readiness["has_starter_cards"] = len(starter_cards) >= 10
                    readiness["has_standard_cards"] = len(standard_cards) >= 5
                    readiness["has_unique_cards"] = len(unique_cards) >= 3
                    
                    total_cards = len(starter_cards) + len(standard_cards) + len(unique_cards)
                    readiness["min_cards_available"] = total_cards >= 20
                    
                    if not readiness["has_starter_cards"]:
                        readiness["issues"].append("Недостаточно стартовых карт (<10)")
                    if not readiness["has_standard_cards"]:
                        readiness["issues"].append("Недостаточно стандартных карт (<5)")
                    if not readiness["has_unique_cards"]:
                        readiness["issues"].append("Недостаточно уникальных карт (<3)")
                
                else:
                    readiness["issues"].append("Не удается подключиться к Azure Blob Storage")
                    
            except Exception as e:
                readiness["issues"].append(f"Ошибка Azure: {str(e)}")
        else:
            readiness["issues"].append("Azure Blob Service не инициализирован")
        
        # Система готова если Azure подключен и есть минимум карт
        readiness["ready"] = (
            readiness["azure_connected"] and 
            readiness["min_cards_available"]
        )
        
        return readiness 