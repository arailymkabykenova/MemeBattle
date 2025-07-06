#!/usr/bin/env python3
"""
Скрипт для исправления использования connection_manager в game_handler.py
"""

import re

def fix_connection_manager():
    """Исправляет все использования connection_manager в game_handler.py"""
    
    # Читаем файл
    with open('app/websocket/game_handler.py', 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Заменяем импорт
    content = content.replace(
        'from .connection_manager import connection_manager',
        'from .connection_manager import get_connection_manager'
    )
    
    # Заменяем все использования connection_manager. на get_connection_manager().
    # Но сначала добавляем объявление connection_manager = get_connection_manager() в начале каждого метода
    
    # Находим все методы, которые используют connection_manager
    method_pattern = r'(\s+async def \w+\([^)]*\) -> dict:\s*\n\s+"""[^"]*"""\s*\n)'
    
    # Заменяем все вхождения connection_manager. на connection_manager.
    # Но сначала нужно добавить объявление в методы, которые его используют
    
    # Простая замена - добавляем объявление в начало каждого метода, который использует connection_manager
    lines = content.split('\n')
    new_lines = []
    
    for i, line in enumerate(lines):
        new_lines.append(line)
        
        # Если это начало метода и следующий метод использует connection_manager
        if line.strip().startswith('async def _handle_') and '-> dict:' in line:
            # Проверяем, использует ли этот метод connection_manager
            method_name = line.split('_handle_')[1].split('(')[0]
            
            # Список методов, которые используют connection_manager
            methods_using_cm = [
                'ping', 'join_room', 'leave_room', 'start_game', 
                'start_round', 'get_game_state', 'card_choice', 'vote'
            ]
            
            if method_name in methods_using_cm:
                # Добавляем объявление connection_manager после docstring
                j = i + 1
                while j < len(lines) and (lines[j].strip().startswith('"""') or lines[j].strip() == ''):
                    j += 1
                
                # Вставляем объявление connection_manager
                new_lines.insert(j, '        connection_manager = get_connection_manager()')
    
    content = '\n'.join(new_lines)
    
    # Записываем обратно
    with open('app/websocket/game_handler.py', 'w', encoding='utf-8') as f:
        f.write(content)
    
    print("✅ Исправления применены к app/websocket/game_handler.py")

if __name__ == "__main__":
    fix_connection_manager() 