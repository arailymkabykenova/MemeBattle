"""
Роутеры API.
Здесь импортируются все роутеры для правильной работы FastAPI.
"""

# Импортируем роутеры по отдельности для избежания циклических импортов
from . import auth
from . import users  
from . import cards
from . import rooms
from . import games

__all__ = ["auth", "users", "cards", "rooms", "games"] 