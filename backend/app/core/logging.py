"""
Система логирования для приложения.
"""

import logging
import json
import sys
import os
from datetime import datetime
from typing import Any, Dict, Optional
from pathlib import Path
import traceback

from .config import settings


class JSONFormatter(logging.Formatter):
    """Форматтер для JSON логов."""
    
    def format(self, record: logging.LogRecord) -> str:
        """Форматирует запись лога в JSON."""
        log_entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno
        }
        
        # Добавляем дополнительные поля если есть
        if hasattr(record, 'extra'):
            log_entry.update(record.extra)
        
        # Добавляем exception info если есть
        if record.exc_info:
            exc_type, exc_value, exc_tb = record.exc_info
            log_entry['exception'] = {
                'type': str(exc_type.__name__),
                'message': str(exc_value),
                'module': getattr(exc_type, '__module__', 'unknown'),
                'traceback': ''.join(traceback.format_exception(exc_type, exc_value, exc_tb))
            }
        
        # Добавляем traceback если есть
        if hasattr(record, 'stack_info') and record.stack_info:
            log_entry['stack_info'] = record.stack_info
            
        return json.dumps(log_entry, ensure_ascii=False)


class GameLogger:
    """Логгер для игровых событий."""
    
    def __init__(self, logger_name: str = "game"):
        self.logger = logging.getLogger(logger_name)
        self.logger.setLevel(logging.DEBUG if settings.debug else logging.INFO)
        
        # Добавляем обработчики если их еще нет
        if not self.logger.handlers:
            self._setup_handlers()
    
    def _setup_handlers(self):
        """Настраивает обработчики логов."""
        # Создаем директорию для логов
        log_dir = Path("logs")
        log_dir.mkdir(exist_ok=True, parents=True)
        
        # Консольный обработчик для всех уровней
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(logging.DEBUG if settings.debug else logging.INFO)
        console_handler.setFormatter(JSONFormatter())
        self.logger.addHandler(console_handler)
        
        # Файловый обработчик для всех логов
        all_handler = logging.FileHandler(log_dir / "all.log")
        all_handler.setLevel(logging.DEBUG)
        all_handler.setFormatter(JSONFormatter())
        self.logger.addHandler(all_handler)
        
        # Файловый обработчик только для ошибок
        error_handler = logging.FileHandler(log_dir / "error.log")
        error_handler.setLevel(logging.ERROR)
        error_handler.setFormatter(JSONFormatter())
        self.logger.addHandler(error_handler)
        
        # Файловый обработчик для аутентификации
        auth_handler = logging.FileHandler(log_dir / "auth.log")
        auth_handler.setLevel(logging.DEBUG)
        auth_handler.setFormatter(JSONFormatter())
        self.logger.addHandler(auth_handler)
    
    def debug(self, msg: str, **kwargs):
        """Логирует отладочное сообщение."""
        self._log(logging.DEBUG, msg, **kwargs)
    
    def info(self, msg: str, **kwargs):
        """Логирует информационное сообщение."""
        self._log(logging.INFO, msg, **kwargs)
    
    def warning(self, msg: str, **kwargs):
        """Логирует предупреждение."""
        self._log(logging.WARNING, msg, **kwargs)
    
    def error(self, msg: str, **kwargs):
        """Логирует ошибку."""
        self._log(logging.ERROR, msg, **kwargs)
    
    def critical(self, msg: str, **kwargs):
        """Логирует критическую ошибку."""
        self._log(logging.CRITICAL, msg, **kwargs)

    def log_user_action(self, user_id: Optional[int], action: str, details: Dict[str, Any] = None):
        """Логирует действие пользователя."""
        extra = {
            'action': action,
            'user_id': user_id
        }
        if details:
            extra.update(details)
        self._log(logging.INFO, f"User action: {action}", extra=extra)

    def log_error(self, error: str, exception: Optional[Exception] = None, details: Dict[str, Any] = None):
        """Логирует ошибку с дополнительными деталями."""
        extra = {}
        if details:
            extra.update(details)
        self._log(logging.ERROR, error, exception=exception, extra=extra)
    
    def _log(self, level: int, msg: str, **kwargs):
        """Внутренний метод для логирования."""
        extra = kwargs.get('extra', {})
        exc_info = kwargs.get('exc_info')
        stack_info = kwargs.get('stack_info', False)
        
        # Если передано исключение, добавляем его информацию
        if 'exception' in kwargs:
            exc = kwargs['exception']
            if exc_info is None:  # Если exc_info не установлен явно
                exc_info = (type(exc), exc, exc.__traceback__)
            
            # Добавляем информацию об исключении в extra
            extra.update({
                'exception_type': type(exc).__name__,
                'exception_message': str(exc),
                'exception_module': getattr(exc, '__module__', 'unknown')
            })
        
        # Создаем запись лога
        record = logging.LogRecord(
            name=self.logger.name,
            level=level,
            pathname=__file__,
            lineno=0,  # Будет заполнено автоматически
            msg=msg,
            args=(),
            exc_info=exc_info,
            func=sys._getframe(1).f_code.co_name
        )
        
        # Добавляем дополнительные поля
        for key, value in extra.items():
            setattr(record, key, value)
        
        # Добавляем stack_info если запрошено
        if stack_info:
            record.stack_info = ''.join(traceback.format_stack())
        
        self.logger.handle(record)


# Создаем логгер для аутентификации
auth_logger = GameLogger("auth")


def get_logger(name: str) -> GameLogger:
    """Получает логгер по имени."""
    return GameLogger(name)


def log_request(
    method: str,
    path: str,
    user_id: Optional[int] = None,
    status_code: Optional[int] = None,
    duration: Optional[float] = None
):
    """Логирует HTTP запрос."""
    details = {
        "method": method,
        "path": path,
        "status_code": status_code,
        "duration_ms": round(duration * 1000, 2) if duration else None
    }
    
    log_record = logging.LogRecord(
        name="api",
        level=logging.INFO,
        pathname="",
        lineno=0,
        msg=f"HTTP {method} {path}",
        args=(),
        exc_info=None
    )
    log_record.action = "http_request"
    
    if user_id:
        log_record.user_id = user_id
    
    log_record.msg += f" - {json.dumps(details, ensure_ascii=False)}"
    
    GameLogger("api").logger.handle(log_record)


def log_database_query(
    query: str,
    duration: float,
    user_id: Optional[int] = None
):
    """Логирует запрос к базе данных."""
    details = {
        "query": query[:100] + "..." if len(query) > 100 else query,
        "duration_ms": round(duration * 1000, 2)
    }
    
    log_record = logging.LogRecord(
        name="database",
        level=logging.DEBUG,
        pathname="",
        lineno=0,
        msg=f"Database query executed",
        args=(),
        exc_info=None
    )
    log_record.action = "database_query"
    
    if user_id:
        log_record.user_id = user_id
    
    log_record.msg += f" - {json.dumps(details, ensure_ascii=False)}"
    
    GameLogger("database").logger.handle(log_record) 