require 'rubygems'
require 'gosu'
require 'matrix'

class Vector
  def theta
    Math.atan2(self[1], self[0]) * (180 / 3.14159) + 90
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
#		@image.draw_rot((((@x + 5) / 5).round * 5), (((@y + 5) / 5).round * 5), 100, 0)
		@image.draw_rot(@x.round, @y.round, 100, 0)
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
		@gravity += 0.3
		if @x < 0
			if $currentlevel.left == 0
				respawn
			else
				$currentlevel = $currentlevel.left
				$currentlevel.load
			end
		end
		if @x > 800
			if $currentlevel.right == 0
				respawn
			else
				$currentlevel = $currentlevel.right
				$currentlevel.load
			end
		end
		if @y > 600
			if $currentlevel.down == 0
				respawn
			else
				$currentlevel = $currentlevel.down
				$currentlevel.load
			end
		end
		if @y < 0
			if $currentlevel.up == 0
				respawn
			else
				$currentlevel = $currentlevel.up
				$currentlevel.load
			end
		end
	end
	def jump
		if @onblock == true
			@gravity = -5
		end
	end
	def left; @x -= 4; end
	def right; @x += 4; end
	def fireball
		@tomouse = Vector[($mx - @x), ($my - @y)]
		Projectile.new($window, @x, @y, Gosu::offset_x(@tomouse.theta, 8), Gosu::offset_y(@tomouse.theta, 8), "projectiles/fireball.png")
	end
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

class Projectile < GameObject
	def initialize(window, x, y, xspeed, yspeed, image)
		@image = Gosu::Image.new(window, image, true)
		@x = x
		@y = y
		@xspeed = xspeed
		@yspeed = yspeed
		$everything += [self]
		@exists = 1
		$fireball = 1
	end
	def x; @x; end
	def y; @y; end
	def exists; @exists; end
	def draw
		@image.draw_rot(@x.round, @y.round, 0, 0)
	end
	def update
		@x += @xspeed
		@y += @yspeed
		for b in $blocks
			if (b.x - @x).abs < 30 and (b.y - @y).abs < 30
				self.delete
			end
		end
		if @x > 800 or @x < 0 or @y > 600 or @y < 0
			self.delete
		end
	end
	def delete
		super
		$fireball = 0
		@particleangle = 0
		repeat(8) { Particle.new($window, @x, @y, "effects/splosionsmall.png", @particleangle, 5, 5); @particleangle += 45 }
	end
end

class Key < GameObject
	def initialize (window, x, y, parentlevel)
		@image = Gosu::Image.new(window, "interactives/key.png", true)
		@x = x
		@y = y
		$everything = $everything + [self]
		@exists = 1
		parentlevel.add(self)
	end
	def itemtype; "key"; end
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

class Treasure < GameObject
	def initialize (window, x, y, score, image, parentlevel)
		@image = Gosu::Image.new(window, image, true)
		@x = x
		@y = y
		$everything = $everything + [self]
		@exists = 1
		parentlevel.add(self)
	end
	def itemtype; "treasure"; end
	def x; @x; end
	def y; @y; end
	def exists; @exists; end
	def draw
		@image.draw_rot(@x, @y, 0, 0)
	end
	def update
		if ($osc.x - @x).abs < 25 and ($osc.y - @y).abs < 25
			@particleangle = 0
			repeat(5) { Particle.new($window, @x, @y, "effects/greenstar.png", @particleangle, 6, 10); @particleangle += 72 }
			$score += 100
			self.delete
		end
	end
	def delete
		super
	end
end

class Door < GameObject
	def initialize (window, x, y, parentlevel)
		@image = Gosu::Image.new(window, "interactives/door.png", true)
		@x = x
		@y = y
		$everything = $everything + [self]
		$blocks += [self]
		@exists = 1
		parentlevel.add(self)
	end
	def itemtype; "door"; end
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
	def initialize (window, x, y, image, parentlevel)
		@image = Gosu::Image.new(window, image, true)
		@x = x
		@y = y
		$everything = $everything + [self]
		$climbables += [self]
		@exists = 1
		parentlevel.add(self)
	end
	def itemtype; "climbable"; end
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
		@items = []
	end
	def x; @x; end
	def y; @y; end
	def add(gameobject)
		@items += [gameobject]
	end
	def link
		for l in $levels
			if l.x == (@x - 1) and l.y == @y
				@left = l
			end
			if l.x == (@x + 1) and l.y == @y
				@right = l
			end
			if l.y == (@y - 1) and l.x == @x
				@down = l
			end
			if l.y == (@y + 1) and l.x == @x
				@up = l
			end
		end
	end
	def left; @left; end
	def right; @right; end
	def up; @up; end
	def down; @down; end
	def load
		$fireball = 0
		if $osc == nil
			@lastx = 0
			@lasty = 0
		else
			@lastx = $osc.x
			@lasty = $osc.y
		end
		if @lastx > 800
			@lastx = 0
		end
		if @lastx < 0
			@lastx = 800
		end
		if @lasty < 0
			@lasty = 590
		end
		if @lasty > 600
			@lasty = 0
		end
		$everything = $blocks = $climbables = []
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
		if $placedosc == true
			$osc = Creature.new($window, @lastx, @lasty, "creatures/osc.png")
		end
		loadextras
	end
	def loadextras
		if @items == []
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
					Key.new($window, @blockx, @blocky, self)
				end
				if c == "2"
					Door.new($window, @blockx, @blocky, self)
				end
				if c == "3"
					Climbable.new($window, @blockx, @blocky, "props/ladder.png", self)
				end
				if c == "4"
					Climbable.new($window, @blockx, @blocky, "blocks/water.png", self)
				end
				if c == "5"
					Sign.new($window, @blockx, @blocky)
				end
				if c == "6"
					Treasure.new($window, @blockx, @blocky, 100, "treasures/gem.png", self)
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
				if c == "x" and $placedosc == false
					$osc = Creature.new($window, @blockx, @blocky, "creatures/osc.png")
					$placedosc = true
				end
				@charnum += 1
			end
		else
			for i in @items
				$everything += [i]
				if i.itemtype == "climbable"
					$climbables += [i]
				end
				if i.itemtype == "door" and i.exists == 1
					$blocks += [i]
				end
			end
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
		$score = 0
		@bg = Gosu::Image.new(self, "background.png", true)
		$music = Gosu::Sample.new(self, "music/start.mp3")
		$placedosc = false
		$fireball = 0
		$blocktypes = ["blocks/brick.png", "blocks/wood.png", "blocks/dirt.png", "blocks/stone.png", "blocks/vinestone.png"]
#		$music.play(1, 1, true)
	end
	def start
		$levels = [Level.new("level1.txt", "level1stuff.txt", 0, 0), Level.new("level2.txt", "level2stuff.txt", -1, 0), Level.new("level3.txt", "level3stuff.txt", -2, 0), Level.new("level4.txt", "level4stuff.txt", -2, 1)]
		for l in $levels
			l.link
		end
		$currentlevel = $levels[0]
		$currentlevel.load
	end
	def update
		self.caption = "osc | score = #{$score}"
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
		if button_down? Gosu::Button::MsLeft and $fireball == 0
			$osc.fireball
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
#		if id == Gosu::Button::KbG
#			$keys += 1
#		end
	end
end

$window = Game.new
$window.start
$window.show