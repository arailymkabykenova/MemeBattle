"""
Celery задачи для AI генерации.
"""

import asyncio
from typing import Optional
from celery import current_task
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession
from sqlalchemy.orm import sessionmaker

from ..core.celery_app import celery_app
from ..core.config import settings
from ..services.ai_service import AIService
from ..core.redis import RedisClient


@celery_app.task(bind=True, name="generate_situation_for_round")
def generate_situation_for_round_task(
    self,
    game_id: int,
    room_id: int,
    round_number: int,
    age_group: str,
    language: str = "ru"
) -> dict:
    """
    Генерирует ситуацию для раунда в фоновом режиме.
    
    Args:
        game_id: ID игры
        room_id: ID комнаты
        round_number: Номер раунда
        age_group: Возрастная группа
        language: Язык (ru/en)
        
    Returns:
        dict: Результат выполнения задачи
    """
    try:
        # Обновляем статус задачи
        current_task.update_state(
            state="PROGRESS",
            meta={"status": "Генерация ситуации началась"}
        )
        
        # Обертка для async кода
        async def generate_situation():
            # Создаем подключение к базе данных для Celery worker
            engine = create_async_engine(settings.database_url)
            async_session = sessionmaker(
                engine, class_=AsyncSession, expire_on_commit=False
            )
            
            # Создаем Redis клиент
            redis_client = RedisClient(engine)
            
            # Инициализируем AI сервис
            async with async_session() as db:
                ai_service = AIService(db)
                
                # Генерируем ситуацию
                situation_text = ai_service.generate_situation_card(
                    age_group=age_group,
                    language=language
                )
                
                # Публикуем событие об успешной генерации
                await redis_client.publish_game_event(
                    room_id=room_id,
                    event_type="situation_generated",
                    event_data={
                        "game_id": game_id,
                        "round_number": round_number,
                        "situation_text": situation_text,
                        "age_group": age_group,
                        "language": language
                    }
                )
                
                return situation_text
        
        # Запускаем async функцию
        situation_text = asyncio.run(generate_situation())
        
        # Обновляем статус задачи
        current_task.update_state(
            state="SUCCESS",
            meta={
                "status": "Ситуация успешно сгенерирована",
                "situation_text": situation_text[:100] + "..." if len(situation_text) > 100 else situation_text
            }
        )
        
        return {
            "status": "success",
            "situation_text": situation_text,
            "game_id": game_id,
            "round_number": round_number
        }
        
    except Exception as e:
        # Логируем ошибку
        print(f"Error in generate_situation_for_round_task: {e}")
        
        # Публикуем событие об ошибке
        try:
            async def publish_error():
                engine = create_async_engine(settings.database_url)
                redis_client = RedisClient(engine)
                await redis_client.publish_game_event(
                    room_id=room_id,
                    event_type="situation_generation_failed",
                    event_data={
                        "game_id": game_id,
                        "round_number": round_number,
                        "error": str(e)
                    }
                )
            
            asyncio.run(publish_error())
        except Exception as pub_error:
            print(f"Failed to publish error event: {pub_error}")
        
        # Обновляем статус задачи
        current_task.update_state(
            state="FAILURE",
            meta={
                "status": "Ошибка генерации ситуации",
                "error": str(e)
            }
        )
        
        # Повторяем задачу через 30 секунд (максимум 3 попытки)
        raise self.retry(countdown=30, max_retries=3)


@celery_app.task(bind=True, name="generate_bulk_situations")
def generate_bulk_situations_task(
    self,
    age_groups: list[str],
    languages: list[str] = ["ru", "en"],
    count_per_group: int = 10
) -> dict:
    """
    Генерирует набор ситуаций для кэширования.
    
    Args:
        age_groups: Список возрастных групп
        languages: Список языков
        count_per_group: Количество ситуаций на группу
        
    Returns:
        dict: Результат выполнения задачи
    """
    try:
        current_task.update_state(
            state="PROGRESS",
            meta={"status": "Начата массовая генерация ситуаций"}
        )
        
        # Обертка для async кода
        async def generate_bulk():
            # Создаем подключение к базе данных
            engine = create_async_engine(settings.database_url)
            async_session = sessionmaker(
                engine, class_=AsyncSession, expire_on_commit=False
            )
            
            generated_situations = []
            
            async with async_session() as db:
                ai_service = AIService(db)
                
                for age_group in age_groups:
                    for language in languages:
                        for i in range(count_per_group):
                            try:
                                situation = ai_service.generate_situation_card(
                                    age_group=age_group,
                                    language=language
                                )
                                
                                generated_situations.append({
                                    "age_group": age_group,
                                    "language": language,
                                    "situation_text": situation,
                                    "index": i
                                })
                                
                            except Exception as e:
                                print(f"Error generating situation for {age_group}/{language}: {e}")
                                continue
            
            # Сохраняем сгенерированные ситуации в Redis для кэширования
            redis_client = RedisClient(engine)
            await redis_client.set(
                "cached_situations",
                generated_situations,
                expire=3600 * 24  # 24 часа
            )
            
            return generated_situations
        
        # Запускаем async функцию
        generated_situations = asyncio.run(generate_bulk())
        
        current_task.update_state(
            state="SUCCESS",
            meta={
                "status": "Массовая генерация завершена",
                "generated_count": len(generated_situations)
            }
        )
        
        return {
            "status": "success",
            "generated_count": len(generated_situations),
            "situations": generated_situations[:5]  # Возвращаем первые 5 для примера
        }
        
    except Exception as e:
        print(f"Error in generate_bulk_situations_task: {e}")
        
        current_task.update_state(
            state="FAILURE",
            meta={
                "status": "Ошибка массовой генерации",
                "error": str(e)
            }
        )
        
        raise self.retry(countdown=60, max_retries=2)


@celery_app.task(bind=True, name="validate_ai_service")
def validate_ai_service_task(self) -> dict:
    """
    Проверяет работоспособность AI сервиса.
    
    Returns:
        dict: Результат проверки
    """
    try:
        current_task.update_state(
            state="PROGRESS",
            meta={"status": "Проверка AI сервиса"}
        )
        
        # Обертка для async кода
        async def validate_service():
            # Создаем подключение к базе данных
            engine = create_async_engine(settings.database_url)
            async_session = sessionmaker(
                engine, class_=AsyncSession, expire_on_commit=False
            )
            
            test_results = []
            
            async with async_session() as db:
                ai_service = AIService(db)
                
                # Тестируем разные возрастные группы и языки
                test_cases = [
                    ("children", "ru"),
                    ("teens", "en"),
                    ("young_adults", "ru"),
                    ("adults", "en")
                ]
                
                for age_group, language in test_cases:
                    try:
                        situation = ai_service.generate_situation_card(
                            age_group=age_group,
                            language=language
                        )
                        
                        test_results.append({
                            "age_group": age_group,
                            "language": language,
                            "status": "success",
                            "situation_length": len(situation)
                        })
                        
                    except Exception as e:
                        test_results.append({
                            "age_group": age_group,
                            "language": language,
                            "status": "error",
                            "error": str(e)
                        })
            
            return test_results
        
        # Запускаем async функцию
        test_results = asyncio.run(validate_service())
        
        # Определяем общий статус
        success_count = sum(1 for r in test_results if r["status"] == "success")
        total_count = len(test_results)
        
        if success_count == total_count:
            status = "all_tests_passed"
        elif success_count > 0:
            status = "partial_success"
        else:
            status = "all_tests_failed"
        
        current_task.update_state(
            state="SUCCESS",
            meta={
                "status": f"Проверка завершена: {success_count}/{total_count} успешно",
                "test_results": test_results
            }
        )
        
        return {
            "status": status,
            "success_count": success_count,
            "total_count": total_count,
            "test_results": test_results
        }
        
    except Exception as e:
        print(f"Error in validate_ai_service_task: {e}")
        
        current_task.update_state(
            state="FAILURE",
            meta={
                "status": "Ошибка проверки AI сервиса",
                "error": str(e)
            }
        )
        
        return {
            "status": "error",
            "error": str(e)
        } 