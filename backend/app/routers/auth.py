"""
Роутер аутентификации Game Center.
"""

from datetime import date
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from typing import Dict, Any

from ..core.database import get_db
from ..services.auth_service import AuthService
from ..schemas.auth import (
    GameCenterAuthRequest,
    GameCenterUserProfileRequest,
    UserLoginResponse,
    TokenResponse,
    AuthStatusResponse,
    LogoutRequest,
    LogoutResponse,
    ErrorResponse
)
from ..schemas.user import UserResponse
from ..models.user import Gender
from ..utils.exceptions import AppException, create_http_exception

router = APIRouter(prefix="/auth", tags=["authentication"])


@router.post("/login-game-center", response_model=UserLoginResponse)
async def login_game_center(
    auth_data: GameCenterAuthRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Аутентификация пользователя через Game Center.
    
    Принимает данные Game Center от iOS приложения:
    - player_id: Game Center Player ID
    - public_key_url: URL публичного ключа Apple
    - signature: Подпись от Apple
    - salt: Соль для верификации
    - timestamp: Временная метка
    
    Возвращает JWT токен для дальнейшего использования API.
    """
    try:
        auth_service = AuthService(db)
        result = await auth_service.authenticate_game_center(auth_data)
        return result
    except AppException as e:
        raise create_http_exception(e)


@router.post("/complete-profile", response_model=UserResponse)
async def complete_user_profile(
    profile_data: GameCenterUserProfileRequest,
    db: AsyncSession = Depends(get_db)
):
    """
    Завершает создание профиля пользователя после первого входа.
    
    Используется когда пользователь впервые аутентифицируется через Game Center
    и нужно заполнить профиль.
    """
    try:
        auth_service = AuthService(db)
        
        # Находим пользователя по player_id
        user = await auth_service.user_repo.get_by_game_center_id(profile_data.player_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Пользователь не найден. Сначала выполните аутентификацию Game Center."
            )
        
        # Парсим дату рождения
        birth_date = date.fromisoformat(profile_data.birth_date)
        
        # Обновляем профиль
        updated_user = await auth_service.complete_user_profile(
            user.id,
            {
                "nickname": profile_data.nickname,
                "birth_date": birth_date,
                "gender": profile_data.gender
            }
        )
        
        return updated_user
        
    except AppException as e:
        raise create_http_exception(e)
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Некорректная дата рождения: {e}"
        )


@router.get("/status", response_model=AuthStatusResponse)
async def get_auth_status():
    """
    Получает статус системы аутентификации.
    
    Возвращает информацию о доступности Game Center аутентификации
    и поддерживаемых платформах.
    """
    return AuthStatusResponse(
        game_center_available=True,
        jwt_enabled=True,
        supported_platforms=["ios"],
        message="Система аутентификации Game Center готова"
    )


@router.post("/logout", response_model=LogoutResponse)
async def logout_user(
    logout_data: LogoutRequest
):
    """
    Выход пользователя из системы.
    
    Инвалидирует JWT токен (в будущем можно добавить blacklist токенов).
    """
    # TODO: Добавить blacklist токенов в Redis
    # Пока что просто возвращаем успешный ответ
    return LogoutResponse(
        message="Успешный выход из системы"
    )


@router.get("/verify-token")
async def verify_token(
    token: str,
    db: AsyncSession = Depends(get_db)
):
    """
    Верифицирует JWT токен и возвращает информацию о пользователе.
    
    Используется для проверки валидности токена на фронтенде.
    """
    try:
        auth_service = AuthService(db)
        user = await auth_service.get_current_user(token)
        
        return {
            "valid": True,
            "user": {
                "id": user.id,
                "nickname": user.nickname,
                "rating": user.rating
            },
            "message": "Токен валиден"
        }
        
    except AppException as e:
        return {
            "valid": False,
            "user": None,
            "message": str(e)
        }


@router.get("/check-nickname/{nickname}")
async def check_nickname_availability(
    nickname: str,
    db: AsyncSession = Depends(get_db)
):
    """
    Проверяет доступность никнейма для регистрации.
    
    Используется во время создания профиля для проверки
    уникальности никнейма в реальном времени.
    """
    try:
        auth_service = AuthService(db)
        existing_user = await auth_service.user_repo.get_by_nickname(nickname)
        
        return {
            "nickname": nickname,
            "available": existing_user is None,
            "message": "Никнейм доступен" if existing_user is None else "Никнейм уже занят"
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ошибка проверки никнейма: {e}"
        )


# Пример документации для iOS разработчика
@router.get("/docs/ios-integration")
async def get_ios_integration_docs():
    """
    Документация по интеграции с iOS приложением.
    
    Возвращает примеры кода и инструкции для iOS разработчиков.
    """
    return {
        "title": "Game Center Authentication - iOS Integration",
        "description": "Как интегрировать аутентификацию Game Center в iOS приложение",
        "steps": [
            {
                "step": 1,
                "title": "Настройка Game Center в iOS",
                "code": """
import GameKit

// 1. Аутентифицируйте пользователя в Game Center
GKLocalPlayer.local.authenticateHandler = { viewController, error in
    if let error = error {
        print("Game Center authentication failed: \\(error)")
        return
    }
    
    if let viewController = viewController {
        // Покажите контроллер аутентификации
        present(viewController, animated: true)
    } else if GKLocalPlayer.local.isAuthenticated {
        // Пользователь аутентифицирован, получите данные для бэкенда
        generateSignature()
    }
}
                """.strip()
            },
            {
                "step": 2,
                "title": "Генерация подписи для бэкенда",
                "code": """
func generateSignature() {
    GKLocalPlayer.local.generateIdentityVerificationSignature { 
        (publicKeyURL, signature, salt, timestamp, error) in
        
        guard let publicKeyURL = publicKeyURL,
              let signature = signature,
              let salt = salt else {
            print("Failed to generate signature: \\(error)")
            return
        }
        
        // Отправьте данные на ваш бэкенд
        let authData = [
            "player_id": GKLocalPlayer.local.playerID,
            "public_key_url": publicKeyURL.absoluteString,
            "signature": signature.base64EncodedString(),
            "salt": salt.base64EncodedString(),
            "timestamp": Int(timestamp)
        ]
        
        sendToBackend(authData)
    }
}
                """.strip()
            },
            {
                "step": 3,
                "title": "Отправка данных на бэкенд",
                "code": """
func sendToBackend(_ authData: [String: Any]) {
    guard let url = URL(string: "https://your-api.com/auth/login-game-center") else { return }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    
    do {
        request.httpBody = try JSONSerialization.data(withJSONObject: authData)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            // Обработайте ответ с JWT токеном
            if let data = data {
                // Сохраните JWT токен для дальнейших запросов
                handleAuthResponse(data)
            }
        }.resume()
        
    } catch {
        print("Failed to encode auth data: \\(error)")
    }
}
                """.strip()
            }
        ],
        "endpoints": {
            "login": {
                "url": "POST /auth/login-game-center",
                "description": "Основной endpoint для аутентификации",
                "required_fields": ["player_id", "public_key_url", "signature", "salt", "timestamp"]
            },
            "complete_profile": {
                "url": "POST /auth/complete-profile", 
                "description": "Завершение создания профиля для новых пользователей",
                "required_fields": ["player_id", "nickname", "birth_date", "gender"]
            },
            "verify_token": {
                "url": "GET /auth/verify-token?token=<jwt_token>",
                "description": "Проверка валидности JWT токена"
            }
        }
    }


# 🧪 ВРЕМЕННЫЙ ЭНДПОИНТ ДЛЯ ТЕСТИРОВАНИЯ
@router.get("/test/generate-token/{user_id}")
async def generate_test_token(
    user_id: int,
    db: AsyncSession = Depends(get_db)
):
    """
    🚨 ВРЕМЕННЫЙ ЭНДПОИНТ ДЛЯ ТЕСТИРОВАНИЯ! 
    Генерирует JWT токен для существующего пользователя по ID.
    
    НЕ ИСПОЛЬЗОВАТЬ В ПРОДАКШЕНЕ!
    """
    try:
        auth_service = AuthService(db)
        
        # Проверяем что пользователь существует
        user = await auth_service.user_repo.get_by_id(user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail=f"Пользователь с ID {user_id} не найден"
            )
        
        # Генерируем токен
        token = auth_service._create_access_token(user.id)
        
        return {
            "success": True,
            "user_id": user.id,
            "nickname": user.nickname,
            "access_token": token,
            "token_type": "bearer",
            "message": "🧪 ТЕСТОВЫЙ ТОКЕН СОЗДАН!"
        }
        
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ошибка создания тестового токена: {e}"
        ) 