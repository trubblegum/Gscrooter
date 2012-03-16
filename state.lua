local state = {
	current = 'menu',
	prev = '',
	mapfile = '',
	levelfile = '',
	menu = {
		load = function(this)
			this.gui = gui:new()
			-- maps
			local button = this.gui:element(this.gui:button('Load Map', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 160, w = 256, h = 16}))
			button.click = function(this)
				state.current = 'loadmap'
			end
			-- load
			this.loadbutton = this.gui:element(this.gui:button('Load Player', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 128, w = 256, h = 16}))
			this.loadbutton.click = function(this)
				state.current = 'loadplayer'
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
			
			this.gui:text(ctrl.left.key..' : Left', {x = 256, y = 256, w = 256, h = 16})
			this.gui:text(ctrl.right.key..' : Right', {x = 256, y = 272, w = 256, h = 16})
			this.gui:text(ctrl.jump.key..' : Jump', {x = 256, y = 288, w = 256, h = 16})
			this.gui:text(ctrl.use.key..' : Use', {x = 256, y = 304, w = 256, h = 16})
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
	loadplayer = {
		load = function(this)
			this.backdrop = love.graphics.newImage('gui/loadplayer.png')
			this.gui = gui:new(this)
			-- menu
			button = this.gui:element(this.gui:button('Menu', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 64, w = 256, h = 16}))
			button.click = function(this)
				state.current = 'menu'
			end
			-- input
			this.loadinput = this.gui:element(this.gui:input('', {x = 256, y = 256, w = 256, h = 16}))
			this.loadinput.done = function(this)
				if love.filesystem.exists(this.value..'.sav') then
					local l = 1
					for line in love.filesystem.lines(this.value..'.sav') do
						if l == 1 then
							obj = TS:unpack(line)
							if obj then
								player = world.c.player(obj)
							else
								break
							end
						elseif l == 2 then
							if love.filesystem.exists(line) then
								state.mapfile = line
								state.current = 'map'
							end
						end
						l = l + 1
					end
					if l > 1 then state.current = 'loadmap' end
				else
					feedback = this.Gspot:element(this.Gspot:text('No Such Player', {x = 0, y = 32, w = 256, h = 16}, state.loadplayer.loadinput.id))
					feedback.alpha = 255
					feedback.update = function(this, dt)
						this.alpha = this.alpha - (255 * dt)
						if this.alpha < 0 then this.Gspot:rem(this.id) end
						local color = this.Gspot.color.fg
						this.color = {color[1], color[2], color[3], this.alpha}
					end
				end
			end
			-- load
			this.loadbutton = this.gui:element(this.gui:button('Load', {x = 272, y = 0, w = 128, h = 16}, this.loadinput.id))
			this.loadbutton.click = function(this)
				state.loadplayer.loadinput:done()
			end
			this.gui:setfocus(this.loadinput.id)
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
	loadmap = {
		load = function(this)
			this.backdrop = love.graphics.newImage('gui/loadmap.png')
			this.gui = gui:new(this)
			-- load
			this.loadbutton = this.gui:element(this.gui:button('Continue', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 128, w = 256, h = 16}))
			this.loadbutton.click = function(this)
				if state.loadmap.selectmap.value then
					if love.filesystem.isDirectory('/map/'..state.loadmap.selectmap.value) then
						state.mapfile = '/map/'..state.loadmap.selectmap.value
						state.current = 'map'
					else
						state.mapfile = nil
						state.levelfile = '/map/'..state.loadmap.selectmap.value
						player = world.c.player()
						world:load(state.levelfile)
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
			-- select map
			this.selectmap = this.gui:element(this.gui:scrollgroup('Select Map', {x = 256, y = 64, w = love.graphics.getWidth() - 512, h = 256}))
			
			files = love.filesystem.enumerate('/map')
			local y = 0
			for i, file in ipairs(files) do
				if y == 0 then
					this.selectmap.value = file
				end
				y = y + 16
				option = this.gui:element(this.gui:option(file, {x = 0, y = y, w = this.selectmap.pos.w, h = 16}, file, this.selectmap.id))
				option.dblclick = function(this)
					state.loadmap.loadbutton:click()
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
	map = {
		load = function(this)
			if love.filesystem.exists(state.mapfile..'/map.png') then
				this.backdrop = love.graphics.newImage(state.mapfile..'/map.png')
			else
				this.backdrop = love.graphics.newImage('gui/map.png')
			end
			this.gui = gui:new(this)
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
								world:load(state.levelfile)
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
				-- quit
				button = this.gui:element(this.gui:button('Quit', {x = love.graphics.getWidth() - 144, y = 16, w = 128, h = 16}))
				button.click = function(this)
					world:unload()
					player = world.c.player()
					state.current = 'menu'
				end
				-- save input
				this.saveinput = this.gui:element(this.gui:input('', {x = love.graphics.getWidth() - 416, y = 48, w = 256, h = 16}))
				this.saveinput.done = function(this)
					local p = {} -- insert relevant attributes
					local str = TS:pack(p)
					if state.mapfile then str = str..'\n'..state.mapfile end
					love.filesystem.write(this.value..'.sav', str)
					this.Gspot:unfocus()
					this.display = false
				end
				this.saveinput.display = false
				-- save button
				button = this.gui:element(this.gui:button('Save', {x = love.graphics.getWidth() - 144, y = 48, w = 128, h = 16}))
				button.click = function(this)
					if state.world.saveinput.display then
						state.world.saveinput:done()
					else
						state.world.saveinput.display = true
						this.Gspot:setfocus(state.world.saveinput.id)
					end
				end
				-- prefs
				button = this.gui:element(this.gui:button('Prefs', {x = love.graphics.getWidth() - 144, y = 80, w = 128, h = 16}))
				button.click = function(this)
					state.prev = state.current
					state.current = 'prefs'
				end
			end
			world:load(state.levelfile)
		end,
		update = function(this, dt)
			this.dt = dt
			if not this.gui then this:load() end
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