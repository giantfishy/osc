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
	def initialize(window, x, y, id, image, category)
		@id = id
		@image = Gosu::Image.new(window, image, true)
		@x = x
		@y = y
		@exists = 1
		@category = category
		if @category == 1
			$items += [self]
		else
			$interactives += [self]
		end
		$everything += [self]
	end
	def x; @x; end
	def y; @y; end
	def id; @id; end
	def image; @image; end
	def category; @category; end
	def exists; @exists; end
	def draw
		if @category == 1
			@image.draw_rot(@x, @y, 1, 0)
		else
			@image.draw_rot(@x, @y, 2, 0)
		end
	end
	def update
	end
	def delete
		if @category == 1
			$items -= [self]
		else
			$interactives -= [self]
		end
		$everything -= [self]
		@exists = 0
	end
end

class Icon
	def initialize(window, x, y, id, image, category)
		@id = id
		@image = image
		@category = category
		@icon = Gosu::Image.new(window, image, true)
		@x = x
		@y = y
		$sidebar += [self]
		$everything += [self]
	end
	def x; @x; end
	def y; @y; end
	def id; @id; end
	def image; @image; end
	def category; @category; end
	def draw
		@icon.draw_rot(@x, @y, 1, 0)
	end
	def update
	end
	def delete
		$sidebar -= [self]
	end
end

class Game < Gosu::Window
	def initialize
		super(1000, 600, false)
		self.caption = "Level Editor"
		$sidebar = $everything = $items = $interactives = []
		$selectedid = "1"
		$selectedimage = "blocks/brick.png"
		$selectedcategory = 1
		@bg = Gosu::Image.new(self, "background.png", true)
		@sidebar = Gosu::Image.new(self, "editor/sidebar.png", true)
		@grid = Gosu::Image.new(self, "editor/grid.png", true)
		@gridgold = Gosu::Image.new(self, "editor/gridorange.png", true)
		$music = Gosu::Sample.new(self, "music/editor.mp3")
		fillsidebar
		#$music.play(1, 1, true)
	end
	def fillsidebar
		Icon.new(self, 825, 25, "1", "blocks/brick.png", 1)
		Icon.new(self, 875, 25, "2", "blocks/wood.png", 1)
		Icon.new(self, 925, 25, "3", "blocks/dirt.png", 1)
		Icon.new(self, 975, 25, "4", "blocks/stone.png", 1)
		Icon.new(self, 825, 75, "5", "blocks/vinestone.png", 1)
		Icon.new(self, 875, 75, "6", "props/stonebg.png", 1)
		Icon.new(self, 925, 75, "7", "props/grass.png", 1)
		Icon.new(self, 975, 75, "8", "props/mushroom.png", 1)
		Icon.new(self, 825, 125, "9", "props/grasstree.png", 1)
		Icon.new(self, 875, 125, "a", "props/dirtbg.png", 1)
		Icon.new(self, 925, 125, "b", "props/woodbg.png", 1)
		Icon.new(self, 975, 125, "c", "props/brickbg.png", 1)
		Icon.new(self, 825, 175, "1", "interactives/key.png", 2)
		Icon.new(self, 875, 175, "2", "interactives/door.png", 2)
		Icon.new(self, 925, 175, "3", "props/ladder.png", 2)
		Icon.new(self, 975, 175, "4", "blocks/water.png", 2)
		Icon.new(self, 825, 225, "5", "creatures/zombie.png", 2)
		Icon.new(self, 875, 225, "6", "treasures/gem.png", 2)
		Icon.new(self, 925, 225, "7", "interactives/spikes.png", 2)
	end
	def update
		self.caption = "Level Editor"
		$mx = mouse_x
		$my = mouse_y
		$cursor = Gosu::Image.new(self, "hud/cursor.png", true)
		if button_down? Gosu::Button::MsLeft
			if $mx < 800
				if $selectedcategory == 1
					for i in $items
						if i.x == ((($mx + 25) / 50).round * 50) - 25 and i.y == ((($my + 25) / 50).round * 50) - 25
							i.delete
						end
					end
				else
					for i in $interactives
						if i.x == ((($mx + 25) / 50).round * 50) - 25 and i.y == ((($my + 25) / 50).round * 50) - 25
							i.delete
						end
					end
				end
				Item.new(self, ((($mx + 25) / 50).round * 50) - 25, ((($my + 25) / 50).round * 50) - 25, $selectedid, $selectedimage, $selectedcategory)
			else
				for i in $sidebar
					if i.x == ((($mx + 25) / 50).round * 50) - 25 and i.y == ((($my + 25) / 50).round * 50) - 25
						$selectedid = i.id
						$selectedimage = i.image
						$selectedcategory = i.category
					end
				end
			end
		end
		if button_down? Gosu::Button::MsRight
			for i in $everything
				if i.x == ((($mx + 25) / 50).round * 50) - 25 and i.y == ((($my + 25) / 50).round * 50) - 25
					i.delete
				end
			end
		end
		if button_down? Gosu::Button::KbS and button_down? Gosu::Button::Kb1
			levelsave("userlevel1.txt", "userlevel1stuff.txt")
		end
		if button_down? Gosu::Button::KbS and button_down? Gosu::Button::Kb2
			levelsave("userlevel2.txt", "userlevel2stuff.txt")
		end
		if button_down? Gosu::Button::KbS and button_down? Gosu::Button::Kb3
			levelsave("userlevel3.txt", "userlevel3stuff.txt")
		end
		if button_down? Gosu::Button::KbS and button_down? Gosu::Button::Kb4
			levelsave("userlevel4.txt", "userlevel4stuff.txt")
		end
		if button_down? Gosu::Button::KbS and button_down? Gosu::Button::Kb5
			levelsave("userlevel5.txt", "userlevel5stuff.txt")
		end
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
	def levelsave(level, levelstuff)
		$file = File.new(level, "w")
		@blockx = 25
		@blocky = 25
		repeat(192) {
			@id = 0
			for i in $items
				if i.x == (((@blockx + 25) / 50).round * 50) - 25 and i.y == (((@blocky + 25) / 50).round * 50) - 25 and i.exists == 1
					@id = i.id
				end
			end
			$file.putc("#{@id}")
			@blockx += 50
			if @blockx > 800
				@blockx = 25
				@blocky += 50
			end
		}
		$file = File.new(levelstuff, "w")
		@blockx = 25
		@blocky = 25
		repeat(192) {
			@id = 0
			for i in $interactives
				if i.x == (((@blockx + 25) / 50).round * 50) - 25 and i.y == (((@blocky + 25) / 50).round * 50) - 25 and i.exists == 1
					@id = i.id
				end
			end
			$file.putc("#{@id}")
			@blockx += 50
			if @blockx > 800
				@blockx = 25
				@blocky += 50
			end
		}
	end
end

$window = Game.new
$window.show