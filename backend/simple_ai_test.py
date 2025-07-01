"""
Простой тест AI генерации ситуаций.
Использует существующих пользователей и проверяет генерацию ситуаций.
"""

import asyncio
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy import select

from app.services.ai_service import AIService
from app.services.game_service import GameService
from app.models.user import User
from app.core.config import get_settings

async def simple_ai_test():
    """Простой тест AI генерации"""
    
    print("🤖 Простой тест AI генерации ситуаций...")
    print("=" * 50)
    
    # Настройки
    settings = get_settings()
    engine = create_async_engine(settings.database_url)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as db:
        # Получаем существующих пользователей
        result = await db.execute(select(User).limit(2))
        users = result.scalars().all()
        
        if len(users) < 2:
            print("❌ Нужно минимум 2 пользователя для теста")
            return
        
        user1, user2 = users[0], users[1]
        print(f"👥 Используем пользователей: {user1.nickname} и {user2.nickname}")
        
        # Создаем AI сервис
        ai_service = AIService(db)
        
        print("\n🧪 Тестируем генерацию ситуаций для разных раундов:")
        print("-" * 50)
        
        # Тестируем генерацию для разных раундов
        for round_num in range(1, 8):
            print(f"\n🎯 Раунд {round_num}:")
            
            # Генерируем ситуацию
            situation = await ai_service.generate_situation_card(
                round_number=round_num,
                player_ages=[user1.birth_date, user2.birth_date],
                player_genders=[user1.gender, user2.gender]
            )
            
            print(f"📝 Ситуация: {situation}")
            print("-" * 30)
        
        print("\n🎉 Тест завершен!")
        print("=" * 50)
        
    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(simple_ai_test()) 