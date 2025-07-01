#!/usr/bin/env python3
"""
Тестирование разных имен deployment для Azure OpenAI.
"""

import asyncio
import os
from openai import AsyncAzureOpenAI
from dotenv import load_dotenv

load_dotenv()

async def test_deployment(deployment_name: str):
    """Тестирует конкретное имя deployment"""
    try:
        client = AsyncAzureOpenAI(
            azure_endpoint=os.getenv("AZURE_OPENAI_ENDPOINT"),
            api_key=os.getenv("AZURE_OPENAI_KEY"),
            api_version=os.getenv("AZURE_OPENAI_API_VERSION", "2024-02-15-preview")
        )
        
        response = await client.chat.completions.create(
            model=deployment_name,
            messages=[
                {"role": "user", "content": "Привет!"}
            ],
            max_tokens=10
        )
        
        return True, response.choices[0].message.content
    except Exception as e:
        return False, str(e)

async def main():
    """Тестирует разные имена deployment"""
    print("🔍 Тестирование имен deployment...")
    
    # Список возможных имен deployment
    deployment_names = [
        "gpt-35-turbo",
        "gpt-35-turbo-16k", 
        "gpt-35-turbo-0613",
        "gpt-4",
        "gpt-4-32k",
        "gpt-4o",
        "gpt-4o-mini",
        "gpt-35-turbo-instruct",
        "gpt-35-turbo-1106"
    ]
    
    working_deployments = []
    
    for deployment in deployment_names:
        print(f"\n🧪 Тестируем: {deployment}")
        success, result = await test_deployment(deployment)
        
        if success:
            print(f"   ✅ РАБОТАЕТ! Ответ: {result}")
            working_deployments.append(deployment)
        else:
            print(f"   ❌ Не работает: {result[:100]}...")
    
    print(f"\n📊 Результаты:")
    if working_deployments:
        print(f"   ✅ Работающие deployment: {working_deployments}")
        print(f"\n💡 Рекомендация: Используйте '{working_deployments[0]}'")
        
        # Обновляем .env файл
        with open('.env', 'r') as f:
            lines = f.readlines()
        
        with open('.env', 'w') as f:
            for line in lines:
                if line.startswith('AZURE_OPENAI_DEPLOYMENT_NAME='):
                    f.write(f'AZURE_OPENAI_DEPLOYMENT_NAME={working_deployments[0]}\n')
                else:
                    f.write(line)
        
        print(f"   🔧 .env файл обновлен с deployment: {working_deployments[0]}")
    else:
        print(f"   ❌ Ни один deployment не работает")
        print(f"   💡 Проверьте настройки в Azure Portal")

if __name__ == "__main__":
    asyncio.run(main()) 