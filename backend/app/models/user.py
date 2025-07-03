"""
Модель пользователя.
Определяет структуру таблицы users в базе данных.
"""

from datetime import datetime, date
from enum import Enum
from typing import Optional
from sqlalchemy import String, Integer, DateTime, Date, Float, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from ..core.database import Base


class Gender(str, Enum):
    """Перечисление полов пользователя"""
    MALE = "male"
    FEMALE = "female"
    OTHER = "other"


class User(Base):
    """
    Модель пользователя.
    
    Соответствует схеме: users (id, device_id, nickname, birth_date, gender, rating, created_at)
    """
    __tablename__ = "users"
    
    # Основные поля
    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    device_id: Mapped[str] = mapped_column(String(128), unique=True, index=True, nullable=False)
    nickname: Mapped[Optional[str]] = mapped_column(String(50), unique=True, index=True, nullable=True)
    birth_date: Mapped[Optional[date]] = mapped_column(Date, nullable=True)
    gender: Mapped[Optional[Gender]] = mapped_column(String(10), nullable=True)
    rating: Mapped[float] = mapped_column(Float, default=0.0, nullable=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    
    # Связи с другими таблицами (создадим позже)
    # user_cards: Mapped[list["UserCard"]] = relationship(back_populates="user")
    # created_rooms: Mapped[list["Room"]] = relationship(back_populates="creator")
    # room_participations: Mapped[list["RoomParticipant"]] = relationship(back_populates="user")
    
    def __repr__(self) -> str:
        return f"<User(id={self.id}, device_id='{self.device_id}', nickname='{self.nickname}', rating={self.rating})>"
    
    @property
    def age(self) -> Optional[int]:
        """Вычисляет возраст пользователя на основе даты рождения"""
        if not self.birth_date:
            return None
            
        today = date.today()
        return today.year - self.birth_date.year - (
            (today.month, today.day) < (self.birth_date.month, self.birth_date.day)
        )
    
    @property
    def is_profile_complete(self) -> bool:
        """Проверяет, заполнен ли профиль пользователя"""
        return bool(self.nickname and self.birth_date and self.gender)


class UserCard(Base):
    """
    Связующая таблица между пользователями и карточками (гибридный подход).
    
    Хранит связи пользователь -> карта через:
    - card_type: тип карты (starter, standard, unique)  
    - card_number: номер карты в Azure папке (1, 2, 3...)
    
    Соответствует схеме: user_cards (user_id, card_type, card_number, obtained_at)
    """
    __tablename__ = "user_cards"
    
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    user_id: Mapped[int] = mapped_column(Integer, ForeignKey("users.id"), nullable=False)
    card_type: Mapped[str] = mapped_column(String(20), nullable=False)  # starter, standard, unique
    card_number: Mapped[int] = mapped_column(Integer, nullable=False)   # номер в Azure папке
    obtained_at: Mapped[datetime] = mapped_column(DateTime, default=datetime.utcnow, nullable=False)
    
    # Связи (создадим после создания модели Card)
    # user: Mapped["User"] = relationship(back_populates="user_cards")
    
    def __repr__(self) -> str:
        return f"<UserCard(user_id={self.user_id}, card_type='{self.card_type}', card_number={self.card_number})>" 