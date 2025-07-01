"""
Firebase Admin SDK клиент.
Обработка аутентификации Firebase на бэкенде.
"""

import os
import json
from typing import Optional, Dict, Any
import firebase_admin
from firebase_admin import credentials, auth
from ..core.config import settings
from ..utils.exceptions import AuthenticationError, ExternalServiceError


class FirebaseClient:
    """Клиент для работы с Firebase Admin SDK"""
    
    def __init__(self):
        self._app = None
        self._initialize_firebase()
    
    def _initialize_firebase(self):
        """Инициализация Firebase Admin SDK"""
        try:
            # Проверяем, не инициализирован ли уже Firebase
            if firebase_admin._apps:
                self._app = firebase_admin.get_app()
                return
            
            # Если есть путь к service account файлу
            if settings.firebase_service_account_path:
                cred = credentials.Certificate(settings.firebase_service_account_path)
                self._app = firebase_admin.initialize_app(cred)
                print("✅ Firebase инициализирован с service account файлом")
                return
            
            # Если есть JSON строка с credentials
            if settings.firebase_service_account_json:
                service_account_info = json.loads(settings.firebase_service_account_json)
                cred = credentials.Certificate(service_account_info)
                self._app = firebase_admin.initialize_app(cred)
                print("✅ Firebase инициализирован с JSON credentials")
                return
            
            # Если переменные окружения доступны (например, на Google Cloud)
            try:
                cred = credentials.ApplicationDefault()
                self._app = firebase_admin.initialize_app(cred)
                print("✅ Firebase инициализирован с Application Default Credentials")
                return
            except Exception:
                pass
            
            print("⚠️  Firebase не настроен - аутентификация будет недоступна")
            
        except Exception as e:
            print(f"❌ Ошибка инициализации Firebase: {e}")
            raise ExternalServiceError(f"Ошибка настройки Firebase: {e}")
    
    async def verify_token(self, token: str) -> Dict[str, Any]:
        """
        Проверяет Firebase ID токен.
        
        Args:
            token: Firebase ID токен от клиента
            
        Returns:
            Dict[str, Any]: Данные пользователя из токена
            
        Raises:
            AuthenticationError: Если токен невалиден
            ExternalServiceError: Если Firebase недоступен
        """
        if not self._app:
            raise ExternalServiceError("Firebase не настроен")
        
        try:
            # Проверяем токен
            decoded_token = auth.verify_id_token(token)
            
            return {
                "firebase_uid": decoded_token["uid"],
                "email": decoded_token.get("email"),
                "email_verified": decoded_token.get("email_verified", False),
                "name": decoded_token.get("name"),
                "picture": decoded_token.get("picture"),
                "provider": decoded_token.get("firebase", {}).get("sign_in_provider"),
                "auth_time": decoded_token.get("auth_time"),
                "exp": decoded_token.get("exp")
            }
            
        except auth.InvalidIdTokenError:
            raise AuthenticationError("Недействительный токен")
        except auth.ExpiredIdTokenError:
            raise AuthenticationError("Токен истек")
        except auth.RevokedIdTokenError:
            raise AuthenticationError("Токен отозван")
        except Exception as e:
            raise ExternalServiceError(f"Ошибка проверки токена: {e}")
    
    async def get_user_by_uid(self, firebase_uid: str) -> Dict[str, Any]:
        """
        Получает данные пользователя по Firebase UID.
        
        Args:
            firebase_uid: Firebase UID пользователя
            
        Returns:
            Dict[str, Any]: Данные пользователя
            
        Raises:
            ExternalServiceError: Если Firebase недоступен или пользователь не найден
        """
        if not self._app:
            raise ExternalServiceError("Firebase не настроен")
        
        try:
            user_record = auth.get_user(firebase_uid)
            
            return {
                "firebase_uid": user_record.uid,
                "email": user_record.email,
                "email_verified": user_record.email_verified,
                "display_name": user_record.display_name,
                "photo_url": user_record.photo_url,
                "phone_number": user_record.phone_number,
                "disabled": user_record.disabled,
                "provider_data": [
                    {
                        "provider_id": provider.provider_id,
                        "uid": provider.uid,
                        "email": provider.email,
                        "display_name": provider.display_name,
                        "photo_url": provider.photo_url
                    }
                    for provider in user_record.provider_data
                ],
                "creation_timestamp": user_record.user_metadata.creation_timestamp,
                "last_sign_in_timestamp": user_record.user_metadata.last_sign_in_timestamp
            }
            
        except auth.UserNotFoundError:
            raise ExternalServiceError(f"Пользователь с UID {firebase_uid} не найден в Firebase")
        except Exception as e:
            raise ExternalServiceError(f"Ошибка получения пользователя: {e}")
    
    async def create_custom_token(self, firebase_uid: str, additional_claims: Optional[Dict] = None) -> str:
        """
        Создает кастомный токен для пользователя.
        
        Args:
            firebase_uid: Firebase UID пользователя
            additional_claims: Дополнительные claims для токена
            
        Returns:
            str: Кастомный токен
            
        Raises:
            ExternalServiceError: Если Firebase недоступен
        """
        if not self._app:
            raise ExternalServiceError("Firebase не настроен")
        
        try:
            custom_token = auth.create_custom_token(
                firebase_uid, 
                additional_claims or {}
            )
            return custom_token.decode('utf-8')
            
        except Exception as e:
            raise ExternalServiceError(f"Ошибка создания кастомного токена: {e}")
    
    async def revoke_refresh_tokens(self, firebase_uid: str) -> None:
        """
        Отзывает все refresh токены пользователя.
        
        Args:
            firebase_uid: Firebase UID пользователя
            
        Raises:
            ExternalServiceError: Если Firebase недоступен
        """
        if not self._app:
            raise ExternalServiceError("Firebase не настроен")
        
        try:
            auth.revoke_refresh_tokens(firebase_uid)
            
        except Exception as e:
            raise ExternalServiceError(f"Ошибка отзыва токенов: {e}")
    
    async def set_custom_user_claims(self, firebase_uid: str, custom_claims: Dict) -> None:
        """
        Устанавливает кастомные claims для пользователя.
        
        Args:
            firebase_uid: Firebase UID пользователя
            custom_claims: Кастомные claims
            
        Raises:
            ExternalServiceError: Если Firebase недоступен
        """
        if not self._app:
            raise ExternalServiceError("Firebase не настроен")
        
        try:
            auth.set_custom_user_claims(firebase_uid, custom_claims)
            
        except Exception as e:
            raise ExternalServiceError(f"Ошибка установки кастомных claims: {e}")
    
    def is_available(self) -> bool:
        """
        Проверяет доступность Firebase.
        
        Returns:
            bool: True если Firebase настроен
        """
        return self._app is not None


# Глобальный экземпляр клиента
firebase_client = FirebaseClient() 