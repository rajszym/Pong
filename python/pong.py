import os, sys, pygame

White  = (0xFF, 0xFF, 0xFF)
Red    = (0xFF, 0x00, 0x00)
Yellow = (0xFF, 0xFF, 0x00)
Green  = (0x00, 0xFF, 0x00)
Blue   = (0x00, 0x00, 0xFF)
Black  = (0x00, 0x00, 0x00)
BKG    = Black

class Player(pygame.Rect):

	def __init__(self):

		pygame.Rect.__init__(self, (0, 0), PlayerSize)
		self.center = ScreenWidth // 2, ScreenHeight - 24
		self.speed  = 2

	def move_left(self):

		self.x -= self.speed
		if self.colliderect(ball): self.left = ball.right
		if self.left < 0: self.left = 0

	def move_right(self):

		self.x += self.speed
		if self.colliderect(ball): self.right = ball.left
		if self.right > ScreenWidth: self.right = ScreenWidth

	def update(self):

		pygame.draw.rect(screen, Yellow, self)

class Ball(pygame.Rect):

	def __init__(self):

		pygame.Rect.__init__(self, (0, 0), BallSize)
		self.center = ScreenWidth // 2, ScreenHeight // 2
		self.xspeed = self.yspeed = 1

	def move(self):

		global score

		posx  = self.x
		pboom = xboom = yboom = False

		self.x += self.xspeed
		i = self.collidelist(wall.bricks)
		brick = wall.bricks.pop(i) if i >= 0 else None
		if brick:
			xboom = True; score += brick.score
			if self.xspeed > 0: self.right = brick.left
			if self.xspeed < 0: self.left  = brick.right
		if self.colliderect(player):
			xboom = True; score += 1
			if self.xspeed > 0: self.right = player.left
			if self.xspeed < 0: self.left  = player.right
		if self.left < 0:
			xboom = True; self.left = 0
		if self.right > ScreenWidth:
			xboom = True; self.right = ScreenWidth

		newx = self.x; self.x = posx

		self.y += self.yspeed
		i = self.collidelist(wall.bricks)
		brick = wall.bricks.pop(i) if i >= 0 else None
		if brick:
			yboom = True; score += brick.score
			if self.yspeed > 0: self.bottom = brick.top
			if self.yspeed < 0: self.top    = brick.bottom
		if self.colliderect(player):
			pboom = yboom = True; score += 1
			if self.yspeed > 0: self.bottom = player.top
			if self.yspeed < 0: self.top    = player.bottom
		if self.top < 0:
			yboom = True; self.top = 0
		if self.bottom > ScreenHeight:
			yboom = True; self.bottom = ScreenHeight; score -= 1

		self.x = newx

		if not xboom and not yboom:
			i = self.collidelist(wall.bricks)
			brick = wall.bricks.pop(i) if i >= 0 else None
			if brick:
				xboom = yboom = True; score += brick.score
				if self.xspeed > 0: self.right  = brick.left
				if self.xspeed < 0: self.left   = brick.right
				if self.yspeed > 0: self.bottom = brick.top
				if self.yspeed < 0: self.top    = brick.bottom
			if self.colliderect(player):
				xboom = yboom = True; score += 1
				if self.xspeed > 0: self.right  = player.left
				if self.xspeed < 0: self.left   = player.right
				if self.yspeed > 0: self.bottom = player.top
				if self.yspeed < 0: self.top    = player.bottom

		if pboom and (self.yspeed > 0):
			key = pygame.key.get_pressed()
			if self.xspeed > 0 and key[pygame.K_LEFT ]: xboom = True
			if self.xspeed < 0 and key[pygame.K_RIGHT]: xboom = True
		if xboom: self.xspeed = - self.xspeed
		if yboom: self.yspeed = - self.yspeed

	def update(self):

		pygame.draw.rect(screen, Red, self)

class Brick(pygame.Rect):

	def __init__(self, x, y):

		p  = 255 * y // WallHeight
		self.color = (0, p, 255 - p)
		self.score = WallHeight - y
		x = x * BrickWidth // 2 + 1
		y = (y + WallPos) * BrickHeight + 1
		pygame.Rect.__init__(self, (x, y), (BrickWidth - 2, BrickHeight - 2))
		
	def update(self):

		pygame.draw.rect(screen, self.color, self)

class Wall(object):

	def __init__(self):

		self.bricks = []
		for y in range(0, WallHeight, 2):
			for x in range( 0, WallWidth * 2, 2):
				self.bricks.append(Brick(x, y))
		for y in range(1, WallHeight, 2):
			for x in range(-1, WallWidth * 2, 2):
				self.bricks.append(Brick(x, y))

	def update(self):

		for brick in self.bricks:
			brick.update()


def showInfo():

	font = pygame.font.Font(None, 24)
	text = font.render(str(score), 1, White)
	rect = text.get_rect(); rect = rect.move(ScreenWidth - rect.right - 4, 4)
	screen.blit(text, rect)
	text = font.render(str(len(wall.bricks)), 1, White)
	rect = text.get_rect(); rect = rect.move(rect.left + 4, 4)
	screen.blit(text, rect)

def showEnd():

	font = pygame.font.SysFont('Verdana', 32)
	text = font.render("GAME OVER", 1, White)
	rect = text.get_rect(); rect.center = ScreenWidth // 2, ScreenHeight // 2
	screen.blit(text, rect)
	pygame.display.update();
	pygame.time.wait(1000)

def main():

	global screen, player, ball, wall, score

	screen = pygame.display.set_mode(ScreenSize)
	player = Player()
	ball   = Ball()
	wall   = Wall()
	score  = 0
	automat = False

	while wall.bricks:

		pygame.time.delay(3)
		for e in pygame.event.get():
			if e.type == pygame.QUIT: return
			if e.type == pygame.KEYDOWN and e.key == pygame.K_ESCAPE: return
			if e.type == pygame.KEYDOWN and e.key == pygame.K_a:     automat = True
			if e.type == pygame.KEYDOWN and e.key == pygame.K_LEFT:  automat = False
			if e.type == pygame.KEYDOWN and e.key == pygame.K_RIGHT: automat = False

		if automat:
			if ball.x < player.x: player.move_left()
			if ball.x + BallWidth > player.x + PlayerWidth: player.move_right()
		else:
			key = pygame.key.get_pressed()
			if key[pygame.K_LEFT ]: player.move_left()
			if key[pygame.K_RIGHT]: player.move_right()

		ball.move()
		screen.fill(BKG)
		player.update()
		ball.update()
		wall.update()
		showInfo()
		pygame.display.update()

	showEnd()

ScreenSize = ScreenWidth, ScreenHeight = 640, 480
BrickSize  = BrickWidth,  BrickHeight  =  32,  16
WallPos    = 3
WallSize   = WallWidth,   WallHeight   = ScreenWidth // BrickWidth, 10
BallSize   = BallWidth,   BallHeight   =   8,   8
PlayerSize = PlayerWidth, PlayerHeight =  64,   4

if __name__ == "__main__":

	os.environ["SDL_VIDEO_CENTERED"] = "1"
	os.environ["SDL_VIDEODRIVER"]    = "windib"
	pygame.init()
	pygame.display.set_caption("PONG!")
	main()
	pygame.quit()
