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
			class = class or 'object'
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
			else
				obj.p.w = obj.p.w or 0
				obj.p.h = obj.p.h or 0
			end
			
			if classes[class] then
				return setmetatable(obj, {__index = classes[class]})
			else print('failed to set dependency for new object : '..class) end
		end,
		update = function(this, dt)
			-- object does nothing on its own
			-- this is only here to catch errant calls
		end,
		draw = function(this)
			if img[this.img] then
				local x = 0
				while x < this.p.w do
					if this.v and this.v.x > 0 then
						love.graphics.draw(img[this.img], this.p.x + this.p.w + x, this.p.y, 0, -1, 1)
					else
						love.graphics.draw(img[this.img], this.p.x + x, this.p.y)
					end
					x = x + img[this.img]:getWidth()
				end
			else love.graphics.quad('fill', this.p.x, this.p.y, this.p.x + this.p.w, this.p.y, this.p.x + this.p.w, this.p.y + this.p.h, this.p.x, this.p.y + this.p.h) end
		end,
		filtercache = {},
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
					c = assert(loadstring('return function(obj) return '..condition..' end'))()
					if c then this.filtercache[condition] = c end
				end
			else
				c = function() return true end
			end
			for i, obj in ipairs(world.objects) do
				if obj ~= this and (c and c(obj)) and this:intersect(obj) then return obj end
			end
			return false
		end,
	}
}

return def