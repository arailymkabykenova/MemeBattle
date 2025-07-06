"""
Кастомные исключения для приложения.
"""

from fastapi import HTTPException, status


class AppException(Exception):
    """Базовое исключение приложения"""
    
    def __init__(self, message: str, status_code: int = status.HTTP_500_INTERNAL_SERVER_ERROR):
        self.message = message
        self.status_code = status_code
        super().__init__(self.message)


class UserNotFoundError(AppException):
    """Исключение при отсутствии пользователя"""
    
    def __init__(self, message: str = "Пользователь не найден"):
        super().__init__(message, status.HTTP_404_NOT_FOUND)


class NotFoundError(AppException):
    """Общее исключение при отсутствии ресурса"""
    
    def __init__(self, message: str = "Ресурс не найден"):
        super().__init__(message, status.HTTP_404_NOT_FOUND)


class PermissionError(AppException):
    """Исключение при отсутствии прав доступа"""
    
    def __init__(self, message: str = "Недостаточно прав для выполнения операции"):
        super().__init__(message, status.HTTP_403_FORBIDDEN)


class DuplicateNicknameError(AppException):
    """Исключение при дублировании никнейма"""
    
    def __init__(self, message: str = "Никнейм уже занят"):
        super().__init__(message, status.HTTP_409_CONFLICT)


class ValidationError(AppException):
    """Исключение при ошибке валидации"""
    
    def __init__(self, message: str = "Ошибка валидации данных"):
        super().__init__(message, status.HTTP_400_BAD_REQUEST)


class AuthenticationError(AppException):
    """Исключение при ошибке аутентификации"""
    
    def __init__(self, message: str = "Ошибка аутентификации"):
        super().__init__(message, status.HTTP_401_UNAUTHORIZED)


class AuthorizationError(AppException):
    """Исключение при ошибке авторизации"""
    
    def __init__(self, message: str = "Недостаточно прав"):
        super().__init__(message, status.HTTP_403_FORBIDDEN)


class CardNotFoundError(AppException):
    """Исключение при отсутствии карточки"""
    
    def __init__(self, message: str = "Карточка не найдена"):
        super().__init__(message, status.HTTP_404_NOT_FOUND)


class RoomNotFoundError(AppException):
    """Исключение при отсутствии комнаты"""
    
    def __init__(self, message: str = "Игровая комната не найдена"):
        super().__init__(message, status.HTTP_404_NOT_FOUND)


class GameNotFoundError(AppException):
    """Исключение при отсутствии игры"""
    
    def __init__(self, message: str = "Игра не найдена"):
        super().__init__(message, status.HTTP_404_NOT_FOUND)


class RoomFullError(AppException):
    """Исключение при переполнении комнаты"""
    
    def __init__(self, message: str = "Комната переполнена"):
        super().__init__(message, status.HTTP_409_CONFLICT)


class GameAlreadyStartedError(AppException):
    """Исключение при попытке присоединения к уже начатой игре"""
    
    def __init__(self, message: str = "Игра уже началась"):
        super().__init__(message, status.HTTP_409_CONFLICT)


class InvalidGameStateError(AppException):
    """Исключение при неверном состоянии игры"""
    
    def __init__(self, message: str = "Неверное состояние игры"):
        super().__init__(message, status.HTTP_400_BAD_REQUEST)


class ExternalServiceError(AppException):
    """Исключение при ошибке внешнего сервиса"""
    
    def __init__(self, message: str = "Ошибка внешнего сервиса"):
        super().__init__(message, status.HTTP_503_SERVICE_UNAVAILABLE)


# Функция для преобразования исключений в HTTP ответы
def create_http_exception(exception: AppException) -> HTTPException:
    """
    Преобразует кастомное исключение в HTTPException.
    
    Args:
        exception: Кастомное исключение
        
    Returns:
        HTTPException: HTTP исключение для FastAPI
    """
    return HTTPException(
        status_code=exception.status_code,
        detail=exception.message
    ) 