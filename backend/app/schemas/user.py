"""
Pydantic схемы для пользователя.
Используются для валидации входящих и исходящих данных API.
"""

from datetime import datetime, date
from typing import Optional, List
from pydantic import BaseModel, Field, field_validator
from ..models.user import Gender


class UserBase(BaseModel):
    """Базовая схема пользователя с общими полями"""
    nickname: str = Field(..., min_length=2, max_length=50, description="Никнейм пользователя")
    birth_date: date = Field(..., description="Дата рождения")
    gender: Gender = Field(..., description="Пол пользователя")
    
    @field_validator('birth_date')
    @classmethod
    def validate_birth_date(cls, v: date) -> date:
        """Валидация даты рождения"""
        today = date.today()
        age = today.year - v.year - ((today.month, today.day) < (v.month, v.day))
        
        if age < 6:
            raise ValueError("Возраст должен быть не менее 6 лет")
        if age > 120:
            raise ValueError("Некорректная дата рождения")
        
        return v
    
    @field_validator('nickname')
    @classmethod
    def validate_nickname(cls, v: str) -> str:
        """Валидация никнейма"""
        if not v.strip():
            raise ValueError("Никнейм не может быть пустым")
        
        # Базовая проверка на допустимые символы
        allowed_chars = set('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-абвгдеёжзийклмнопрстуфхцчшщъыьэюя')
        if not all(c in allowed_chars for c in v):
            raise ValueError("Никнейм содержит недопустимые символы")
        
        return v.strip()


class UserCreate(UserBase):
    """Схема для создания пользователя"""
    game_center_player_id: str = Field(..., min_length=1, max_length=128, description="Game Center Player ID")
    
    @field_validator('game_center_player_id')
    @classmethod
    def validate_game_center_player_id(cls, v: str) -> str:
        """Валидация Game Center Player ID"""
        if not v.strip():
            raise ValueError("Game Center Player ID не может быть пустым")
        return v.strip()


class UserUpdate(BaseModel):
    """Схема для обновления пользователя"""
    nickname: Optional[str] = Field(None, min_length=2, max_length=50)
    birth_date: Optional[date] = None
    gender: Optional[Gender] = None
    
    @field_validator('birth_date')
    @classmethod
    def validate_birth_date(cls, v: Optional[date]) -> Optional[date]:
        """Валидация даты рождения при обновлении"""
        if v is None:
            return v
        
        today = date.today()
        age = today.year - v.year - ((today.month, today.day) < (v.month, v.day))
        
        if age < 6:
            raise ValueError("Возраст должен быть не менее 6 лет")
        if age > 120:
            raise ValueError("Некорректная дата рождения")
        
        return v


class UserResponse(UserBase):
    """Схема ответа с данными пользователя"""
    id: int
    game_center_player_id: str
    rating: float
    created_at: datetime
    
    # Вычисляемые поля
    age: Optional[int] = Field(None, description="Возраст пользователя")
    
    class Config:
        from_attributes = True
        
    @staticmethod
    def from_orm_with_age(user_orm):
        """Создает UserResponse из ORM объекта с вычислением возраста"""
        user_data = UserResponse.model_validate(user_orm)
        user_data.age = user_orm.age
        return user_data


class UserCardResponse(BaseModel):
    """Схема ответа для карточки пользователя (гибридный подход)"""
    user_id: int
    card_type: str  # starter, standard, unique
    card_number: int  # номер в Azure папке
    card_name: Optional[str] = None  # название из Azure
    card_url: Optional[str] = None   # URL изображения из Azure
    obtained_at: datetime
    
    class Config:
        from_attributes = True


class UserCardsGroupedResponse(BaseModel):
    """Схема ответа для карточек пользователя, сгруппированных по типам"""
    starter_cards: List[UserCardResponse] = []
    standard_cards: List[UserCardResponse] = []
    unique_cards: List[UserCardResponse] = []
    total_cards: int = 0


class UserProfileResponse(UserResponse):
    """Расширенная схема профиля пользователя"""
    cards_count: Optional[int] = Field(None, description="Общее количество карт")
    rank: Optional[int] = Field(None, description="Позиция в рейтинге") 