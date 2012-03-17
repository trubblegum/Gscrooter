local w = {
	Gclass = nil, -- classes
	loadparams = {def = nil, obj = nil},
	gravity = 512,
	ceiling = -1024,
	objects = {},
	effects = {},
	cam = camera(vector(0, 0), 1, 0),
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
	getdef = function()
		local inc
		local filename = nil
		if world.loadparams.inc and world.loadparams.inc[world.loadparams.def] then
			return true
		else
			world.loadparams.filename = nil
		end
		if state.mapfile then
			if love.filesystem.exists(state.mapfile..'/defs.lua') then
				print('looking for def in : '..state.mapfile..'/defs.lua')
				world.loadparams.filename = state.mapfile..'/defs.lua'
			elseif love.filesystem.exists(state.mapfile..'/'..world.loadparams.def..'.lua') then
				print('looking for def in : '..state.mapfile..'/'..world.loadparams.def..'.lua')
				world.loadparams.filename = state.mapfile..'/'..world.loadparams.def..'.lua'
			end
		else
			if love.filesystem.exists('/map/defs.lua') then
				print('looking for def in : /map/defs.lua')
				world.loadparams.filename = 'map/defs.lua'
			elseif love.filesystem.exists('/map/'..world.loadparams.def..'.lua') then
				print('looking for def in : /map/'..world.loadparams.def..'.lua')
				world.loadparams.filename = '/map/'..world.loadparams.def..'.lua'
			end
		end
		if world.loadparams.filename then
			print('found : '..world.loadparams.filename)
			if pcall(function() world.loadparams.inc = require(world.loadparams.filename) end) then
				
				return true
			else
				print('failed to create object def : '..world.loadparams.def)
				return false
			end
		else
			print('failed to find object def file : '..world.loadparams.def)
			return false
		end
		return false
	end,
	load = function(this, levelfile)
		this:unload()
		if love.filesystem.exists(levelfile) then
			local linenum = 0
			for line in love.filesystem.lines(levelfile) do
				linenum = linenum + 1
				local i = line:find(' ', 1)
				if i then
					this.loadparams.def = line:sub(1, i - 1)
					this.loadparams.proto = line:sub(i + 1)
					if this.loadparams.def then
						if pcall(function() world.loadparams.proto = TS:unpack(world.loadparams.proto) end) then
							if classes[this.loadparams.def] then
								print('creating object from cached def : '..this.loadparams.def)
								table.insert(this.objects, classes[this.loadparams.def](this.loadparams.proto))
								--if pcall(function() table.insert(world.objects, classes[world.loadparams.def](classes, world.loadparams.proto)) end) then
								--else print('failed to create object : '..this.loadparams.def) end
							elseif this.getdef() then
								if this.loadparams.inc and this.loadparams.inc[this.loadparams.def] then
									for k, v in pairs(this.loadparams.inc) do
										this.loadparams.objk = k
										this.loadparams.objv = v
										if pcall(function() classes[world.loadparams.objk] = world.loadparams.objv end) then
											--if pcall(function() setmetatable(classes[world.loadparams.objk], {__index = classes[classes[world.loadparams.objk].parent], __call = classes[world.loadparams.objk].load}) end) then
											--else print('failed to set object dependency : '..this.loadparams.objk..' - '..classes[world.loadparams.objk].parent) end
										else print('failed to insert object def : '..this.loadparams.objk) end
									end
									classes:init()
									print('creating object from new def : '..this.loadparams.def)
									table.insert(world.objects, classes[world.loadparams.def](world.loadparams.proto))
									--if pcall(function() table.insert(world.objects, classes[world.loadparams.def](classes, world.loadparams.proto)) end) then
									--else print('failed to create object : '..this.loadparams.def) end
								else print('failed to load object : '..this.loadparams.def) end
							else print('failed to find object def : '..this.loadparams.def) end
						else print('failed to create object prototype : '..this.loadparams.def..' ('..levelfile..' line '..linenum..')') end
					end
				end
			end
			player.p.x = 128
			player.p.y = -256
			
			table.insert(this.objects, player)
			love.audio.play(snd.load)
			state.current = 'world'
		else
			print('failed to find level file : '..levelfile)
			this:unload()
			state.current = 'menu'
		end
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
				if love.keyboard.isDown(c.key) then c.cmd(player, dt, c.key) end
			end
		end
		for i, obj in ipairs(this.effects) do obj:update(dt) end
		for i, obj in ipairs(this.objects) do obj:update(dt) end
	end,
	draw = function(this, dt)
		if this.objects[1] then
			local ground = this.objects[1]
			--this.cam.pos = vector(math.min(math.max((player.p.x + (player.p.w / 2)) - (player.v.x * dt), ground.p.x + (love.graphics.getWidth() / 2)), (ground.p.x + ground.p.w) - (love.graphics.getWidth() / 2)), (player.p.y + player.p.h) - (player.v.y * dt))
			this.cam.pos = vector(math.min(math.max(player.p.x + (player.p.w / 2), ground.p.x + (love.graphics.getWidth() / 2)), (ground.p.x + ground.p.w) - (love.graphics.getWidth() / 2)), player.p.y + player.p.h)
			this.cam:attach()
			for i, obj in ipairs(this.objects) do obj:draw() end
			for i, obj in ipairs(this.effects) do obj:draw() end
			this.cam:detach()
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