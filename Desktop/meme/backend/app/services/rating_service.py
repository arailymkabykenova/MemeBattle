"""
Сервис для работы с рейтинговой системой.
Обеспечивает расчет рейтинга, ведение таблицы лидеров и статистики игроков.
"""

import math
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from sqlalchemy import select, func, desc
from sqlalchemy.ext.asyncio import AsyncSession

from ..models.user import User
from ..models.game import Game, GameRound, PlayerChoice, Vote
from ..repositories.user_repository import UserRepository
from ..repositories.game_repository import GameRepository
from ..external.redis_client import redis_client
from ..utils.exceptions import RatingError


class RatingService:
    """Сервис для работы с рейтинговой системой"""
    
    def __init__(self):
        self.user_repo = UserRepository()
        self.game_repo = GameRepository()
        
        # Константы для расчета рейтинга
        self.K_FACTOR = 32  # Фактор изменения рейтинга
        self.INITIAL_RATING = 1000  # Начальный рейтинг
        self.MIN_RATING = 100  # Минимальный рейтинг
        self.MAX_RATING = 3000  # Максимальный рейтинг
        
        # Бонусы за достижения
        self.WIN_BONUS = 10  # Бонус за победу
        self.STREAK_BONUS = 5  # Бонус за серию побед
        self.PARTICIPATION_BONUS = 1  # Бонус за участие
    
    async def calculate_rating(
        self,
        user_id: int,
        game_result: Dict[str, Any],
        db: AsyncSession
    ) -> Dict[str, Any]:
        """
        Рассчитывает новый рейтинг пользователя после игры.
        
        Args:
            user_id: ID пользователя
            game_result: Результаты игры
            db: Сессия базы данных
            
        Returns:
            Dict: Новый рейтинг и статистика
        """
        try:
            # Получаем текущий рейтинг пользователя
            user = await self.user_repo.get_by_id(user_id, db)
            if not user:
                raise RatingError(f"Пользователь {user_id} не найден")
            
            current_rating = user.rating or self.INITIAL_RATING
            
            # Рассчитываем изменение рейтинга
            rating_change = await self._calculate_rating_change(
                user_id, game_result, current_rating, db
            )
            
            # Применяем изменение
            new_rating = max(
                self.MIN_RATING,
                min(self.MAX_RATING, current_rating + rating_change)
            )
            
            # Обновляем рейтинг в базе
            await self.user_repo.update_rating(user_id, new_rating, db)
            
            # Обновляем статистику
            stats = await self._update_player_stats(user_id, game_result, db)
            
            # Кэшируем новый рейтинг
            await redis_client.set(f"rating:{user_id}", new_rating, expire=3600)
            
            return {
                "user_id": user_id,
                "old_rating": current_rating,
                "new_rating": new_rating,
                "rating_change": rating_change,
                "stats": stats
            }
            
        except Exception as e:
            raise RatingError(f"Ошибка расчета рейтинга: {str(e)}")
    
    async def _calculate_rating_change(
        self,
        user_id: int,
        game_result: Dict[str, Any],
        current_rating: int,
        db: AsyncSession
    ) -> int:
        """Рассчитывает изменение рейтинга"""
        
        # Базовое изменение на основе результата игры
        if game_result.get("is_winner"):
            base_change = self.WIN_BONUS
        else:
            base_change = -self.WIN_BONUS
        
        # Бонус за серию побед
        streak_bonus = await self._calculate_streak_bonus(user_id, db)
        
        # Бонус за участие
        participation_bonus = self.PARTICIPATION_BONUS
        
        # Штраф за быстрое поражение
        quick_loss_penalty = await self._calculate_quick_loss_penalty(game_result)
        
        total_change = base_change + streak_bonus + participation_bonus - quick_loss_penalty
        
        return int(total_change)
    
    async def _calculate_streak_bonus(self, user_id: int, db: AsyncSession) -> int:
        """Рассчитывает бонус за серию побед"""
        try:
            # Получаем последние 5 игр пользователя
            recent_games = await self.game_repo.get_user_recent_games(user_id, 5, db)
            
            win_streak = 0
            for game in recent_games:
                if game.winner_id == user_id:
                    win_streak += 1
                else:
                    break
            
            # Бонус за каждую победу в серии (максимум 3)
            return min(win_streak * self.STREAK_BONUS, 15)
            
        except Exception:
            return 0
    
    async def _calculate_quick_loss_penalty(self, game_result: Dict[str, Any]) -> int:
        """Рассчитывает штраф за быстрое поражение"""
        try:
            game_duration = game_result.get("duration", 0)
            if game_duration < 60:  # Меньше минуты
                return 5
            elif game_duration < 300:  # Меньше 5 минут
                return 2
            return 0
        except Exception:
            return 0
    
    async def get_leaderboard(
        self,
        limit: int = 100,
        offset: int = 0,
        db: AsyncSession = None
    ) -> List[Dict[str, Any]]:
        """
        Получает таблицу лидеров.
        
        Args:
            limit: Количество записей
            offset: Смещение
            db: Сессия базы данных
            
        Returns:
            List[Dict]: Таблица лидеров
        """
        try:
            # Сначала пытаемся получить из кэша
            cache_key = f"leaderboard:{limit}:{offset}"
            cached = await redis_client.get(cache_key)
            if cached:
                return cached
            
            # Получаем из базы данных
            query = select(User).order_by(desc(User.rating)).offset(offset).limit(limit)
            result = await db.execute(query)
            users = result.scalars().all()
            
            leaderboard = []
            for i, user in enumerate(users, offset + 1):
                stats = await self._get_user_stats(user.id, db)
                leaderboard.append({
                    "rank": i,
                    "user_id": user.id,
                    "nickname": user.nickname,
                    "rating": user.rating,
                    "games_played": stats.get("games_played", 0),
                    "games_won": stats.get("games_won", 0),
                    "win_rate": stats.get("win_rate", 0)
                })
            
            # Кэшируем результат на 5 минут
            await redis_client.set(cache_key, leaderboard, expire=300)
            
            return leaderboard
            
        except Exception as e:
            raise RatingError(f"Ошибка получения таблицы лидеров: {str(e)}")
    
    async def get_player_rank(self, user_id: int, db: AsyncSession) -> Optional[int]:
        """
        Получает позицию игрока в рейтинге.
        
        Args:
            user_id: ID пользователя
            db: Сессия базы данных
            
        Returns:
            Optional[int]: Позиция в рейтинге
        """
        try:
            # Сначала пытаемся получить из кэша
            cache_key = f"player_rank:{user_id}"
            cached = await redis_client.get(cache_key)
            if cached:
                return cached
            
            # Получаем из базы данных
            query = select(func.count(User.id)).select_from(User).where(User.rating > (
                select(User.rating).where(User.id == user_id)
            ))
            result = await db.execute(query)
            rank = result.scalar() + 1
            
            # Кэшируем результат на 1 минуту
            await redis_client.set(cache_key, rank, expire=60)
            
            return rank
            
        except Exception as e:
            raise RatingError(f"Ошибка получения позиции игрока: {str(e)}")
    
    async def update_player_stats(
        self,
        user_id: int,
        game_result: Dict[str, Any],
        db: AsyncSession
    ) -> Dict[str, Any]:
        """
        Обновляет статистику игрока.
        
        Args:
            user_id: ID пользователя
            game_result: Результаты игры
            db: Сессия базы данных
            
        Returns:
            Dict: Обновленная статистика
        """
        try:
            # Получаем текущую статистику
            current_stats = await self._get_user_stats(user_id, db)
            
            # Обновляем статистику
            games_played = current_stats.get("games_played", 0) + 1
            games_won = current_stats.get("games_won", 0)
            
            if game_result.get("is_winner"):
                games_won += 1
            
            win_rate = (games_won / games_played * 100) if games_played > 0 else 0
            
            # Обновляем в базе данных
            await self.user_repo.update_stats(
                user_id,
                games_played=games_played,
                games_won=games_won,
                win_rate=win_rate,
                db=db
            )
            
            # Очищаем кэш статистики
            await redis_client.delete(f"user_stats:{user_id}")
            
            return {
                "games_played": games_played,
                "games_won": games_won,
                "win_rate": round(win_rate, 2)
            }
            
        except Exception as e:
            raise RatingError(f"Ошибка обновления статистики: {str(e)}")
    
    async def _get_user_stats(self, user_id: int, db: AsyncSession) -> Dict[str, Any]:
        """Получает статистику пользователя"""
        try:
            # Сначала пытаемся получить из кэша
            cache_key = f"user_stats:{user_id}"
            cached = await redis_client.get(cache_key)
            if cached:
                return cached
            
            # Получаем из базы данных
            user = await self.user_repo.get_by_id(user_id, db)
            if not user:
                return {}
            
            stats = {
                "games_played": getattr(user, 'games_played', 0),
                "games_won": getattr(user, 'games_won', 0),
                "win_rate": getattr(user, 'win_rate', 0)
            }
            
            # Кэшируем результат на 5 минут
            await redis_client.set(cache_key, stats, expire=300)
            
            return stats
            
        except Exception:
            return {}
    
    async def get_rating_history(
        self,
        user_id: int,
        days: int = 30,
        db: AsyncSession = None
    ) -> List[Dict[str, Any]]:
        """
        Получает историю изменения рейтинга.
        
        Args:
            user_id: ID пользователя
            days: Количество дней
            db: Сессия базы данных
            
        Returns:
            List[Dict]: История рейтинга
        """
        try:
            # Получаем игры за последние N дней
            since_date = datetime.utcnow() - timedelta(days=days)
            games = await self.game_repo.get_user_games_since(user_id, since_date, db)
            
            history = []
            current_rating = self.INITIAL_RATING
            
            for game in games:
                if game.winner_id == user_id:
                    current_rating += self.WIN_BONUS
                else:
                    current_rating -= self.WIN_BONUS
                
                current_rating = max(self.MIN_RATING, min(self.MAX_RATING, current_rating))
                
                history.append({
                    "date": game.created_at.isoformat(),
                    "rating": current_rating,
                    "game_id": game.id,
                    "is_winner": game.winner_id == user_id
                })
            
            return history
            
        except Exception as e:
            raise RatingError(f"Ошибка получения истории рейтинга: {str(e)}")
    
    async def get_season_stats(self, db: AsyncSession) -> Dict[str, Any]:
        """
        Получает статистику сезона.
        
        Args:
            db: Сессия базы данных
            
        Returns:
            Dict: Статистика сезона
        """
        try:
            # Получаем статистику из кэша
            cache_key = "season_stats"
            cached = await redis_client.get(cache_key)
            if cached:
                return cached
            
            # Получаем из базы данных
            total_users = await db.execute(select(func.count(User.id)))
            total_users = total_users.scalar()
            
            avg_rating = await db.execute(select(func.avg(User.rating)))
            avg_rating = avg_rating.scalar() or 0
            
            total_games = await db.execute(select(func.count(Game.id)))
            total_games = total_games.scalar()
            
            stats = {
                "total_users": total_users,
                "average_rating": round(avg_rating, 2),
                "total_games": total_games,
                "season_start": datetime.utcnow().replace(day=1, hour=0, minute=0, second=0, microsecond=0).isoformat()
            }
            
            # Кэшируем результат на 1 час
            await redis_client.set(cache_key, stats, expire=3600)
            
            return stats
            
        except Exception as e:
            raise RatingError(f"Ошибка получения статистики сезона: {str(e)}")


# Создаем глобальный экземпляр сервиса
rating_service = RatingService() 