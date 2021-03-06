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
		@cooldown = 30
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
			if (i.y - @y) < 55 and (i.y - @y) > 0 and (i.x - @x).abs < 40
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
		@cooldown -= 4
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
		edgecheck
		if $osc == self
			for e in $enemies
				if (e.x - @x).abs < 25 and (e.y - @y).abs < 25 and e.exists == 1
					respawn
				end
			end
		end
	end
	def edgecheck
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
	def left
		if $paused == false
			@x -= 4
		end
	end
	def right
		if $paused == false
			@x += 4
		end
	end
	def fireball
		if @cooldown < 0
			@tomouse = Vector[($mx - @x), ($my - @y)]
			Projectile.new($window, @x, @y, Gosu::offset_x(@tomouse.theta, 8), Gosu::offset_y(@tomouse.theta, 8), "projectiles/fireball.png")
			@cooldown = 50
		end
	end
	def delete; super; end
end

class Enemy < Creature
	def initialize (window, x, y, image, health, speed, parentlevel)
		@image = Gosu::Image.new(window, image, true)
		@x = @spawnx = x
		@y = @spawny = y
		$everything = $everything + [self]
		$enemies = $enemies + [self]
		@exists = 1
		@gravity = 0
		@health = health
		@cooldown = 50
		@speed = speed
		@bright = false
		parentlevel.add(self)
	end
	def itemtype; "enemy"; end
	def goto(x, y); super; end
	def respawn
		goto(@spawnx, @spawny)
		@gravity = 0
	end
	def x; @x; end
	def y; @y; end
	def exists; @exists; end
	def draw
		if @bright == true
			super
		end
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
		@distance = 100
		for b in $blocks
			if b.y - @y == 50 and (b.x - @x).abs < @distance
				@distance = (b.x - @x).abs
			end
		end
		if @distance > 30
			jump
		end
		if @nexttoblock == true
			jump
		end
		if @health < 1
			self.delete
		end
		@toosc = Vector[($osc.x - @x), ($osc.y - @y)]
		if @toosc.r.round < 130
			@bright = true
		else
			@bright = false
		end
	end
	def edgecheck
		if @x > 800
			@x = 800
		end
		if @y > 600
			self.delete
		end
		if @y < 0
			@y = 0
		end
	end
	def hurt(damage)
		@health -= damage
	end
	def jump
		if @onblock == true
			@gravity = -5
		end
	end
	def left
		if $paused == false
			@x -= @speed
		end
	end
	def right
		if $paused == false
			@x += @speed
		end
	end
	def delete
		super
		@particleangle = 0
		repeat(10) { Particle.new($window, @x, @y, "effects/blood.png", @particleangle, rand(6), 8); @particleangle += 36}
	end
end

class Block < GameObject
	def initialize (window, x, y, image)
		@image = Gosu::Image.new(window, image, true)
		@silimage = Gosu::Image.new(window, "silblock.png", true)
		@bright = false
		@x = x
		@y = y
		$everything = $everything + [self]
		$blocks = $blocks + [self]
		@exists = 1
	end
	def itemtype; "block"; end
	def x; @x; end
	def y; @y; end
	def exists; @exists; end
	def draw
		if @bright == true
			@image.draw_rot(@x, @y, 1, 0)
		else
			@silimage.draw_rot(@x, @y, 1, 0)
		end
	end
	def update
		@toosc = Vector[($osc.x - @x), ($osc.y - @y)]
		if @toosc.r.round < 130
			@bright = true
		else
			@bright = false
		end
	end
	def delete
		super
	end
end

class Prop < GameObject
	def initialize (window, x, y, image)
		@image = Gosu::Image.new(window, image, true)
		@x = x
		@y = y
		@bright = false
		$everything = $everything + [self]
		@exists = 1
	end
	def x; @x; end
	def y; @y; end
	def exists; @exists; end
	def draw
		if @bright == true
			@image.draw_rot(@x, @y, 0, 10)
		end
	end
	def update
		@toosc = Vector[($osc.x - @x), ($osc.y - @y)]
		if @toosc.r.round < 130
			@bright = true
		else
			@bright = false
		end
	end
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
		Gosu::Image.new($window, "effects/orangelight.png", true).draw_rot(@x.round, @y.round, 0, 0)
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
		for e in $enemies
			if (e.x - @x).abs < 20 and (e.y - @y).abs < 20
				SplashDamage.new(30, @x, @y, 15)
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
		SplashDamage.new(50, @x, @y, 15)
		repeat(8) { Particle.new($window, @x, @y, "effects/splosionsmall.png", @particleangle, 5, 5); @particleangle += 45 }
	end
end

class TurretFireball < Projectile
	def initialize(window, x, y, xspeed, yspeed, image)
		super
	end
	def x; @x; end
	def y; @y; end
	def exists; super; end
	def draw
		Particle.new($window, @x, @y, "effects/splosionsmall.png", rand(360), 1, 5)
		@image.draw_rot(@x.round, @y.round, 0, 0)
	end
	def update
		@x += @xspeed
		@y += @yspeed
		for b in $blocks
			if (b.x - @x).abs < 30 and (b.y - @y).abs < 30 and not b.itemtype == "turret"
				self.delete
			end
		end
		for e in $enemies
			if (e.x - @x).abs < 20 and (e.y - @y).abs < 20 and not b.itemtype == "turret"
				SplashDamage.new(30, @x, @y, 15)
			end
		end
		@toosc = Vector[($osc.x - @x), ($osc.y - @y)]
		if @toosc.r < 30
			$osc.respawn
		end
		if @x > 800 or @x < 0 or @y > 600 or @y < 0
			self.delete
		end
	end
	def delete; super; end
end

class SplashDamage
	def initialize(radius, x, y, damage)
		@x = x
		@y = y
		@r = radius
		@damage = damage
		for e in $enemies
			@vector = Vector[(e.x - @x), (e.y - @y)]
			if @vector.r < @r
				e.hurt(@damage)
			end
		end
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
			self.delete
		end
	end
	def delete
		super
		$blocks -= [self]
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

class Turret < GameObject
	def initialize (window, x, y, parentlevel)
		@image = Gosu::Image.new(window, "interactives/turret.png", true)
		@x = x
		@y = y
		$everything = $everything + [self]
		$blocks += [self]
		$enemies += [self]
		@exists = 1
		@health = 50
		@cooldown = 50
		parentlevel.add(self)
	end
	def itemtype; "turret"; end
	def x; @x; end
	def y; @y; end
	def exists; @exists; end
	def draw
		@image.draw_rot(@x, @y, 0, 0)
	end
	def hurt(damage)
		@health -= damage
	end
	def update
		@toosc = Vector[($osc.x - @x), ($osc.y - @y)]
		if @toosc.r < 1000 and @cooldown < 0
			TurretFireball.new($window, @x, @y, Gosu::offset_x(@toosc.theta, 7), Gosu::offset_y(@toosc.theta, 7), "projectiles/turretfireball.png")
			@cooldown = 50
		end
		if @health < 1
			self.delete
		end
		@cooldown -= 1
	end
	def delete
		super
		$blocks -= [self]
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

class GenericHUD < GameObject
	def initialize (window, x, y, image)
		@image = Gosu::Image.new(window, image, true)
		@x = x
		@y = y
		$everything += [self]
		@exists = 1
		@visible = true
	end
	def goto(x, y); super; end
	def x; @x; end
	def y; @y; end
	def exists; @exists; end
	def visible; @visible; end
	def hide
		@visible = false
	end
	def show
		@visible = true
	end
	def draw
		if @visible == true
			@image.draw_rot(@x.round, @y.round, 100, 0)
		end
	end
	def update
		super
	end
	def delete; super; end
end

class Cursor < GameObject
	def initialize (window, x, y)
		@image = Gosu::Image.new(window, "hud/cursor.png", true)
		@x = x
		@y = y
		$everything += [self]
		@exists = 1
	end
	def goto(x, y); super; end
	def x; @x; end
	def y; @y; end
	def exists; @exists; end
	def draw
		@image.draw_rot(@x.round, @y.round, 1337, 0)
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
			if c == "b"
				Prop.new($window, @blockx, @blocky, "props/woodbg.png")
			end
			if c == "c"
				Prop.new($window, @blockx, @blocky, "props/brickbg.png")
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
					Enemy.new($window, @blockx, @blocky, "creatures/nosc.png", 10, 3, self)
				end
				if c == "6"
					Treasure.new($window, @blockx, @blocky, 100, "treasures/gem.png", self)
				end
				if c == "7"
					Turret.new($window, @blockx, @blocky, self)
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
				if i.itemtype == "enemy" and i.exists == 1
					$enemies += [i]
				end
			end
		end
		Cursor.new($window, 0, 0)
		KeyHUD.new($window, 750, 25, "interactives/key.png")
		$pausescreen = GenericHUD.new($window, 400, 300, "hud/pausescreen.png")
		$pausescreen.hide
	end
end

class Game < Gosu::Window
	def initialize
		super(800, 600, false)
		self.caption = "osc"
		$everything = $blocks = $enemies = $climbables = []
		$keys = 0
		$score = 0
		$paused = false
		$test = Prop.new(self, 0, 0, "effects/light.png")
		@bg = Gosu::Image.new(self, "silbg.png", true)
		$music = Gosu::Sample.new(self, "music/start.mp3")
		$placedosc = false
		$lightradius = 0
		$fireball = 0
		$blocktypes = ["blocks/brick.png", "blocks/wood.png", "blocks/dirt.png", "blocks/stone.png", "blocks/vinestone.png"]
#		$music.play(1, 1, true)
	end
	def start
		$levels = [Level.new("level1.txt", "level1stuff.txt", 0, 0), Level.new("level2.txt", "level2stuff.txt", -1, 0), Level.new("level3.txt", "level3stuff.txt", -2, 0), Level.new("level4.txt", "level4stuff.txt", -2, 1), Level.new("level5.txt", "level5stuff.txt", -3, 1), Level.new("level6.txt", "level6stuff.txt", -3, 0)]
		for l in $levels
			l.link
		end
		$currentlevel = $levels[0]
		$currentlevel.load
	end
	def update
		self.caption = "sil | score: #{$score}"
		$mx = mouse_x
		$my = mouse_y
		@osctomouse = Vector[($osc.x - $mx), ($osc.y - $my)]
		$lightradius = 200 - (@osctomouse.r.round / 2)
		if $lightradius < 0
			$lightradius = 0
		end
		if button_down? Gosu::Button::KbW
			$osc.jump
		end
		if button_down? Gosu::Button::KbA
			$osc.left
		end
		if button_down? Gosu::Button::KbD
			$osc.right
		end
		if button_down? Gosu::Button::MsLeft
			$osc.fireball
		end
		for i in $everything
			if i.exists == 1 and $paused == false
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
		Gosu::Image.new(self, "effects/halo.png", true).draw_rot($osc.x, $osc.y, 0, 0)
	end
	def button_down(id)
		if id == Gosu::Button::KbG
			$keys += 1
		end
		if id == Gosu::Button::MsRight
			$osc.goto($mx, $my)
		end
		if id == Gosu::Button::KbEscape
			if $paused == false
				$paused = true
				$pausescreen.show
			else
				$paused = false
				$pausescreen.hide
			end
		end
	end
end

$window = Game.new
$window.start
$window.show