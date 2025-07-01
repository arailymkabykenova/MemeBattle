"""
Скрипт для диагностики Azure OpenAI настроек.
Показывает текущие настройки и проверяет их корректность.
"""

import os
from dotenv import load_dotenv

# Загружаем .env
load_dotenv()

def debug_azure_settings():
    """Проверяет Azure OpenAI настройки"""
    
    print("🔍 Диагностика Azure OpenAI настроек...")
    print("=" * 50)
    
    # Проверяем переменные окружения
    endpoint = os.getenv("AZURE_OPENAI_ENDPOINT")
    key = os.getenv("AZURE_OPENAI_KEY") 
    deployment = os.getenv("AZURE_OPENAI_DEPLOYMENT_NAME")
    api_version = os.getenv("AZURE_OPENAI_API_VERSION", "2024-02-15-preview")
    
    print(f"📍 Endpoint: {endpoint}")
    print(f"🔑 Key: {key[:10]}..." if key else "❌ Не установлен")
    print(f"🚀 Deployment: {deployment}")
    print(f"📅 API Version: {api_version}")
    
    print("\n" + "=" * 50)
    
    # Проверяем корректность
    if not endpoint:
        print("❌ AZURE_OPENAI_ENDPOINT не установлен")
    elif not endpoint.startswith("https://"):
        print("❌ Endpoint должен начинаться с https://")
    elif not endpoint.endswith("/"):
        print("⚠️  Endpoint должен заканчиваться на /")
    else:
        print("✅ Endpoint формат корректный")
    
    if not key:
        print("❌ AZURE_OPENAI_KEY не установлен")
    elif len(key) < 20:
        print("❌ Ключ слишком короткий")
    else:
        print("✅ Ключ установлен")
    
    if not deployment:
        print("❌ AZURE_OPENAI_DEPLOYMENT_NAME не установлен")
    else:
        print("✅ Deployment имя установлено")
    
    print("\n" + "=" * 50)
    print("🔧 Возможные решения:")
    print("1. Проверьте в Azure Portal:")
    print("   - Откройте ваш Azure OpenAI ресурс")
    print("   - Перейдите в 'Deployments'")
    print("   - Скопируйте точное имя deployment")
    print("2. Убедитесь что deployment активен")
    print("3. Проверьте что у вас есть доступ к ресурсу")
    print("4. Endpoint должен быть: https://your-resource-name.openai.azure.com/")
    print("5. Deployment имена обычно: gpt-35-turbo, gpt-4, gpt-4o")

if __name__ == "__main__":
    debug_azure_settings() 