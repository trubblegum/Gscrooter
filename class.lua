local def = {
	loadparams = {},
	load = function(this, filename, loadparams)
		if this:getdef(filename, loadparams) then
			for k, obj in pairs(this) do
				if type(obj) == 'table' and not getmetatable(obj) then
					if this[obj.parent] then
						setmetatable(obj, {__index = this[obj.parent], __call = obj.load})
						print('set dependency for object def : '..k..' - '..obj.parent)
					else
						setmetatable(obj, {__call = obj.load})
						if obj.parent then
							print('failed to set dependency for object def : '..k..' - '..obj.parent)
						else
							print('warning : invalid or no dependency defined for object def : '..k)
						end
					end
				end
			end
			return true
		else return false end
	end,
	getdef = function(this, filename, loadparams)
		if filename then
			if love.filesystem.exists(filename) then print('loading defs from file : '..filename)
			else print('def file not found : '..filename) return false end
		elseif loadparams then
			if state.mapfile then
				if love.filesystem.exists(state.mapfile..'/'..loadparams.def..'.lua') then filename = state.mapfile..'/'..loadparams.def..'.lua'
				elseif love.filesystem.exists(state.mapfile..'/defs.lua') then filename = state.mapfile..'/defs.lua' end
			else
				if love.filesystem.exists('/map/'..loadparams.def..'.lua') then filename = '/map/'..loadparams.def..'.lua'
				elseif love.filesystem.exists('/map/defs.lua') then filename = 'map/defs.lua' end
			end
		end
		if filename then
			print('found def file : '..filename)
			local success, inc = pcall(function(filename) return love.filesystem.load(filename)() end, filename)
			if success then
				if loadparams and not inc[loadparams.def] then print('warning : def file does not contain def : '..loadparams.def..' .. continuing') end
				for k, v in pairs(inc) do
					if pcall(function(this, k, v) this[k] = v end, this, k, v) then print('created def : '..k)
					else print('failed to create def : '..k) end
				end
				return true
			else print('failed to load def file : '..filename) end
		else print('failed to find def file') end
		return false
	end,
	
	position = {
		load = function(this, p, defaults)
			p = p or {}
			defaults = defaults or {}
			p.x = p.x or defaults.x or 256
			p.y = p.y or defaults.y or -256
			p.w = p.w or defaults.w or 32
			p.h = p.h or defaults.h or 32
			return setmetatable(p, {__index = this})
		end,
	},
	
	animation = {
		load = function(this, proto)
			local framerate = 0.5
			proto = proto or {}
			for i, v in pairs(proto) do
				if type(v) == 'table' then
					v.framerate = v.framerate or framerate
					v.y = v.y or 1
					proto[i] = v
				end
			end
			proto.idle = proto.idle or {framerate = framerate, y = 1}
			return setmetatable(proto, {__index = this})
		end,
		play = function(this, current)
			this.current = current
			this.dt = 0
			this.frame = 1
		end,
	},
	-- OBJECT
	object = {
		load = function(this, proto, class)
			class = class or this
			local obj = {}
			if type(proto) == 'table' then for k, v in pairs(proto) do obj[k] = v end end
			obj.p = classes.position(obj.p)
			obj.img = obj.img or nil
			obj.sprite = obj.sprite or {}
			obj.sprite.dt = obj.sprite.dt or 0
			obj.sprite.dir = obj.sprite.dir or 1
			obj.sprite.frame = obj.sprite.frame or 1
			obj.sprite.current = obj.sprite.current or 'idle'
			obj.sprite.anim = classes.animation(obj.sprite.anim)
			
			if obj.img then
				if not img[obj.img] then
					if love.filesystem.exists('img/'..obj.img) then img[obj.img] = love.graphics.newImage('img/'..obj.img)
					elseif state.mapfile and love.filesystem.exists(state.mapfile..'/img/'..obj.img) then img[obj.img] = love.graphics.newImage(state.mapfile..'/img/'..obj.img)
					elseif love.filesystem.exists('/map/'..obj.img) then img[obj.img] = love.graphics.newImage('/map/'..obj.img)
					else obj.img = nil end
				end
				if obj.img then
					img[obj.img]:setWrap("repeat", "repeat")
					obj.quad = love.graphics.newQuad(0, 0, obj.p.w, obj.p.h, img[obj.img]:getWidth(), img[obj.img]:getHeight())
				end
			end
			
			return setmetatable(obj, {__index = class})
		end,
		update = function(this, dt)
			this.sprite.dt = this.sprite.dt + dt
			anim = this.sprite.anim[this.sprite.current]
			if (type(anim.framerate) == 'number' and this.sprite.dt > anim.framerate) or (type(anim.framerate) == 'function' and anim.framerate(dt)) then
				this.sprite.dt = 0
				this.sprite.frame = this.sprite.frame + 1
				if this.sprite.frame * this.p.w > img[this.img]:getWidth() then this.sprite.frame = 1 end
				this.quad:setViewport((this.sprite.frame - 1) * this.p.w, (anim.y - 1) * this.p.h, this.p.w, this.p.h)
			end
		end,
		draw = function(this)
			if img[this.img] then
				if this.v and this.v.x ~= 0 then
					if this.v.x > 0 then this.sprite.dir = -1 else this.sprite.dir = 1 end
				end
				local x = 0
				--while x < this.p.w do
					if this.sprite.dir < 0 then love.graphics.drawq(img[this.img], this.quad, this.p.x + this.p.w + x, this.p.y, 0, this.sprite.dir, 1, 0, 0)
					else love.graphics.drawq(img[this.img], this.quad, this.p.x + x, this.p.y, 0, 1, 1, 0, 0) end
					x = x + img[this.img]:getWidth()
				--end
			else love.graphics.quad('fill', this.p.x, this.p.y, this.p.x + this.p.w, this.p.y, this.p.x + this.p.w, this.p.y + this.p.h, this.p.x, this.p.y + this.p.h) end
		end,
		filters = {
			['true'] = function() return true end,
			['false'] = function() return false end,
			platform = function(obj) return obj.type == 'platform' end,
			player = function(obj) return obj == player end,
			friendly = function(obj) return obj.type == 'friendly' end,
			playerorfriendly = function(obj) return obj.type == 'friendly' or obj == player end,
			enemy = function(obj) return obj.type == 'enemy' end,
			usable = function(obj) return obj.type == 'portal' or obj.type == 'chest' end,
			item = function(obj) return obj.type == 'item' end,
			notplatform = function(obj) return obj.type ~= 'platform' end,
			notportal = function(obj) return obj.type ~= 'portal' end,
			entity = function(obj) if obj.hp then return true else return false end end,
		},
		getfilter = function(this, condition)
			if condition then
				if this.filters[condition] then
					return this.filters[condition]
				else
					if type(condition) == 'function' then
						return condition
					elseif type(condition) == 'table' then
						return function(obj) return obj == condition end
					--elseif type(condition) == 'string' then
						--c = loadstring('return function(obj) return '..condition..' end')() or function() return false end
					--	this.filters[condition] = assert(loadstring('return function(obj) return '..condition..' end'), 'error : malformed collision filter condition')()
					--	return this.filters[condition]
					else
						print('invalid filter parameter : '..condition)
						return function() return false end
					end
				end
			else return function() return true end end
		end,
		intersect = function(this, obj)
			if this.p.x + this.p.w >= obj.p.x and this.p.x <= obj.p.x + obj.p.w then
				if this.p.y + this.p.h >= obj.p.y and this.p.y <= obj.p.y + obj.p.h then return true
				else return false end
			end
		end,
		collide = function(this, condition)
			local c = this:getfilter(condition)
			for i, obj in ipairs(world.objects) do
				if c(obj) and obj ~= this and this:intersect(obj) then return obj end
			end
			return false
		end,
	},
	
	player = {
		parent = 'entity',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.p = classes.position(proto.p, {x = 128, y = -256, w = 64, h = 64})
			proto.img = 'player.png'
			proto.bounce = 0
			proto.sprite = {
				anim = {
					idle = {
						framerate = function(dt) return math.random() * 2 < dt end
					}
				}
			}
			proto.ohp = 128
			proto.hp = proto.hp or proto.ohp
			proto.type = 'player'
			proto.slot = proto.slot or {
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
			table.insert(world.effects, classes.bullet({p = orig, v = dir, orig = this}))
		end,
		use = function(this, key, slot)
			local item = this:collide('item')
			if item then this:pickup(item)
			else
				item = this:collide('usable')
				if item then item:use(this, slot) end
			end
		end,
		item = function(this, key, slot)
			if this.slot[slot] then
				this.slot[slot]:use(this)
				if this.slot[slot].q < 1 then this.slot[slot] = false end
				state.world.invgroup:load()
			end
		end,
		pickup = function(this, item)
			local done = false
			for i, slot in ipairs(this.slot) do
				if slot and slot.item == item.item then
					slot.q = slot.q + item.q
					done = true
					break
				end
			end
			if not done then
				for i, slot in ipairs(this.slot) do
					if not slot then
						this.slot[i] = classes[item.item]({q = item.q})
						done = true
						break
					end
				end
			end
			if done then
				world:remobject(item)
				state.world.invgroup:load()
			end
		end,
		drop = function(this, slot)
			table.insert(world.objects, classes[this.slot[slot].item]({q = this.slot[slot].q, p = {x = this.p.x + (this.p.w / 2), y = this.p.y}, v = {x = 256 - (math.random() * 512), y = -256}}))
			this.slot[slot] = false
			state.world.invgroup:load()
		end,

	},
}

return def