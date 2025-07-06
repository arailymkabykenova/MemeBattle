"""
Конфигурация pytest и общие фикстуры для тестов.
"""

import pytest
import asyncio
from typing import AsyncGenerator, Generator
from fastapi.testclient import TestClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.pool import StaticPool
import jwt
from datetime import datetime, timedelta

from ..main import app
from ..core.config import settings
from ..core.database import get_db, async_session_maker
from ..models.user import User
from ..models.card import Card
from ..models.game import Room, Game, GameRound
from ..core.security import create_access_token


# Тестовая база данных
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

# Создаем тестовый движок
test_engine = create_async_engine(
    TEST_DATABASE_URL,
    poolclass=StaticPool,
    connect_args={"check_same_thread": False}
)

TestingSessionLocal = async_sessionmaker(
    test_engine,
    class_=AsyncSession,
    expire_on_commit=False
)


@pytest.fixture(scope="session")
def event_loop() -> Generator:
    """Создает event loop для тестов."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    """Создает тестовую сессию базы данных."""
    async with TestingSessionLocal() as session:
        yield session


@pytest.fixture
async def client(db_session: AsyncSession) -> AsyncGenerator[TestClient, None]:
    """Создает тестовый клиент FastAPI."""
    
    async def override_get_db():
        yield db_session
    
    app.dependency_overrides[get_db] = override_get_db
    
    with TestClient(app) as test_client:
        yield test_client
    
    app.dependency_overrides.clear()


@pytest.fixture
async def test_user(db_session: AsyncSession) -> User:
    """Создает тестового пользователя."""
    user = User(
        device_id="test_device_123",
        nickname="TestUser",
        birth_date=datetime(1990, 1, 1),
        gender="male",
        rating=1000
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    return user


@pytest.fixture
async def test_user2(db_session: AsyncSession) -> User:
    """Создает второго тестового пользователя."""
    user = User(
        device_id="test_device_456",
        nickname="TestUser2",
        birth_date=datetime(1995, 5, 15),
        gender="female",
        rating=950
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    return user


@pytest.fixture
async def test_cards(db_session: AsyncSession) -> list[Card]:
    """Создает тестовые карты."""
    cards = [
        Card(
            name="Test Card 1",
            image_url="https://test.com/card1.jpg",
            type="starter",
            is_unique=False
        ),
        Card(
            name="Test Card 2", 
            image_url="https://test.com/card2.jpg",
            type="standard",
            is_unique=False
        ),
        Card(
            name="Test Card 3",
            image_url="https://test.com/card3.jpg", 
            type="unique",
            is_unique=True
        )
    ]
    
    for card in cards:
        db_session.add(card)
    
    await db_session.commit()
    
    for card in cards:
        await db_session.refresh(card)
    
    return cards


@pytest.fixture
async def test_room(db_session: AsyncSession, test_user: User) -> Room:
    """Создает тестовую комнату."""
    room = Room(
        creator_id=test_user.id,
        max_players=4,
        status="waiting",
        is_public=True,
        room_code="TEST123"
    )
    db_session.add(room)
    await db_session.commit()
    await db_session.refresh(room)
    return room


@pytest.fixture
async def test_game(db_session: AsyncSession, test_room: Room) -> Game:
    """Создает тестовую игру."""
    game = Game(
        room_id=test_room.id,
        status="active",
        current_round=1
    )
    db_session.add(game)
    await db_session.commit()
    await db_session.refresh(game)
    return game


@pytest.fixture
async def test_round(db_session: AsyncSession, test_game: Game) -> GameRound:
    """Создает тестовый раунд."""
    round_obj = GameRound(
        game_id=test_game.id,
        round_number=1,
        situation_text="Тестовая ситуация",
        duration=30
    )
    db_session.add(round_obj)
    await db_session.commit()
    await db_session.refresh(round_obj)
    return round_obj


@pytest.fixture
def auth_headers(test_user: User) -> dict:
    """Создает заголовки авторизации для тестового пользователя."""
    token = create_access_token(data={"sub": str(test_user.id)})
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def auth_headers_user2(test_user2: User) -> dict:
    """Создает заголовки авторизации для второго тестового пользователя."""
    token = create_access_token(data={"sub": str(test_user2.id)})
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def websocket_auth_token(test_user: User) -> str:
    """Создает токен для WebSocket аутентификации."""
    return create_access_token(data={"sub": str(test_user.id)})


@pytest.fixture
def websocket_auth_token_user2(test_user2: User) -> str:
    """Создает токен для WebSocket аутентификации второго пользователя."""
    return create_access_token(data={"sub": str(test_user2.id)}) 
Конфигурация pytest и общие фикстуры для тестов.
"""

import pytest
import asyncio
from typing import AsyncGenerator, Generator
from fastapi.testclient import TestClient
from sqlalchemy.ext.asyncio import AsyncSession, create_async_engine, async_sessionmaker
from sqlalchemy.pool import StaticPool
import jwt
from datetime import datetime, timedelta

from ..main import app
from ..core.config import settings
from ..core.database import get_db, async_session_maker
from ..models.user import User
from ..models.card import Card
from ..models.game import Room, Game, GameRound
from ..core.security import create_access_token


# Тестовая база данных
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

# Создаем тестовый движок
test_engine = create_async_engine(
    TEST_DATABASE_URL,
    poolclass=StaticPool,
    connect_args={"check_same_thread": False}
)

TestingSessionLocal = async_sessionmaker(
    test_engine,
    class_=AsyncSession,
    expire_on_commit=False
)


@pytest.fixture(scope="session")
def event_loop() -> Generator:
    """Создает event loop для тестов."""
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    """Создает тестовую сессию базы данных."""
    async with TestingSessionLocal() as session:
        yield session


@pytest.fixture
async def client(db_session: AsyncSession) -> AsyncGenerator[TestClient, None]:
    """Создает тестовый клиент FastAPI."""
    
    async def override_get_db():
        yield db_session
    
    app.dependency_overrides[get_db] = override_get_db
    
    with TestClient(app) as test_client:
        yield test_client
    
    app.dependency_overrides.clear()


@pytest.fixture
async def test_user(db_session: AsyncSession) -> User:
    """Создает тестового пользователя."""
    user = User(
        device_id="test_device_123",
        nickname="TestUser",
        birth_date=datetime(1990, 1, 1),
        gender="male",
        rating=1000
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    return user


@pytest.fixture
async def test_user2(db_session: AsyncSession) -> User:
    """Создает второго тестового пользователя."""
    user = User(
        device_id="test_device_456",
        nickname="TestUser2",
        birth_date=datetime(1995, 5, 15),
        gender="female",
        rating=950
    )
    db_session.add(user)
    await db_session.commit()
    await db_session.refresh(user)
    return user


@pytest.fixture
async def test_cards(db_session: AsyncSession) -> list[Card]:
    """Создает тестовые карты."""
    cards = [
        Card(
            name="Test Card 1",
            image_url="https://test.com/card1.jpg",
            type="starter",
            is_unique=False
        ),
        Card(
            name="Test Card 2", 
            image_url="https://test.com/card2.jpg",
            type="standard",
            is_unique=False
        ),
        Card(
            name="Test Card 3",
            image_url="https://test.com/card3.jpg", 
            type="unique",
            is_unique=True
        )
    ]
    
    for card in cards:
        db_session.add(card)
    
    await db_session.commit()
    
    for card in cards:
        await db_session.refresh(card)
    
    return cards


@pytest.fixture
async def test_room(db_session: AsyncSession, test_user: User) -> Room:
    """Создает тестовую комнату."""
    room = Room(
        creator_id=test_user.id,
        max_players=4,
        status="waiting",
        is_public=True,
        room_code="TEST123"
    )
    db_session.add(room)
    await db_session.commit()
    await db_session.refresh(room)
    return room


@pytest.fixture
async def test_game(db_session: AsyncSession, test_room: Room) -> Game:
    """Создает тестовую игру."""
    game = Game(
        room_id=test_room.id,
        status="active",
        current_round=1
    )
    db_session.add(game)
    await db_session.commit()
    await db_session.refresh(game)
    return game


@pytest.fixture
async def test_round(db_session: AsyncSession, test_game: Game) -> GameRound:
    """Создает тестовый раунд."""
    round_obj = GameRound(
        game_id=test_game.id,
        round_number=1,
        situation_text="Тестовая ситуация",
        duration=30
    )
    db_session.add(round_obj)
    await db_session.commit()
    await db_session.refresh(round_obj)
    return round_obj


@pytest.fixture
def auth_headers(test_user: User) -> dict:
    """Создает заголовки авторизации для тестового пользователя."""
    token = create_access_token(data={"sub": str(test_user.id)})
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def auth_headers_user2(test_user2: User) -> dict:
    """Создает заголовки авторизации для второго тестового пользователя."""
    token = create_access_token(data={"sub": str(test_user2.id)})
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def websocket_auth_token(test_user: User) -> str:
    """Создает токен для WebSocket аутентификации."""
    return create_access_token(data={"sub": str(test_user.id)})


@pytest.fixture
def websocket_auth_token_user2(test_user2: User) -> str:
    """Создает токен для WebSocket аутентификации второго пользователя."""
    return create_access_token(data={"sub": str(test_user2.id)})