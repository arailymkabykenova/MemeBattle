# 🎮 Руководство по тестированию WebSocket

## 🚀 Быстрый старт

### 1. Запуск сервера
```bash
cd backend
source venv/bin/activate
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 2. Открытие тест-клиентов
- **Player1**: Откройте `websocket_test_client.html` в браузере
- **Player2WS**: Откройте `websocket_test_client_player2.html` в браузере

## 🔑 JWT Токены (действительны 7 дней)

### Основные игроки для тестирования:

**👤 Player1 (ID: 1)**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxLCJleHAiOjE3NTE5MDU0MjUsImlhdCI6MTc1MTMwMDYyNSwidHlwZSI6ImFjY2VzcyJ9.jGvAj2HlPhJccrdxiSYRVtJhxZOw3Uq6cxxZX_ZCgMw
```

**👤 Player2 (ID: 2)**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoyLCJleHAiOjE3NTE5MDU0MjUsImlhdCI6MTc1MTMwMDYyNSwidHlwZSI6ImFjY2VzcyJ9.x-wUUmJ1iaNU6w6YcLn2aRsGkUKhxd7-iLjBfQYHhJA
```

**👤 Player2WS (ID: 12)**
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxMiwiZXhwIjoxNzUxOTA1NDI1LCJpYXQiOjE3NTEzMDA2MjUsInR5cGUiOiJhY2Nlc3MifQ.dhsHj_qn-9o9bj2WR5BgdaugkCRuQc68Kv6HA3tcBHo
```

## 📊 Актуальные данные в базе

### 🏠 Доступные комнаты:
- **Room ID: 20** - статус: `waiting`, создатель: 16, возрастная группа: `young_adults`
- **Room ID: 14** - статус: `waiting`, создатель: 14
- **Room ID: 13** - статус: `playing`, создатель: 13
- **Room ID: 12** - статус: `playing`, создатель: 12
- **Room ID: 11** - статус: `playing`, создатель: 11

### 🎮 Активные игры:
- **Game ID: 5** - комната 13, статус: `card_selection`, раунд: 3
- **Game ID: 4** - комната 12, статус: `voting`, раунд: 2
- **Game ID: 3** - комната 11, статус: `card_selection`, раунд: 1

### 🎯 Доступные раунды:
- **Round ID: 5** - игра 5, раунд #2
- **Round ID: 6** - игра 5, раунд #3 (активный)

## 🎯 Сценарии тестирования

### Базовое подключение
1. Откройте HTML клиент
2. Нажмите "Connect" (токен уже вставлен)
3. Проверьте статус подключения
4. Отправьте "Ping" для проверки связи

### Присоединение к существующей комнате
1. **Player1**: Нажмите "Join Room" → введите ID комнаты `11`, `12`, `13`, `14` или `20`
2. **Player2WS**: Измените быструю кнопку на нужную комнату
3. Проверьте, что оба игрока получили уведомления о присоединении

### Создание новой комнаты
1. **Player1**: Нажмите "Join Room" → введите новый ID (например, `25`)
2. **Player2WS**: Присоединитесь к той же комнате
3. Система автоматически создаст новую комнату

### Тестирование активной игры
**Для игры 5 (комната 13, раунд 3):**
1. Присоединитесь к комнате 13
2. Используйте **Round ID: 6** для тестирования:
   - `get_round_cards` с `{"round_id": 6}`
   - `submit_card_choice` с:
     ```json
     {
       "round_id": 6,
       "card_type": "starter", 
       "card_number": 1
     }
     ```
   - `get_choices_for_voting` с `{"round_id": 6}`
   - `submit_vote` с полученным choice_id

### Тестирование ИИ генерации
1. Присоединитесь к комнате в статусе `waiting` (14 или 20)
2. Нажмите "Start Game"
3. Нажмите "Start Round" (ИИ сгенерирует новую ситуацию)
4. Проверьте адаптацию под возрастную группу

## 🔧 Практические примеры

### Быстрое тестирование с существующими данными:
```json
// Присоединение к активной игре
{"action": "join_room", "data": {"room_id": 13}}

// Получение карт для текущего раунда
{"action": "get_round_cards", "data": {"round_id": 6}}

// Выбор карты
{"action": "submit_card_choice", "data": {
  "round_id": 6,
  "card_type": "starter",
  "card_number": 2
}}

// Получение вариантов для голосования
{"action": "get_choices_for_voting", "data": {"round_id": 6}}

// Голосование (замените choice_id на реальный)
{"action": "submit_vote", "data": {
  "round_id": 6,
  "choice_id": 1
}}
```

### Создание новой игры:
```json
// Создание новой комнаты
{"action": "join_room", "data": {"room_id": 25}}

// Начало игры (после присоединения второго игрока)
{"action": "start_game", "data": {}}

// Начало раунда с ИИ
{"action": "start_round", "data": {}}
```

## 🔧 Отладка

### Проверка состояния игры
```json
{"action": "get_game_state", "data": {}}
```

### Очистка сообщений
Используйте кнопку "Clear Messages" в клиентах

## 📝 Структура WebSocket сообщений

### Отправка:
```json
{
  "action": "action_name",
  "data": { "key": "value" }
}
```

### Получение:
```json
{
  "type": "response_type",
  "data": { "response_data": "..." },
  "timestamp": "2025-01-30T..."
}
```

## 🎮 Доступные действия

- `ping` - проверка связи
- `join_room` - присоединение к комнате
- `leave_room` - выход из комнаты
- `start_game` - начало игры
- `start_round` - начало раунда
- `get_game_state` - получение состояния игры
- `submit_card_choice` - выбор карты
- `submit_vote` - голосование
- `get_round_cards` - получение карт раунда
- `get_choices_for_voting` - получение вариантов для голосования

## ⚠️ Важные замечания

1. **Минимум игроков**: Временно снижен до 2 для тестирования
2. **Таймауты**: Временно отключены для удобства тестирования  
3. **Награды**: Карты выдаются только победителю игры (после 7 раундов)
4. **Возрастные группы**: Комнаты создаются по возрастным группам пользователей

## 🚨 После тестирования
Не забудьте вернуть:
- Минимум 3 игрока для начала игры
- Логику времени/таймаутов в игре 