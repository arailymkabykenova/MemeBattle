"""
Azure Blob Storage клиент для работы с карточками.
Загружает, получает и управляет изображениями мем-карточек.
"""

import logging
from typing import List, Optional, Dict, Any
import asyncio
from concurrent.futures import ThreadPoolExecutor
import os

from ..core.config import settings

# Опциональный импорт Azure SDK
try:
    from azure.storage.blob import BlobServiceClient, BlobClient, ContainerClient
    from azure.core.exceptions import ResourceNotFoundError, ResourceExistsError
    AZURE_AVAILABLE = True
except ImportError:
    AZURE_AVAILABLE = False
    # Заглушки для типов
    BlobServiceClient = None
    BlobClient = None 
    ContainerClient = None
    ResourceNotFoundError = Exception
    ResourceExistsError = Exception

logger = logging.getLogger(__name__)


class AzureBlobService:
    """Сервис для работы с Azure Blob Storage"""
    
    def __init__(self):
        self.connection_string = settings.azure_storage_connection_string
        self.container_name = settings.azure_container_name or "meme-cards"
        self.blob_service_client = None
        self.container_client = None
        self._cards_cache = {}  # Кэш карт по папкам
        self._initialize_client()
    
    def _initialize_client(self):
        """Инициализация Azure клиента"""
        if not AZURE_AVAILABLE:
            logger.warning("⚠️ Azure SDK не установлен. Установите: pip install azure-storage-blob")
            self.blob_service_client = None
            self.container_client = None
            return
            
        try:
            if self.connection_string:
                self.blob_service_client = BlobServiceClient.from_connection_string(
                    self.connection_string
                )
                self.container_client = self.blob_service_client.get_container_client(
                    self.container_name
                )
                logger.info(f"✅ Azure Blob Storage подключен к контейнеру: {self.container_name}")
            else:
                logger.warning("⚠️ Azure connection string не настроен")
        except Exception as e:
            logger.error(f"❌ Ошибка подключения к Azure: {e}")
            self.blob_service_client = None
            self.container_client = None
    
    def is_connected(self) -> bool:
        """Проверяет подключение к Azure"""
        return self.blob_service_client is not None and self.container_client is not None
    
    async def ensure_container_exists(self) -> bool:
        """Проверяет и создает контейнер если нужно"""
        if not self.is_connected():
            return False
        
        try:
            # Выполняем в thread pool, так как Azure SDK синхронный
            loop = asyncio.get_event_loop()
            with ThreadPoolExecutor() as executor:
                await loop.run_in_executor(
                    executor, 
                    self.container_client.create_container
                )
            logger.info(f"✅ Контейнер {self.container_name} создан")
            return True
        except ResourceExistsError:
            logger.info(f"✅ Контейнер {self.container_name} уже существует")
            return True
        except Exception as e:
            logger.error(f"❌ Ошибка создания контейнера: {e}")
            return False
    
    async def list_cards_in_folder(self, folder: str) -> List[int]:
        """
        Получает список номеров карточек в папке.
        
        Args:
            folder: Название папки (starter, standard, unique)
            
        Returns:
            List[int]: Список номеров карт
        """
        if not self.is_connected():
            logger.warning("Azure не подключен")
            return []
        
        # Проверяем кэш
        if folder in self._cards_cache:
            return self._cards_cache[folder]
        
        try:
            cards = []
            prefix = f"{folder}/"
            
            loop = asyncio.get_event_loop()
            with ThreadPoolExecutor() as executor:
                blob_list = await loop.run_in_executor(
                    executor,
                    lambda: list(self.container_client.list_blobs(name_starts_with=prefix))
                )
            
            # Сортируем блобы по имени для стабильного порядка
            image_blobs = [blob for blob in blob_list 
                          if blob.name.lower().endswith(('.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'))]
            image_blobs.sort(key=lambda x: x.name)
            
            # Присваиваем номера по порядку
            for index, blob in enumerate(image_blobs, 1):
                cards.append(index)
            
            # Кэшируем результат
            self._cards_cache[folder] = cards
            
            logger.info(f"📁 Найдено {len(cards)} карточек в папке {folder}")
            return cards
            
        except Exception as e:
            logger.error(f"❌ Ошибка получения карточек из {folder}: {e}")
            return []
    
    async def list_cards_in_folder_with_details(self, folder: str) -> List[Dict[str, Any]]:
        """
        Получает список карточек в папке с полными деталями.
        
        Args:
            folder: Название папки (starter, standard, unique)
            
        Returns:
            List[Dict]: Список файлов с метаданными
        """
        if not self.is_connected():
            logger.warning("Azure не подключен")
            return []
        
        try:
            cards = []
            prefix = f"{folder}/"
            
            loop = asyncio.get_event_loop()
            with ThreadPoolExecutor() as executor:
                blob_list = await loop.run_in_executor(
                    executor,
                    lambda: list(self.container_client.list_blobs(name_starts_with=prefix))
                )
            
            # Сортируем блобы по имени для стабильного порядка
            image_blobs = [blob for blob in blob_list 
                          if blob.name.lower().endswith(('.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'))]
            image_blobs.sort(key=lambda x: x.name)
            
            # Присваиваем номера по порядку
            for index, blob in enumerate(image_blobs, 1):
                filename = os.path.basename(blob.name)
                name_without_ext = os.path.splitext(filename)[0]
                
                cards.append({
                    "filename": filename,
                    "blob_path": blob.name,
                    "url": self._get_blob_url(blob.name),
                    "size": blob.size,
                    "last_modified": blob.last_modified,
                    "card_number": index,  # Номер по порядку
                    "card_name": name_without_ext,  # Оригинальное название
                    "card_type": folder
                })
            
            logger.info(f"📁 Найдено {len(cards)} карточек в папке {folder}")
            return cards
            
        except Exception as e:
            logger.error(f"❌ Ошибка получения карточек из {folder}: {e}")
            return []
    
    def get_card_url(self, card_type: str, card_number: int) -> Optional[str]:
        """
        Получает URL карты по типу и номеру.
        
        Args:
            card_type: Тип карты (starter, standard, unique)
            card_number: Номер карты в папке
            
        Returns:
            Optional[str]: URL карты или None если не найдена
        """
        if not self.is_connected():
            return f"https://placeholder.example.com/{card_type}_{card_number}.jpg"
        
        try:
            # Получаем список всех блобов в папке синхронно (для простоты)
            prefix = f"{card_type}/"
            blob_list = list(self.container_client.list_blobs(name_starts_with=prefix))
            
            # Фильтруем только изображения и сортируем
            image_blobs = [blob for blob in blob_list 
                          if blob.name.lower().endswith(('.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'))]
            image_blobs.sort(key=lambda x: x.name)
            
            # Проверяем есть ли карта с таким номером
            if 1 <= card_number <= len(image_blobs):
                blob = image_blobs[card_number - 1]  # Индексы с 0, номера с 1
                return self._get_blob_url(blob.name)
            
            logger.warning(f"❌ Карта {card_type}:{card_number} не найдена")
            return None
            
        except Exception as e:
            logger.error(f"❌ Ошибка получения URL для {card_type}:{card_number}: {e}")
            return None
    
    def _extract_number_from_filename(self, filename: str) -> Optional[int]:
        """
        Извлекает номер из имени файла (например, img1 -> 1).
        
        Args:
            filename: Имя файла без расширения
            
        Returns:
            Optional[int]: Номер карты или None
        """
        import re
        
        # Ищем число в имени файла (img1, card123, 001 и т.д.)
        match = re.search(r'(\d+)', filename)
        if match:
            return int(match.group(1))
        return None
    
    def _get_blob_url(self, blob_path: str) -> str:
        """
        Получает публичный URL файла.
        
        Args:
            blob_path: Путь к blob в контейнере
            
        Returns:
            str: Публичный URL
        """
        if not self.is_connected():
            return f"https://placeholder.example.com/{os.path.basename(blob_path)}"
        
        try:
            blob_client = self.blob_service_client.get_blob_client(
                container=self.container_name, 
                blob=blob_path
            )
            return blob_client.url
        except Exception as e:
            logger.error(f"❌ Ошибка получения URL для {blob_path}: {e}")
            return f"https://placeholder.example.com/{os.path.basename(blob_path)}"
    
    async def upload_card_image(self, local_path: str, blob_path: str) -> bool:
        """
        Загружает изображение карточки в Azure.
        
        Args:
            local_path: Локальный путь к файлу
            blob_path: Путь в Azure (например, "starter/meme_001.jpg")
            
        Returns:
            bool: True если загружено успешно
        """
        if not self.is_connected():
            logger.warning("Azure не подключен")
            return False
        
        try:
            loop = asyncio.get_event_loop()
            with ThreadPoolExecutor() as executor:
                with open(local_path, 'rb') as data:
                    blob_client = self.blob_service_client.get_blob_client(
                        container=self.container_name, 
                        blob=blob_path
                    )
                    await loop.run_in_executor(
                        executor,
                        lambda: blob_client.upload_blob(data, overwrite=True)
                    )
            
            logger.info(f"✅ Загружено: {local_path} -> {blob_path}")
            return True
            
        except Exception as e:
            logger.error(f"❌ Ошибка загрузки {local_path}: {e}")
            return False
    
    async def get_storage_statistics(self) -> Dict[str, Any]:
        """
        Получает статистику по хранилищу карточек.
        
        Returns:
            Dict: Статистика хранилища
        """
        if not self.is_connected():
            return {
                "connected": False,
                "error": "Azure не подключен"
            }
        
        stats = {
            "connected": True,
            "container": self.container_name,
            "folders": {}
        }
        
        # Получаем статистику по каждой папке
        for folder in ['starter', 'standard', 'unique']:
            cards = await self.list_cards_in_folder_with_details(folder)
            stats["folders"][folder] = {
                "count": len(cards),
                "cards": cards[:5]  # Первые 5 для примера
            }
        
        # Общая статистика
        total_cards = sum(stats["folders"][folder]["count"] for folder in stats["folders"])
        stats["total_cards"] = total_cards
        
        return stats

    async def debug_list_all_blobs(self) -> Dict[str, Any]:
        """
        ДИАГНОСТИКА: Показывает все файлы в контейнере для отладки.
        
        Returns:
            Dict: Список всех файлов в контейнере
        """
        if not self.is_connected():
            return {
                "connected": False,
                "error": "Azure не подключен"
            }
        
        try:
            all_blobs = []
            folders = set()
            
            loop = asyncio.get_event_loop()
            with ThreadPoolExecutor() as executor:
                blob_list = await loop.run_in_executor(
                    executor,
                    lambda: list(self.container_client.list_blobs())
                )
            
            for blob in blob_list:
                # Извлекаем папку из пути
                parts = blob.name.split('/')
                if len(parts) > 1:
                    folder = parts[0]
                    folders.add(folder)
                
                all_blobs.append({
                    "name": blob.name,
                    "size": blob.size,
                    "is_image": blob.name.lower().endswith(('.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'))
                })
            
            return {
                "connected": True,
                "container": self.container_name,
                "total_blobs": len(all_blobs),
                "folders_found": list(folders),
                "all_blobs": all_blobs[:20]  # Первые 20 для отладки
            }
            
        except Exception as e:
            logger.error(f"❌ Ошибка диагностики Azure: {e}")
            return {
                "connected": True,
                "error": f"Ошибка получения списка файлов: {str(e)}"
            }


# Создаем глобальный экземпляр сервиса
azure_service = AzureBlobService() 