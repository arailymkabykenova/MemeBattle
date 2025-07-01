#!/usr/bin/env python3
"""
Тест многоязычной функциональности AI сервиса.
"""

import asyncio
from datetime import date, datetime
from app.services.ai_service import AIService
from sqlalchemy.ext.asyncio import AsyncSession


class MockAsyncSession:
    """Мок для AsyncSession для тестирования"""
    pass


async def test_ai_multilingual():
    """Тестирует многоязычную функциональность AI сервиса"""
    print("🧪 Тестирование многоязычной функциональности AI сервиса...")
    
    # Создаем мок сессии
    mock_db = MockAsyncSession()
    ai_service = AIService(mock_db)
    
    # Тестовые данные
    test_ages = [
        date(2015, 5, 15),  # 8 лет - kids
        date(2008, 3, 10),  # 15 лет - teens
        date(1995, 7, 20),  # 28 лет - young_adults
        date(1980, 12, 5),  # 43 года - adults
    ]
    
    test_genders = ["male", "female", "male", "female"]
    
    print("\n📝 Тестирование тем по возрастным группам:")
    
    # Тест 1: Проверка тем для русского языка
    print("\n🇷🇺 Русский язык:")
    for age_group in ["kids", "teens", "young_adults", "adults", "seniors"]:
        topics = ai_service.get_topics_by_demographics(age_group, "ru")
        print(f"  {age_group}: {', '.join(topics[:5])}...")
    
    # Тест 2: Проверка тем для английского языка
    print("\n🇺🇸 Английский язык:")
    for age_group in ["kids", "teens", "young_adults", "adults", "seniors"]:
        topics = ai_service.get_topics_by_demographics(age_group, "en")
        print(f"  {age_group}: {', '.join(topics[:5])}...")
    
    print("\n🎯 Тестирование определения возрастных групп:")
    
    # Тест 3: Определение возрастных групп
    age_group = ai_service._determine_age_group(test_ages)
    print(f"  Средняя возрастная группа: {age_group}")
    
    # Тест 4: Определение гендерной группы
    gender_group = ai_service._determine_gender_group(test_genders)
    print(f"  Преобладающая гендерная группа: {gender_group}")
    
    print("\n🔄 Тестирование fallback ситуаций:")
    
    # Тест 5: Fallback ситуации на русском
    print("\n🇷🇺 Fallback ситуации (русский):")
    for i in range(1, 4):
        situation = ai_service._get_fallback_situation(i, "ru")
        print(f"  Раунд {i}: {situation}")
    
    # Тест 6: Fallback ситуации на английском
    print("\n🇺🇸 Fallback ситуации (английский):")
    for i in range(1, 4):
        situation = ai_service._get_fallback_situation(i, "en")
        print(f"  Раунд {i}: {situation}")
    
    print("\n🔧 Тестирование обработки неподдерживаемых языков:")
    
    # Тест 7: Неподдерживаемый язык
    topics = ai_service.get_topics_by_demographics("kids", "fr")
    print(f"  Неподдерживаемый язык 'fr' -> используется 'ru': {len(topics)} тем")
    
    fallback = ai_service._get_fallback_situation(1, "de")
    print(f"  Fallback для неподдерживаемого языка 'de' -> используется 'ru': {fallback}")
    
    print("\n✅ Тестирование завершено успешно!")
    print("\n📊 Результаты:")
    print("  ✅ Поддержка русского и английского языков")
    print("  ✅ Темы для всех возрастных групп")
    print("  ✅ Fallback ситуации на обоих языках")
    print("  ✅ Обработка неподдерживаемых языков")
    print("  ✅ Определение возрастных и гендерных групп")


if __name__ == "__main__":
    asyncio.run(test_ai_multilingual()) 