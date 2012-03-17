vector = require('vector')
camera = require('camera')
TS = require('Tserial')
Gspot = require('Gspot')

img = {}
snd = {}
state = require('state')
world = require('world')
classes = require('class')

player = false
ctrl = false

focus = true

love.load = function()
	
	classes:init()
	player = classes.player()
	ctrl = {
		left = {key = 'a', cmd = player.left, label = 'Move Left'},
		right = {key = 'd', cmd = player.right, label = 'Move right'},
		jump = {key = 'w', cmd = player.jump, label = 'Jump'},
		use = {key = 's', cmd = player.use, label = 'Use'},
		slot1 = {key = 'f1', cmd = player.use, label = 'Slot 1'},
		slot2 = {key = 'f2', cmd = player.use, label = 'Slot 2'},
		slot3 = {key = 'f3', cmd = player.use, label = 'Slot 3'},
		slot4 = {key = 'f4', cmd = player.use, label = 'Slot 4'},
	}
	
	snd.click = love.audio.newSource('snd/click.ogg', 'static')
	snd.load = love.audio.newSource('snd/load.ogg')
	current = state[state.current]
end

love.update = function(dt)
	--if focus then
		current = state[state.current]
		current:update(dt)
	--end
end

love.draw = function()
	current:draw()
end

love.focus = function(f)
	focus = f
end

love.mousepressed = function(x, y, button)
	if current.gui then
		current.gui:mousepress(x, y, button)
		if current.gui.mousein then
			snd.click:stop()
			love.audio.play(snd.click)
		elseif current.mousepress then
			current:mousepress(x, y, button)
		end
	end
end
love.mousereleased = function(x, y, button)
	if current.gui then
		current.gui:mouserelease(x, y, button)
		if current.mouserelease then
			current:mouserelease(x, y, button)
		end
	end
end
love.keypressed = function(key, code)
	if current.gui then
		if current.gui.focus then
			current.gui:keypress(key, code)
		elseif current.keypress then
			current:keypress(key, code)
		end
	end
end
