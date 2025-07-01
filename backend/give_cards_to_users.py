#!/usr/bin/env python3
"""
Временный скрипт для выдачи карт пользователям 13 и 14.
Для тестирования игры.
"""

import asyncio
import os
import sys
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession

# Добавляем директорию app в path
sys.path.append(os.path.join(os.path.dirname(__file__), 'app'))

from app.core.database import get_async_session
from app.models.user import UserCard


async def give_cards_to_users():
    """Выдает карты пользователям 13 и 14"""
    
    async for session in get_async_session():
        try:
            # Карты для пользователя 13 (Player1)
            cards_player1 = [
                UserCard(user_id=13, card_type="starter", card_number=1),
                UserCard(user_id=13, card_type="starter", card_number=2),
                UserCard(user_id=13, card_type="starter", card_number=3),
                UserCard(user_id=13, card_type="starter", card_number=4),
                UserCard(user_id=13, card_type="starter", card_number=5),
                UserCard(user_id=13, card_type="starter", card_number=6),
                UserCard(user_id=13, card_type="starter", card_number=7),
                UserCard(user_id=13, card_type="starter", card_number=8),
                UserCard(user_id=13, card_type="starter", card_number=9),
                UserCard(user_id=13, card_type="starter", card_number=10),
            ]
            
            # Карты для пользователя 14 (Player2)
            cards_player2 = [
                UserCard(user_id=14, card_type="starter", card_number=1),
                UserCard(user_id=14, card_type="starter", card_number=2),
                UserCard(user_id=14, card_type="starter", card_number=3),
                UserCard(user_id=14, card_type="starter", card_number=4),
                UserCard(user_id=14, card_type="starter", card_number=5),
                UserCard(user_id=14, card_type="starter", card_number=6),
                UserCard(user_id=14, card_type="starter", card_number=7),
                UserCard(user_id=14, card_type="starter", card_number=8),
                UserCard(user_id=14, card_type="starter", card_number=9),
                UserCard(user_id=14, card_type="starter", card_number=10),
            ]
            
            # Добавляем карты в базу
            for card in cards_player1 + cards_player2:
                session.add(card)
            
            await session.commit()
            print("✅ Карты успешно выданы пользователям 13 и 14!")
            print(f"Player1 (ID=13): 10 стартовых карт")
            print(f"Player2 (ID=14): 10 стартовых карт")
            
        except Exception as e:
            print(f"❌ Ошибка: {e}")
            await session.rollback()
        finally:
            await session.close()
            break


if __name__ == "__main__":
    asyncio.run(give_cards_to_users()) 