#!/usr/bin/env python3
"""
🎮 Автоматический тест перехода раундов
Проверяет работает ли автоматический переход на следующий раунд после голосования всех игроков.
"""

import asyncio
import websockets
import json
import time
from typing import Dict, Any

# Тестовые токены из базы данных
PLAYER1_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxMSwiZXhwIjoxNzUxODQ4MTk0LCJpYXQiOjE3NTEyNDMzOTQsInR5cGUiOiJhY2Nlc3MifQ.c7TcbbHYVi8vhWcKbyUoYQZnPhKhRcVMnh98ncs-j4s"
PLAYER2_TOKEN = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoxMiwiZXhwIjoxNzUxODQ4MjA0LCJpYXQiOjE3NTEyNDM0MDQsInR5cGUiOiJhY2Nlc3MifQ.CKUg0Jlsf2b4fqWwzBgjwlQp7B8Zlo192TCz-vo9EWM"

WEBSOCKET_URL = "ws://localhost:8000/websocket/ws"
TEST_ROOM_ID = 100  # Используем новую комнату для чистого теста

class WebSocketTestClient:
    def __init__(self, name: str, token: str):
        self.name = name
        self.token = token
        self.websocket = None
        self.messages = []
        self.current_round_id = None
        self.game_id = None
        
    async def connect(self):
        """Подключается к WebSocket"""
        url = f"{WEBSOCKET_URL}?token={self.token}"
        try:
            self.websocket = await websockets.connect(url)
            print(f"✅ {self.name} подключен к WebSocket")
            
            # Запускаем обработчик сообщений
            asyncio.create_task(self._message_handler())
            return True
        except Exception as e:
            print(f"❌ {self.name}: Ошибка подключения: {e}")
            return False
    
    async def _message_handler(self):
        """Обрабатывает входящие сообщения"""
        try:
            async for message in self.websocket:
                data = json.loads(message)
                self.messages.append(data)
                
                # Автоматически сохраняем важные ID
                if data.get("success") and "round_id" in data:
                    self.current_round_id = data["round_id"]
                if data.get("success") and "game_id" in data:
                    self.game_id = data["game_id"]
                    
                print(f"📨 {self.name} получил: {json.dumps(data, indent=2, ensure_ascii=False)}")
                
        except websockets.exceptions.ConnectionClosed:
            print(f"🔌 {self.name}: Соединение закрыто")
    
    async def send_action(self, action: str, data: Dict[Any, Any] = None):
        """Отправляет WebSocket действие"""
        if not self.websocket:
            print(f"❌ {self.name}: Не подключен к WebSocket")
            return
            
        message = {
            "action": action,
            "data": data or {}
        }
        
        await self.websocket.send(json.dumps(message))
        print(f"📤 {self.name} отправил: {action} - {data}")
        
        # Ждем ответ
        await asyncio.sleep(0.5)
    
    async def disconnect(self):
        """Отключается от WebSocket"""
        if self.websocket:
            await self.websocket.close()

async def test_round_progression():
    """
    🎯 Главный тест: проверяет автоматический переход раундов
    """
    print("🚀 Начинаем тест автоматического перехода раундов...")
    
    # Создаем двух игроков
    player1 = WebSocketTestClient("Player1", PLAYER1_TOKEN)
    player2 = WebSocketTestClient("Player2", PLAYER2_TOKEN)
    
    try:
        # 1. Подключаемся к WebSocket
        print("\n📡 1. Подключение к WebSocket...")
        if not await player1.connect():
            return False
        if not await player2.connect():
            return False
        
        await asyncio.sleep(1)
        
        # 2. Создаем комнату или используем существующую
        print("\n🚪 2. Создание/присоединение к комнате...")
        
        # Player1 создает комнату  
        await player1.send_action("ping")  # Получаем room_id из connection_established
        
        # Берем room_id из первоначального подключения Player1
        player1_room_id = None
        for msg in player1.messages:
            if msg.get("type") == "connection_established" and "room_id" in msg:
                player1_room_id = msg["room_id"]
                break
        
        if player1_room_id:
            print(f"✅ Используем существующую комнату Player1: {player1_room_id}")
            # Player2 присоединяется к комнате Player1
            await player2.send_action("join_room", {"room_id": player1_room_id})
        else:
            print("❌ Не удалось получить room_id Player1")
            return False
        
        await asyncio.sleep(2)
        
        # 3. Начинаем игру
        print("\n🎮 3. Начинаем игру...")
        await player1.send_action("start_game")
        
        await asyncio.sleep(2)
        
        # 4. Начинаем первый раунд
        print("\n🎯 4. Начинаем первый раунд...")
        await player1.send_action("start_round", {
            "situation_text": "Тестовая ситуация: Что делаете если интернет отключился во время важной встречи?"
        })
        
        await asyncio.sleep(2)
        
        # Получаем round_id из последних сообщений
        current_round_id = None
        for msg in player1.messages[-5:]:
            if msg.get("success") and "round_id" in msg:
                current_round_id = msg["round_id"]
                break
        
        if not current_round_id:
            print("❌ Не удалось получить round_id")
            return False
            
        print(f"✅ Текущий round_id: {current_round_id}")
        
        # 5. Получаем карты для раунда
        print("\n🎲 5. Получаем карты для раунда...")
        await player1.send_action("get_round_cards", {"round_id": current_round_id})
        await player2.send_action("get_round_cards", {"round_id": current_round_id})
        
        await asyncio.sleep(2)
        
        # 6. Выбираем карты (используем первую доступную)
        print("\n✨ 6. Выбираем карты...")
        
        # Player1 выбирает starter:1
        await player1.send_action("submit_card_choice", {
            "round_id": current_round_id,
            "card_type": "starter", 
            "card_number": 1
        })
        
        # Player2 выбирает starter:2
        await player2.send_action("submit_card_choice", {
            "round_id": current_round_id,
            "card_type": "starter",
            "card_number": 2
        })
        
        await asyncio.sleep(3)
        
        # 7. Проверяем статус игры перед голосованием
        print("\n📊 7. Проверяем статус перед голосованием...")
        await player1.send_action("get_game_state")
        
        await asyncio.sleep(2)
        
        # 8. Получаем карты для голосования
        print("\n🗳️ 8. Получаем карты для голосования...")
        await player1.send_action("get_choices_for_voting", {"round_id": current_round_id})
        await player2.send_action("get_choices_for_voting", {"round_id": current_round_id})
        
        await asyncio.sleep(2)
        
        # 9. Голосуем (нам нужны choice_id из предыдущих ответов)
        print("\n🏆 9. Голосуем за карты...")
        
        # Ищем choice_id в последних сообщениях
        choice_ids = []
        for msg in player1.messages[-10:]:
            if msg.get("success") and "choices" in msg:
                for choice in msg["choices"]:
                    choice_ids.append(choice["id"])
        
        for msg in player2.messages[-10:]:
            if msg.get("success") and "choices" in msg:
                for choice in msg["choices"]:
                    if choice["id"] not in choice_ids:
                        choice_ids.append(choice["id"])
        
        if len(choice_ids) >= 2:
            # Player1 голосует за карту Player2
            await player1.send_action("submit_vote", {
                "round_id": current_round_id,
                "choice_id": choice_ids[1] if len(choice_ids) > 1 else choice_ids[0]
            })
            
            # Player2 голосует за карту Player1  
            await player2.send_action("submit_vote", {
                "round_id": current_round_id,
                "choice_id": choice_ids[0]
            })
        
        print(f"🗳️ Используем choice_ids: {choice_ids}")
        
        # 10. Ждем автоматический переход к следующему раунду
        print("\n⏳ 10. Ждем автоматический переход к следующему раунду...")
        
        # Проверяем статус каждые 2 секунды в течение 10 секунд
        for i in range(5):
            await asyncio.sleep(2)
            await player1.send_action("get_game_state")
            
            # Проверяем последние сообщения на переход раунда
            for msg in player1.messages[-3:]:
                if (msg.get("success") and 
                    msg.get("game_state", {}).get("current_round", 0) > 1):
                    print(f"🎉 УСПЕХ! Переход на раунд {msg['game_state']['current_round']}")
                    return True
        
        print("❌ Автоматический переход не произошел за 10 секунд")
        return False
        
    except Exception as e:
        print(f"❌ Ошибка в тесте: {e}")
        return False
    
    finally:
        # Отключаемся
        await player1.disconnect()
        await player2.disconnect()

async def main():
    """Запуск тестов"""
    print("🧪 Автоматическое тестирование WebSocket игрового процесса")
    print("=" * 60)
    
    success = await test_round_progression()
    
    print("\n" + "=" * 60)
    if success:
        print("✅ ТЕСТ ПРОЙДЕН: Автоматический переход раундов работает!")
    else:
        print("❌ ТЕСТ НЕ ПРОЙДЕН: Проблемы с переходом раундов")
    
    return success

if __name__ == "__main__":
    asyncio.run(main()) 