"""
AI Service для генерации ситуационных карточек.
Использует Azure OpenAI для создания интересных и забавных ситуаций для игры.
"""

import random
import logging
from typing import List, Optional, Dict
from datetime import datetime, date
from openai import AsyncAzureOpenAI
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.config import get_settings
from ..utils.exceptions import ExternalServiceError

logger = logging.getLogger(__name__)


class AIService:
    """Сервис для AI генерации игрового контента с поддержкой многоязычности."""

    def __init__(self, db: AsyncSession):
        self.db = db
        self.settings = get_settings()
        self._client: Optional[AsyncAzureOpenAI] = None
        
        # Словарь с контентом для разных языков
        self.content_templates: Dict[str, Dict] = {
            "ru": {
                "age_topics": {
                    "kids": ["школа", "друзья", "игры", "семья", "животные", "мультфильмы", "игрушки", "день рождения", "супергерои", "видеоигры", "домашние животные", "прятки"],
                    "teens": ["школа", "друзья", "увлечения", "социальные сети", "спорт", "музыка", "мемы", "кринж", "краш", "стримы", "домашка", "экзамены"],
                    "young_adults": ["учеба", "работа", "отношения", "развлечения", "технологии", "путешествия", "дедлайн", "удаленка", "свидания в Тиндере", "бывшие", "аренда"],
                    "adults": ["работа", "семья", "отношения", "быт", "здоровье", "карьера", "ипотека", "родительский чат", "коммуналка", "отпуск", "коллеги"],
                    "seniors": ["семья", "здоровье", "досуг", "воспоминания", "внуки", "опыт"]
                },
                "base_situation_prompt": """
                    Ты — стендап-комик и сценарист для популярного комедийного шоу. Твоя задача — придумать УБИЙСТВЕННО смешную, жизненную и слегка абсурдную ситуацию для карточной игры.
                    
                    Правила:
                    1.  **Формат:** Ситуация должна начинаться со слов "Когда...", "Твое лицо, когда...", "Тот момент, когда..." или быть в виде прямого приказа "Объясни...".
                    2.  **Цель:** Заставить игроков кататься по полу от смеха. Ситуация должна быть узнаваемой, но с неожиданным поворотом.
                    3.  **Темы:** Обязательно используй одну из этих тем: {topics}.
                    4.  **Сложность:** Это раунд {round_number} из 7. Чем дальше, тем более тонким и неожиданным должен быть юмор.
                    5.  **Длина:** Строго 1-2 предложения.
                    6.  **Язык:** Русский.
                    
                    Вот примеры ТОП-УРОВНЯ, на который нужно ориентироваться:
                    - "Твое лицо, когда ты 5 минут рассказывал смешную историю, а потом понял, что у тебя выключен микрофон."
                    - "Когда пытаешься незаметно посмотреть на нового симпатичного коллегу, но встречаешься с ним взглядом."
                    - "Объясни своему коту, почему он не может пойти с тобой на работу."
                """,
                "customization_prompt": """
                    Ты — редактор, который адаптирует юмор под конкретную аудиторию. Твоя задача — взять базовую ситуацию и сделать ее максимально смешной и понятной для этой группы.
                    
                    **Аудитория:** {age_group}, преимущественно {gender_group}.
                    
                    **Инструкции по адаптации:**
                    - **{age_group}:** {age_instruction}
                    - **{gender_group}:** {gender_instruction}
                    
                    **Золотые правила:**
                    - Сохрани суть и юмор, но замени детали на релевантные для этой аудитории.
                    - Используй их сленг (но не перебарщивай!).
                    - Не будь стереотипным или оскорбительным. Просто сделай так, чтобы они сказали: "О да, это про меня!".
                    - Выдай ТОЛЬКО финальный текст ситуации, без лишних слов.
                """,
                "age_instructions": {
                    "kids": "Сделай ситуацию очень простой и понятной, связанной с играми, школой или родителями.",
                    "teens": "Используй слова типа 'кринж', 'вайб', говори про соцсети, школу, первую влюбленность.",
                    "young_adults": "Говори про универ, первую работу, съемную квартиру, неловкие свидания, нехватку денег.",
                    "adults": "Темы: работа, дети, усталость, бытовые проблемы, ностальгия по молодости.",
                    "seniors": "Сделай подходящей для старшего поколения - семья, опыт, мудрость"
                },
                "gender_instructions": {
                    "male": "Можно добавить отсылки к популярным видеоиграм, спорту или технике.",
                    "female": "Можно добавить отсылки к темам ухода за собой, поп-культуре или социальным трендам.",
                    "mixed": "Сделай ситуацию максимально универсальной."
                },
                "fallback_situations": [
                    "Твое лицо, когда нашел прошлогоднюю заначку в зимней куртке.",
                    "Когда случайно лайкнул фото человека, которое он выложил 5 лет назад.",
                    "Попытка приготовить что-то по видео-рецепту из TikTok.",
                    "Когда твой кот смотрит на тебя так, будто ты его главный должник.",
                    "Момент, когда ты уверенно говоришь 'да', не имея понятия, о чем идет речь.",
                    "Твое лицо, когда кто-то садится рядом с тобой в пустом автобусе.",
                    "Когда делаешь вид, что понял шутку, и смеешься на 3 секунды позже всех."
                ]
            },
            "en": {
                "age_topics": {
                    "kids": ["school", "superheroes", "video games", "pets", "cartoons", "friends", "family", "toys", "birthday"],
                    "teens": ["memes", "cringe", "crush", "streaming", "homework", "TikTok trends", "social media", "sports", "music"],
                    "young_adults": ["student debt", "remote work", "Tinder dates", "exes", "rent", "college", "first job", "relationships"],
                    "adults": ["mortgage", "the group chat", "bills", "vacation", "work colleagues", "family", "kids", "career"],
                    "seniors": ["family", "health", "leisure", "memories", "grandchildren", "experience"]
                },
                "base_situation_prompt": """
                    You are a stand-up comedian and a writer for a hit comedy show. Your task is to come up with a HILARIOUS, relatable, and slightly absurd situation for a card game.
                    
                    Rules:
                    1.  **Format:** The situation must start with "When...", "Your face when...", "That moment when..." or be a direct command like "Explain...".
                    2.  **Goal:** Make the players roll on the floor laughing. The situation should be recognizable but with a funny twist.
                    3.  **Topics:** You must use one of these topics: {topics}.
                    4.  **Difficulty:** This is round {round_number} of 7. The humor should get more subtle and unexpected as the game progresses.
                    5.  **Length:** Strictly 1-2 sentences.
                    6.  **Language:** English (B1-B2 level, with some light, common slang).
                    
                    Here are examples of the TOP-TIER quality you should aim for:
                    - "Your face when you've been telling a funny story for 5 minutes, only to realize you were muted."
                    - "When you try to discreetly check out the new cute colleague and make direct eye contact."
                    - "Explain to your cat why it can't come to work with you."
                """,
                "customization_prompt": """
                    You are an editor adapting humor for a specific audience. Your task is to take a base situation and make it as funny and relatable as possible for this group.
                    
                    **Audience:** {age_group}, mostly {gender_group}.
                    
                    **Adaptation instructions:**
                    - **{age_group}:** {age_instruction}
                    - **{gender_group}:** {gender_instruction}
                    
                    **Golden Rules:**
                    - Keep the core idea and humor, but change the details to be relevant to this audience.
                    - Use their slang (but don't overdo it!).
                    - Avoid being stereotypical or offensive. Just make them say, "OMG, that's so me!".
                    - Output ONLY the final situation text, with no extra words.
                """,
                "age_instructions": {
                    "kids": "Make the situation very simple and clear, related to games, school, or parents.",
                    "teens": "Use words like 'cringe', 'vibe', 'ghosting'. Talk about social media, school, first crushes.",
                    "young_adults": "Talk about college, first jobs, roommates, awkward dates, being broke.",
                    "adults": "Topics: work, kids, being tired, bills, nostalgia for your youth.",
                    "seniors": "Make it suitable for older generation - family, experience, wisdom"
                },
                "gender_instructions": {
                    "male": "You can add references to popular video games, sports, or gadgets.",
                    "female": "You can add references to self-care routines, pop culture, or social trends.",
                    "mixed": "Make the situation as universal as possible."
                },
                "fallback_situations": [
                    "Your face when you find money you hid in last year's winter coat.",
                    "When you accidentally like someone's photo from 5 years ago.",
                    "Trying to cook something from a TikTok video recipe.",
                    "When your cat looks at you like you owe it money.",
                    "That moment you confidently say 'yes' having no idea what the question was.",
                    "Your face when someone sits right next to you on an empty bus.",
                    "When you pretend to get a joke and laugh 3 seconds after everyone else."
                ]
            }
        }

    @property
    def client(self) -> AsyncAzureOpenAI:
        """Ленивая инициализация Azure OpenAI клиента"""
        if self._client is None:
            if not all([self.settings.azure_openai_endpoint, self.settings.azure_openai_key, self.settings.azure_openai_deployment_name]):
                raise ExternalServiceError("Azure OpenAI is not configured. Check environment variables.")
            self._client = AsyncAzureOpenAI(
                azure_endpoint=self.settings.azure_openai_endpoint,
                api_key=self.settings.azure_openai_key,
                api_version=self.settings.azure_openai_api_version
            )
        return self._client

    async def generate_situation_card(
        self, 
        round_number: int, 
        player_ages: List[Optional[date]] = None,
        player_genders: List[Optional[str]] = None,
        language: str = "ru",
        age_group: Optional[str] = None
    ) -> str:
        """
        Генерирует ситуационную карточку для раунда с поддержкой языка и age_group.
        Args:
            round_number: Номер раунда (1-7)
            player_ages: Даты рождения игроков (если age_group не передан)
            player_genders: Пол игроков для кастомизации тем
            language: Язык генерации ("ru" или "en")
            age_group: Явно заданная возрастная группа комнаты (если есть)
        Returns:
            str: Текст ситуационной карточки
        """
        try:
            lang_code = language.lower()
            if lang_code not in self.content_templates:
                logger.warning(f"Language '{lang_code}' not supported, defaulting to 'ru'.")
                lang_code = "ru"

            # Используем age_group если передан, иначе вычисляем по игрокам
            group = age_group or self._determine_age_group(player_ages)
            gender_group = self._determine_gender_group(player_genders)
            
            topics = self.get_topics_by_demographics(group, lang_code)
            base_situation = await self._generate_base_situation(round_number, topics, lang_code)
            if random.random() > 0.3:
                customized_situation = await self.customize_situation(
                    base_situation, group, gender_group, lang_code
                )
                logger.info(f"Generated customized situation for round {round_number}, age_group: {group}, gender_group: {gender_group}, language: {lang_code}")
                return customized_situation
            logger.info(f"Generated base situation for round {round_number}, age_group: {group}, gender_group: {gender_group}, language: {lang_code}")
            return base_situation
        except Exception as e:
            logger.error(f"Error generating situation card: {e}", exc_info=True)
            return self._get_fallback_situation(round_number, language)

    def get_topics_by_demographics(self, age_group: str, language: str) -> List[str]:
        """
        Получает подходящие темы по демографическим данным и языку.
        
        Args:
            age_group: Возрастная группа
            language: Язык контента
            
        Returns:
            List[str]: Список подходящих тем
        """
        # Убедимся, что язык поддерживается
        lang_code = language.lower()
        if lang_code not in self.content_templates:
            logger.warning(f"Language '{lang_code}' not supported, defaulting to 'ru'.")
            lang_code = "ru"
            
        age_topics = self.content_templates[lang_code]["age_topics"]
        
        # Берем темы для целевой возрастной группы
        topics = set(age_topics.get(age_group, age_topics["young_adults"]))
        
        # Добавляем 1-2 случайные темы из других групп для абсурдного юмора
        all_topics = [topic for group_topics in age_topics.values() for topic in group_topics]
        if len(all_topics) > 2:
            topics.update(random.sample(all_topics, 2))
        
        return list(topics)

    async def _generate_base_situation(self, round_number: int, topics: List[str], language: str) -> str:
        """Генерирует базовую ситуацию, используя шаблон для конкретного языка."""
        prompt_template = self.content_templates[language]["base_situation_prompt"]
        
        system_prompt = prompt_template.format(
            topics=', '.join(random.sample(topics, min(len(topics), 5))),
            round_number=round_number
        )
        
        user_prompt = "Generate one situation." if language == "en" else "Придумай одну ситуацию."

        try:
            response = await self.client.chat.completions.create(
                model=self.settings.azure_openai_deployment_name,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                max_tokens=150,
                temperature=0.85, # Чуть выше для большей креативности
                top_p=0.95
            )
            situation = response.choices[0].message.content.strip()
            return situation if situation else self._get_fallback_situation(round_number, language)
        except Exception as e:
            logger.error(f"Error in _generate_base_situation: {e}", exc_info=True)
            return self._get_fallback_situation(round_number, language)

    async def customize_situation(self, base_situation: str, age_group: str, gender_group: str, language: str) -> str:
        """
        Кастомизирует ситуацию, используя шаблон для конкретного языка.
        
        Args:
            base_situation: Базовая ситуация
            age_group: Возрастная группа
            gender_group: Гендерная группа
            language: Язык контента
            
        Returns:
            str: Кастомизированная ситуация
        """
        templates = self.content_templates[language]
        prompt_template = templates["customization_prompt"]
        
        system_prompt = prompt_template.format(
            age_group=age_group,
            gender_group=gender_group,
            age_instruction=templates["age_instructions"].get(age_group, ""),
            gender_instruction=templates["gender_instructions"].get(gender_group, "")
        )
        
        user_prompt = f"Adapt this situation: '{base_situation}'" if language == "en" else f"Адаптируй эту ситуацию: '{base_situation}'"
        
        try:
            response = await self.client.chat.completions.create(
                model=self.settings.azure_openai_deployment_name,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                max_tokens=200,
                temperature=0.7
            )
            customized = response.choices[0].message.content.strip()
            return customized if customized else base_situation
        except Exception as e:
            logger.error(f"Error in customize_situation: {e}", exc_info=True)
            return base_situation

    def _determine_age_group(self, player_ages: List[Optional[date]]) -> str:
        """Определяет среднюю возрастную группу игроков."""
        if not player_ages:
            return "young_adults"
        
        valid_ages = [datetime.now().year - d.year for d in player_ages if d and isinstance(d, date)]
        if not valid_ages:
            return "young_adults"
        
        avg_age = sum(valid_ages) / len(valid_ages)
        
        if avg_age < 13:
            return "kids"
        elif avg_age < 18:
            return "teens"
        elif avg_age < 30:
            return "young_adults"
        elif avg_age < 60:
            return "adults"
        else:
            return "seniors"

    def _determine_gender_group(self, player_genders: List[Optional[str]]) -> str:
        """Определяет преобладающую гендерную группу."""
        if not player_genders:
            return "mixed"
        
        valid_genders = [g.lower() for g in player_genders if g and isinstance(g, str)]
        if not valid_genders:
            return "mixed"
        
        total = len(valid_genders)
        if total == 0:
            return "mixed"
            
        male_count = valid_genders.count("male")
        female_count = valid_genders.count("female")
        
        if male_count / total > 0.7: 
            return "male"
        elif female_count / total > 0.7: 
            return "female"
        else: 
            return "mixed"

    def _get_fallback_situation(self, round_number: int, language: str = "ru") -> str:
        """Возвращает запасную ситуацию, если AI недоступен."""
        lang_code = language.lower()
        if lang_code not in self.content_templates:
            lang_code = "ru"
            
        fallback_situations = self.content_templates[lang_code]["fallback_situations"]
        index = (round_number - 1) % len(fallback_situations)
        return fallback_situations[index] 