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
    nickname: Optional[str] = Field(None, min_length=2, max_length=50, description="Никнейм пользователя")
    birth_date: Optional[date] = Field(None, description="Дата рождения")
    gender: Optional[Gender] = Field(None, description="Пол пользователя")
    
    @field_validator('birth_date')
    @classmethod
    def validate_birth_date(cls, v: Optional[date]) -> Optional[date]:
        """Валидация даты рождения"""
        if v is None:
            return None
            
        today = date.today()
        age = today.year - v.year - ((today.month, today.day) < (v.month, v.day))
        
        if age < 6:
            raise ValueError("Возраст должен быть не менее 6 лет")
        if age > 120:
            raise ValueError("Некорректная дата рождения")
        
        return v
    
    @field_validator('nickname')
    @classmethod
    def validate_nickname(cls, v: Optional[str]) -> Optional[str]:
        """Валидация никнейма"""
        if v is None:
            return None
            
        if not v.strip():
            raise ValueError("Никнейм не может быть пустым")
        
        # Базовая проверка на допустимые символы (латиница, цифры, кириллица, дефис, подчеркивание)
        allowed_chars = set('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ')
        if not all(c in allowed_chars for c in v):
            raise ValueError("Никнейм содержит недопустимые символы")
        
        return v.strip()


class UserCreate(UserBase):
    """
    Схема для создания пользователя
    """
    # game_center_player_id: str = Field(..., min_length=1, max_length=128, description="Game Center Player ID")
    # @field_validator('game_center_player_id')
    # @classmethod
    # def validate_game_center_player_id(cls, v: str) -> str:
    #     if not v.strip():
    #         raise ValueError("Game Center Player ID не может быть пустым")
    #     return v.strip()
    # Оставляем только device_id, nickname, birth_date, gender и т.д.


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


class UserResponse(BaseModel):
    """Схема ответа с данными пользователя"""
    id: int
    device_id: str
    nickname: Optional[str] = Field(None, description="Никнейм пользователя")
    birth_date: Optional[date] = Field(None, description="Дата рождения")
    gender: Optional[Gender] = Field(None, description="Пол пользователя")
    rating: float = Field(default=0.0)
    created_at: datetime
    
    # Вычисляемые поля
    age: Optional[int] = Field(None, description="Возраст пользователя")
    is_profile_complete: bool = Field(default=False, description="Заполнен ли профиль")
    
    class Config:
        from_attributes = True
        
    @staticmethod
    def from_orm_with_age(user_orm):
        """Создает UserResponse из ORM объекта с вычислением возраста"""
        # Создаем базовый объект из ORM модели
        user_data = UserResponse.model_validate(user_orm)
        
        # Используем свойство age из модели User
        user_data.age = user_orm.age
        
        # Проверяем заполненность профиля
        user_data.is_profile_complete = all([
            user_orm.nickname,
            user_orm.birth_date,
            user_orm.gender
        ])
        
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


class UserProfileCreate(BaseModel):
    """Схема для заполнения профиля пользователя после аутентификации"""
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
        if v > today:
            raise ValueError("Дата рождения не может быть в будущем")
        
        return v
    
    @field_validator('nickname')
    @classmethod
    def validate_nickname(cls, v: str) -> str:
        """Валидация никнейма"""
        if not v.strip():
            raise ValueError("Никнейм не может быть пустым")
        
        # Базовая проверка на допустимые символы (латиница, цифры, кириллица, дефис, подчеркивание)
        allowed_chars = set('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯ')
        if not all(c in allowed_chars for c in v):
            raise ValueError("Никнейм содержит недопустимые символы")
        
        return v.strip()


class AuthResponse(BaseModel):
    access_token: str
    token_type: str
    user: UserResponse
    is_new_user: bool


class DeviceAuthRequest(BaseModel):
    device_id: str = Field(..., description="Уникальный идентификатор устройства") 