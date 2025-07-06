"""create_game_tables

Revision ID: 9439cfcfa962
Revises: 41a4398402d4
Create Date: 2025-06-29 21:22:30.327728

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '9439cfcfa962'
down_revision: Union[str, None] = '41a4398402d4'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """
    Создает таблицы для игровой логики:
    - rooms: игровые комнаты
    - room_participants: участники комнат
    - games: игры
    - game_rounds: раунды игр
    - player_choices: выборы карт игроками
    - votes: голосования за карты
    """
    
    # 1. Таблица игровых комнат
    op.create_table(
        'rooms',
        sa.Column('id', sa.Integer, primary_key=True, index=True),
        sa.Column('creator_id', sa.Integer, sa.ForeignKey('users.id'), nullable=False),
        sa.Column('max_players', sa.Integer, default=6, nullable=False),
        sa.Column('status', sa.String(20), default='waiting', nullable=False),
        sa.Column('created_at', sa.DateTime, default=sa.func.now(), nullable=False),
    )
    
    # 2. Таблица участников комнат
    op.create_table(
        'room_participants',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('room_id', sa.Integer, sa.ForeignKey('rooms.id'), nullable=False),
        sa.Column('user_id', sa.Integer, sa.ForeignKey('users.id'), nullable=False),
        sa.Column('joined_at', sa.DateTime, default=sa.func.now(), nullable=False),
        sa.Column('status', sa.String(20), default='active', nullable=False),
    )
    
    # 3. Таблица игр
    op.create_table(
        'games',
        sa.Column('id', sa.Integer, primary_key=True, index=True),
        sa.Column('room_id', sa.Integer, sa.ForeignKey('rooms.id'), nullable=False),
        sa.Column('status', sa.String(20), default='starting', nullable=False),
        sa.Column('current_round', sa.Integer, default=1, nullable=False),
        sa.Column('winner_id', sa.Integer, sa.ForeignKey('users.id'), nullable=True),
        sa.Column('created_at', sa.DateTime, default=sa.func.now(), nullable=False),
        sa.Column('finished_at', sa.DateTime, nullable=True),
    )
    
    # 4. Таблица раундов игр
    op.create_table(
        'game_rounds',
        sa.Column('id', sa.Integer, primary_key=True, index=True),
        sa.Column('game_id', sa.Integer, sa.ForeignKey('games.id'), nullable=False),
        sa.Column('round_number', sa.Integer, nullable=False),
        sa.Column('situation_text', sa.Text, nullable=False),
        sa.Column('duration_seconds', sa.Integer, default=50, nullable=False),
        sa.Column('created_at', sa.DateTime, default=sa.func.now(), nullable=False),
        sa.Column('started_at', sa.DateTime, nullable=True),
        sa.Column('finished_at', sa.DateTime, nullable=True),
    )
    
    # 5. Таблица выборов карт игроками
    op.create_table(
        'player_choices',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('round_id', sa.Integer, sa.ForeignKey('game_rounds.id'), nullable=False),
        sa.Column('user_id', sa.Integer, sa.ForeignKey('users.id'), nullable=False),
        sa.Column('card_type', sa.String(20), nullable=False),
        sa.Column('card_number', sa.Integer, nullable=False),
        sa.Column('submitted_at', sa.DateTime, default=sa.func.now(), nullable=False),
    )
    
    # 6. Таблица голосований
    op.create_table(
        'votes',
        sa.Column('id', sa.Integer, primary_key=True),
        sa.Column('round_id', sa.Integer, sa.ForeignKey('game_rounds.id'), nullable=False),
        sa.Column('voter_id', sa.Integer, sa.ForeignKey('users.id'), nullable=False),
        sa.Column('choice_id', sa.Integer, sa.ForeignKey('player_choices.id'), nullable=False),
        sa.Column('created_at', sa.DateTime, default=sa.func.now(), nullable=False),
    )
    
    # Создаем индексы для производительности
    op.create_index('ix_rooms_creator_id', 'rooms', ['creator_id'])
    op.create_index('ix_rooms_status', 'rooms', ['status'])
    op.create_index('ix_room_participants_room_id', 'room_participants', ['room_id'])
    op.create_index('ix_room_participants_user_id', 'room_participants', ['user_id'])
    op.create_index('ix_games_room_id', 'games', ['room_id'])
    op.create_index('ix_games_status', 'games', ['status'])
    op.create_index('ix_game_rounds_game_id', 'game_rounds', ['game_id'])
    op.create_index('ix_player_choices_round_id', 'player_choices', ['round_id'])
    op.create_index('ix_player_choices_user_id', 'player_choices', ['user_id'])
    op.create_index('ix_votes_round_id', 'votes', ['round_id'])
    op.create_index('ix_votes_voter_id', 'votes', ['voter_id'])


def downgrade() -> None:
    """
    Удаляет все игровые таблицы.
    """
    # Удаляем индексы
    op.drop_index('ix_votes_voter_id', 'votes')
    op.drop_index('ix_votes_round_id', 'votes') 
    op.drop_index('ix_player_choices_user_id', 'player_choices')
    op.drop_index('ix_player_choices_round_id', 'player_choices')
    op.drop_index('ix_game_rounds_game_id', 'game_rounds')
    op.drop_index('ix_games_status', 'games')
    op.drop_index('ix_games_room_id', 'games')
    op.drop_index('ix_room_participants_user_id', 'room_participants')
    op.drop_index('ix_room_participants_room_id', 'room_participants')
    op.drop_index('ix_rooms_status', 'rooms')
    op.drop_index('ix_rooms_creator_id', 'rooms')
    
    # Удаляем таблицы в обратном порядке (из-за foreign keys)
    op.drop_table('votes')
    op.drop_table('player_choices')
    op.drop_table('game_rounds')
    op.drop_table('games')
    op.drop_table('room_participants')
    op.drop_table('rooms')
