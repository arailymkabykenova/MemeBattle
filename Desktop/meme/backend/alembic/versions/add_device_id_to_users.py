"""add_device_id_to_users

Revision ID: add_device_id_to_users
Revises: 82cec1c583b5
Create Date: 2025-06-30 16:30:00.000000

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'add_device_id_to_users'
down_revision: Union[str, None] = '82cec1c583b5'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """
    Adds device_id column and makes profile fields nullable.
    """
    # Add device_id column
    op.add_column('users', sa.Column('device_id', sa.String(128), nullable=False))
    op.create_index('ix_users_device_id', 'users', ['device_id'], unique=True)
    
    # Make profile fields nullable
    op.alter_column('users', 'nickname',
        existing_type=sa.String(50),
        nullable=True
    )
    op.alter_column('users', 'birth_date',
        existing_type=sa.Date(),
        nullable=True
    )
    op.alter_column('users', 'gender',
        existing_type=sa.String(10),
        nullable=True
    )
    
    # Drop game_center_player_id as we're not using it anymore
    op.drop_index('ix_users_game_center_player_id', 'users')
    op.drop_column('users', 'game_center_player_id')


def downgrade() -> None:
    """
    Reverts the changes.
    """
    # Add back game_center_player_id
    op.add_column('users', sa.Column('game_center_player_id', sa.String(128), nullable=False))
    op.create_index('ix_users_game_center_player_id', 'users', ['game_center_player_id'], unique=True)
    
    # Make profile fields non-nullable again
    op.alter_column('users', 'nickname',
        existing_type=sa.String(50),
        nullable=False
    )
    op.alter_column('users', 'birth_date',
        existing_type=sa.Date(),
        nullable=False
    )
    op.alter_column('users', 'gender',
        existing_type=sa.String(10),
        nullable=False
    )
    
    # Drop device_id
    op.drop_index('ix_users_device_id', 'users')
    op.drop_column('users', 'device_id') 