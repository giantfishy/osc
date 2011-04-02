require 'rubygems'
require 'gosu'
require 'matrix'

def repeat(num)
	while num > 0
		yield
		num -= 1
	end
end

class Item
	def initialize(window, x, y, id, image)
		@id = id
		@image = Gosu::Image.new(window, image, true)
		@x = x
		@y = y
		$everything = $everything + [self]
	end
	def x; @x; end
	def y; @y; end
	def draw
		@image.draw_rot(@x, @y, 1, 0)
	end
	def update
	end
	def delete
		$everything -= [self]
	end
end

class Game < Gosu::Window
	def initialize
		super(1000, 600, false)
		self.caption = "Level Editor"
		$everything = []
		$selectedid = 0
		$selectedimage = "blocks/brick.png"
		@bg = Gosu::Image.new(self, "background.png", true)
		@sidebar = Gosu::Image.new(self, "editor/sidebar.png", true)
		@grid = Gosu::Image.new(self, "editor/grid.png", true)
		@gridgold = Gosu::Image.new(self, "editor/gridorange.png", true)
		$music = Gosu::Sample.new(self, "music/editor.mp3")
		$music.play(1, 1, true)
	end
	def update
		self.caption = "Level Editor"
		$mx = mouse_x
		$my = mouse_y
		$cursor = Gosu::Image.new(self, "hud/cursor.png", true)
	end
	def draw
		@bg.draw(0, 0, 0)
		@sidebar.draw(800, 0, 0)
		@gridx = @gridy = @step = 0
		repeat(192) {
			@grid.draw(@gridx, @gridy, 0)
			@gridx += 50
			if @gridx > 750
				@gridy += 50
				@gridx = 0
			end
			@step += 1
		}
		@gridx = 800
		@gridy = @step = 0
		repeat(48) {
			@gridgold.draw(@gridx, @gridy, 0)
			@gridx += 50
			if @gridx > 950
				@gridy += 50
				@gridx = 800
			end
			@step += 1
		}
		for i in $everything
			i.draw
		end
		unless $cursor == nil
			$cursor.draw_rot($mx.round, $my.round, 1337, 0)
		end
	end
	def levelsave
		$file = File.open("userlevel.txt")
		for i in $everything
			
		end
	end
	def button_down(id)
		if id == Gosu::Button::MsLeft
			Item.new(self, (($mx / 50).round * 50), (($my / 50).round * 50), $selectedid, $selectedimage)
		end
	end
end

$window = Game.new
$window.show