"""add_room_code_and_public_flag

Revision ID: 80d22484ede1
Revises: 9439cfcfa962
Create Date: 2025-06-29 21:39:51.499266

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '80d22484ede1'
down_revision: Union[str, None] = '9439cfcfa962'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """
    Добавляет поля для кодов комнат и публичности:
    - room_code: уникальный 6-значный код для приглашений
    - is_public: флаг публичности комнаты
    """
    
    # Добавляем поле room_code (уникальный код комнаты)
    op.add_column('rooms', sa.Column('room_code', sa.String(6), nullable=True))
    
    # Добавляем поле is_public (публичная/приватная комната)  
    op.add_column('rooms', sa.Column('is_public', sa.Boolean, nullable=False, server_default=sa.text('true')))
    
    # Создаем уникальный индекс для room_code
    op.create_index('ix_rooms_room_code', 'rooms', ['room_code'], unique=True)
    
    # Создаем индекс для быстрого поиска публичных комнат
    op.create_index('ix_rooms_is_public', 'rooms', ['is_public'])


def downgrade() -> None:
    """
    Удаляет добавленные поля и индексы.
    """
    # Удаляем индексы
    op.drop_index('ix_rooms_is_public', 'rooms')
    op.drop_index('ix_rooms_room_code', 'rooms')
    
    # Удаляем колонки
    op.drop_column('rooms', 'is_public')
    op.drop_column('rooms', 'room_code')
