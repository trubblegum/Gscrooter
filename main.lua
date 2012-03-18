vector = require('vector')
camera = require('camera')
TS = require('Tserial')
Gspot = require('Gspot')

img = {}
snd = {}
state = require('state')
world = require('world')
classes = require('class')

current, player, ctrl = nil

focus = true

love.load = function()
	current = state[state.current]	
	
	classes:load('classdefault.lua')
	player = classes.player()
	ctrl = {
		{key = 'a', cmd = 'left', label = 'Move Left'},
		{key = 'd', cmd = 'right', label = 'Move right'},
		{key = 'w', cmd = 'jump', label = 'Jump'},
		{key = 's', cmd = 'use', label = 'Enter / Use'},
		{key = 'f1', cmd = 'use', label = 'Slot 1'},
		{key = 'f2', cmd = 'use', label = 'Slot 2'},
		{key = 'f3', cmd = 'use', label = 'Slot 3'},
		{key = 'f4', cmd = 'use', label = 'Slot 4'},
	}
	
	snd.click = love.audio.newSource('snd/click.ogg', 'static')
	snd.load = love.audio.newSource('snd/load.ogg')
	
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
