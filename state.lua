local state = {
	current = 'menu',
	prev = nil,
	mapfile = nil,
	levelfile = nil,
	loadparams = {},
	load = function(this)
		for i, state in pairs(this) do
			if type(state) == 'table' and state.load then state:load() end
		end
	end,
	feedback = function(label, dest, pos)
		local gui = (dest and state[dest].gui) or state[state.current].gui
		feedback = gui:feedback(label, pos, nil, (pos and false) or true)
	end,
	menu = {
		load = function(this)
			this.gui = Gspot()
			-- maps
			local button = this.gui:button('Load Map', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 160, w = 256, h = 16})
			button.click = function(this)
				state.current = 'loadmap'
			end
			-- load
			this.loadbutton = this.gui:button('Load Player', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 128, w = 256, h = 16})
			this.loadbutton.click = function(this)
				state.current = 'loadplayer'
			end
			-- prefs
			button = this.gui:button('Prefs', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 96, w = 256, h = 16})
			button.click = function(this)
				state.prev = state.current
				state.current = 'prefs'
			end
			-- quit
			button = this.gui:button('Quit', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 64, w = 256, h = 16})
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
			this.gui = Gspot()
			-- quit
			local button = this.gui:button('Back', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 64, w = 256, h = 16})
			button.click = function(this)
				state.current = state.prev
			end
			
			this.gui:text('Player Controls', {x = 256, y = 64, w = 256, h = 16})
			local y = 32
			for i, c in ipairs(ctrl) do
				local label = this.gui:text(c.label, {x = 336, y = 64 + y, w = 256, h = 16})
				local input = this.gui:input('', {x = -80, y = 0, w = 64, h = 16}, label)
				input.value = c.key
				input.ctrl = i
				input.keypress = function(this, key, code)
					this.value = key
					this:done()
				end
				input.done = function(this)
					ctrl[this.ctrl].key = this.value
					this.Gspot:unfocus()
				end

				y = y + 16
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
	loadplayer = {
		load = function(this)
			this.backdrop = love.graphics.newImage('gui/loadplayer.png')
			this.gui = Gspot()
			-- menu
			button = this.gui:button('Menu', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 64, w = 256, h = 16})
			button.click = function(this)
				state.current = 'menu'
			end
			-- input
			this.loadinput = this.gui:input('', {x = 256, y = 256, w = 256, h = 16})
			if state.world.saveinput then this.loadinput.value = state.world.saveinput.value end
			this.loadinput.done = function(this)
				print('looking for player in : '..this.value..'.sav')
				if love.filesystem.exists(this.value..'.sav') then
					print('found player file : '..this.value..'.sav')
					state.mapfile = nil
					local linenum = 0
					local success
					for line in love.filesystem.lines(this.value..'.sav') do
						linenum = linenum + 1
						print('line '..linenum..' : '..line)
						if linenum == 1 then
							success, player = pcall(function(proto) return classes.player(proto) end, TS:unpack(line))
						elseif linenum == 2 then
							if love.filesystem.exists(line) then
								state.mapfile = line
								print('loaded map : '..line)
							else print('invalid map, or no map saved') end
						elseif linenum == 3 then
							if pcall(function() ctrl = TS:unpack(line) end) then
								print('loaded player controls')
							else print('failed to load player controls .. reverting to default') end
						end
					end
					if success then
						for i, slot in ipairs(player.slot) do
							if slot then
								if classes[slot.item] or classes:load(nil, {def = slot.item}) then
									player.slot[i] = classes[slot.item](slot)
									print('loaded inventory slot ' .. i)
								else print('failed to load inventory item object def') end
							end
						end
						if state.mapfile then
							state.map:load()
							state.current = 'map'
						else
							state.current = 'loadmap'
						end
						if state.world.saveinput then state.world.saveinput.value = this.value end
						state.feedback('Loaded '..state.loadplayer.loadinput.value)
					else
						print('failed to load player .. reverting to default')
						state.feedback('Failed to Load '..state.loadplayer.loadinput.value)
					end
				else
					print('player file not found : '..this.value..'.sav')
					state.feedback('No Such Player saved', nil, {x = state.loadplayer.loadinput.pos.x, y = state.loadplayer.loadinput.pos.y + 32})
				end
			end
			
			-- load
			this.loadbutton = this.gui:button('Load', {x = 272, y = 0, w = 128, h = 16}, this.loadinput)
			this.loadbutton.click = function(this)
				state.loadplayer.loadinput:done()
			end
			this.gui:setfocus(this.loadinput)
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
			this.gui = Gspot()
			-- load
			this.loadbutton = this.gui:button('Continue', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 128, w = 256, h = 16})
			this.loadbutton.click = function(this)
				if state.loadmap.selectmap.value then
					if love.filesystem.isDirectory('/map/'..state.loadmap.selectmap.value) then
						state.mapfile = '/map/'..state.loadmap.selectmap.value
						state.map:load()
						state.current = 'map'
					else
						state.mapfile = nil
						state.levelfile = '/map/'..state.loadmap.selectmap.value:sub(1, -5)
						player = classes.player()
						world:load(state.levelfile)
					end
				end
			end
			-- prefs
			button = this.gui:button('Prefs', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 96, w = 256, h = 16})
			button.click = function(this)
				state.prev = state.current
				state.current = 'prefs'
			end
			-- menu
			button = this.gui:button('Menu', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 64, w = 256, h = 16})
			button.click = function(this)
				state.current = 'menu'
			end
			-- select map
			this.selectmap = this.gui:scrollgroup('Select Map', {x = 256, y = 64, w = love.graphics.getWidth() - 512, h = 256})
			
			files = love.filesystem.enumerate('/map')
			local y = 0
			for i, file in ipairs(files) do
				if file:find('.lvl') or (love.filesystem.isDirectory('/map/'..file) and love.filesystem.exists('/map/'..file..'/map.lvl')) then
					if y == 0 then
						this.selectmap.value = file
					end
					y = y + 16
					option = this.gui:option(file, {x = 0, y = y, w = this.selectmap.pos.w, h = 16}, this.selectmap, file)
					option.dblclick = function(this)
						state.loadmap.loadbutton:click()
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
	map = {
		load = function(this)
			if state.mapfile and love.filesystem.exists(state.mapfile..'/map.png') then this.backdrop = love.graphics.newImage(state.mapfile..'/map.png')
			else this.backdrop = love.graphics.newImage('gui/map.png') end
			this.gui = Gspot()
			-- prefs
			button = this.gui:button('Prefs', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 96, w = 256, h = 16})
			button.click = function(this)
				state.prev = state.current
				state.current = 'prefs'
			end
			-- menu
			button = this.gui:button('Menu', {x = love.graphics.getWidth() - 320, y = love.graphics.getHeight() - 64, w = 256, h = 16})
			button.click = function(this) state.current = 'menu' end
			
			if state.mapfile then
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
								button = this.gui:image(level, {x = obj.x, y = obj.y, w = 64, h = 64}, nil, obj.img)
								button.click = function(this)
									state.levelfile = state.mapfile..'/'..this.label
									world:load(state.levelfile)
								end
							end
						end
					end
				else
					print('no map.lvl defined for map : '..state.mapfile)
					state.current = 'loadmap'
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
				this.gui = Gspot()
				
				-- menu
				this.menugroup = this.gui:hidden(nil, {x = love.graphics.getWidth() - 144, y = 0, w = 0, h = 0})
				
				-- quit
				button = this.gui:button('Quit', {x = 0, y = 16, w = 128, h = 16}, this.menugroup)
				button.click = function(this)
					world:unload()
					player = classes.player()
					state.current = 'menu'
				end
				-- save input
				this.saveinput = this.gui:input('', {x = -272, y = 48, w = 256, h = 16}, this.menugroup)
				if state.loadplayer.loadinput then this.saveinput.value = state.loadplayer.loadinput.value end
				this.saveinput.done = function(this)
					local p = {hp = player.hp, slot = {}}
					for i, slot in ipairs(player.slot) do
						p.slot[i] = (slot and {item = slot.item, q = slot.q}) or false
					end
					local str = TS:pack(p)
					str = str..'\n'
					if state.mapfile then str = str..state.mapfile end
					str = str..'\n'..TS:pack(ctrl)
					if pcall(function() love.filesystem.write(this.value..'.sav', str) end) then
						if state.loadplayer.loadinput then state.world.saveinput.value = state.loadplayer.loadinput.value end
						print('wrote player file : '..this.value..'.sav')
						state.feedback('Saved '..this.value, nil, {x = love.graphics.getWidth() - 416, y = 48})
					else
						print('failed to write player file : '..this.value..'.sav')
						state.feedback('Unable to save '..this.value, nil, {x = love.graphics.getWidth() - 416, y = 48})
					end
					this.Gspot:unfocus()
					this.display = false
				end
				-- save button
				button = this.gui:button('Save', {x = 0, y = 48, w = 128, h = 16}, this.menugroup)
				button.click = function(this)
					if state.world.saveinput.display then state.world.saveinput:done()
					else
						state.world.saveinput.display = true
						this.Gspot:setfocus(state.world.saveinput)
					end
				end
				-- prefs
				button = this.gui:button('Prefs', {x = 0, y = 80, w = 128, h = 16}, this.menugroup)
				button.click = function(this)
					state.prev = state.current
					state.current = 'prefs'
				end
				
				-- hide the menu
				this.menugroup:hide()

				--inventory
				this.invgroup = this.gui:group('Inventory', {x = 16, y = 16, w = 256, h = 48})
				this.invgroup.drag = true
				this.invgroup.load = function(this)
					this.Gspot:add(this.Gspot:rem(this))
					for i, item in ipairs(player.slot) do
						if item then this:item(item, i) end
					end
				end
				this.invgroup.item = function(this, item, slot)
					local item = this.Gspot:image(item.q, {x = (slot - 1) * 32, y = 16}, this, img[item.img])
					item.display = this.display
					item.drag = true
					item.slot = slot
					item.dblclick = function(this) player:item(nil, this.slot) end
					item.click = function(this)
						this:setlevel()
						this.parent:remchild(this)
					end
					item.drop = function(this, bucket)
						local invgroup = state.world.invgroup
						if bucket and (bucket == invgroup or bucket.slot) then
							i = 0
							while i < 8 do
								i = i + 1
								if love.mouse.getX() < invgroup.pos.x + (i * 32) then
									if i ~= this.slot then
										table.insert(player.slot, i, table.remove(player.slot, this.slot))
										table.insert(player.slot, this.slot, table.remove(player.slot, (i < this.slot and i + 1) or i - 1))
									end
									break
								end
							end
						else player:drop(this.slot) end
						this.Gspot:rem(this)
						invgroup:load()
					end
				end
			end
		end,
		update = function(this, dt)
			this.dt = dt
			if not this.gui then this:load() end
			if not this.gui.focus then
				for i, c in pairs(ctrl) do
					if love.keyboard.isDown(c.key) and c.repeatable then
						if player[c.cmd] then player[c.cmd](player, dt, c.key) end
					end
				end
			end
			world:update(dt)
			this.gui:update(dt)
		end,
		draw = function(this)
			world:draw(this.dt)
			this.gui:draw()
		end,
		mousepress = function(this, x, y, button)
			if not this.gui.mousein then
				local c = world.cam:worldCoords(vector(x, y))
				local orig = {x = player.p.x + (player.p.w / 2), y = player.p.y + (player.p.h / 2)}
				local rel = vector(c.x - orig.x, c.y - orig.y)
				player:fire(orig, rel:normalized())
			end
		end,
		keypress = function(this, key, code)
			if not state.world.gui.focus then
				for i, c in pairs(ctrl) do
					if key == c.key and not c.repeatable then
						if player[c.cmd] then player[c.cmd](player, key, c.slot) break
						elseif this[c.cmd] then this[c.cmd](this, key, c.slot) break end
					end
				end
			end
		end,
		inv = function(this, key)
			if this.invgroup.display then this.invgroup:hide()
			else this.invgroup:show() end
		end,
		menu = function(this, key)
			if this.menugroup.display then this.menugroup:hide()
			else
				this.menugroup:show()
				this.saveinput:hide()
			end
		end,
	},
}
return state