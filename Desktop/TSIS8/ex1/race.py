import pygame as pg
from pygame.locals import *
import random
import time

pg.mixer.init() 
pg.init()
FPS = pg.time.Clock()
background_music = pg.mixer.Sound("ex1/background.wav")
background_music.play(loops=-1)
W = 500
H = 700
speed = 5
score = 0
money = 0

font = pg.font.SysFont("Poppins/Poppins-BlackItalic.ttf", 60)
game_over = font.render("Game over", True, "BLACK")

screen = pg.display.set_mode((W, H))
#screen=pg.display.set_mode((W,H),flags=pg.NOFRAME)
bcg = pg.image.load("ex1/bcg.jpeg")

pg.display.set_caption("Игра Racer")
pg.display.set_icon(pg.image.load("ex1/lam.png"))

WEIGHTED_COINS = [(1, 'ex1/coin2.png'), (1, 'ex1/coin3.png'), (2, 'ex1/coin4.png')]


class ENEMY(pg.sprite.Sprite):
    def __init__(self):
        super().__init__()
        self.image = pg.image.load("ex1/Enemy.png")
        self.rect = self.image.get_rect()
        self.rect.center = (random.randint(55, W - 55), 0)

    def move(self):
        global score
        #move_ip -отвечает за движение двигая по y(твоя скорость как бы)
        #здесь мы по горизонатали всегда на +speed двигаемся 
        self.rect.move_ip(0, speed)
        if self.rect.bottom > 790:
             #если хочешь чтобы она полностью уезжала добавь длину машинки
            score += 1
            self.rect.top = 0
            self.rect.center = (random.randint(55, W - 55), 0)


class Player(pg.sprite.Sprite):
    def __init__(self):
        super().__init__()
        self.image = pg.image.load("ex1/Player.png")
        self.rect = self.image.get_rect()
        self.rect.center = (250, 640)

    def move(self):
        pressed_keys = pg.key.get_pressed()
         #следить за нажатием любой клавиши на клавиатуре
        if self.rect.left > 44:
            if pressed_keys[K_LEFT]:
                self.rect.move_ip(-5, 0)
        if self.rect.right < W - 49:
            if pressed_keys[K_RIGHT]:
                self.rect.move_ip(5, 0)


class COIN(pg.sprite.Sprite):
    def __init__(self):
        super().__init__()
        self.weight, self.image_path = random.choice(WEIGHTED_COINS)
        self.image = pg.image.load(self.image_path)
        self.rect = self.image.get_rect()
        self.rect.center = (random.randint(55, W - 55), 0)

    def move(self):
         #можно еще через
        #self.rect.y+=speed
        #if self.rect>790
        #self.rect.top=0
        self.rect.move_ip(0, speed)
        if self.rect.bottom > 790:
            self.rect.top = 0
            self.rect.center = (random.randint(55, W - 55), 0)

    def update(self):
        self.weight, self.image_path = random.choice(WEIGHTED_COINS)
        self.image = pg.image.load(self.image_path)
        self.rect = self.image.get_rect()
        self.rect.center = (random.randint(55, W - 55), 0)

#установка спрайтов
P1 = Player()
E1 = ENEMY()
C1 = COIN()

enemies = pg.sprite.Group()
enemies.add(E1)

coins = pg.sprite.Group()
coins.add(C1)

all_sprites = pg.sprite.Group()
all_sprites.add(P1)
all_sprites.add(E1)
all_sprites.add(C1)
#increase the speed
inc_speed = pg.USEREVENT + 1
#pg.USEREVENT+1 мы как бы создаем новое действие промежуточное для изменения скорости
pg.time.set_timer(inc_speed, 1000)
#inc_speed=>будет срабатывать каждую секунду

run = True
while run:
    screen.blit(bcg, (-95, 0))
    score_font = pg.font.SysFont("Poppins/Poppins-BlackItalic.ttf", 30)
    money_font = pg.font.SysFont("Poppins/Poppins-BlackItalic.ttf", 30)
    score_text = score_font.render("SCORE: " + str(score), True, (255, 255, 255))
    money_text = money_font.render("COINS: " + str(money), True, (255, 255, 255))
    screen.blit(score_text, (20, 10))
    screen.blit(money_text, (20, 40))

    for event in pg.event.get():
        if event.type == inc_speed:
            speed += 0.2
        if event.type == pg.QUIT:
            run = False
#отвечает за движение персонажей
    for entity in all_sprites:
        screen.blit(entity.image, entity.rect)
        entity.move()
    
    if pg.sprite.spritecollideany(P1, coins):
        money += C1.weight
        C1.update()

    if pg.sprite.spritecollideany(P1, enemies):
      pg.mixer.Sound("ex1/crash.wav").play()
      time.sleep(0.5)
      screen.fill("Red")
      screen.blit(game_over,(140,340))
      pg.display.update()
      for entity in all_sprites:
        entity.kill()
      if money % 5 == 0:
        speed += 2
      pg.time.wait(500)  
      pg.quit()

   
    


    pg.display.update()
    FPS.tick(60)
