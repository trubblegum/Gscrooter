local w = {
	gravity = 512,
	ceiling = -1024,
	objects = {},
	effects = {},
	cam = camera(vector(0, 0), 1, 0),
	load = function(this, levelfile)
		this:unload()
		if state.world.invgroup then state.world.invgroup:load() end
		if love.filesystem.exists(levelfile..'.lvl') then
			local linenum = 0
			print('loading level from file : '..levelfile..'.lvl')
			for line in love.filesystem.lines(levelfile..'.lvl') do
				linenum = linenum + 1
				print('line '..linenum..' : '..line)
				local i = line:find(' ', 1)
				if i then
					classes.loadparams.def = line:sub(1, i - 1)
					classes.loadparams.proto = line:sub(i + 1)
					if classes.loadparams.def then
						if pcall(function() classes.loadparams.proto = TS:unpack(classes.loadparams.proto) end) then
							if classes[classes.loadparams.def] or classes:load() then
								if pcall(function() table.insert(world.objects, classes[classes.loadparams.def](classes.loadparams.proto)) end) then print('added object : '..classes.loadparams.def)
								else print('failed to add object : '..classes.loadparams.def..' (missing def.load() or bad prototype)') end
							else print('failed to load def : '..classes.loadparams.def) end
						else print('failed to create object prototype : '..classes.loadparams.def) end
					end
					classes.loadparams = {}
				end
			end
			if this.objects[1] then
				this:loadbackdrop(levelfile)
				player.p.x = 128
				player.p.y = -256
				table.insert(this.objects, player)
				love.audio.play(snd.load)
				state.current = 'world'
				return
			else
				print('failed to load level')
				this:unload()
				state.current = 'menu'
			end
		else
			print('failed to find level file : '..levelfile..'.lvl')
			this:unload()
			state.current = 'menu'
		end
	end,
	loadbackdrop = function(this, levelfile)
		if love.filesystem.exists(levelfile..'.png') then this.backdrop = love.graphics.newImage(levelfile..'.png')
		elseif state.mapfile and love.filesystem.exists(state.mapfile..'/backdrop.png') then this.backdrop = love.graphics.newImage(mapfile..'/backdrop.png')
		else this.backdrop = love.graphics.newImage('/map/backdrop.png') end
		this.backdrop:setWrap("repeat", "repeat")
		this.quad = love.graphics.newQuad(0, 0, love.graphics.getWidth(), love.graphics.getHeight(), this.backdrop:getWidth(), this.backdrop:getHeight())
	end,
	unload = function(this)
		this.objects = {}
		this.effects = {}
		if state.mapfile then
			state.current = 'map'
		else
			player = classes.player()
			state.current = 'loadmap'
		end
	end,
	update = function(this, dt)
		if not state.world.gui.focus then
			for i, c in pairs(ctrl) do
				if love.keyboard.isDown(c.key) and c.repeatable then
					if player[c.cmd] then player[c.cmd](player, dt, c.key) end
				end
			end
		end
		for i, obj in ipairs(this.effects) do obj:update(dt) end
		for i, obj in ipairs(this.objects) do obj:update(dt) end
	end,
	draw = function(this, dt)
		if this.objects[1] then
			local ground = this.objects[1]
			this.cam.pos = vector(math.min(math.max(player.p.x + (player.p.w / 2), ground.p.x + (love.graphics.getWidth() / 2)), (ground.p.x + ground.p.w) - (love.graphics.getWidth() / 2)), player.p.y + (player.p.h / 2))
			
			this.quad:setViewport(this.cam.pos.x / 4, this.cam.pos.y / 8, love.graphics.getWidth(), love.graphics.getHeight())
			love.graphics.drawq(this.backdrop, this.quad, 0, 0, 0, 1, 1)
			
			this.cam:attach()
			for i, obj in ipairs(this.objects) do obj:draw() end
			for i, obj in ipairs(this.effects) do obj:draw() end
			this.cam:detach()
		else
			
		end
	end,
	remeffect = function(this, rem)
		for i, obj in pairs(this.effects) do
			if obj == rem then table.remove(this.effects, i) break end
		end
	end,
	remobject = function(this, rem)
		for i, obj in pairs(this.objects) do
			if obj == rem then table.remove(this.objects, i) break end
		end
	end,
	mousepress = function(this, x, y, button)
		local c = this.cam:worldCoords(vector(x, y))
		local orig = {x = player.p.x + (player.p.w / 2), y = player.p.y + (player.p.h / 2)}
		local rel = vector(c.x - orig.x, c.y - orig.y)
		player:fire(orig, rel:normalized())
	end,
}

return w