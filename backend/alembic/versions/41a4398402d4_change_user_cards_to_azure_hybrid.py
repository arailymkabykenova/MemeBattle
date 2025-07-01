"""change_user_cards_to_azure_hybrid

Revision ID: 41a4398402d4
Revises: a8ac1a5acc8c
Create Date: 2025-06-29 21:05:42.775791

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '41a4398402d4'
down_revision: Union[str, None] = 'a8ac1a5acc8c'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """
    Изменяет структуру user_cards для гибридного подхода:
    - Удаляет card_id (ссылка на таблицу cards)
    - Добавляет card_type (starter, standard, unique)
    - Добавляет card_number (номер карты в Azure папке)
    """
    # Удаляем foreign key constraint
    op.drop_constraint('user_cards_card_id_fkey', 'user_cards', type_='foreignkey')
    
    # Удаляем колонку card_id
    op.drop_column('user_cards', 'card_id')
    
    # Добавляем новые колонки
    op.add_column('user_cards', sa.Column('card_type', sa.String(20), nullable=False, server_default='starter'))
    op.add_column('user_cards', sa.Column('card_number', sa.Integer, nullable=False, server_default='1'))
    
    # Убираем server_default после добавления
    op.alter_column('user_cards', 'card_type', server_default=None)
    op.alter_column('user_cards', 'card_number', server_default=None)
    
    # Создаем составной индекс для быстрого поиска
    op.create_index('ix_user_cards_user_type_number', 'user_cards', ['user_id', 'card_type', 'card_number'])


def downgrade() -> None:
    """
    Откатывает изменения обратно к структуре с card_id.
    """
    # Удаляем индекс
    op.drop_index('ix_user_cards_user_type_number', 'user_cards')
    
    # Удаляем новые колонки
    op.drop_column('user_cards', 'card_number')
    op.drop_column('user_cards', 'card_type')
    
    # Возвращаем card_id
    op.add_column('user_cards', sa.Column('card_id', sa.Integer, nullable=False, server_default='1'))
    op.alter_column('user_cards', 'card_id', server_default=None)
    
    # Восстанавливаем foreign key
    op.create_foreign_key('user_cards_card_id_fkey', 'user_cards', 'cards', ['card_id'], ['id'])
