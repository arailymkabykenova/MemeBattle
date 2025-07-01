"""
Система логирования для приложения.
"""

import logging
import json
import sys
from datetime import datetime
from typing import Any, Dict, Optional
from pathlib import Path

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
        if hasattr(record, 'user_id'):
            log_entry['user_id'] = record.user_id
        if hasattr(record, 'room_id'):
            log_entry['room_id'] = record.room_id
        if hasattr(record, 'game_id'):
            log_entry['game_id'] = record.game_id
        if hasattr(record, 'action'):
            log_entry['action'] = record.action
        
        # Добавляем exception info если есть
        if record.exc_info:
            log_entry['exception'] = self.formatException(record.exc_info)
        
        return json.dumps(log_entry, ensure_ascii=False)


class GameLogger:
    """Логгер для игровых событий."""
    
    def __init__(self, logger_name: str = "game"):
        self.logger = logging.getLogger(logger_name)
        self.logger.setLevel(logging.INFO)
        
        # Добавляем обработчики если их еще нет
        if not self.logger.handlers:
            self._setup_handlers()
    
    def _setup_handlers(self):
        """Настраивает обработчики логов."""
        # Консольный обработчик
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setLevel(logging.INFO)
        console_handler.setFormatter(JSONFormatter())
        self.logger.addHandler(console_handler)
        
        # Файловый обработчик для production
        if settings.ENVIRONMENT == "production":
            log_dir = Path("logs")
            log_dir.mkdir(exist_ok=True)
            
            file_handler = logging.FileHandler(log_dir / "game.log")
            file_handler.setLevel(logging.INFO)
            file_handler.setFormatter(JSONFormatter())
            self.logger.addHandler(file_handler)
    
    def log_user_action(
        self, 
        user_id: int, 
        action: str, 
        details: Optional[Dict[str, Any]] = None,
        level: str = "info"
    ):
        """Логирует действие пользователя."""
        log_record = logging.LogRecord(
            name=self.logger.name,
            level=getattr(logging, level.upper()),
            pathname="",
            lineno=0,
            msg=f"User action: {action}",
            args=(),
            exc_info=None
        )
        log_record.user_id = user_id
        log_record.action = action
        
        if details:
            log_record.msg += f" - {json.dumps(details, ensure_ascii=False)}"
        
        self.logger.handle(log_record)
    
    def log_room_event(
        self, 
        room_id: int, 
        event: str, 
        user_id: Optional[int] = None,
        details: Optional[Dict[str, Any]] = None,
        level: str = "info"
    ):
        """Логирует событие в комнате."""
        log_record = logging.LogRecord(
            name=self.logger.name,
            level=getattr(logging, level.upper()),
            pathname="",
            lineno=0,
            msg=f"Room event: {event}",
            args=(),
            exc_info=None
        )
        log_record.room_id = room_id
        log_record.action = event
        
        if user_id:
            log_record.user_id = user_id
        
        if details:
            log_record.msg += f" - {json.dumps(details, ensure_ascii=False)}"
        
        self.logger.handle(log_record)
    
    def log_game_event(
        self, 
        game_id: int, 
        event: str, 
        room_id: Optional[int] = None,
        user_id: Optional[int] = None,
        details: Optional[Dict[str, Any]] = None,
        level: str = "info"
    ):
        """Логирует игровое событие."""
        log_record = logging.LogRecord(
            name=self.logger.name,
            level=getattr(logging, level.upper()),
            pathname="",
            lineno=0,
            msg=f"Game event: {event}",
            args=(),
            exc_info=None
        )
        log_record.game_id = game_id
        log_record.action = event
        
        if room_id:
            log_record.room_id = room_id
        if user_id:
            log_record.user_id = user_id
        
        if details:
            log_record.msg += f" - {json.dumps(details, ensure_ascii=False)}"
        
        self.logger.handle(log_record)
    
    def log_error(
        self, 
        error: str, 
        user_id: Optional[int] = None,
        room_id: Optional[int] = None,
        game_id: Optional[int] = None,
        exception: Optional[Exception] = None
    ):
        """Логирует ошибку."""
        log_record = logging.LogRecord(
            name=self.logger.name,
            level=logging.ERROR,
            pathname="",
            lineno=0,
            msg=f"Error: {error}",
            args=(),
            exc_info=(type(exception), exception, exception.__traceback__) if exception else None
        )
        
        if user_id:
            log_record.user_id = user_id
        if room_id:
            log_record.room_id = room_id
        if game_id:
            log_record.game_id = game_id
        
        self.logger.handle(log_record)
    
    def log_websocket_event(
        self, 
        event: str, 
        user_id: Optional[int] = None,
        room_id: Optional[int] = None,
        details: Optional[Dict[str, Any]] = None,
        level: str = "info"
    ):
        """Логирует WebSocket событие."""
        log_record = logging.LogRecord(
            name=self.logger.name,
            level=getattr(logging, level.upper()),
            pathname="",
            lineno=0,
            msg=f"WebSocket event: {event}",
            args=(),
            exc_info=None
        )
        log_record.action = event
        
        if user_id:
            log_record.user_id = user_id
        if room_id:
            log_record.room_id = room_id
        
        if details:
            log_record.msg += f" - {json.dumps(details, ensure_ascii=False)}"
        
        self.logger.handle(log_record)


# Создаем глобальные логгеры
game_logger = GameLogger("game")
auth_logger = GameLogger("auth")
api_logger = GameLogger("api")
websocket_logger = GameLogger("websocket")


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
    
    api_logger.logger.handle(log_record)


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