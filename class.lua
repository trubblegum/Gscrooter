local c = {
	loadparams = {},
	load = function(this, filename)
		if this:getdef(filename) then
			for k, obj in pairs(this) do
				if type(obj) == 'table' then
					if classes[obj.parent] then
						print('set dependency for object def : '..k..' - '..obj.parent)
						setmetatable(obj, {__index = classes[obj.parent], __call = obj.load})
					elseif obj.parent then
						setmetatable(obj, {__call = obj.load})
						print('failed to set dependency for object def : '..k..' - '..obj.parent)
					else
						setmetatable(obj, {__call = obj.load})
						print('warning : no dependency defined for object def : '..k)
					end
				end
			end
		end
	end,
	getdef = function(this, filename)
		local inc
		if filename then
			if love.filesystem.exists(filename) then
				print('looking for def in : '..filename)
				this.loadparams.filename = filename
			else
				print('invalid def file path : '..filename)
			end
		else
			if this.loadparams.inc and this.loadparams.inc[this.loadparams.def] then
				print('found object def in cache : '..this.loadparams.def)
			elseif this.loadparams.def then
				print('looking for def file for : '..this.loadparams.def)
				if state.mapfile then
					if love.filesystem.exists(state.mapfile..'/'..this.loadparams.def..'.lua') then
						print('looking for def in : '..state.mapfile..'/'..this.loadparams.def..'.lua')
						this.loadparams.filename = state.mapfile..'/'..this.loadparams.def..'.lua'
					elseif love.filesystem.exists(state.mapfile..'/defs.lua') then
						print('looking for def in : '..state.mapfile..'/defs.lua')
						this.loadparams.filename = state.mapfile..'/defs.lua'
					end
				else
					if love.filesystem.exists('/map/'..this.loadparams.def..'.lua') then
						print('looking for def in : /map/'..this.loadparams.def..'.lua')
						this.loadparams.filename = '/map/'..this.loadparams.def..'.lua'
					elseif love.filesystem.exists('/map/defs.lua') then
						print('looking for def in : /map/defs.lua')
						this.loadparams.filename = 'map/defs.lua'
					end
				end
			else
				print('no object requested .. falling over')
				return false
			end
		end
		if this.loadparams.filename then
			print('found : '..this.loadparams.filename)
			if pcall(function() this.loadparams.inc = require(this.loadparams.filename) end) then
				if this.loadparams.inc then
					if this.loadparams.def then
						if this.loadparams.inc[this.loadparams.def] then
						else print('failed to load def for object : '..this.loadparams.def..' .. continuing') end
					end
					for k, v in pairs(this.loadparams.inc) do
						this.loadparams.objk = k
						this.loadparams.objv = v
						if pcall(function() classes[classes.loadparams.objk] = classes.loadparams.objv end) then
						print('created object def : '..this.loadparams.objk)
						else print('failed to create object def : '..this.loadparams.objk) end
					end
					return true
				else print('failed to load object defs from file : '..this.loadparams.filename..'(nothing returned)') end
				return false
			else
				print('failed to load object def file : '..this.loadparams.filename)
				return false
			end
		else
			print('failed to find object def file')
			return false
		end
		return false
	end,

	-- OBJECT
	object = {
		load = function(this, proto, class)
			class = class or 'object'
			local obj = {img = nil, p = {x = 0, y = 0}, s = 1}
			if type(proto) == 'table' then
				for k, v in pairs(proto) do
					obj[k] = v
				end
			end
			
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
			else
				print('failed to set dependency for new object : '..class)
			end
		end,
		update = function(this, dt)
			-- object does nothing on its own
			-- this is only here to catch errant calls
		end,
		draw = function(this)
			if img[this.img] then
				local x = 0
				while x < this.p.w do
					if this.v then
						if this.v.x < 0 then this.s = 1 elseif this.v.x > 0 then this.s = -1 end
					end
					if this.s < 0 then
						love.graphics.draw(img[this.img], this.p.x + this.p.w + x, this.p.y, 0, -1, 1)
					else
						love.graphics.draw(img[this.img], this.p.x + x, this.p.y)
					end
					x = x + img[this.img]:getWidth()
				end
			else
				love.graphics.quad('fill', this.p.x, this.p.y, this.p.x + this.p.w, this.p.y, this.p.x + this.p.w, this.p.y + this.p.h, this.p.x, this.p.y + this.p.h)
			end
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
			condition = condition or 'true'
			local c = this.filtercache[condition] or loadstring('return function(this, target) return '..condition..' end')()
			if c then this.filtercache[condition] = c else print('failed to construct comparison : '..condition) end
			--if this.filtercache[condition] then
			--	c = this.filtercache[condition]
			--else
				-- collision cache construction testing
				--loadstring('function c(obj) return '..condition..' end')()
				--this.c[condition] = c
			--	c = loadstring('return function(obj) return '..condition..' end')()
				
				--this.filtercache[condition] = loadstring('return function(obj) return '..condition..' end')()
				-- /collision cache construction testing
			--end
			for i, obj in ipairs(world.objects) do
				if obj ~= this and this.filtercache[condition](obj) and this:intersect(obj) then
					--print('check '..this.type..' for '..condition)
					return obj
				end
			end
			return false
		end,
	}
}

return c