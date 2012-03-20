

love.load = function()
	vector = require('vector')
	camera = require('camera')
	TS = require('Tserial')
	Gspot = require('Gspot')

	img = {}
	snd = {}
	ctrl = {
		{key = 'a', cmd = 'left', label = 'Move Left', repeatable = true},
		{key = 'd', cmd = 'right', label = 'Move right', repeatable = true},
		{key = 'w', cmd = 'jump', label = 'Jump'},
		{key = 's', cmd = 'use', label = 'Enter / Use'},
		{key = 'i', cmd = 'inv', label = 'Open / Close Inventory'},
		{key = 'f1', cmd = 'item', label = 'Slot 1', slot = 1},
		{key = 'f2', cmd = 'item', label = 'Slot 2', slot = 2},
		{key = 'f3', cmd = 'item', label = 'Slot 3', slot = 3},
		{key = 'f4', cmd = 'item', label = 'Slot 4', slot = 4},
		{key = 'f5', cmd = 'item', label = 'Slot 5', slot = 5},
		{key = 'f6', cmd = 'item', label = 'Slot 6', slot = 6},
		{key = 'f7', cmd = 'item', label = 'Slot 7', slot = 7},
		{key = 'f8', cmd = 'item', label = 'Slot 8', slot = 8},
		{key = 'escape', cmd = 'menu', label = 'Open / Close Menu'},
	}

	state = require('state')
	world = require('world')
	classes = require('class')

	
	classes:load('defsdefault.lua')
	player = classes.player()
	state:load()
	
	snd.click = love.audio.newSource('snd/click.ogg', 'static')
	snd.load = love.audio.newSource('snd/load.ogg')
	
	current = state[state.current]
	focus = true
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
love.keypreleased = function(key, code)
	if current.gui and current.keyrelease then
		current:keyrelease(key, code)
	end
end
