"""
Сервис для управления игровыми комнатами.
"""

from typing import Optional, List, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_, or_
from sqlalchemy.orm import selectinload
import asyncio
from datetime import date

from ..models.game import Room, RoomParticipant, Game
from ..models.user import User
from ..models.game import RoomStatus, ParticipantStatus, GameStatus
from ..schemas.game import (
    RoomCreate, RoomResponse, RoomDetailResponse, RoomParticipantResponse,
    RoomJoinByCode, QuickMatchRequest, QuickMatchResponse
)
from ..utils.exceptions import ValidationError, NotFoundError, PermissionError
from ..services.user_service import UserService


class RoomService:
    """Сервис для управления игровыми комнатами"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def _determine_age_group(self, user: User) -> str:
        """Определяет возрастную группу пользователя по birth_date"""
        # Проверяем что у пользователя есть birth_date
        if not user or not user.birth_date:
            return "young_adults"  # Дефолтная группа
            
        today = date.today()
        age = today.year - user.birth_date.year - ((today.month, today.day) < (user.birth_date.month, user.birth_date.day))
        if age < 13:
            return "kids"
        elif age < 18:
            return "teens"
        elif age < 30:
            return "young_adults"
        elif age < 60:
            return "adults"
        else:
            return "seniors"

    async def create_room(self, creator_id: int, room_data: RoomCreate) -> RoomResponse:
        """
        Создает новую игровую комнату.
        
        Args:
            creator_id: ID создателя комнаты
            room_data: Данные для создания комнаты
            
        Returns:
            RoomResponse: Созданная комната
        """
        # Проверяем что профиль пользователя заполнен
        user = await self.db.get(User, creator_id)
        if not user:
            raise ValidationError("Пользователь не найден")
        
        # Обновляем объект пользователя чтобы увидеть последние изменения
        await self.db.refresh(user)
        
        # Отладочная информация
        print(f"DEBUG: User {creator_id} - nickname: {user.nickname}, birth_date: {user.birth_date}, gender: {user.gender}")
        print(f"DEBUG: is_profile_complete: {user.is_profile_complete}")
        
        if not user.is_profile_complete:
            raise ValidationError("Для создания комнаты необходимо заполнить профиль (никнейм, дата рождения, пол)")
        
        # Проверяем что у пользователя нет активной комнаты
        existing_room = await self.db.execute(
            select(Room).where(
                and_(
                    Room.creator_id == creator_id,
                    Room.status.in_([RoomStatus.WAITING, RoomStatus.PLAYING])
                )
            )
        )
        if existing_room.scalar():
            raise ValidationError("У вас уже есть активная игровая комната")
        
        # Генерируем уникальный код если запрошен
        room_code = None
        if room_data.generate_code or not room_data.is_public:
            room_code = await self._generate_unique_room_code()
        
        # 🎯 НОВАЯ ЛОГИКА: age_group зависит от типа комнаты
        if room_data.is_public:
            # Для публичных комнат определяем age_group по создателю
            user = await self.db.get(User, creator_id)
            age_group = await self._determine_age_group(user) if user else "young_adults"
        else:
            # Для приватных комнат устанавливаем "mixed" - без возрастных ограничений
            age_group = "mixed"
        
        # Создаем комнату
        room = Room(
            creator_id=creator_id,
            max_players=room_data.max_players,
            status=RoomStatus.WAITING,
            room_code=room_code,
            is_public=room_data.is_public,
            age_group=age_group
        )
        self.db.add(room)
        await self.db.flush()  # Получаем ID комнаты
        
        # Автоматически добавляем создателя как участника
        participant = RoomParticipant(
            room_id=room.id,
            user_id=creator_id,
            status=ParticipantStatus.ACTIVE
        )
        self.db.add(participant)
        
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        
        # Возвращаем комнату с количеством игроков
        return RoomResponse(
            id=room.id,
            creator_id=room.creator_id,
            max_players=room.max_players,
            status=room.status,
            room_code=room.room_code,
            is_public=room.is_public,
            created_at=room.created_at,
            current_players=1
        )
    
    async def join_room(self, room_id: int, user_id: int) -> RoomDetailResponse:
        """
        Присоединяет игрока к ПУБЛИЧНОЙ комнате.
        Для приватных комнат используйте join_room_by_code.
        
        Args:
            room_id: ID комнаты
            user_id: ID пользователя
            
        Returns:
            RoomDetailResponse: Обновленная комната с участниками
        """
        # Проверяем что профиль пользователя заполнен
        user = await self.db.get(User, user_id)
        if not user or not user.is_profile_complete:
            raise ValidationError("Для присоединения к комнате необходимо заполнить профиль (никнейм, дата рождения, пол)")
        
        # Получаем комнату
        room = await self._get_room_or_404(room_id)
        
        # 🔒 ПРОВЕРЯЕМ ЧТО КОМНАТА ПУБЛИЧНАЯ
        if not room.is_public:
            raise PermissionError("Это приватная комната. Используйте код комнаты для присоединения.")
        
        # Проверяем что комната ожидает игроков
        if room.status != RoomStatus.WAITING:
            raise ValidationError("Комната не принимает новых игроков")
        
        # Проверяем что игрок еще не в комнате
        existing_participant = await self.db.execute(
            select(RoomParticipant).where(
                and_(
                    RoomParticipant.room_id == room_id,
                    RoomParticipant.user_id == user_id,
                    RoomParticipant.status == ParticipantStatus.ACTIVE
                )
            )
        )
        if existing_participant.scalar():
            raise ValidationError("Вы уже в этой комнате")
        
        # Проверяем что есть место
        current_players = await self._get_active_players_count(room_id)
        if current_players >= room.max_players:
            raise ValidationError("Комната заполнена")
        
        # Используем внутренний метод присоединения
        return await self._join_room_internal(room_id, user_id)
    
    async def join_room_by_code(self, room_code: str, user_id: int) -> RoomDetailResponse:
        """
        Присоединяется к комнате по коду.
        
        Args:
            room_code: 6-значный код комнаты
            user_id: ID пользователя
            
        Returns:
            RoomDetailResponse: Комната с участниками
        """
        # Проверяем что профиль пользователя заполнен
        user = await self.db.get(User, user_id)
        if not user or not user.is_profile_complete:
            raise ValidationError("Для присоединения к комнате необходимо заполнить профиль (никнейм, дата рождения, пол)")
        
        # Находим комнату по коду
        room_result = await self.db.execute(
            select(Room).where(
                and_(
                    Room.room_code == room_code.upper(),
                    Room.status == RoomStatus.WAITING
                )
            )
        )
        room = room_result.scalar()
        
        if not room:
            raise NotFoundError("Комната с таким кодом не найдена или уже началась")
        
        # Используем внутренний метод присоединения (обход проверки is_public)
        return await self._join_room_internal(room.id, user_id)
    
    async def quick_match(self, user_id: int, request: QuickMatchRequest) -> QuickMatchResponse:
        """
        Быстрый поиск игры (matchmaking).
        
        Args:
            user_id: ID пользователя
            request: Параметры поиска
            
        Returns:
            QuickMatchResponse: Результат поиска
        """
        # Проверяем что пользователь не в активной комнате
        current_room = await self.get_user_current_room(user_id)
        if current_room:
            return QuickMatchResponse(
                success=False,
                message="Сначала покиньте текущую комнату"
            )
        
        # Получаем пользователя для age_group
        user = await self.db.get(User, user_id)
        age_group = await self._determine_age_group(user) if user else None
        
        # 🎯 СТРОГИЙ ПОИСК: ищем подходящие публичные комнаты ТОЛЬКО с нужной age_group
        # Исключаем "mixed" комнаты, чтобы Quick Match не попадал в приватные комнаты
        query = select(Room, func.count(RoomParticipant.id).label('current_players')).join(
            RoomParticipant, Room.id == RoomParticipant.room_id
        ).where(
            and_(
                Room.status == RoomStatus.WAITING,
                Room.is_public == True,
                RoomParticipant.status == ParticipantStatus.ACTIVE,
                Room.age_group == age_group,  # Строгое совпадение
                Room.age_group != "mixed"     # Исключаем mixed комнаты
            )
        ).group_by(Room.id)
        
        # Фильтр по предпочитаемому количеству игроков
        if request.preferred_players:
            query = query.having(
                and_(
                    func.count(RoomParticipant.id) < Room.max_players,  # Есть место
                    Room.max_players == request.preferred_players  # Подходящий размер
                )
            )
        else:
            query = query.having(func.count(RoomParticipant.id) < Room.max_players)
        
        query = query.order_by(func.count(RoomParticipant.id).desc())  # Сначала более заполненные
        
        result = await self.db.execute(query)
        rooms = result.all()
        
        if rooms:
            # Присоединяемся к первой подходящей комнате
            room, current_players = rooms[0]
            try:
                room_details = await self.join_room(room.id, user_id)
                return QuickMatchResponse(
                    success=True,
                    room_id=room.id,
                    room_code=room.room_code,
                    message=f"Присоединились к комнате! Игроков: {current_players + 1}/{room.max_players}"
                )
            except ValidationError as e:
                # Если не удалось присоединиться, создаем новую комнату
                pass
        
        # Если подходящих комнат нет, создаем новую с age_group
        room_data = RoomCreate(
            max_players=request.preferred_players or 6,
            is_public=True,
            generate_code=False
        )
        
        new_room = await self.create_room(user_id, room_data)
        return QuickMatchResponse(
            success=True,
            room_id=new_room.id,
            room_code=new_room.room_code,
            wait_time=request.max_wait_time,
            message="Создана новая комната! Ожидаем других игроков..."
        )
    
    async def leave_room(self, room_id: int, user_id: int) -> Dict[str, Any]:
        """
        Игрок покидает комнату.
        
        Args:
            room_id: ID комнаты
            user_id: ID пользователя
            
        Returns:
            Dict: Результат операции
        """
        room = await self._get_room_or_404(room_id)
        
        # Находим участника
        participant_result = await self.db.execute(
            select(RoomParticipant).where(
                and_(
                    RoomParticipant.room_id == room_id,
                    RoomParticipant.user_id == user_id,
                    RoomParticipant.status == ParticipantStatus.ACTIVE
                )
            )
        )
        participant = participant_result.scalar()
        if not participant:
            raise ValidationError("Вы не участник этой комнаты")
        
        # Помечаем как покинувшего
        participant.status = ParticipantStatus.LEFT
        
        # Если это создатель и комната еще в ожидании, отменяем комнату
        if room.creator_id == user_id and room.status == RoomStatus.WAITING:
            room.status = RoomStatus.CANCELLED
            # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
            return {
                "success": True,
                "message": "Комната отменена, так как создатель покинул ее",
                "room_cancelled": True
            }
        
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        return {
            "success": True,
            "message": "Вы покинули комнату",
            "room_cancelled": False
        }
    
    async def start_game(self, room_id: int, user_id: int) -> Dict[str, Any]:
        """
        Начинает игру в комнате.
        
        Args:
            room_id: ID комнаты
            user_id: ID пользователя (должен быть создателем)
            
        Returns:
            Dict: Результат операции
        """
        room = await self._get_room_or_404(room_id)
        
        # Проверяем что пользователь - создатель
        if room.creator_id != user_id:
            raise PermissionError("Только создатель может начать игру")
        
        # Проверяем статус комнаты
        if room.status != RoomStatus.WAITING:
            raise ValidationError("Игра уже началась или комната закрыта")
        
        # Проверяем количество игроков
        active_players = await self._get_active_players_count(room_id)
        if active_players < 3:
            raise ValidationError("Для начала игры нужно минимум 3 игрока")
        
        # Меняем статус комнаты
        room.status = RoomStatus.PLAYING
        
        # Создаем игру
        game = Game(
            room_id=room_id,
            status=GameStatus.STARTING,
            current_round=1
        )
        self.db.add(game)
        
        # Flush чтобы получить ID игры
        await self.db.flush()
        
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        
        return {
            "success": True,
            "message": "Игра началась!",
            "game_id": game.id,
            "players_count": active_players
        }
    
    async def get_room_details(self, room_id: int, user_id: Optional[int] = None) -> RoomDetailResponse:
        """
        Получает детальную информацию о комнате.
        
        Args:
            room_id: ID комнаты
            user_id: ID пользователя (для проверки прав доступа)
            
        Returns:
            RoomDetailResponse: Детали комнаты
        """
        # Получаем комнату
        room_result = await self.db.execute(
            select(Room).where(Room.id == room_id)
        )
        room = room_result.scalar()
        if not room:
            raise NotFoundError("Комната не найдена")
        
        # 🔒 ПРОВЕРКА ПРАВ ДОСТУПА ДЛЯ ПРИВАТНЫХ КОМНАТ
        if not room.is_public and user_id:
            # Проверяем является ли пользователь участником приватной комнаты
            participant_check = await self.db.execute(
                select(RoomParticipant).where(
                    and_(
                        RoomParticipant.room_id == room_id,
                        RoomParticipant.user_id == user_id,
                        RoomParticipant.status == ParticipantStatus.ACTIVE
                    )
                )
            )
            if not participant_check.scalar():
                raise PermissionError("Доступ к приватной комнате только для участников")
        elif not room.is_public and not user_id:
            raise PermissionError("Не удается определить права доступа к приватной комнате")
        
        # Получаем активных участников с никнеймами
        participants_result = await self.db.execute(
            select(RoomParticipant, User.nickname)
            .join(User, RoomParticipant.user_id == User.id)
            .where(
                and_(
                    RoomParticipant.room_id == room_id,
                    RoomParticipant.status == ParticipantStatus.ACTIVE
                )
            )
            .order_by(RoomParticipant.joined_at)
        )
        
        participants = []
        for participant, nickname in participants_result:
            participants.append(RoomParticipantResponse(
                id=participant.id,
                room_id=participant.room_id,
                user_id=participant.user_id,
                user_nickname=nickname or f"Игрок {participant.user_id}",
                joined_at=participant.joined_at,
                status=participant.status
            ))
        
        # Получаем никнейм создателя
        creator_result = await self.db.execute(
            select(User.nickname).where(User.id == room.creator_id)
        )
        creator_nickname = creator_result.scalar() or "Неизвестно"
        
        return RoomDetailResponse(
            id=room.id,
            creator_id=room.creator_id,
            max_players=room.max_players,
            status=room.status,
            room_code=room.room_code,
            is_public=room.is_public,
            created_at=room.created_at,
            current_players=len(participants),
            participants=participants,
            creator_nickname=creator_nickname,
            can_start_game=(len(participants) >= 3 and room.status == RoomStatus.WAITING)
        )
    
    async def get_available_rooms(self, limit: int = 20) -> List[RoomResponse]:
        """
        Получает список доступных комнат для присоединения.
        
        Args:
            limit: Максимальное количество комнат
            
        Returns:
            List[RoomResponse]: Список публичных комнат
        """
        # Подзапрос для подсчета активных участников
        participants_count_subq = (
            select(func.count(RoomParticipant.id))
            .where(
                and_(
                    RoomParticipant.room_id == Room.id,
                    RoomParticipant.status == ParticipantStatus.ACTIVE
                )
            )
            .scalar_subquery()
        )
        
        # Получаем только публичные комнаты в ожидании с количеством игроков
        rooms_result = await self.db.execute(
            select(Room, participants_count_subq.label('current_players'))
            .where(
                and_(
                    Room.status == RoomStatus.WAITING,
                    Room.is_public == True  # Только публичные комнаты
                )
            )
            .order_by(Room.created_at.desc())
            .limit(limit)
        )
        
        rooms = []
        for room, current_players in rooms_result:
            # Показываем только комнаты с свободными местами
            if current_players < room.max_players:
                rooms.append(RoomResponse(
                    id=room.id,
                    creator_id=room.creator_id,
                    max_players=room.max_players,
                    status=room.status,
                    room_code=room.room_code,
                    is_public=room.is_public,
                    created_at=room.created_at,
                    current_players=current_players or 0
                ))
        
        return rooms
    
    async def get_user_current_room(self, user_id: int) -> Optional[RoomDetailResponse]:
        """
        Получает текущую активную комнату пользователя.
        
        Args:
            user_id: ID пользователя
            
        Returns:
            Optional[RoomDetailResponse]: Текущая комната или None
        """
        print(f"🔍 DEBUG: Looking for current room for user {user_id}")
        
        # Ищем активное участие в комнате
        participant_result = await self.db.execute(
            select(RoomParticipant.room_id)
            .join(Room, RoomParticipant.room_id == Room.id)
            .where(
                and_(
                    RoomParticipant.user_id == user_id,
                    RoomParticipant.status == ParticipantStatus.ACTIVE,
                    Room.status.in_([RoomStatus.WAITING, RoomStatus.PLAYING])
                )
            )
        )
        
        # Проверяем все результаты
        all_results = participant_result.fetchall()
        print(f"🔍 DEBUG: All results for user {user_id}: {all_results}")
        
        # Если есть результаты, берем первый
        room_id = all_results[0][0] if all_results else None
        print(f"🔍 DEBUG: Found room_id {room_id} for user {user_id}")
        
        if room_id:
            print(f"🔍 DEBUG: Getting room details for room {room_id}")
            return await self.get_room_details(room_id, user_id)
        
        print(f"🔍 DEBUG: No current room found for user {user_id}")
        return None
    
    # === Вспомогательные методы ===
    
    async def _join_room_internal(self, room_id: int, user_id: int) -> RoomDetailResponse:
        """
        Внутренний метод присоединения к комнате (без проверки is_public и age_group).
        Используется для присоединения по коду и обычного присоединения.
        
        🎯 ВАЖНО: Этот метод НЕ проверяет age_group, что позволяет игрокам любого 
        возраста присоединяться к приватным комнатам по коду.
        
        Args:
            room_id: ID комнаты
            user_id: ID пользователя
            
        Returns:
            RoomDetailResponse: Обновленная комната с участниками
        """
        # Получаем комнату (уже проверена в вызывающих методах)
        room = await self._get_room_or_404(room_id)
        
        # Проверяем что комната ожидает игроков
        if room.status != RoomStatus.WAITING:
            raise ValidationError("Комната не принимает новых игроков")
        
        # Проверяем что игрок еще не в комнате
        existing_participant = await self.db.execute(
            select(RoomParticipant).where(
                and_(
                    RoomParticipant.room_id == room_id,
                    RoomParticipant.user_id == user_id,
                    RoomParticipant.status == ParticipantStatus.ACTIVE
                )
            )
        )
        if existing_participant.scalar():
            raise ValidationError("Вы уже в этой комнате")
        
        # Проверяем что есть место
        current_players = await self._get_active_players_count(room_id)
        if current_players >= room.max_players:
            raise ValidationError("Комната заполнена")
        
        # 🎯 УДАЛЕНА ПРОВЕРКА age_group - теперь игроки любого возраста могут 
        # присоединяться к приватным комнатам по коду
        
        # Добавляем участника
        participant = RoomParticipant(
            room_id=room_id,
            user_id=user_id,
            status=ParticipantStatus.ACTIVE
        )
        self.db.add(participant)
        await self.db.flush()  # Гарантируем, что участник попадет в детали комнаты
        
        return await self.get_room_details(room_id, user_id)
    
    async def _get_room_or_404(self, room_id: int) -> Room:
        """Получает комнату или выбрасывает 404"""
        result = await self.db.execute(select(Room).where(Room.id == room_id))
        room = result.scalar()
        if not room:
            raise NotFoundError("Комната не найдена")
        return room
    
    async def _get_active_players_count(self, room_id: int) -> int:
        """Получает количество активных игроков в комнате"""
        result = await self.db.execute(
            select(func.count(RoomParticipant.id))
            .where(
                and_(
                    RoomParticipant.room_id == room_id,
                    RoomParticipant.status == ParticipantStatus.ACTIVE
                )
            )
        )
        return result.scalar() or 0
    
    async def _generate_unique_room_code(self, max_attempts: int = 10) -> str:
        """
        Генерирует уникальный код комнаты.
        
        Args:
            max_attempts: Максимальное количество попыток
            
        Returns:
            str: Уникальный 6-значный код
        """
        for _ in range(max_attempts):
            code = Room.generate_room_code()
            
            # Проверяем уникальность
            existing = await self.db.execute(
                select(Room).where(Room.room_code == code)
            )
            if not existing.scalar():
                return code
        
        raise ValidationError("Не удалось сгенерировать уникальный код комнаты") 