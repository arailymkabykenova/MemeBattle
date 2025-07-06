"""
Модели для игровой логики.
Определяет структуру таблиц для комнат, игр, раундов и голосований.
"""

from datetime import datetime
from enum import Enum
from typing import Optional
import random
import string
from sqlalchemy import String, Integer, DateTime, Text, ForeignKey, Boolean
from sqlalchemy.orm import Mapped, mapped_column, relationship
from ..core.database import Base


class RoomStatus(str, Enum):
    """Статусы игровой комнаты"""
    WAITING = "waiting"      # Ожидание игроков
    PLAYING = "playing"      # Игра идет
    FINISHED = "finished"    # Игра завершена
    CANCELLED = "cancelled"  # Игра отменена


class ParticipantStatus(str, Enum):
    """Статусы участника комнаты"""
    ACTIVE = "active"          # Активный игрок
    DISCONNECTED = "disconnected"  # Временно отключен
    LEFT = "left"              # Покинул игру


class ConnectionStatus(str, Enum):
    """Статусы подключения игрока"""
    CONNECTED = "connected"        # Подключен
    DISCONNECTED = "disconnected"  # Отключен
    TIMEOUT = "timeout"           # Таймаут (не отвечает)


class GameStatus(str, Enum):
    """Статусы игры"""
    STARTING = "starting"      # Игра начинается
    ROUND_SETUP = "round_setup"    # Настройка раунда
    CARD_SELECTION = "card_selection"  # Выбор карт игроками
    VOTING = "voting"          # Голосование
    ROUND_RESULTS = "round_results"    # Результаты раунда
    FINISHED = "finished"      # Игра завершена


class Room(Base):
    """
    Модель игровой комнаты.
    
    Соответствует схеме: rooms (id, creator_id, max_players, status, room_code, created_at)
    """
    __tablename__ = "rooms"
    
    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    creator_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), nullable=False)
    max_players: Mapped[int] = mapped_column(Integer, default=6, nullable=False)  # 3-8 игроков
    status: Mapped[RoomStatus] = mapped_column(String(20), default=RoomStatus.WAITING, nullable=False)
    room_code: Mapped[Optional[str]] = mapped_column(String(6), unique=True, nullable=True, index=True)  # Код комнаты
    is_public: Mapped[bool] = mapped_column(Boolean, default=True, nullable=False)  # Публичная/приватная
    age_group: Mapped[Optional[str]] = mapped_column(String(20), nullable=True)  # Возрастная группа: kids, teens, young_adults, adults, seniors
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    
    # Связи
    # creator: Mapped["User"] = relationship(back_populates="created_rooms")
    # participants: Mapped[list["RoomParticipant"]] = relationship(back_populates="room")
    # games: Mapped[list["Game"]] = relationship(back_populates="room")
    
    def __repr__(self) -> str:
        return f"<Room(id={self.id}, code='{self.room_code}', creator_id={self.creator_id}, status='{self.status}')>"
    
    @staticmethod
    def generate_room_code() -> str:
        """Генерирует уникальный 6-значный код комнаты"""
        return ''.join(random.choices(string.ascii_uppercase + string.digits, k=6))


class RoomParticipant(Base):
    """
    Участники игровой комнаты.
    
    Соответствует схеме: room_participants (room_id, user_id, joined_at, status)
    """
    __tablename__ = "room_participants"
    
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    room_id: Mapped[int] = mapped_column(Integer, ForeignKey("rooms.id"), nullable=False)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), nullable=False)
    joined_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    status: Mapped[ParticipantStatus] = mapped_column(String(20), default=ParticipantStatus.ACTIVE, nullable=False)
    
    # Новые поля для отслеживания подключения
    connection_status: Mapped[ConnectionStatus] = mapped_column(String(20), default=ConnectionStatus.CONNECTED, nullable=False)
    last_activity: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    last_ping: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    disconnect_count: Mapped[int] = mapped_column(Integer, default=0, nullable=False)  # Количество отключений в игре
    missed_actions: Mapped[int] = mapped_column(Integer, default=0, nullable=False)   # Пропущенные действия (выбор карт/голосование)
    
    # Связи
    # room: Mapped["Room"] = relationship(back_populates="participants")
    # user: Mapped["User"] = relationship(back_populates="room_participations")
    
    def __repr__(self) -> str:
        return f"<RoomParticipant(room_id={self.room_id}, user_id={self.user_id}, status='{self.status}', connection='{self.connection_status}')>"


class Game(Base):
    """
    Модель игры.
    
    Соответствует схеме: games (id, room_id, status, current_round, winner_id, created_at)
    """
    __tablename__ = "games"
    
    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    room_id: Mapped[int] = mapped_column(Integer, ForeignKey("rooms.id"), nullable=False)
    status: Mapped[GameStatus] = mapped_column(String(20), default=GameStatus.STARTING, nullable=False)
    current_round: Mapped[int] = mapped_column(Integer, default=1, nullable=False)
    winner_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("users.id"), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    finished_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    
    # Связи
    # room: Mapped["Room"] = relationship(back_populates="games")
    # winner: Mapped[Optional["User"]] = relationship()
    # rounds: Mapped[list["GameRound"]] = relationship(back_populates="game")
    
    def __repr__(self) -> str:
        return f"<Game(id={self.id}, room_id={self.room_id}, round={self.current_round}, status='{self.status}')>"


class GameRound(Base):
    """
    Модель игрового раунда.
    
    Соответствует схеме: game_rounds (id, game_id, round_number, situation_text, duration, created_at)
    """
    __tablename__ = "game_rounds"
    
    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    game_id: Mapped[int] = mapped_column(Integer, ForeignKey("games.id"), nullable=False)
    round_number: Mapped[int] = mapped_column(Integer, nullable=False)
    situation_text: Mapped[str] = mapped_column(Text, nullable=False)  # Ситуационная карточка
    duration_seconds: Mapped[int] = mapped_column(Integer, default=50, nullable=False)  # Время на раунд
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    started_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    finished_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    
    # Новые поля для управления таймаутами
    selection_deadline: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)  # Дедлайн выбора карт
    voting_deadline: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)     # Дедлайн голосования
    auto_advanced: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)     # Автоматически продвинут по таймауту
    
    # Связи
    # game: Mapped["Game"] = relationship(back_populates="rounds")
    # player_choices: Mapped[list["PlayerChoice"]] = relationship(back_populates="round")
    # votes: Mapped[list["Vote"]] = relationship(back_populates="round")
    
    def __repr__(self) -> str:
        return f"<GameRound(id={self.id}, game_id={self.game_id}, round={self.round_number})>"


class PlayerChoice(Base):
    """
    Выбор карты игроком в раунде.
    
    Соответствует схеме: player_choices (id, round_id, user_id, card_type, card_number, submitted_at)
    """
    __tablename__ = "player_choices"
    
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    round_id: Mapped[int] = mapped_column(Integer, ForeignKey("game_rounds.id"), nullable=False)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), nullable=False)
    card_type: Mapped[str] = mapped_column(String(20), nullable=False)  # starter, standard, unique
    card_number: Mapped[int] = mapped_column(Integer, nullable=False)   # номер в Azure папке
    submitted_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    
    # Связи
    # round: Mapped["GameRound"] = relationship(back_populates="player_choices")
    # user: Mapped["User"] = relationship()
    
    def __repr__(self) -> str:
        return f"<PlayerChoice(round_id={self.round_id}, user_id={self.user_id}, card={self.card_type}:{self.card_number})>"


class Vote(Base):
    """
    Голосование за карту в раунде.
    
    Соответствует схеме: votes (id, round_id, voter_id, choice_id, created_at)
    """
    __tablename__ = "votes"
    
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    round_id: Mapped[int] = mapped_column(Integer, ForeignKey("game_rounds.id"), nullable=False)
    voter_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), nullable=False)  # Кто голосует
    choice_id: Mapped[int] = mapped_column(Integer, ForeignKey("player_choices.id"), nullable=False)  # За какой выбор
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    
    # Связи
    # round: Mapped["GameRound"] = relationship(back_populates="votes")
    # voter: Mapped["User"] = relationship()
    # choice: Mapped["PlayerChoice"] = relationship()
    
    def __repr__(self) -> str:
        return f"<Vote(round_id={self.round_id}, voter_id={self.voter_id}, choice_id={self.choice_id})>" 