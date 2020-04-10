require 'gosu'

White  = Gosu::Color.argb(0xFF_FFFFFF)
Red    = Gosu::Color.argb(0xFF_FF0000)
Yellow = Gosu::Color.argb(0xFF_FFFF00)
Green  = Gosu::Color.argb(0xFF_008000)
Azure  = Gosu::Color.argb(0xFF_4080FF)
Blue   = Gosu::Color.argb(0xFF_000080)
Black  = Gosu::Color.argb(0xFF_000000)

class Rect

	attr_accessor :x, :y, :w, :h, :c

	def initialize(x, y, w, h, c); @x, @y, @w, @h, @c = x, y, w, h, c; end

	def width;  @w;      end
	def height; @h;      end
	def left;   @x;      end
	def right;  @x + @w; end
	def top;    @y;      end
	def bottom; @y + @h; end

	def width= (v); @w = v;      end
	def height=(v); @h = v;      end
	def left=  (v); @x = v;      end
	def right= (v); @x = v - @w; end
	def top=   (v); @y = v;      end
	def bottom=(v); @y = v - @h; end

	def rect
		return @x, @y, @w, @h
	end

	def center(x, y)
		@x = x - @w / 2
		@y = y - @h / 2
	end

	def move(x, y)
		@x += x
		@y += y
	end

	def collide?(r)
		r.left < self.right  and r.right  > self.left and
		r.top  < self.bottom and r.bottom > self.top
	end

	def collidelist(l)
		l.each { |r| return r if collide?(r) }
		nil
	end

	def draw
		Gosu::draw_rect(x, y, w, h, c)
	end

end

class Pad < Rect

	def initialize
		super(0, 0, *PadSize, Yellow)
		self.center(ScreenWidth / 2, ScreenHeight - 24)
		@speed = 8
	end

	def move_left
		@x -= @speed
		self.left = $ball.right if self.collide?($ball)
		self.left = 0 if self.left < 0
	end

	def move_right
		@x += @speed
		self.right = $ball.left  if self.collide?($ball)
		self.right = ScreenWidth if self.right > ScreenWidth
	end

end

class Ball < Rect

	def initialize
		super(0, 0, *BallSize, Red)
		self.center(ScreenWidth / 2, ScreenHeight / 2)
		@xspeed = 4
		@yspeed = 4
	end

	def move
		posx  = @x
		pboom = xboom = yboom = false

		@x += @xspeed
		brick = collidelist($wall.bricks)
		unless brick.nil?
			$wall.bricks.delete(brick)
			xboom = true
			$score += brick.score
			self.right = brick.left  if @xspeed > 0
			self.left  = brick.right if @xspeed < 0
		end
		if collide?($pad)
			xboom = true
			$score += 1
			self.right = $pad.left  if @xspeed > 0
			self.left  = $pad.right if @xspeed < 0
		end
		if self.left < 0
			xboom = true
			self.left = 0
		end
		if self.right > ScreenWidth
			xboom = true
			self.right = ScreenWidth
		end

		newx = @x; @x = posx

		@y += @yspeed
		brick = collidelist($wall.bricks)
		unless brick.nil?
			$wall.bricks.delete(brick)
			yboom = true
			$score += brick.score
			self.bottom = brick.top    if @yspeed > 0
			self.top    = brick.bottom if @yspeed < 0
		end
		if collide?($pad)
			pboom = yboom = true
			$score += 1
			self.bottom = $pad.top    if @yspeed > 0
			self.top    = $pad.bottom if @yspeed < 0
		end
		if self.top < 0
			yboom = true
			self.top = 0
		end
		if self.bottom > ScreenHeight
			yboom = true
			self.bottom = ScreenHeight
			$score -= 1
		end

		@x = newx

		if not xboom and not yboom
			brick = collidelist($wall.bricks)
			unless brick.nil?
				$wall.bricks.delete(brick)
				xboom = yboom = true
				$score += brick.score
				self.right  = brick.left   if @xspeed > 0
				self.left   = brick.right  if @xspeed < 0
				self.bottom = brick.top    if @yspeed > 0
				self.top    = brick.bottom if @yspeed < 0
			end
			if collide?($pad)
				xboom = yboom = true
				$score += 1
				self.right  = $pad.left   if @xspeed > 0
				self.left   = $pad.right  if @xspeed < 0
				self.bottom = $pad.top    if @yspeed > 0
				self.top    = $pad.bottom if @yspeed < 0
			end
		end

		if pboom and @yspeed > 0
			xboom = true if @xspeed < 0 and $game.button_down?(Gosu::KbRight)
			xboom = true if @xspeed > 0 and $game.button_down?(Gosu::KbLeft)
		end

		@xspeed = -@xspeed if xboom
		@yspeed = -@yspeed if yboom
	end

end

class Brick < Rect

	def initialize(x, y)
		@score = WallHeight - y
		
		p  = 255.0 * y / WallHeight
		c = Gosu::Color::rgba(0, p, 255 - p, 255)
		x = x * BrickWidth / 2 + 1
		y = (y + WallPos) * BrickHeight + 1

		super(x, y, BrickWidth - 2, BrickHeight - 2, c)
	end

	def score
		@score
	end

end

class Wall

	attr_reader :bricks

	def initialize
		@bricks = []
		(0 .. WallHeight - 1).step(2) do |y|
			(0 .. WallWidth * 2 - 1).step(2) do |x|
				@bricks << Brick.new(x, y)
			end
		end
		(1 .. WallHeight).step(2) do |y|
			(-1 .. WallWidth * 2).step(2) do |x|
				@bricks << Brick.new(x, y)
			end
		end
	end

	def draw
		@bricks.each do |b| b.draw end
	end

	def alive?
		bricks.length > 0
	end

end

class Game < Gosu::Window

	def initialize
		super(*ScreenSize)
		self.caption = 'PONG!'
		@font = Gosu::Font.new(self, Gosu::default_font_name, 20)
	end

	def button_down(id)
		close if id == Gosu::KbEscape
	end

	def update
	    if $wall.alive?
			$automat = true  if button_down?(Gosu::KbA)
			$automat = false if button_down?(Gosu::KbLeft)
			$automat = false if button_down?(Gosu::KbRight)
			if $automat
				$pad.move_left  if $ball.x < $pad.x
				$pad.move_right if $ball.x + BallWidth > $pad.x + PadWidth
			else
				$pad.move_left  if button_down?(Gosu::KbLeft)
				$pad.move_right if button_down?(Gosu::KbRight)
			end
			$ball.move
			@stop = Gosu::milliseconds + 3000
		end
		close if Gosu::milliseconds >= @stop
	end

	def draw
		$pad.draw
		$ball.draw
		$wall.draw
		showInfo
		showEnd if not $wall.alive?
	end

	private

	def showInfo
		@font.draw_text_rel("#{$wall.bricks.length}", 4, 4, 0, 0.0, 0.0)
		@font.draw_text_rel("#{$score}", ScreenWidth - 4, 4, 0, 1.0, 0.0)
	end

	def showEnd
		@font.draw_text_rel("GAME OVER", ScreenWidth / 2, ScreenHeight / 2, 0, 0.5, 0.5)
	end

end

ScreenSize = (ScreenWidth, ScreenHeight = 640, 480)
ScreenRect =  0, 0, *ScreenSize
BrickSize  = (BrickWidth,  BrickHeight  =  32,  16)
WallPos    =  3
WallSize   = (WallWidth,   WallHeight   = ScreenWidth / BrickWidth, 10)
BallSize   = (BallWidth,   BallHeight   =   8,   8)
PadSize    = (PadWidth,    PadHeight    =  64,   4)

if __FILE__ == $0

	$score = 0
	$automat = false
	$pad   = Pad.new
	$ball  = Ball.new
	$wall  = Wall.new
	$game  = Game.new
	$game.show

end
