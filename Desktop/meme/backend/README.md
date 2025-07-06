# 🎮 Meme Card Game Backend

Backend API для iOS игры с мем-карточками, построенный на FastAPI.

## 🚀 Быстрый старт

### 1. Настройка окружения

```bash
# Клонируйте репозиторий
git clone <repository-url>
cd backend

# Создайте виртуальное окружение
python3 -m venv venv
source venv/bin/activate  # На Windows: venv\Scripts\activate

# Установите зависимости
pip install -r requirements.txt
```

### 2. Настройка переменных окружения

```bash
# Скопируйте пример файла
cp env.example .env

# Отредактируйте .env файл с вашими настройками
nano .env
```

**КРИТИЧЕСКИ ВАЖНО**: Обязательно настройте следующие переменные в `.env`:

- `JWT_SECRET_KEY` - безопасный секретный ключ (минимум 32 символа)
- `AZURE_STORAGE_CONNECTION_STRING` - строка подключения к Azure Storage
- `AZURE_OPENAI_KEY` - API ключ Azure OpenAI

### 3. Запуск с Docker (рекомендуется)

```bash
# Запустите все сервисы
docker-compose up -d

# Проверьте статус
docker-compose ps

# Посмотрите логи
docker-compose logs -f app
```

### 4. Запуск без Docker

```bash
# Убедитесь что PostgreSQL и Redis запущены
# Затем запустите приложение
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

## 📋 Требования

- Python 3.11+
- PostgreSQL 15+
- Redis 7+
- Docker & Docker Compose (опционально)

## 🔧 Конфигурация

### Переменные окружения

Все настройки хранятся в `.env` файле. См. `env.example` для полного списка переменных.

### Основные настройки

| Переменная | Описание | По умолчанию |
|------------|----------|--------------|
| `DEBUG` | Режим отладки | `false` |
| `ENVIRONMENT` | Окружение | `development` |
| `JWT_SECRET_KEY` | Секретный ключ JWT | **обязательно** |
| `DATABASE_URL` | URL базы данных | **обязательно** |

### Azure настройки

| Переменная | Описание |
|------------|----------|
| `AZURE_STORAGE_CONNECTION_STRING` | Строка подключения к Azure Storage |
| `AZURE_CONTAINER_NAME` | Имя контейнера для карточек |
| `AZURE_OPENAI_ENDPOINT` | Endpoint Azure OpenAI |
| `AZURE_OPENAI_KEY` | API ключ Azure OpenAI |

## 🗄️ База данных

### Миграции

```bash
# Создать миграцию
alembic revision --autogenerate -m "Описание изменений"

# Применить миграции
alembic upgrade head

# Откатить миграцию
alembic downgrade -1
```

### Схема базы данных

Основные таблицы:
- `users` - пользователи
- `cards` - карточки
- `user_cards` - карточки пользователей
- `rooms` - игровые комнаты
- `room_participants` - участники комнат
- `games` - игры
- `game_rounds` - раунды игр
- `player_choices` - выборы карт
- `votes` - голоса

## 🔌 API Endpoints

### Аутентификация
- `POST /auth/login` - вход через Game Center
- `POST /auth/verify` - проверка токена
- `POST /auth/logout` - выход

### Пользователи
- `GET /users/me` - профиль текущего пользователя
- `PUT /users/me` - обновление профиля
- `GET /users/me/cards` - карточки пользователя

### Комнаты
- `POST /rooms` - создание комнаты
- `GET /rooms` - список комнат
- `POST /rooms/{room_id}/join` - присоединение к комнате
- `DELETE /rooms/{room_id}/leave` - выход из комнаты

### Игры
- `POST /rooms/{room_id}/start` - начало игры
- `GET /games/{game_id}` - информация об игре
- `POST /games/rounds/{round_id}/submit-card` - выбор карты
- `POST /games/rounds/{round_id}/vote` - голосование

### WebSocket
- `WS /websocket/ws` - WebSocket соединение для реального времени

## 🌐 WebSocket API

### Подключение
```javascript
const ws = new WebSocket('ws://localhost:8000/websocket/ws?token=YOUR_JWT_TOKEN');
```

### Основные события

#### Клиент → Сервер
- `join_room` - присоединиться к комнате
- `leave_room` - покинуть комнату
- `start_game` - начать игру
- `submit_card_choice` - выбрать карту
- `submit_vote` - проголосовать

#### Сервер → Клиент
- `room_state_updated` - обновление состояния комнаты
- `game_started` - игра началась
- `round_started` - раунд начался
- `voting_started` - началось голосование
- `round_results` - результаты раунда
- `game_ended` - игра завершена

## 🧪 Тестирование

```bash
# Запуск тестов
pytest

# Запуск с покрытием
pytest --cov=app

# Запуск конкретного теста
pytest tests/test_auth.py::test_login
```

## 📊 Мониторинг

### Health Check
```bash
curl http://localhost:8000/health
```

### Логирование
Логи сохраняются в формате JSON в директории `logs/`:
- `game.log` - игровые события
- `auth.log` - события аутентификации
- `api.log` - HTTP запросы
- `websocket.log` - WebSocket события

## 🚀 Деплой

### Docker Production
```bash
# Сборка production образа
docker build -t meme-backend:latest .

# Запуск с production настройками
docker-compose -f docker-compose.yml --profile production up -d
```

### Переменные для production
- `ENVIRONMENT=production`
- `DEBUG=false`
- `CORS_ORIGINS=https://yourdomain.com`
- Используйте внешние PostgreSQL и Redis

## 🔒 Безопасность

### Рекомендации
1. **НИКОГДА** не коммитьте `.env` файлы в Git
2. Используйте сложные пароли для базы данных
3. Регулярно меняйте `JWT_SECRET_KEY`
4. Ограничьте `CORS_ORIGINS` в продакшене
5. Используйте HTTPS в продакшене
6. Настройте rate limiting

### Переменные для продакшена
```bash
# Обязательно измените в продакшене
JWT_SECRET_KEY=your_super_secure_production_key
POSTGRES_PASSWORD=your_secure_db_password
CORS_ORIGINS=https://yourdomain.com,https://app.yourdomain.com
```

## 📝 Разработка

### Структура проекта
```
backend/
├── app/
│   ├── core/           # Основные настройки
│   ├── models/         # Модели базы данных
│   ├── schemas/        # Pydantic схемы
│   ├── services/       # Бизнес-логика
│   ├── repositories/   # Работа с данными
│   ├── routers/        # API endpoints
│   ├── websocket/      # WebSocket логика
│   └── external/       # Внешние сервисы
├── alembic/            # Миграции БД
├── tests/              # Тесты
└── requirements.txt    # Зависимости
```

### Добавление новых endpoints
1. Создайте схему в `app/schemas/`
2. Добавьте логику в `app/services/`
3. Создайте роутер в `app/routers/`
4. Подключите роутер в `app/main.py`

## 🤝 Вклад в проект

1. Fork репозитория
2. Создайте feature branch
3. Внесите изменения
4. Добавьте тесты
5. Создайте Pull Request

## 📄 Лицензия

MIT License

## 🆘 Поддержка

При возникновении проблем:
1. Проверьте логи: `docker-compose logs app`
2. Убедитесь что все переменные окружения настроены
3. Проверьте подключение к базе данных и Redis
4. Создайте issue в репозитории 