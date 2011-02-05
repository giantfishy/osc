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
		@gravity += 0.5
		if @x < 0
			@canwarp = true
			for b in $blocks
				if b.x > 750 and (b.y - @y).abs < 40
					@canwarp = false
				end
			end
			if @canwarp == true
				@x = 800
			else
				@x = 0
			end
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
			@gravity = -6
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
			@particleangle = 0
			repeat(5) { Particle.new($window, @x, @y, "effects/star.png", @particleangle, 6, 10); @particleangle += 72 }
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
			@particleangle = 0
			repeat(8) { Particle.new($window, @x, @y, "effects/splosion.png", @particleangle, 8, 5); @particleangle += 45 }
			$keys -= 1
			$blocks -= [self]
			self.delete
		end
	end
	def delete
		super
	end
end

class Sign < GameObject
	def initialize (window, x, y)
		@image = Gosu::Image.new(window, "interactives/sign.png", true)
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
		if ($osc.x - @x).abs < 30 and ($osc.y - @y).abs < 30 and $window.button_down? Gosu::Button::KbSpace
			
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

class Level
	def initialize(map, extras, x, y)
		@map = map
		@extras = extras
		@x = x
		@y = y
		@left = @right = @up = @down = 0
	end
	def x; @x; end
	def y; @y; end
	def link
		for l in $levels
			if l.x == (@x - 1) and l.y == @y
				l = @left
			end
			if l.x == (@x + 1) and l.y == @y
				l = @right
			end
			if l.y == (@y - 1) and l.x == @x
				l = @down
			end
			if l.y == (@y + 1) and l.x == @x
				l = @up
			end
		end
	end
	def left; @left; end
	def right; @right; end
	def up; @up; end
	def down; @down; end
	def load
		$everything = $blocks = $enemies = $climbables = []
		@level = File.open(@map)
		$charlist = []
		repeat(File.size(@map)) { $charlist = $charlist + [@level.getc.chr] }
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
				Block.new($window, @blockx, @blocky, "blocks/brick.png")
			end
			if c == "2"
				Block.new($window, @blockx, @blocky, "blocks/wood.png")
			end
			if c == "3"
				Block.new($window, @blockx, @blocky, "blocks/dirt.png")
			end
			if c == "4"
				Block.new($window, @blockx, @blocky, "blocks/stone.png")
			end
			if c == "5"
				Block.new($window, @blockx, @blocky, "blocks/vinestone.png")
			end
			if c == "6"
				Prop.new($window, @blockx, @blocky, "props/stonebg.png")
			end
			if c == "7"
				Prop.new($window, @blockx, @blocky, "props/grass.png")
			end
			if c == "8"
				Prop.new($window, @blockx, @blocky, "props/tree.png")
			end
			if c == "9"
				Prop.new($window, @blockx, @blocky, "props/grasstree.png")
			end
			if c == "a"
				Prop.new($window, @blockx, @blocky, "props/dirtbg.png")
			end
			@charnum += 1
		end
		loadextras
	end
	def loadextras
		@level = File.open(@extras)
		$charlist = []
		repeat(File.size(@extras)) { $charlist = $charlist + [@level.getc.chr] }
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
				Key.new($window, @blockx, @blocky)
			end
			if c == "2"
				Door.new($window, @blockx, @blocky)
			end
			if c == "3"
				Climbable.new($window, @blockx, @blocky, "props/ladder.png")
			end
			if c == "4"
				Climbable.new($window, @blockx, @blocky, "blocks/water.png")
			end
			if c == "5"
				Sign.new($window, @blockx, @blocky)
			end
			if c == "6"
				Prop.new($window, @blockx, @blocky, "props/stonebg.png")
			end
			if c == "7"
				Prop.new($window, @blockx, @blocky, "props/grass.png")
			end
			if c == "8"
				Prop.new($window, @blockx, @blocky, "props/tree.png")
			end
			if c == "a"
				Prop.new($window, @blockx, @blocky, "props/dirtbg.png")
			end
			if c == "b"
				Prop.new($window, @blockx, @blocky, "props/dirtbg.png")
			end
			if c == "x"
				$osc = Creature.new($window, @blockx, @blocky, "creatures/osc.png")
			end
			@charnum += 1
		end
		Cursor.new($window, 0, 0)
		KeyHUD.new($window, 750, 25, "interactives/key.png")
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
		$music = Gosu::Sample.new(self, "music/start.mp3")
		$blocktypes = ["blocks/brick.png", "blocks/wood.png", "blocks/dirt.png", "blocks/stone.png", "blocks/vinestone.png"]
#		$music.play(1, 1, true)
	end
	def start
		$levels = [Level.new("level1.txt", "level1stuff.txt", 0, 0), Level.new("level2.txt", "level2stuff.txt", 0, 1), Level.new("level3.txt", "level3stuff.txt", 0, 2), Level.new("level4.txt", "level4stuff.txt", 0, 3)]
		$levels[0].load
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
			$keys += 1
		end
	end
end

puts("Creating window...")
$window = Game.new
$window.start
$window.show