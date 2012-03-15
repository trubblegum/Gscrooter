state = require('state')
gui = require('Gspot')
world = require('Gscrooter')

img = {}
snd = {}

love.load = function()
	snd.click = love.audio.newSource('snd/click.ogg', 'static')
	snd.load = love.audio.newSource('snd/load.ogg')
	--
end

love.update = function(dt)
	state[state.current]:update(dt)
end

love.draw = function()
	state[state.current]:draw()
end

focus = true

love.focus = function(f)
	focus = f
end

love.mousepressed = function(x, y, button)
	if state[state.current].gui.mousein then
		snd.click:stop()
		love.audio.play(snd.click)
		state[state.current].gui:mousepress(x, y, button)
	elseif state[state.current].mousepress then
		state[state.current]:mousepress(x, y, button)
	end
end
love.mousereleased = function(x, y, button)
	if state[state.current].mousein then
		state[state.current].gui:mouserelease(x, y, button)
	elseif state[state.current].mouserelease then
		state[state.current]:mouserelease(x, y, button)
	end
end
love.keypressed = function(key, code)
	if state[state.current].gui.focus then
		state[state.current].gui:keypress(key, code)
	elseif state[state.current].keypress then
		state[state.current]:keypress(key, code)
		-- note : world uses mostly love.keyboard.isDown()
	end
end

normal = function(v)
	local len = math.sqrt(v.x * v.x + v.y * v.y)
	v.x = v.x / len
	v.y = v.y / len
	return v
end