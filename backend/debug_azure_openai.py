#!/usr/bin/env python3
"""
Отладка подключения к Azure OpenAI.
Проверяет настройки и пытается подключиться к API.
"""

import asyncio
import sys
import os
from openai import AsyncAzureOpenAI
from dotenv import load_dotenv

# Загружаем переменные окружения
load_dotenv()

async def test_azure_openai_connection():
    """Тестирует подключение к Azure OpenAI"""
    print("🔍 Отладка Azure OpenAI подключения...")
    
    # Получаем настройки
    endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
    key = os.getenv("AZURE_OPENAI_KEY")
    deployment = os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME")
    api_version = os.getenv("AZURE_OPENAI_API_VERSION", "2024-02-15-preview")
    
    print(f"📋 Настройки:")
    print(f"   Endpoint: {endpoint}")
    print(f"   Key: {key[:10]}..." if key else "   Key: НЕ УСТАНОВЛЕН")
    print(f"   Deployment: {deployment}")
    print(f"   API Version: {api_version}")
    
    # Проверяем наличие всех настроек
    if not all([endpoint, key, deployment]):
        print("❌ Не все настройки Azure OpenAI установлены!")
        return False
    
    try:
        # Создаем клиент
        print("\n🔌 Создание клиента Azure OpenAI...")
        client = AsyncAzureOpenAI(
            azure_endpoint=endpoint,
            api_key=key,
            api_version=api_version
        )
        print("✅ Клиент создан успешно")
        
        # Тестируем простой запрос
        print("\n🧪 Тестирование простого запроса...")
        response = await client.chat.completions.create(
            model=deployment,
            messages=[
                {"role": "system", "content": "Ты помощник для тестирования."},
                {"role": "user", "content": "Скажи 'Привет, мир!'"}
            ],
            max_tokens=50,
            temperature=0.7
        )
        
        result = response.choices[0].message.content
        print(f"✅ Ответ получен: {result}")
        return True
        
    except Exception as e:
        print(f"❌ Ошибка подключения: {e}")
        print(f"   Тип ошибки: {type(e).__name__}")
        
        # Анализируем ошибку
        if "DeploymentNotFound" in str(e):
            print("\n🔧 РЕШЕНИЕ: Deployment не найден!")
            print("   Возможные причины:")
            print("   1. Неправильное имя deployment")
            print("   2. Deployment не создан в Azure")
            print("   3. Неправильный endpoint")
            print("   4. Недостаточно прав доступа")
            
            # Предлагаем альтернативы
            print("\n💡 Попробуйте:")
            print("   1. Проверить имя deployment в Azure Portal")
            print("   2. Использовать другое имя модели (например, 'gpt-35-turbo-16k')")
            print("   3. Проверить права доступа к ресурсу")
            
        elif "Unauthorized" in str(e):
            print("\n🔧 РЕШЕНИЕ: Неавторизованный доступ!")
            print("   Проверьте API ключ в Azure Portal")
            
        elif "NotFound" in str(e):
            print("\n🔧 РЕШЕНИЕ: Ресурс не найден!")
            print("   Проверьте endpoint URL")
            
        return False

async def test_fallback_system():
    """Тестирует fallback систему"""
    print("\n🔄 Тестирование fallback системы...")
    
    try:
        from app.services.ai_service import AIService
        from sqlalchemy.ext.asyncio import AsyncSession
        
        # Создаем мок сессию
        class MockSession:
            pass
        
        ai_service = AIService(MockSession())
        
        # Тестируем генерацию с fallback
        situation = await ai_service.generate_situation_card(
            round_number=1,
            age_group="teens",
            language="ru"
        )
        
        print(f"✅ Fallback ситуация сгенерирована: {situation[:100]}...")
        return True
        
    except Exception as e:
        print(f"❌ Ошибка fallback системы: {e}")
        return False

async def main():
    """Основная функция"""
    print("🚀 Запуск отладки Azure OpenAI...")
    
    # Тестируем подключение
    connection_ok = await test_azure_openai_connection()
    
    # Тестируем fallback
    fallback_ok = await test_fallback_system()
    
    print(f"\n📊 Результаты:")
    print(f"   Azure OpenAI подключение: {'✅' if connection_ok else '❌'}")
    print(f"   Fallback система: {'✅' if fallback_ok else '❌'}")
    
    if not connection_ok:
        print(f"\n💡 Рекомендации:")
        print(f"   1. Проверьте настройки в Azure Portal")
        print(f"   2. Убедитесь, что deployment создан и активен")
        print(f"   3. Проверьте API ключ и права доступа")
        print(f"   4. Fallback система работает, поэтому игра будет функционировать")
    
    if fallback_ok:
        print(f"\n✅ Fallback система работает! Игра будет использовать предустановленные ситуации.")

if __name__ == "__main__":
    asyncio.run(main()) 