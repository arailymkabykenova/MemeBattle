"""
Pydantic схемы для карточек.
Используются для валидации входящих и исходящих данных API.
"""

from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, field_validator
from ..models.card import CardType


class CardBase(BaseModel):
    """Базовая схема карточки с общими полями"""
    name: str = Field(default="", max_length=100, description="Название карточки (необязательно)")
    image_url: str = Field(..., max_length=500, description="URL изображения карточки")
    card_type: CardType = Field(..., description="Тип карточки")
    is_unique: bool = Field(default=False, description="Является ли карточка уникальной")
    description: Optional[str] = Field(None, description="Описание карточки")
    azure_blob_path: Optional[str] = Field(None, max_length=500, description="Путь в Azure Blob Storage")
    
    @field_validator('name')
    @classmethod
    def validate_name(cls, v: str) -> str:
        """Валидация названия карточки (может быть пустым)"""
        return v.strip() if v else ""
    
    @field_validator('image_url')
    @classmethod
    def validate_image_url(cls, v: str) -> str:
        """Валидация URL изображения"""
        if not v.strip():
            raise ValueError("URL изображения не может быть пустым")
        
        # Базовая проверка на URL формат (добавляем поддержку azure://)
        if not (v.startswith('http://') or v.startswith('https://') or v.startswith('/') or v.startswith('azure://')):
            raise ValueError("Некорректный формат URL")
        
        return v.strip()


class CardCreate(CardBase):
    """Схема для создания карточки"""
    pass


class CardUpdate(BaseModel):
    """Схема для обновления карточки"""
    name: Optional[str] = Field(None, min_length=1, max_length=100)
    image_url: Optional[str] = Field(None, max_length=500)
    card_type: Optional[CardType] = None
    is_unique: Optional[bool] = None
    description: Optional[str] = None
    azure_blob_path: Optional[str] = Field(None, max_length=500)
    
    @field_validator('name')
    @classmethod
    def validate_name(cls, v: Optional[str]) -> Optional[str]:
        """Валидация названия при обновлении (может быть пустым)"""
        if v is None:
            return v
        return v.strip() if v else ""
    
    @field_validator('image_url')
    @classmethod
    def validate_image_url(cls, v: Optional[str]) -> Optional[str]:
        """Валидация URL при обновлении"""
        if v is None:
            return v
        if not v.strip():
            raise ValueError("URL изображения не может быть пустым")
        
        if not (v.startswith('http://') or v.startswith('https://') or v.startswith('/') or v.startswith('azure://')):
            raise ValueError("Некорректный формат URL")
        
        return v.strip()


class CardResponse(CardBase):
    """Схема ответа с данными карточки"""
    id: str = Field(description="Уникальный идентификатор карточки")
    created_at: datetime
    
    # Вычисляемые поля (взяты из свойств модели Card)
    is_starter_card: bool = Field(description="Является ли стартовой карточкой")
    is_unique_card: bool = Field(description="Является ли уникальной карточкой")
    is_standard_card: bool = Field(description="Является ли стандартной карточкой")
    
    class Config:
        from_attributes = True


class CardListResponse(BaseModel):
    """Схема ответа для списка карточек"""
    cards: list[CardResponse]
    total: int
    limit: int
    offset: int
    has_more: bool
    
    
class StarterCardsResponse(BaseModel):
    """Схема ответа для стартовых карточек пользователя"""
    cards: list[CardResponse] = Field(..., description="Выданные стартовые карточки")
    count: int = Field(..., description="Количество выданных карточек")
    message: str = Field(..., description="Сообщение о выдаче карточек")


class CardForRoundResponse(BaseModel):
    """Схема ответа для карточек раунда"""
    cards: list[CardResponse] = Field(..., max_length=3, description="3 карточки для выбора в раунде")
    round_number: int = Field(..., description="Номер раунда")
    
    @field_validator('cards')
    @classmethod
    def validate_cards_count(cls, v: list[CardResponse]) -> list[CardResponse]:
        """Валидация количества карточек для раунда"""
        if len(v) != 3:
            raise ValueError("Для раунда должно быть ровно 3 карточки")
        return v 