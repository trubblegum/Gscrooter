local state = {
	current = 'menu',
	prev = '',
	mapfile = '',
	levelfile = '',
	menu = {
		load = function(this)
			this.gui = gui:new()
			-- load
			local button = this.gui:element(this.gui:button('Load Map', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 128, w = 256, h = 16}))
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
			this.backdrop = love.graphics.newImage('gui/prefs.png')
			this.gui = gui:new()
			-- quit
			button = this.gui:element(this.gui:button('Back', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 64, w = 256, h = 16}))
			button.click = function(this)
				state.current = state.prev
			end
			
			this.gui:text('A : Left', {x = 256, y = 256, w = 256, h = 16})
			this.gui:text('D : Right', {x = 256, y = 272, w = 256, h = 16})
			this.gui:text('W : Jump', {x = 256, y = 288, w = 256, h = 16})
			this.gui:text('S : Use', {x = 256, y = 304, w = 256, h = 16})
			this.gui:text('No custom controls yet', {x = 256, y = 336, w = 256, h = 16})
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
			this.backdrop = love.graphics.newImage('gui/load.png')
			this.gui = gui:new(this)
			-- load
			this.loadload = this.gui:element(this.gui:button('Load Map', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 128, w = 256, h = 16}))
			this.loadload.click = function(this)
				if state.load.maps.value then
					if love.filesystem.isDirectory('/map/'..state.load.maps.value) then
						state.mapfile = '/map/'..state.load.maps.value
						state.current = 'map'
					else
						state.mapfile = nil
						state.levelfile = '/map/'..state.load.maps.value
						state.current = 'world'
					end
				end
			end
			-- prefs
			button = this.gui:element(this.gui:button('Prefs', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 96, w = 256, h = 16}))
			button.click = function(this)
				state.prev = state.current
				state.current = 'prefs'
			end
			-- menu
			button = this.gui:element(this.gui:button('Menu', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 64, w = 256, h = 16}))
			button.click = function(this)
				state.current = 'menu'
			end
			-- maps
			this.maps = this.gui:element(this.gui:scrollgroup('Select Map', {x = 256, y = 64, w = love.graphics.getWidth() - 512, h = 256}))
			
			files = love.filesystem.enumerate('/map')
			local y = 0
			for i, file in ipairs(files) do
				if y == 0 then
					this.maps.value = file
				end
				y = y + 16
				option = this.gui:element(this.gui:option(file, {x = 0, y = y, w = this.maps.pos.w, h = 16}, file, this.maps.id))
			end
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
	map = {
		load = function(this)
			if love.filesystem.exists(state.mapfile..'/map.png') then
				this.backdrop = love.graphics.newImage(state.mapfile..'/map.png')
			else
				this.backdrop = love.graphics.newImage('gui/map.png')
			end
			this.gui = gui:new(this)
			-- load
			local button = this.gui:element(this.gui:button('Load', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 128, w = 256, h = 16}))
			button.click = function(this)
				if state.load.levels.value then
					state.level = state.load.levels.value
					state.current = 'world'
				end
			end
			-- prefs
			button = this.gui:element(this.gui:button('Prefs', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 96, w = 256, h = 16}))
			button.click = function(this)
				state.prev = state.current
				state.current = 'prefs'
			end
			-- menu
			button = this.gui:element(this.gui:button('Menu', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 64, w = 256, h = 16}))
			button.click = function(this)
				state.current = 'menu'
			end
			-- levels
			if love.filesystem.exists(state.mapfile..'/map.lvl') then
				for line in love.filesystem.lines(state.mapfile..'/map.lvl') do
					local i = line:find(' ', 1)
					if i then
						local level = line:sub(1, i - 1)
						local obj = line:sub(i + 1)
						--print('level = "'..level..'" obj = "'..obj..'"')
						if love.filesystem.exists(state.mapfile..'/'..level..'.lvl') and obj then
							obj = loadstring('return '..obj)
							obj = obj()
							obj.img = ''
							if love.filesystem.exists(state.mapfile..'/'..level..'.png') then
								obj.img = state.mapfile..'/'..level..'.png'
							else
								obj.img = 'gui/mapportal.png'
							end
							button = this.gui:element(this.gui:image(level, {x = obj.x, y = obj.y, w = 64, h = 64}, obj.img))
							button.click = function(this)
								state.levelfile = state.mapfile..'/'..this.label..'.lvl'
								print(state.levelfile)
								state.current = 'world'
							end
						end
					end
				end
			end
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
				-- menu
				button = this.gui:element(this.gui:button('Menu', {x = love.graphics.getWidth() - 144, y = 16, w = 128, h = 16}))
				button.click = function(this)
					world:unload()
					state.mapfile = ''
					state.current = 'menu'
				end
				
				-- prefs
				button = this.gui:element(this.gui:button('Prefs', {x = love.graphics.getWidth() - 144, y = 48, w = 128, h = 16}))
				button.click = function(this)
					state.prev = state.current
					state.current = 'prefs'
				end
			end
			world:load(state.levelfile)
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