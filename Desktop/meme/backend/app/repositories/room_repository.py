"""
Репозиторий для работы с игровыми комнатами и участниками.
"""

from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, and_, or_, func, desc
from sqlalchemy.orm import selectinload

from ..models.game import Room, RoomParticipant, RoomStatus, ParticipantStatus, ConnectionStatus
from ..models.user import User


class RoomRepository:
    """Репозиторий для работы с игровыми комнатами."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def create_room(
        self,
        creator_id: int,
        max_players: int = 6,
        is_public: bool = True,
        age_group: str = "mixed",
        room_code: Optional[str] = None
    ) -> Room:
        """
        Создает новую игровую комнату.
        
        Args:
            creator_id: ID создателя комнаты
            max_players: Максимальное количество игроков
            is_public: Публичная ли комната
            age_group: Возрастная группа
            room_code: Код комнаты (для приватных)
            
        Returns:
            Room: Созданная комната
        """
        room = Room(
            creator_id=creator_id,
            max_players=max_players,
            is_public=is_public,
            age_group=age_group,
            room_code=room_code,
            status=RoomStatus.WAITING
        )
        self.db.add(room)
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        await self.db.refresh(room)
        return room
    
    async def get_room_by_id(self, room_id: int) -> Optional[Room]:
        """
        Получает комнату по ID.
        
        Args:
            room_id: ID комнаты
            
        Returns:
            Optional[Room]: Комната или None
        """
        result = await self.db.execute(
            select(Room).where(Room.id == room_id)
        )
        return result.scalar_one_or_none()
    
    async def get_room_by_code(self, room_code: str) -> Optional[Room]:
        """
        Получает комнату по коду.
        
        Args:
            room_code: Код комнаты
            
        Returns:
            Optional[Room]: Комната или None
        """
        result = await self.db.execute(
            select(Room).where(Room.room_code == room_code)
        )
        return result.scalar_one_or_none()
    
    async def get_available_public_rooms(
        self, 
        age_group: Optional[str] = None,
        limit: int = 20
    ) -> List[Room]:
        """
        Получает доступные публичные комнаты.
        
        Args:
            age_group: Возрастная группа для фильтрации
            limit: Максимальное количество комнат
            
        Returns:
            List[Room]: Список доступных комнат
        """
        query = select(Room).where(
            and_(
                Room.status == RoomStatus.WAITING,
                Room.is_public == True,
                Room.age_group != "mixed"  # Исключаем приватные комнаты
            )
        )
        
        if age_group:
            query = query.where(Room.age_group == age_group)
        
        result = await self.db.execute(
            query.order_by(desc(Room.created_at)).limit(limit)
        )
        return result.scalars().all()
    
    async def get_rooms_by_creator(self, creator_id: int, limit: int = 10) -> List[Room]:
        """
        Получает комнаты созданные пользователем.
        
        Args:
            creator_id: ID создателя
            limit: Максимальное количество комнат
            
        Returns:
            List[Room]: Список комнат
        """
        result = await self.db.execute(
            select(Room)
            .where(Room.creator_id == creator_id)
            .order_by(desc(Room.created_at))
            .limit(limit)
        )
        return result.scalars().all()
    
    async def update_room_status(self, room_id: int, status: RoomStatus) -> Optional[Room]:
        """
        Обновляет статус комнаты.
        
        Args:
            room_id: ID комнаты
            status: Новый статус
            
        Returns:
            Optional[Room]: Обновленная комната или None
        """
        room = await self.get_room_by_id(room_id)
        if not room:
            return None
        
        room.status = status
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        await self.db.refresh(room)
        return room
    
    async def get_room_with_participants(self, room_id: int) -> Optional[Dict[str, Any]]:
        """
        Получает комнату с информацией об участниках.
        
        Args:
            room_id: ID комнаты
            
        Returns:
            Optional[Dict]: Комната с участниками или None
        """
        # Получаем комнату
        room_result = await self.db.execute(
            select(Room).where(Room.id == room_id)
        )
        room = room_result.scalar_one_or_none()
        
        if not room:
            return None
        
        # Получаем участников
        participants_result = await self.db.execute(
            select(RoomParticipant, User.nickname, User.birth_date, User.gender)
            .join(User, RoomParticipant.user_id == User.id)
            .where(RoomParticipant.room_id == room_id)
            .order_by(RoomParticipant.joined_at)
        )
        
        participants = []
        for participant, nickname, birth_date, gender in participants_result:
            participants.append({
                "user_id": participant.user_id,
                "nickname": nickname,
                "birth_date": birth_date,
                "gender": gender,
                "status": participant.status,
                "connection_status": participant.connection_status,
                "joined_at": participant.joined_at,
                "last_activity": participant.last_activity,
                "disconnect_count": participant.disconnect_count,
                "missed_actions": participant.missed_actions
            })
        
        return {
            "id": room.id,
            "creator_id": room.creator_id,
            "max_players": room.max_players,
            "is_public": room.is_public,
            "age_group": room.age_group,
            "room_code": room.room_code,
            "status": room.status,
            "created_at": room.created_at,
            "participants": participants
        }
    
    async def delete_room(self, room_id: int) -> bool:
        """
        Удаляет комнату.
        
        Args:
            room_id: ID комнаты
            
        Returns:
            bool: True если удалена, False если не найдена
        """
        room = await self.get_room_by_id(room_id)
        if not room:
            return False
        
        await self.db.delete(room)
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        return True


class RoomParticipantRepository:
    """Репозиторий для работы с участниками комнат."""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def add_participant(
        self, 
        room_id: int, 
        user_id: int
    ) -> RoomParticipant:
        """
        Добавляет участника в комнату.
        
        Args:
            room_id: ID комнаты
            user_id: ID пользователя
            
        Returns:
            RoomParticipant: Созданный участник
        """
        participant = RoomParticipant(
            room_id=room_id,
            user_id=user_id,
            status=ParticipantStatus.ACTIVE,
            connection_status=ConnectionStatus.CONNECTED
        )
        self.db.add(participant)
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        await self.db.refresh(participant)
        return participant
    
    async def get_participant(
        self, 
        room_id: int, 
        user_id: int
    ) -> Optional[RoomParticipant]:
        """
        Получает участника комнаты.
        
        Args:
            room_id: ID комнаты
            user_id: ID пользователя
            
        Returns:
            Optional[RoomParticipant]: Участник или None
        """
        result = await self.db.execute(
            select(RoomParticipant).where(
                and_(
                    RoomParticipant.room_id == room_id,
                    RoomParticipant.user_id == user_id
                )
            )
        )
        return result.scalar_one_or_none()
    
    async def get_active_participants(self, room_id: int) -> List[RoomParticipant]:
        """
        Получает активных участников комнаты.
        
        Args:
            room_id: ID комнаты
            
        Returns:
            List[RoomParticipant]: Список активных участников
        """
        result = await self.db.execute(
            select(RoomParticipant)
            .where(
                and_(
                    RoomParticipant.room_id == room_id,
                    RoomParticipant.status == ParticipantStatus.ACTIVE
                )
            )
            .order_by(RoomParticipant.joined_at)
        )
        return result.scalars().all()
    
    async def get_connected_participants(self, room_id: int) -> List[RoomParticipant]:
        """
        Получает подключенных участников комнаты.
        
        Args:
            room_id: ID комнаты
            
        Returns:
            List[RoomParticipant]: Список подключенных участников
        """
        result = await self.db.execute(
            select(RoomParticipant)
            .where(
                and_(
                    RoomParticipant.room_id == room_id,
                    RoomParticipant.status == ParticipantStatus.ACTIVE,
                    RoomParticipant.connection_status == ConnectionStatus.CONNECTED
                )
            )
            .order_by(RoomParticipant.joined_at)
        )
        return result.scalars().all()
    
    async def update_participant_status(
        self, 
        room_id: int, 
        user_id: int, 
        status: ParticipantStatus
    ) -> Optional[RoomParticipant]:
        """
        Обновляет статус участника.
        
        Args:
            room_id: ID комнаты
            user_id: ID пользователя
            status: Новый статус
            
        Returns:
            Optional[RoomParticipant]: Обновленный участник или None
        """
        participant = await self.get_participant(room_id, user_id)
        if not participant:
            return None
        
        participant.status = status
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        await self.db.refresh(participant)
        return participant
    
    async def update_connection_status(
        self, 
        room_id: int, 
        user_id: int, 
        connection_status: ConnectionStatus
    ) -> Optional[RoomParticipant]:
        """
        Обновляет статус подключения участника.
        
        Args:
            room_id: ID комнаты
            user_id: ID пользователя
            connection_status: Новый статус подключения
            
        Returns:
            Optional[RoomParticipant]: Обновленный участник или None
        """
        participant = await self.get_participant(room_id, user_id)
        if not participant:
            return None
        
        participant.connection_status = connection_status
        participant.last_activity = datetime.utcnow()
        
        if connection_status == ConnectionStatus.DISCONNECTED:
            participant.disconnect_count += 1
        
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        await self.db.refresh(participant)
        return participant
    
    async def update_last_activity(
        self, 
        room_id: int, 
        user_id: int
    ) -> Optional[RoomParticipant]:
        """
        Обновляет время последней активности участника.
        
        Args:
            room_id: ID комнаты
            user_id: ID пользователя
            
        Returns:
            Optional[RoomParticipant]: Обновленный участник или None
        """
        participant = await self.get_participant(room_id, user_id)
        if not participant:
            return None
        
        participant.last_activity = datetime.utcnow()
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        await self.db.refresh(participant)
        return participant
    
    async def increment_missed_actions(
        self, 
        room_id: int, 
        user_id: int
    ) -> Optional[RoomParticipant]:
        """
        Увеличивает счетчик пропущенных действий.
        
        Args:
            room_id: ID комнаты
            user_id: ID пользователя
            
        Returns:
            Optional[RoomParticipant]: Обновленный участник или None
        """
        participant = await self.get_participant(room_id, user_id)
        if not participant:
            return None
        
        participant.missed_actions += 1
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        await self.db.refresh(participant)
        return participant
    
    async def remove_participant(
        self, 
        room_id: int, 
        user_id: int
    ) -> bool:
        """
        Удаляет участника из комнаты.
        
        Args:
            room_id: ID комнаты
            user_id: ID пользователя
            
        Returns:
            bool: True если удален, False если не найден
        """
        participant = await self.get_participant(room_id, user_id)
        if not participant:
            return False
        
        await self.db.delete(participant)
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        return True
    
    async def get_participants_count(self, room_id: int) -> int:
        """
        Получает количество участников в комнате.
        
        Args:
            room_id: ID комнаты
            
        Returns:
            int: Количество участников
        """
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
    
    async def get_connected_participants_count(self, room_id: int) -> int:
        """
        Получает количество подключенных участников в комнате.
        
        Args:
            room_id: ID комнаты
            
        Returns:
            int: Количество подключенных участников
        """
        result = await self.db.execute(
            select(func.count(RoomParticipant.id))
            .where(
                and_(
                    RoomParticipant.room_id == room_id,
                    RoomParticipant.status == ParticipantStatus.ACTIVE,
                    RoomParticipant.connection_status == ConnectionStatus.CONNECTED
                )
            )
        )
        return result.scalar() or 0
    
    async def get_inactive_participants(
        self, 
        room_id: int, 
        timeout_minutes: int = 5
    ) -> List[RoomParticipant]:
        """
        Получает неактивных участников.
        
        Args:
            room_id: ID комнаты
            timeout_minutes: Таймаут в минутах
            
        Returns:
            List[RoomParticipant]: Список неактивных участников
        """
        timeout_threshold = datetime.utcnow() - timedelta(minutes=timeout_minutes)
        
        result = await self.db.execute(
            select(RoomParticipant)
            .where(
                and_(
                    RoomParticipant.room_id == room_id,
                    RoomParticipant.status == ParticipantStatus.ACTIVE,
                    RoomParticipant.last_activity < timeout_threshold
                )
            )
        )
        return result.scalars().all() 