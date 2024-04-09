import pygame,sys
from pygame.locals import*
import random
pygame.init()
FPS=60
FRAMEPERSEC=pygame.time.Clock()
WIDTH,HEIGHT=(500,500)
screen=pygame.display.set_mode((500,500)) 
screen.fill((255,255,255))
pygame.display.set_caption("Car game")

c_1=pygame.Color(0,0,128)
c_2=pygame.Color(218,165,32)
c_3=pygame.Color(128,0,0)
c_4=pygame.Color(255,210,210)
c_5=pygame.Color(210,13,16)
c_6=pygame.Color(175,10,122)
c_7=pygame.Color(133,255,0)
c_8=pygame.Color(100,12,123)
COLORS=[c_1,c_2,c_3,c_4,c_5,c_6,c_7,c_8]
class Car:
    def __init__(self, x, y):
        self.x = x
        self.y = y
        self.color = random.choice(COLORS)  # Случайный выбор цвета для каждой машины
        self.image = pygame.image.load("car_image.png")  # Загрузка изображения машинки

    def draw(self, screen):
        screen.blit(self.image, (self.x, self.y))  # Отображение изображения машинки

# Создание экрана
screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
pygame.display.set_caption("Changing Color Cars")

clock = pygame.time.Clock()

running = True
while running:
    for event in pygame.event.get():
        if event.type == QUIT:
            running = False

    # Очистка экрана
    screen.fill((255, 255, 255))

    # Создание машин
    car1 = Car(100, 100)
    car2 = Car(200, 200)

    # Отрисовка машин
    car1.draw(screen)
    car2.draw(screen)

    # Обновление экрана
    pygame.display.flip()

    # Пауза на 1 секунду перед началом нового раунда
    pygame.time.wait(1000)

pygame.quit()