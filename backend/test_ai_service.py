"""
Тестовый скрипт для проверки AI Service.
Запускается только если настроены Azure OpenAI переменные окружения.
"""

import asyncio
import os
from datetime import date
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine
from sqlalchemy.orm import sessionmaker

from app.services.ai_service import AIService
from app.core.config import get_settings

async def test_ai_service():
    """Тестирует AI сервис"""
    
    print("🤖 Тестирование AI Service...")
    
    # Проверяем настройки
    settings = get_settings()
    
    if not all([
        settings.azure_openai_endpoint,
        settings.azure_openai_key,
        settings.azure_openai_deployment_name
    ]):
        print("❌ Azure OpenAI не настроен!")
        print("Добавьте в .env файл:")
        print("AZURE_OPENAI_ENDPOINT=https://your-resource.openai.azure.com/")
        print("AZURE_OPENAI_KEY=your-key")
        print("AZURE_OPENAI_DEPLOYMENT_NAME=gpt-35-turbo")
        return
    
    print("✅ Azure OpenAI настроен")
    
    # Используем PostgreSQL из настроек
    if not settings.database_url:
        print("❌ DATABASE_URL не настроен!")
        return
    
    print("✅ База данных настроена")
    
    # Создаем подключение к БД
    engine = create_async_engine(settings.database_url)
    async_session = sessionmaker(engine, class_=AsyncSession, expire_on_commit=False)
    
    async with async_session() as db:
        ai_service = AIService(db)
        
        print("\n🧪 Тест 1: Генерация базовой ситуации")
        try:
            situation = await ai_service.generate_situation_card(
                round_number=1,
                player_ages=[date(1995, 1, 1), date(1998, 5, 15)],  # 25-28 лет
                player_genders=["male", "female"]
            )
            print(f"✅ Сгенерировано: {situation}")
        except Exception as e:
            print(f"❌ Ошибка: {e}")
        
        print("\n🧪 Тест 2: Генерация для подростков")
        try:
            situation = await ai_service.generate_situation_card(
                round_number=3,
                player_ages=[date(2008, 3, 10), date(2009, 7, 22)],  # 14-15 лет
                player_genders=["male", "male"]
            )
            print(f"✅ Сгенерировано: {situation}")
        except Exception as e:
            print(f"❌ Ошибка: {e}")
        
        print("\n🧪 Тест 3: Генерация для взрослых")
        try:
            situation = await ai_service.generate_situation_card(
                round_number=5,
                player_ages=[date(1985, 11, 5), date(1982, 4, 12)],  # 38-41 лет
                player_genders=["female", "female"]
            )
            print(f"✅ Сгенерировано: {situation}")
        except Exception as e:
            print(f"❌ Ошибка: {e}")
        
        print("\n🧪 Тест 4: Fallback ситуация (без AI)")
        try:
            # Тестируем fallback без Azure OpenAI
            original_endpoint = settings.azure_openai_endpoint
            settings.azure_openai_endpoint = None
            
            situation = await ai_service.generate_situation_card(
                round_number=7,
                player_ages=[],
                player_genders=[]
            )
            print(f"✅ Fallback: {situation}")
            
            # Восстанавливаем настройки
            settings.azure_openai_endpoint = original_endpoint
            
        except Exception as e:
            print(f"❌ Ошибка fallback: {e}")
    
    await engine.dispose()

if __name__ == "__main__":
    asyncio.run(test_ai_service()) 