"""
Тестовый скрипт для проверки AI генерации в игровом процессе.
Создает тестовую игру и проверяет генерацию ситуаций для каждого раунда.
"""

import asyncio
import json
from datetime import datetime
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

from app.services.ai_service import AIService
from app.services.game_service import GameService
from app.services.room_service import RoomService
from app.services.user_service import UserService
from app.schemas.user import UserCreate
from app.core.config import get_settings

async def test_ai_in_game():
    """Тестирует AI генерацию в игровом процессе"""
    
    print("🎮 Тестирование AI генерации в игре...")
    print("=" * 60)
    
    # Настройки
    settings = get_settings()
    engine = create_async_engine(settings.database_url)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as db:
        # Создаем тестовых пользователей
        user_service = UserService(db)
        
        print("👥 Создаем тестовых пользователей...")
        
        # Создаем пользователя 1 (25 лет, мужчина)
        user1_data = UserCreate(
            game_center_player_id="test_player_1_ai",
            nickname="Player1_AI",
            birth_date="1999-01-15",
            gender="male"
        )
        user1 = await user_service.create_user_profile(user1_data)
        
        # Создаем пользователя 2 (28 лет, женщина)
        user2_data = UserCreate(
            game_center_player_id="test_player_2_ai", 
            nickname="Player2_AI",
            birth_date="1996-05-20",
            gender="female"
        )
        user2 = await user_service.create_user_profile(user2_data)
        
        print(f"✅ Созданы пользователи: {user1.nickname} (ID: {user1.id}), {user2.nickname} (ID: {user2.id})")
        
        # Создаем комнату
        room_service = RoomService(db)
        
        print("\n🏠 Создаем игровую комнату...")
        
        room = await room_service.create_room(
            creator_id=user1.id,
            max_players=4,
            is_public=True
        )
        
        print(f"✅ Создана комната: ID {room.id}")
        
        # Присоединяем второго игрока
        await room_service.join_room(room.id, user2.id)
        print(f"✅ {user2.nickname} присоединился к комнате")
        
        # Начинаем игру
        print("\n🎮 Начинаем игру...")
        
        game_result = await room_service.start_game(room.id, user1.id)
        game_id = game_result["game_id"]
        
        print(f"✅ Игра началась: ID {game_id}")
        
        # Тестируем AI генерацию для каждого раунда
        game_service = GameService(db)
        
        print("\n🤖 Тестируем AI генерацию ситуаций для каждого раунда:")
        print("-" * 60)
        
        for round_num in range(1, 8):  # 7 раундов
            print(f"\n🎯 Раунд {round_num}:")
            
            # Получаем игру
            game = await game_service.get_game_by_room(room.id)
            
            # Генерируем ситуацию через AI
            situation = await game_service._generate_situation_for_round(game)
            
            print(f"📝 Ситуация: {situation}")
            
            # Начинаем раунд с этой ситуацией
            round_result = await game_service.start_round(game.id, situation)
            
            print(f"✅ Раунд {round_num} создан: ID {round_result.id}")
            
            # Имитируем выбор карт (для тестирования)
            print(f"🎴 Игроки выбирают карты...")
            
            # Имитируем голосование (для тестирования)  
            print(f"🗳️ Игроки голосуют...")
            
            # Подсчитываем результаты
            results = await game_service.calculate_round_results(round_result.id)
            
            print(f"🏆 Победитель раунда: {results.winner_nickname}")
            print(f"📊 Очки: {results.vote_counts}")
            
            print("-" * 40)
        
        print("\n🎉 Тестирование завершено!")
        print("=" * 60)
        
        # Показываем финальные результаты
        final_game = await game_service.get_game_by_room(room.id)
        print(f"🏁 Финальный статус игры: {final_game.status}")
        print(f"🎯 Общий победитель: {final_game.winner_id}")
        
    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(test_ai_in_game()) 