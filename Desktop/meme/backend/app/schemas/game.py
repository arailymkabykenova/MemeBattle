"""
Pydantic схемы для игровой логики.
"""

from datetime import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field
from ..models.game import RoomStatus, ParticipantStatus, GameStatus


# === ROOM SCHEMAS ===

class RoomCreate(BaseModel):
    """Схема создания игровой комнаты"""
    max_players: int = Field(default=6, ge=3, le=8, description="Максимум игроков (3-8)")
    is_public: bool = Field(default=True, description="Публичная комната (видна в списке)")
    generate_code: bool = Field(default=False, description="Генерировать код для приглашений")


class RoomJoinByCode(BaseModel):
    """Схема присоединения к комнате по коду"""
    room_code: str = Field(..., min_length=6, max_length=6, description="6-значный код комнаты")


class RoomResponse(BaseModel):
    """Схема ответа для игровой комнаты"""
    id: int
    creator_id: int
    max_players: int
    status: RoomStatus
    room_code: Optional[str] = None  # Код комнаты для приглашений
    is_public: bool = True  # Публичная/приватная
    age_group: Optional[str] = None  # Возрастная группа: kids, teens, young_adults, adults, seniors
    created_at: datetime
    current_players: int = 0  # Количество текущих игроков
    
    class Config:
        from_attributes = True


class RoomParticipantResponse(BaseModel):
    """Схема ответа для участника комнаты"""
    id: int
    room_id: int
    user_id: int
    user_nickname: Optional[str] = None  # Никнейм пользователя (может быть None)
    joined_at: datetime
    status: ParticipantStatus
    
    class Config:
        from_attributes = True


class RoomDetailResponse(RoomResponse):
    """Детальная схема комнаты с участниками"""
    participants: List[RoomParticipantResponse] = []
    creator_nickname: str  # Никнейм создателя
    can_start_game: bool = False  # Можно ли начать игру


# === QUICK MATCH SCHEMAS ===

class QuickMatchRequest(BaseModel):
    """Схема быстрого поиска игры"""
    preferred_players: Optional[int] = Field(None, ge=3, le=8, description="Предпочитаемое количество игроков")
    max_wait_time: int = Field(default=30, ge=10, le=120, description="Максимальное время ожидания в секундах")


class QuickMatchResponse(BaseModel):
    """Схема ответа быстрого поиска"""
    success: bool
    room_id: Optional[int] = None
    room_code: Optional[str] = None
    wait_time: Optional[int] = None  # Время ожидания
    message: str


# === GAME SCHEMAS ===

class GameResponse(BaseModel):
    """Схема ответа для игры"""
    id: int
    room_id: int
    status: GameStatus
    current_round: int
    winner_id: Optional[int] = None
    winner_nickname: Optional[str] = None
    created_at: datetime
    finished_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True


class GameRoundResponse(BaseModel):
    """Схема ответа для игрового раунда"""
    id: int
    game_id: int
    round_number: int
    situation_text: str
    duration_seconds: int
    created_at: datetime
    started_at: Optional[datetime] = None
    finished_at: Optional[datetime] = None
    time_remaining: Optional[int] = None  # Оставшееся время в секундах
    
    class Config:
        from_attributes = True


# === PLAYER CHOICE SCHEMAS ===

class PlayerChoiceCreate(BaseModel):
    """Схема создания выбора карты игроком"""
    card_type: str = Field(..., description="Тип карты (starter/standard/unique)")
    card_number: int = Field(..., gt=0, description="Номер карты в Azure папке")


class PlayerChoiceResponse(BaseModel):
    """Схема ответа для выбора карты игроком"""
    id: int
    round_id: int
    user_id: int
    user_nickname: Optional[str] = None  # Никнейм игрока (может быть None)
    card_type: str
    card_number: int
    card_name: Optional[str] = None  # Название карты из Azure
    card_url: Optional[str] = None   # URL изображения
    submitted_at: datetime
    vote_count: int = 0  # Количество голосов за эту карту
    
    class Config:
        from_attributes = True


# === VOTE SCHEMAS ===

class VoteCreate(BaseModel):
    """Схема создания голоса"""
    choice_id: int = Field(..., description="ID выбора карты за который голосуем")


class VoteResponse(BaseModel):
    """Схема ответа для голоса"""
    id: int
    round_id: int
    voter_id: int
    voter_nickname: Optional[str] = None  # Никнейм голосующего (может быть None)
    choice_id: int
    created_at: datetime
    
    class Config:
        from_attributes = True


# === ROUND RESULTS SCHEMAS ===

class RoundResultResponse(BaseModel):
    """Схема результатов раунда"""
    round_id: int
    round_number: int
    situation_text: str
    winner_choice: Optional[PlayerChoiceResponse] = None
    all_choices: List[PlayerChoiceResponse] = []
    votes: List[VoteResponse] = []
    next_round_starts_in: Optional[int] = None  # Секунды до следующего раунда


# === GAME STATE SCHEMAS ===

class GameStateResponse(BaseModel):
    """Полное состояние игры для WebSocket"""
    game: GameResponse
    current_round: Optional[GameRoundResponse] = None
    participants: List[RoomParticipantResponse] = []
    player_choices: List[PlayerChoiceResponse] = []
    votes: List[VoteResponse] = []
    my_choice: Optional[PlayerChoiceResponse] = None  # Выбор текущего игрока
    my_vote: Optional[VoteResponse] = None  # Голос текущего игрока
    can_submit_choice: bool = False
    can_vote: bool = False
    leaderboard: List[Dict[str, Any]] = []  # Текущий счет игроков


# === SITUATION GENERATION SCHEMAS ===

class SituationGenerateRequest(BaseModel):
    """Схема запроса генерации ситуационной карточки"""
    topic: Optional[str] = Field(None, description="Тема ситуации")
    difficulty: Optional[str] = Field("medium", description="Сложность: easy/medium/hard")
    age_group: Optional[str] = Field(None, description="Возрастная группа игроков")


class SituationResponse(BaseModel):
    """Схема ответа с сгенерированной ситуацией"""
    situation_text: str
    topic: Optional[str] = None
    estimated_difficulty: str
    generated_at: datetime 