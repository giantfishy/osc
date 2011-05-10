require 'rubygems'
require 'gosu'
require 'matrix'

class Menu
end

class Button
end

class Game < Gosu::Window
	def initialize
		super(800, 600, false)
		self.caption = "Welcome to osc!"
		$everything = []
		@bg = Gosu::Image.new(self, "background.png", true)
		$music = Gosu::Sample.new(self, "music/theme.mp3")
		#$music.play(1, 1, true)
	end
	
	def update
		self.caption = "Welcome to osc!"
		$mx = mouse_x
		$my = mouse_y
		$cursor = Gosu::Image.new(self, "hud/cursor.png", true)
	end
	def draw
		@bg.draw(0, 0, 0)
		for i in $everything
			i.draw
		end
		unless $cursor == nil
			$cursor.draw_rot($mx.round, $my.round, 1337, 0)
		end
	end
end

$window = Game.new
$window.show