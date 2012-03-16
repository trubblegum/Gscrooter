TS = require('Tserial')
img = {}
snd = {}
state = require('state')
gui = require('Gspot')
world = require('Gscrooter') -- also brings us the marvels of player and ctrl

focus = true

love.load = function()
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
