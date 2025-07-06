"""
OpenAI клиент для генерации ситуационных карточек.
Интегрируется с Azure OpenAI для создания персонализированного контента.
"""

import openai
from typing import List, Dict, Any, Optional
from datetime import datetime
import asyncio
from ..core.config import settings
from ..utils.exceptions import AIServiceError


class OpenAIClient:
    """Клиент для работы с OpenAI API"""
    
    def __init__(self):
        self.client = openai.AsyncOpenAI(
            api_key=settings.azure_openai_key,
            base_url=settings.azure_openai_endpoint,
            api_version=settings.azure_openai_api_version
        )
        self.deployment_name = settings.azure_openai_deployment_name
    
    async def generate_situation_card(
        self,
        age_group: str,
        gender: str,
        topics: List[str],
        difficulty: str = "medium"
    ) -> Dict[str, Any]:
        """
        Генерирует ситуационную карточку с помощью OpenAI.
        
        Args:
            age_group: Возрастная группа (teen, young_adult, adult)
            gender: Пол (male, female, other)
            topics: Список тем для карточки
            difficulty: Сложность (easy, medium, hard)
            
        Returns:
            Dict: Сгенерированная ситуация
        """
        try:
            # Формируем промпт для генерации
            prompt = self._build_situation_prompt(age_group, gender, topics, difficulty)
            
            response = await self.client.chat.completions.create(
                model=self.deployment_name,
                messages=[
                    {
                        "role": "system",
                        "content": "Ты эксперт по созданию забавных ситуаций для мем-карточек. Создавай короткие, смешные и понятные ситуации."
                    },
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                max_tokens=200,
                temperature=0.8,
                top_p=0.9
            )
            
            situation_text = response.choices[0].message.content.strip()
            
            return {
                "situation_text": situation_text,
                "age_group": age_group,
                "gender": gender,
                "topics": topics,
                "difficulty": difficulty,
                "generated_at": datetime.utcnow().isoformat()
            }
            
        except Exception as e:
            raise AIServiceError(f"Ошибка генерации ситуации: {str(e)}")
    
    def _build_situation_prompt(
        self,
        age_group: str,
        gender: str,
        topics: List[str],
        difficulty: str
    ) -> str:
        """Строит промпт для генерации ситуации"""
        
        age_context = {
            "teen": "подростков 13-17 лет",
            "young_adult": "молодых людей 18-25 лет", 
            "adult": "взрослых 26+ лет"
        }
        
        difficulty_context = {
            "easy": "простые и понятные",
            "medium": "средней сложности",
            "hard": "сложные и неожиданные"
        }
        
        topics_text = ", ".join(topics) if topics else "повседневные ситуации"
        
        prompt = f"""
        Создай {difficulty_context.get(difficulty, 'средней сложности')} ситуацию для {age_context.get(age_group, 'взрослых')}.
        
        Темы: {topics_text}
        
        Требования:
        - Ситуация должна быть смешной и понятной
        - Максимум 2-3 предложения
        - Подходит для создания мем-карточки
        - Учитывай возрастную группу и интересы
        - Избегай оскорбительного контента
        
        Создай только текст ситуации, без дополнительных комментариев.
        """
        
        return prompt.strip()
    
    async def generate_topics_by_demographics(
        self,
        age_group: str,
        gender: str,
        count: int = 5
    ) -> List[str]:
        """
        Генерирует список тем по демографическим данным.
        
        Args:
            age_group: Возрастная группа
            gender: Пол
            count: Количество тем
            
        Returns:
            List[str]: Список тем
        """
        try:
            prompt = f"""
            Создай {count} тем для мем-карточек для {age_group} {gender}.
            Темы должны быть актуальными и интересными для этой аудитории.
            Верни только список тем, каждую с новой строки.
            """
            
            response = await self.client.chat.completions.create(
                model=self.deployment_name,
                messages=[
                    {
                        "role": "system",
                        "content": "Ты эксперт по созданию актуальных тем для мем-карточек."
                    },
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                max_tokens=150,
                temperature=0.7
            )
            
            topics_text = response.choices[0].message.content.strip()
            topics = [topic.strip() for topic in topics_text.split('\n') if topic.strip()]
            
            return topics[:count]
            
        except Exception as e:
            raise AIServiceError(f"Ошибка генерации тем: {str(e)}")
    
    async def customize_situation(
        self,
        base_situation: str,
        age_group: str,
        gender: str
    ) -> str:
        """
        Кастомизирует базовую ситуацию под демографию.
        
        Args:
            base_situation: Базовая ситуация
            age_group: Возрастная группа
            gender: Пол
            
        Returns:
            str: Кастомизированная ситуация
        """
        try:
            prompt = f"""
            Адаптируй эту ситуацию для {age_group} {gender}:
            
            "{base_situation}"
            
            Сделай ситуацию более релевантной и понятной для этой аудитории.
            Сохрани юмор, но адаптируй под интересы и опыт.
            """
            
            response = await self.client.chat.completions.create(
                model=self.deployment_name,
                messages=[
                    {
                        "role": "system",
                        "content": "Ты эксперт по адаптации контента под разные аудитории."
                    },
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                max_tokens=150,
                temperature=0.6
            )
            
            return response.choices[0].message.content.strip()
            
        except Exception as e:
            raise AIServiceError(f"Ошибка кастомизации ситуации: {str(e)}")
    
    async def validate_situation_quality(self, situation_text: str) -> Dict[str, Any]:
        """
        Проверяет качество сгенерированной ситуации.
        
        Args:
            situation_text: Текст ситуации
            
        Returns:
            Dict: Результаты проверки
        """
        try:
            prompt = f"""
            Оцени качество этой ситуации для мем-карточки:
            
            "{situation_text}"
            
            Оцени по шкале 1-10:
            - Юмор (насколько смешно)
            - Понятность (насколько понятно)
            - Актуальность (насколько современно)
            - Безопасность (нет ли оскорбительного контента)
            
            Верни только оценки в формате JSON.
            """
            
            response = await self.client.chat.completions.create(
                model=self.deployment_name,
                messages=[
                    {
                        "role": "system",
                        "content": "Ты эксперт по оценке качества контента."
                    },
                    {
                        "role": "user",
                        "content": prompt
                    }
                ],
                max_tokens=100,
                temperature=0.3
            )
            
            # Парсим JSON ответ
            try:
                import json
                result = json.loads(response.choices[0].message.content.strip())
                return result
            except json.JSONDecodeError:
                return {
                    "humor": 5,
                    "clarity": 5,
                    "relevance": 5,
                    "safety": 10
                }
                
        except Exception as e:
            raise AIServiceError(f"Ошибка валидации ситуации: {str(e)}")


# Создаем глобальный экземпляр клиента
openai_client = OpenAIClient() 