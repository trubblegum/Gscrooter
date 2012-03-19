local def = {
	loadparams = {},
	load = function(this, filename)
		if this:getdef(filename) then
			for k, obj in pairs(this) do
				if type(obj) == 'table' and not getmetatable(obj) then
					if classes[obj.parent] then
						setmetatable(obj, {__index = classes[obj.parent], __call = obj.load})
						print('set dependency for object def : '..k..' - '..obj.parent)
					elseif obj.parent then
						setmetatable(obj, {__call = obj.load})
						print('failed to set dependency for object def : '..k..' - '..obj.parent)
					else
						setmetatable(obj, {__call = obj.load})
						print('warning : no dependency defined for object def : '..k)
					end
				end
			end
			return true
		else return false end
	end,
	getdef = function(this, filename)
		if filename then
			if love.filesystem.exists(filename) then
				print('loading defs from file : '..filename)
				this.loadparams.filename = filename
			else print('invalid def filename : '..filename) return false end
		else
			if state.mapfile then
				if this.loadparams.def and love.filesystem.exists(state.mapfile..'/'..this.loadparams.def..'.lua') then
					print('found def file : '..state.mapfile..'/'..this.loadparams.def..'.lua')
					this.loadparams.filename = state.mapfile..'/'..this.loadparams.def..'.lua'
				elseif love.filesystem.exists(state.mapfile..'/defs.lua') then
					print('found def file : '..state.mapfile..'/defs.lua')
					this.loadparams.filename = state.mapfile..'/defs.lua'
				end
			else
				if this.loadparams.def and love.filesystem.exists('/map/'..this.loadparams.def..'.lua') then
					print('found def file : /map/'..this.loadparams.def..'.lua')
					this.loadparams.filename = '/map/'..this.loadparams.def..'.lua'
				elseif love.filesystem.exists('/map/defs.lua') then
					print('found def file : /map/defs.lua')
					this.loadparams.filename = 'map/defs.lua'
				end
			end
		end
		if this.loadparams.filename then
			if pcall(function() this.loadparams.inc = require(this.loadparams.filename) end) then
				if this.loadparams.def and not this.loadparams.inc[this.loadparams.def] then print('warning : def file does not contain def : '..this.loadparams.def..' .. continuing') end
				for k, v in pairs(this.loadparams.inc) do
					this.loadparams.objk = k
					this.loadparams.objv = v
					if pcall(function() classes[classes.loadparams.objk] = classes.loadparams.objv end) then print('created object def : '..this.loadparams.objk)
					else print('failed to create def : '..this.loadparams.objk) end
				end
				return true
			else print('failed to load def file : '..this.loadparams.filename) end
		else print('failed to find def file') end
		return false
	end,

	-- OBJECT
	object = {
		load = function(this, proto, class)
			class = class or this
			local obj = {img = nil, p = {x = 0, y = 0}, s = 1}
			if type(proto) == 'table' then for k, v in pairs(proto) do obj[k] = v end end
			
			if type(obj.img) == 'string' then
				if not img[obj.img] then
					if love.filesystem.exists('img/'..obj.img) then
						img[obj.img] = love.graphics.newImage('img/'..obj.img)
					else
						obj.img = nil
					end
				end
				if obj.img and ((not obj.p.w) or obj.p.w < img[obj.img]:getWidth()) then
					obj.p.w = img[obj.img]:getWidth()
					obj.p.h = img[obj.img]:getHeight()
				end
			end
			obj.p.w = obj.p.w or 0
			obj.p.h = obj.p.h or 0
			
			return setmetatable(obj, {__index = class})
		end,
		update = function(this, dt)
			-- object does nothing on its own, update is only here to catch errant calls
		end,
		draw = function(this)
			if img[this.img] then
				local x = 0
				while x < this.p.w do
					if this.v and this.v.x ~= 0 then
						if this.v.x > 0 then
							this.s = -1
						else
							this.s = 1
						end
					end
					if this.s < 0 then
						love.graphics.draw(img[this.img], this.p.x + this.p.w + x, this.p.y, 0, -1, 1)
					else
						love.graphics.draw(img[this.img], this.p.x + x, this.p.y)
					end
					x = x + img[this.img]:getWidth()
				end
			else love.graphics.quad('fill', this.p.x, this.p.y, this.p.x + this.p.w, this.p.y, this.p.x + this.p.w, this.p.y + this.p.h, this.p.x, this.p.y + this.p.h) end
		end,
		filtercache = {
			['true'] = function() return true end,
		},
		intersect = function(this, obj)
			if this.p.x + this.p.w >= obj.p.x and this.p.x <= obj.p.x + obj.p.w then
				if this.p.y + this.p.h >= obj.p.y and this.p.y <= obj.p.y + obj.p.h then
					return true
				end
			end
			return false
		end,
		collide = function(this, condition)
			local c = nil
			if condition then
				if this.filtercache[condition] then
					c = this.filtercache[condition]
				else
					if type(condition) == 'function' then
						c = condition
						this.filtercache[condition] = condition
					else
						--c = loadstring('return function(obj) return '..condition..' end')() or function() return false end
						c = assert(loadstring('return function(obj) return '..condition..' end'), 'error : bad filter function')()
						this.filtercache[condition] = c
					end
				end
			else
				c = function() return false end
			end
			for i, obj in ipairs(world.objects) do
				if obj ~= this and c(obj) and this:intersect(obj) then return obj end
			end
			return false
		end,
	},
	
	player = {
		parent = 'entity',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.p = {x = 128, y = -256, w = 0, h = 0}
			proto.hp = proto.hp or 100
			proto.type = 'player'
			proto.img = 'player.png'
			proto.slot = {
				[1] = false,
				[2] = false,
				[3] = false,
				[4] = false,
				[5] = false,
				[6] = false,
				[7] = false,
				[8] = false,
			}
			
			return classes.entity(proto, class)
		end,
		update = function(this, dt)
			-- hp regen
			--if this.hp < this.ohp then
			--this.hp = math.min(this.hp + (dt * 4), this.ohp)
			--end
			classes.entity.update(this, dt)
		end,
		fire = function(this, orig, dir)
			table.insert(world.effects, classes.proj({p = orig, v = dir, orig = this}))
		end,
		use = function(this, key, slot)
			item = this:collide('obj.type == "item"')
			if item then this:pickup(item) else
				item = this:collide('obj.type == "portal" or obj.type == "chest"')
				if item then item:use(this) end
			end
		end,
		item = function(this, key, slot)
			if this.slot[slot] then
				this.slot[slot]:use(player)
				if this.slot[slot].q < 1 then
					this.slot[slot] = false
					state.world.invgroup:load()
				end
			end
		end,
		pickup = function(this, item)
			for i, slot in ipairs(this.slot) do
				if slot and slot.item == item.item then
					slot.q = slot.q + 1
					world:remobject(item)
					state.world.invgroup:load()
					return
				end
			end
			for i, slot in ipairs(this.slot) do
				if not slot then
					this.slot[i] = classes[item.item](item)
					world:remobject(item)
					state.world.invgroup:load()
					return
				end
			end
		end,
	},
}

return def