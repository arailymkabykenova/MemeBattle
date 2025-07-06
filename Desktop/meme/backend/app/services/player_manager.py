"""
Сервис для управления состоянием игроков в игре.
Отвечает за отслеживание подключений, таймаутов и активности игроков.
"""

from typing import List, Dict, Optional, Set
from datetime import datetime, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, update, and_, or_, func
from sqlalchemy.orm import selectinload
import asyncio

from ..models.game import (
    RoomParticipant, Game, GameRound,
    ParticipantStatus, ConnectionStatus, GameStatus
)
from ..models.user import User
from ..utils.exceptions import ValidationError, NotFoundError


class PlayerManager:
    """Менеджер состояния игроков"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
        self.TIMEOUT_SECONDS = 30  # Таймаут неактивности
        self.MAX_DISCONNECT_COUNT = 3  # Максимум отключений
        self.MAX_MISSED_ACTIONS = 2   # Максимум пропущенных действий
    
    async def update_player_activity(self, user_id: int, room_id: int) -> bool:
        """
        Обновляет активность игрока.
        
        Args:
            user_id: ID игрока
            room_id: ID комнаты
            
        Returns:
            bool: True если игрок активен, False если исключен
        """
        current_time = datetime.utcnow()
        
        result = await self.db.execute(
            update(RoomParticipant)
            .where(
                and_(
                    RoomParticipant.user_id == user_id,
                    RoomParticipant.room_id == room_id
                )
            )
            .values(
                last_activity=current_time,
                last_ping=current_time,
                connection_status=ConnectionStatus.CONNECTED
            )
        )
        
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        return result.rowcount > 0
    
    async def mark_player_disconnected(self, user_id: int, room_id: int) -> Dict[str, any]:
        """
        Отмечает игрока как отключенного.
        
        Args:
            user_id: ID игрока
            room_id: ID комнаты
            
        Returns:
            Dict: Информация о состоянии игрока
        """
        current_time = datetime.utcnow()
        
        # Получаем текущее состояние игрока
        result = await self.db.execute(
            select(RoomParticipant)
            .where(
                and_(
                    RoomParticipant.user_id == user_id,
                    RoomParticipant.room_id == room_id
                )
            )
        )
        participant = result.scalar()
        
        if not participant:
            raise NotFoundError("Игрок не найден в комнате")
        
        # Увеличиваем счетчик отключений
        new_disconnect_count = participant.disconnect_count + 1
        should_exclude = new_disconnect_count >= self.MAX_DISCONNECT_COUNT
        
        # Обновляем статус
        new_status = ParticipantStatus.LEFT if should_exclude else ParticipantStatus.DISCONNECTED
        
        await self.db.execute(
            update(RoomParticipant)
            .where(RoomParticipant.id == participant.id)
            .values(
                connection_status=ConnectionStatus.DISCONNECTED,
                status=new_status,
                disconnect_count=new_disconnect_count,
                last_activity=current_time
            )
        )
        
        await self.db.commit()
        
        return {
            "user_id": user_id,
            "excluded": should_exclude,
            "disconnect_count": new_disconnect_count,
            "status": new_status.value if hasattr(new_status, 'value') else new_status,
            "can_rejoin": not should_exclude
        }
    
    async def handle_missed_action(self, user_id: int, room_id: int, action_type: str) -> Dict[str, any]:
        """
        Обрабатывает пропущенное действие игрока (выбор карты или голосование).
        
        Args:
            user_id: ID игрока
            room_id: ID комнаты
            action_type: Тип действия ("card_selection" или "voting")
            
        Returns:
            Dict: Информация о последствиях
        """
        # Получаем игрока
        result = await self.db.execute(
            select(RoomParticipant)
            .where(
                and_(
                    RoomParticipant.user_id == user_id,
                    RoomParticipant.room_id == room_id
                )
            )
        )
        participant = result.scalar()
        
        if not participant:
            return {"excluded": False, "missed_actions": 0}
        
        new_missed_actions = participant.missed_actions + 1
        should_exclude = new_missed_actions >= self.MAX_MISSED_ACTIONS
        
        # Обновляем статус
        new_status = ParticipantStatus.LEFT if should_exclude else participant.status
        new_connection_status = ConnectionStatus.TIMEOUT if not should_exclude else ConnectionStatus.DISCONNECTED
        
        await self.db.execute(
            update(RoomParticipant)
            .where(RoomParticipant.id == participant.id)
            .values(
                missed_actions=new_missed_actions,
                status=new_status,
                connection_status=new_connection_status,
                last_activity=datetime.utcnow()
            )
        )
        
        # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        
        return {
            "user_id": user_id,
            "action_type": action_type,
            "excluded": should_exclude,
            "missed_actions": new_missed_actions,
            "status": new_status.value if hasattr(new_status, 'value') else new_status,
            "reason": f"Пропущено действие: {action_type}"
        }
    
    async def get_active_players(self, room_id: int) -> List[Dict[str, any]]:
        """
        Получает список активных игроков в комнате.
        
        Args:
            room_id: ID комнаты
            
        Returns:
            List: Список активных игроков
        """
        result = await self.db.execute(
            select(RoomParticipant, User.nickname)
            .join(User, RoomParticipant.user_id == User.id)
            .where(
                and_(
                    RoomParticipant.room_id == room_id,
                    RoomParticipant.status == ParticipantStatus.ACTIVE
                )
            )
        )
        
        players = []
        for participant, nickname in result:
            players.append({
                "user_id": participant.user_id,
                "nickname": nickname,
                "connection_status": participant.connection_status,
                "last_activity": participant.last_activity,
                "disconnect_count": participant.disconnect_count,
                "missed_actions": participant.missed_actions,
                "is_connected": participant.connection_status == ConnectionStatus.CONNECTED
            })
        
        return players
    
    async def check_players_timeout(self, room_id: int) -> List[Dict[str, any]]:
        """
        Проверяет игроков на таймаут и обновляет их статус.
        
        Args:
            room_id: ID комнаты
            
        Returns:
            List: Игроки с таймаутом
        """
        timeout_threshold = datetime.utcnow() - timedelta(seconds=self.TIMEOUT_SECONDS)
        
        # Находим игроков с таймаутом
        result = await self.db.execute(
            select(RoomParticipant, User.nickname)
            .join(User, RoomParticipant.user_id == User.id)
            .where(
                and_(
                    RoomParticipant.room_id == room_id,
                    RoomParticipant.status == ParticipantStatus.ACTIVE,
                    RoomParticipant.connection_status == ConnectionStatus.CONNECTED,
                    RoomParticipant.last_activity < timeout_threshold
                )
            )
        )
        
        timeout_players = []
        for participant, nickname in result:
            # Отмечаем как таймаут
            await self.db.execute(
                update(RoomParticipant)
                .where(RoomParticipant.id == participant.id)
                .values(connection_status=ConnectionStatus.TIMEOUT)
            )
            
            timeout_players.append({
                "user_id": participant.user_id,
                "nickname": nickname,
                "last_activity": participant.last_activity,
                "timeout_duration": (datetime.utcnow() - participant.last_activity).total_seconds()
            })
        
        if timeout_players:
            # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
            pass
        
        return timeout_players
    
    async def get_players_for_action(self, room_id: int, action_type: str) -> Dict[str, any]:
        """
        Получает игроков которые должны выполнить действие.
        
        Args:
            room_id: ID комнаты
            action_type: Тип действия
            
        Returns:
            Dict: Статистика по игрокам
        """
        active_players = await self.get_active_players(room_id)
        
        # Фильтруем по статусу подключения
        connected_players = [p for p in active_players if p["is_connected"]]
        timeout_players = [p for p in active_players if p["connection_status"] == "timeout"]
        disconnected_players = [p for p in active_players if p["connection_status"] == "disconnected"]
        
        return {
            "total_active": len(active_players),
            "connected": len(connected_players),
            "timeout": len(timeout_players),
            "disconnected": len(disconnected_players),
            "should_wait_for": connected_players,
            "can_skip": timeout_players + disconnected_players,
            "action_type": action_type
        }
    
    async def cleanup_inactive_players(self, room_id: int) -> List[int]:
        """
        Удаляет неактивных игроков из игры.
        
        Args:
            room_id: ID комнаты
            
        Returns:
            List[int]: ID исключенных игроков
        """
        # Находим игроков для исключения
        result = await self.db.execute(
            select(RoomParticipant.user_id)
            .where(
                and_(
                    RoomParticipant.room_id == room_id,
                    or_(
                        RoomParticipant.disconnect_count >= self.MAX_DISCONNECT_COUNT,
                        RoomParticipant.missed_actions >= self.MAX_MISSED_ACTIONS
                    )
                )
            )
        )
        
        excluded_users = [user_id for (user_id,) in result]
        
        if excluded_users:
            # Обновляем статус на LEFT
            await self.db.execute(
                update(RoomParticipant)
                .where(
                    and_(
                        RoomParticipant.room_id == room_id,
                        RoomParticipant.user_id.in_(excluded_users)
                    )
                )
                .values(status=ParticipantStatus.LEFT)
            )
            # НЕ коммитим здесь - пусть FastAPI dependency сам управляет транзакцией
        
        return excluded_users 