import pygame as pg
pg.init()
clock=pg.time.Clock()
FPS=60

W,H=(1400,1000)
BGC=(150,90,30)
#screen=pg.display.set_mode((W,H),flags=pg.NOFRAME)
#flags=pg.NOFRAME)убирает рамки
screen=pg.display.set_mode((W,H))
#название
pg.display.set_caption("PYGAME")
#иконка
pg.display.set_icon(pg.image.load("mickey-clock.png"))

#РИСУЕМ ФИГУРЫ
square=pg.Surface((30,30))
square.fill("Red")

screen.fill(BGC)
font=pg.font.Font('Poppins/Poppins-BlackItalic.ttf',40)
text_surface=font.render("Text",1,"red")
player=pg.image.load("left_hand.png")

#pg.QUIT-это у нас константа что показывает действие
#pg.quit()-это функция которая которая завершает программу 
go=True
while go:
    #метод рисование фигуры
    #screen.bilt(то что заранее создали с параметрами,(x,y))
    #pg.draw
    #pg.draw.figure(space_for_draw,COLOR,(x,y,w,h),толщина)
    pg.draw.circle(screen, "Blue", (70,70),70)
    screen.blit(square,(70,70))
    screen.blit(text_surface, (70,70))
    screen.blit(player,(300,400))
    
    pg.display.update()
    for event in pg.event.get():
        if event.type==pg.QUIT:
            pg.quit()
            go= False
            #момент где можно менять цвет фона,когда нажимаем клавишу вниз
        elif event.type==pg.KEYDOWN:
            if event.key==pg.K_DOWN:
               screen.fill((255,255,255))
    clock.tick(FPS)