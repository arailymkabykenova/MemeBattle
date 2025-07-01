"""
Модель карточки.
Определяет структуру таблицы cards в базе данных.
"""

from datetime import datetime
from enum import Enum
from sqlalchemy import String, Integer, DateTime, Boolean, Text
from sqlalchemy.orm import Mapped, mapped_column
from ..core.database import Base


class CardType(str, Enum):
    """Типы карточек - упрощенная система из 3 типов"""
    STARTER = "starter"      # Стартовые карточки (100 штук) - базовые карты для новых игроков
    STANDARD = "standard"    # Стандартные карточки (выдаются за победы в играх)
    UNIQUE = "unique"        # Уникальные карточки (редкие, за особые достижения)


class Card(Base):
    """
    Модель карточки.
    
    Соответствует схеме: cards (id, name, image_url, type, is_unique, created_at)
    """
    __tablename__ = "cards"
    
    # Основные поля
    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    name: Mapped[str] = mapped_column(String(100), nullable=False, index=True)
    image_url: Mapped[str] = mapped_column(String(500), nullable=False)
    card_type: Mapped[CardType] = mapped_column(String(20), nullable=False, index=True)
    is_unique: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    
    # Дополнительные поля для гибкости
    description: Mapped[str | None] = mapped_column(Text, nullable=True)
    azure_blob_path: Mapped[str | None] = mapped_column(String(500), nullable=True)  # Путь в Azure
    
    # Связи с другими таблицами (создадим позже)
    # user_cards: Mapped[list["UserCard"]] = relationship(back_populates="card")
    # player_choices: Mapped[list["PlayerChoice"]] = relationship(back_populates="card")
    
    def __repr__(self) -> str:
        return f"<Card(id={self.id}, name='{self.name}', type='{self.card_type}')>"
    
    @property
    def is_starter_card(self) -> bool:
        """Проверяет является ли карточка стартовой"""
        return self.card_type == CardType.STARTER
    
    @property
    def is_unique_card(self) -> bool:
        """Проверяет является ли карточка уникальной"""
        return self.is_unique or self.card_type == CardType.UNIQUE
    
    @property
    def is_standard_card(self) -> bool:
        """Проверяет является ли карточка стандартной"""
        return self.card_type == CardType.STANDARD 