local state = {
	current = 'menu',
	prev = '',
	menu = {
		load = function(this)
			this.gui = gui:new()
			-- load
			local button = this.gui:element(this.gui:button('Load', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 128, w = 256, h = 16}))
			button.click = function(this)
				state.current = 'load'
			end
			-- prefs
			button = this.gui:element(this.gui:button('Prefs', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 96, w = 256, h = 16}))
			button.click = function(this)
				state.prev = state.current
				state.current = 'prefs'
			end
			-- quit
			button = this.gui:element(this.gui:button('Quit', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 64, w = 256, h = 16}))
			button.click = function(this)
				love.event.push('q')
			end
			
			this.backdrop = love.graphics.newImage('gui/menu.png')
		end,
		update = function(this, dt)
			if not this.gui then this:load() end
			this.gui:update(dt)
		end,
		draw = function(this)
			love.graphics.draw(this.backdrop, 0, 0)
			this.gui:draw()
		end,
	},
	prefs = {
		load = function(this)
			this.gui = gui:new()
			-- quit
			button = this.gui:element(this.gui:button('Back', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 64, w = 256, h = 16}))
			button.click = function(this)
				state.current = state.prev
			end
			
			this.backdrop = love.graphics.newImage('gui/prefs.png')
		end,
		update = function(this, dt)
			if not this.gui then this:load() end
			this.gui:update(dt)
		end,
		draw = function(this)
			love.graphics.draw(this.backdrop, 0, 0)
			this.gui:draw()
		end,
	},
	load = {
		load = function(this)
			this.gui = gui:new(this)
			-- load
			local button = this.gui:element(this.gui:button('Continue', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 128, w = 256, h = 16}))
			button.click = function(this)
				state.level = state.load.levels.value
				state.current = 'world'
			end
			-- prefs
			button = this.gui:element(this.gui:button('Prefs', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 96, w = 256, h = 16}))
			button.click = function(this)
				state.prev = state.current
				state.current = 'prefs'
			end
			-- quit
			button = this.gui:element(this.gui:button('Main', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 64, w = 256, h = 16}))
			button.click = function(this)
				state.current = 'menu'
			end
			-- levels
			this.levels = this.gui:element(this.gui:scrollgroup('Select Level', {x = 256, y = 64, w = love.graphics.getWidth() - 512, h = 256}))
			files = love.filesystem.enumerate('/level')
			for i, file in ipairs(files) do
				option = this.gui:element(this.gui:option(file, {x = 0, y = this.levels.maxh, w = this.levels.pos.w, h = 16}, file, this.levels.id))
			end
			
			this.backdrop = love.graphics.newImage('gui/load.png')
		end,
		update = function(this, dt)
			if not this.gui then this:load() end
			this.gui:update(dt)
		end,
		draw = function(this)
			love.graphics.draw(this.backdrop, 0, 0)
			this.gui:draw()
		end,
	},
	world = {
		dt = 0,
		load = function(this)
			if not this.gui then
				this.gui = gui:new()
			end
			world:load(state.level)
		end,
		update = function(this, dt)
			this.dt = dt
			if not world.objects[1] then this:load() end
			world:update(dt)
			this.gui:update(dt)
		end,
		draw = function(this)
			world:draw(this.dt)
			this.gui:draw()
		end,
		mousepress = function(this, x, y, button)
			world:mousepress(x, y, button)
		end,
	},
}
return state