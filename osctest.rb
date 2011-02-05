require 'rubygems'
require 'gosu'
require 'matrix'

class Vector
  def theta
    Math.atan2(self[1], self[0]) * (180 / 3.14159)
  end
end

def repeat(num)
	while num > 0
		yield
		num -= 1
	end
end

class GameObject
	def initialize (window, x, y, image)
		@image = Gosu::Image.new(window, image, true)
		@x = x
		@y = y
		$everything = $everything + [self]
		@exists = 1
	end
	def goto(x, y)
		@x = x
		@y = y
	end
	def x; @x; end
	def y; @y; end
	def exists; @exists; end
	def draw
		@image.draw_rot(@x, @y, 1, 0)
	end
	def update
	end
	def delete
		@exists = 0
	end
end

class Creature < GameObject
	def initialize (window, x, y, image)
		@image = Gosu::Image.new(window, image, true)
		@x = @spawnx = x
		@y = @spawny = y
		$everything = $everything + [self]
		@exists = 1
		@gravity = 0
	end
	def goto(x, y); super; end
	def respawn
		goto(@spawnx, @spawny)
		@gravity = 0
	end
	def x; @x; end
	def y; @y; end
	def exists; @exists; end
	def draw
		@image.draw_rot((((@x + 5) / 5).round * 5), (((@y + 5) / 5).round * 5), 100, 0)
	end
	def update
		@onblock = false
		@nexttoblock = false
		for i in $blocks
			if (i.y - @y) < 55 and (i.y - @y) > 0 and (i.x - @x).abs < 25
				@onblock = true
			end
			if (i.y - @y).abs < 50 and (i.x - @x).abs < 40
				if (i.y - y) > 0
					@y = (i.y - 50)
				else
					@y = (i.y + 50)
				end
				@gravity = 0
			end
			if (i.x - @x).abs < 45 and (i.y - @y).abs < 45
				@nexttoblock = true
				if (i.x - @x) > 0
					@x = i.x - 46
				else
					@x = i.x + 46
				end
			end
			for c in $climbables
				if (@x - c.x).abs < 25 and (@y - c.y).abs < 25
					@onblock = true
				end
			end
		end
		@y += @gravity
		@gravity += 0.25
		if @x < 0
			@x = 800
		end
		if @x > 800
			@x = 0
		end
		if @y > 600
			respawn
		end
	end
	def jump
		if @onblock == true
			@gravity = -5.5
		end
	end
	def left; @x -= 4; end
	def right; @x += 4; end
	def delete; super; end
end

class Enemy < Creature
	def initialize (window, x, y, image)
		@image = Gosu::Image.new(window, image, true)
		@x = @spawnx = x
		@y = @spawny = y
		$everything = $everything + [self]
		$enemies = $enemies + [self]
		@exists = 1
		@gravity = 0
	end
	def goto(x, y); super; end
	def respawn
		goto(@spawnx, @spawny)
		@gravity = 0
	end
	def x; @x; end
	def y; @y; end
	def exists; @exists; end
	def draw
		super
	end
	def update
		super
		if ($osc.x - @x).abs > 10
			if $osc.x < @x
				left
			else
				right
			end
		end
		if $osc.y < @y or @nexttoblock == true
			jump
		end
	end
	def jump
		if @onblock == true
			@gravity = -5
		end
	end
	def left; @x -= 2; end
	def right; @x += 2; end
	def delete; super; end
end

class Block < GameObject
	def initialize (window, x, y, image)
		@image = Gosu::Image.new(window, image, true)
		@x = x
		@y = y
		$everything = $everything + [self]
		$blocks = $blocks + [self]
		@exists = 1
	end
	def x; @x; end
	def y; @y; end
	def exists; @exists; end
	def draw
		@image.draw_rot(@x, @y, 1, 0)
	end
	def update; end
	def delete
		super
	end
end

class Prop < GameObject
	def initialize (window, x, y, image)
		@image = Gosu::Image.new(window, image, true)
		@x = x
		@y = y
		$everything = $everything + [self]
		@exists = 1
	end
	def x; @x; end
	def y; @y; end
	def exists; @exists; end
	def draw
		@image.draw_rot(@x, @y, 0, 0)
	end
	def update; end
	def delete
		super
	end
end

class Key < GameObject
	def initialize (window, x, y)
		@image = Gosu::Image.new(window, "interactives/key.png", true)
		@x = x
		@y = y
		$everything = $everything + [self]
		@exists = 1
	end
	def x; @x; end
	def y; @y; end
	def exists; @exists; end
	def draw
		@image.draw_rot(@x, @y, 0, 0)
	end
	def update
		if ($osc.x - @x).abs < 25 and ($osc.y - @y).abs < 25
			$keys += 1
			self.delete
		end
	end
	def delete
		super
	end
end

class Door < GameObject
	def initialize (window, x, y)
		@image = Gosu::Image.new(window, "interactives/door.png", true)
		@x = x
		@y = y
		$everything = $everything + [self]
		$blocks += [self]
		@exists = 1
	end
	def x; @x; end
	def y; @y; end
	def exists; @exists; end
	def draw
		@image.draw_rot(@x, @y, 0, 0)
	end
	def update
		if ($osc.x - @x).abs < 50 and ($osc.y - @y).abs < 50 and $keys > 0
			$keys -= 1
			$blocks -= [self]
			self.delete
		end
	end
	def delete
		super
	end
end

class Climbable < GameObject
	def initialize (window, x, y, image)
		@image = Gosu::Image.new(window, image, true)
		@x = x
		@y = y
		$everything = $everything + [self]
		$climbables += [self]
		@exists = 1
	end
	def x; @x; end
	def y; @y; end
	def exists; @exists; end
	def draw
		@image.draw_rot(@x, @y, 0, 0)
	end
	def update; end
	def delete
		super
	end
end

class KeyHUD < GameObject
	def initialize (window, x, y, image)
		@image = Gosu::Image.new(window, image, true)
		@x = x
		@y = y
		$everything = $everything + [self]
		@exists = 1
	end
	def x; @x; end
	def y; @y; end
	def exists; @exists; end
	def draw
		if $keys > 0
			@image.draw_rot(@x, @y, 1000, 0)
		end
	end
	def update; end
	def delete
		super
	end
end

class Cursor < GameObject
	def initialize (window, x, y)
		@image = Gosu::Image.new(window, "hud/cursor.png", true)
		@x = x
		@y = y
		$everything = $everything + [self]
		@exists = 1
	end
	def goto(x, y); super; end
	def x; @x; end
	def y; @y; end
	def exists; @exists; end
	def draw
		@image.draw_rot(@x, @y, 1337, 0)
	end
	def update
		goto($mx, $my)
	end
	def delete; super; end
end

class Particle < GameObject
	def initialize(window, x, y, image, angle, speed, lifespan)
		@image = Gosu::Image.new(window, image, true)
		@x = x
		@y = y
		$everything = $everything + [self]
		@exists = 1
		@angle = angle
		@speed = speed
		@lifespan = lifespan
	end
	def update
		@x += Gosu::offset_x(@angle, @speed)
		@y += Gosu::offset_y(@angle, @speed)
		@lifespan -= 1
		if @lifespan < 0
			delete
		end
	end
end

class Game < Gosu::Window
	def initialize
		super(800, 600, false)
		self.caption = "osc"
		$everything = $blocks = $enemies = $climbables = []
		$keys = 0
		$points = 0
		@bg = Gosu::Image.new(self, "background.png", true)
#		$music = Gosu::Sample.new(self, "music/start.mp3")
		$blocktypes = ["blocks/brick.png", "blocks/wood.png", "blocks/dirt.png", "blocks/stone.png", "blocks/vinestone.png"]
		loadlevel("level1.txt")
		addstuff("level1stuff.txt")
		Cursor.new(self, 0, 0)
		KeyHUD.new(self, 750, 25, "interactives/key.png")
#		$music.play(1, 1, true)
	end
	def loadlevel(levelname)
		@level = File.open(levelname)
		$charlist = []
		repeat(File.size(levelname)) { $charlist = $charlist + [@level.getc.chr] }
		@charnum = 0
		for c in $charlist
			@blockx = @charnum * 50 + 800
			@blocky = -1
			until @blockx < 800
				@blockx -= 800
				@blocky += 1
			end
			@blockx += 25
			@blocky = @blocky * 50
			@blocky += 25
			if c == "1"
				Block.new(self, @blockx, @blocky, "blocks/brick.png")
			end
			if c == "2"
				Block.new(self, @blockx, @blocky, "blocks/wood.png")
			end
			if c == "3"
				Block.new(self, @blockx, @blocky, "blocks/dirt.png")
			end
			if c == "4"
				Block.new(self, @blockx, @blocky, "blocks/stone.png")
			end
			if c == "5"
				Block.new(self, @blockx, @blocky, "blocks/vinestone.png")
			end
			if c == "6"
				Prop.new(self, @blockx, @blocky, "props/stonebg.png")
			end
			if c == "7"
				Prop.new(self, @blockx, @blocky, "props/grass.png")
			end
			if c == "8"
				Prop.new(self, @blockx, @blocky, "props/tree.png")
			end
			if c == "9"
				Prop.new(self, @blockx, @blocky, "props/grasstree.png")
			end
			if c == "a"
				Prop.new(self, @blockx, @blocky, "props/dirtbg.png")
			end
			if c == "a"
				Prop.new(self, @blockx, @blocky, "props/dirtbg.png")
			end
			if c == "x"
				$osc = Creature.new(self, @blockx, @blocky, "creatures/osc.png")
			end
			@charnum += 1
		end
	end
	def addstuff(levelname)
		@level = File.open(levelname)
		$charlist = []
		repeat(File.size(levelname)) { $charlist = $charlist + [@level.getc.chr] }
		@charnum = 0
		for c in $charlist
			@blockx = @charnum * 50 + 800
			@blocky = -1
			until @blockx < 800
				@blockx -= 800
				@blocky += 1
			end
			@blockx += 25
			@blocky = @blocky * 50
			@blocky += 25
			if c == "1"
				Key.new(self, @blockx, @blocky)
			end
			if c == "2"
				Door.new(self, @blockx, @blocky)
			end
			if c == "3"
				Climbable.new(self, @blockx, @blocky, "props/ladder.png")
			end
			if c == "4"
				Block.new(self, @blockx, @blocky, "blocks/stone.png")
			end
			if c == "5"
				Block.new(self, @blockx, @blocky, "blocks/vinestone.png")
			end
			if c == "6"
				Prop.new(self, @blockx, @blocky, "props/stonebg.png")
			end
			if c == "7"
				Prop.new(self, @blockx, @blocky, "props/grass.png")
			end
			if c == "8"
				Prop.new(self, @blockx, @blocky, "props/tree.png")
			end
			if c == "9"
				Prop.new(self, @blockx, @blocky, "props/grasstree.png")
			end
			if c == "a"
				Prop.new(self, @blockx, @blocky, "props/dirtbg.png")
			end
			if c == "a"
				Prop.new(self, @blockx, @blocky, "props/dirtbg.png")
			end
			if c == "x"
				$osc = Creature.new(self, @blockx, @blocky, "creatures/osc.png")
			end
			@charnum += 1
		end
	end
	def update
		self.caption = "osc"
		$mx = mouse_x
		$my = mouse_y
		if button_down? Gosu::Button::KbW
			$osc.jump
		end
		if button_down? Gosu::Button::KbA
			$osc.left
		end
		if button_down? Gosu::Button::KbD
			$osc.right
		end
		for i in $everything
			if i.exists == 1
				i.update
			end
		end
	end
	def draw
		@bg.draw(0, 0, 0)
		for i in $everything
			if i.exists == 1
				i.draw
			end
		end
	end
	def button_down(id)
		if id == Gosu::Button::KbEscape
			close
		end
		if id == Gosu::Button::KbG
			generatelevel
		end
	end
end

$window = Game.new
$window.show