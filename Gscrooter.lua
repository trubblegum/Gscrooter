vector = require('vector')
camera = require('camera')

local w = {
	c = {}, -- classes
	gravity = 512,
	objects = {},
	effects = {},
	ctrl = {},
	cam = camera(vector(0, 0), 1, 0),
	remeffect = function(this, rem)
		for i, obj in pairs(this.effects) do
			if obj == rem then
				table.remove(this.effects, i)
				break
			end
		end
	end,
	remobject = function(this, rem)
		for i, obj in pairs(this.objects) do
			if obj == rem then
				table.remove(this.objects, i)
				break
			end
		end
	end,
	load = function(this, level)
		
		--for i, line in love.filesystem.lines('level/level1.lvl') do
		--	local type, obj = line:find(' ', 1)
		--	if this.c[type] then
		--		obj = assert(obj)
		--		this.c[type](obj)
		--	end
		--end
		
		-- level
		table.insert(this.objects, this.c.platform({p = {x = -128, y = 0, w = 4096, h = 0}, img = 'platform4.png'}))
		table.insert(this.objects, this.c.platform({p = {x = 256, y = -128, w = 0, h = 0}, img = 'platform2.png'}))
		table.insert(this.objects, this.c.platform({p = {x = 128, y = -256, w = 0, h = 0}, img = 'platform1.png'}))
		table.insert(this.objects, this.c.platform({p = {x = 360, y = -256, w = 0, h = 0}, img = 'platform4.png'}))
		table.insert(this.objects, this.c.platform({p = {x = 720, y = -192, w = 0, h = 0}, img = 'platform2.png'}))
		
		table.insert(this.objects, this.c.spawn({p = {x = 640, y = -128}}))
		-- /level
		
		this.player = this.c.player()
		table.insert(this.objects, this.player)
		
		this.ctrl = { -- do this after setting global player
			{key = 'a', cmd = this.player.left},
			{key = 'd', cmd = this.player.right},
			{key = 'w', cmd = this.player.jump},
		}
	end,
	unload = function(this)
		this.objects = {}
		this.effects = {}
	end,
	update = function(this, dt)
		if focus then
			for i, ctrl in ipairs(this.ctrl) do
				if love.keyboard.isDown(ctrl.key) then
					ctrl.cmd(this.player, dt)
				end
			end
			for i, obj in ipairs(this.effects) do
				obj:update(dt)
			end
			for i, obj in ipairs(this.objects) do
				obj:update(dt)
			end
		end
	end,
	draw = function(this, dt)
		this.cam.pos = vector((this.player.p.x + this.player.p.w) - (this.player.v.x * dt), (this.player.p.y + this.player.p.h) - (this.player.v.y * dt))
		this.cam:attach()
		for i, obj in ipairs(this.objects) do
			obj:draw()
		end
		for i, obj in ipairs(this.effects) do
			obj:draw()
		end
		this.cam:detach()
	end,
	mousepress = function(this, x, y, button)
		local c = this.cam:worldCoords(vector(x, y))
		local orig = {x = this.player.p.x + (this.player.p.w / 2), y = this.player.p.y + (this.player.p.h / 2)}
		local rel = vector(c.x - orig.x, c.y - orig.y)
		norm = rel:normalized()
		this.player:fire(orig, norm)
	end,
}

--OBJECT
w.c.objectclass = {
	collide = function(this, target)
		target = target or 'none'
		-- assumes that platform.w >= player.w, and no overlapping objects
		for i, obj in ipairs(world.objects) do
			if obj ~= this and ((type(target) == 'string' and (target == 'none' or obj.type == target)) or (type(target) == 'table' and obj == target)) then
				-- print('check '..this.type..' for '..target)
				if this.p.x + this.p.w >= obj.p.x then
					if this.p.x <= obj.p.x + obj.p.w then
						if this.p.y + this.p.h >= obj.p.y then
							if this.p.y <= obj.p.y + obj.p.h then
								return obj
							end
						end
					end
				end
			end
		end
		return false
	end,
	update = function(this, dt)
		-- object does nothing
	end,
	draw = function(this)
		if img[this.img] then
			local x = 0
			while x < this.p.w do
				love.graphics.draw(img[this.img], this.p.x + x, this.p.y)
				x = x + img[this.img]:getWidth()
			end
		else
			love.graphics.quad('fill', this.p.x, this.p.y, this.p.x + this.p.w, this.p.y, this.p.x + this.p.w, this.p.y + this.p.h, this.p.x, this.p.y + this.p.h)
		end
	end,
}
-- object inherits nothing
w.c.object = function(proto)
	local obj = {img = nil, p = {x = 0, y = 0, h = 0, w = 0}}
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
	end
	return setmetatable(obj, {__index = w.c.objectclass})
end

w.c.platformclass = {
	update = function(this, dt)
		w.c.objectclass.update(this, dt)
	end,
}
setmetatable(w.c.platformclass, {__index = w.c.objectclass})
w.c.platform = function(proto)
	proto = proto or {}
	proto.type = 'platform'
	proto.img = proto.img or 'platform4.png'
	local obj = w.c.object(proto)
	return setmetatable(obj, {__index = w.c.platformclass})
end

w.c.projclass = {
	update = function(this, dt)
		this.age = this.age + dt
		if this.age > this.life then
			world:remeffect(this)
			return
		end
		this.p.x = this.p.x + ((this.v.x * this.speed) * dt)
		this.p.y = this.p.y + ((this.v.y * this.speed) * dt)
		this.target = this:collide()
		if this.target and this.target ~= this.orig then
			if this.target.hp then
				this.target.hp = this.target.hp - this.damage
			end
			table.insert(world.effects, w.c.hit({p = {x = this.p.x, y = this.p.y}}))
			world:remeffect(this)
			return
		end
		w.c.objectclass.update(this, dt)
	end,
}
setmetatable(w.c.projclass, {__index = w.c.objectclass})
w.c.proj = function(proto)
	proto = proto or {}
	proto.type = 'proj'
	proto.img = proto.img or 'bullet.png'
	proto.v = proto.v or {x = 0, y = 0}
	proto.age = proto.age or 0
	proto.life = proto.life or 4
	proto.speed = proto.speed or 512
	proto.damage = proto.damage or 16
	local obj = w.c.object(proto)
	return setmetatable(obj, {__index = w.c.projclass})
end

-- EFFECT
w.c.effectclass = {
	update = function(this, dt)
		-- inertia
		this.p.x = this.p.x + (this.v.x * dt)
		this.p.y = this.p.y + (this.v.y * dt)
		-- gravity
		if this.v.y < world.gravity then
			this.v.y = math.min(this.v.y + (world.gravity * dt), world.gravity)
		end
		-- friction
		if this.v.x > 0 then
			this.v.x = math.max(this.v.x - (world.gravity * dt), 0)
		end
		if this.v.x < 0 then
			this.v.x = math.min(this.v.x + (world.gravity * dt), 0)
		end
		w.c.objectclass.update(this, dt)
	end
}
setmetatable(w.c.effectclass, {__index = w.c.objectclass})
w.c.effect = function(proto)
	proto = proto or {}
	proto.v = proto.v or {x = 0, y = 0}
	obj = w.c.object(proto)
	return setmetatable(obj, {__index = w.c.effectclass})
end

w.c.hitclass = {
	update = function(this, dt)
		this.scale = this.scale + (dt * 2)
		this.alpha = this.alpha - (255 * (dt * 2))
		if this.alpha <= 0 then
			world:remeffect(this)
		end
		w.c.effectclass.update(this, dt)
	end,
	draw = function(this)
		local color = {}
		color.r, color.g, color.b, color.a = love.graphics.getColor()
		love.graphics.setColor(255, 255, 255, math.floor(this.alpha))
		love.graphics.draw(img[this.img], this.p.x, this.p.y, 0, this.scale, this.scale, this.p.w / 2, this.p.h / 2)
		love.graphics.setColor(color.r, color.g, color.b, color.a)
	end,
}
setmetatable(w.c.hitclass, {__index = w.c.effectclass})
w.c.hit = function(proto)
	proto = proto or {}
	proto.img = proto.img or 'hit.png'
	proto.v = proto.v or {x = 0, y = -128}
	proto.scale = proto.scale or 0.1
	proto.alpha = proto.alpha or 255
	local obj = w.c.object(proto)
	return setmetatable(obj, {__index = w.c.hitclass})
end

w.c.deathclass = {
	update = function(this, dt)
		this.alpha = this.alpha - (128 * dt)
		if this.alpha <= 0 then
			if this.type == 'player' then
				state.current = 'load'
			end
			world:remeffect(this)
			return
		end
		w.c.effectclass.update(this, dt)
	end,
	draw = function(this)
		local color = {}
		color.r, color.g, color.b, color.a = love.graphics.getColor()
		love.graphics.setColor(255, 255, 255, math.floor(this.alpha))
		love.graphics.draw(img[this.img], this.p.x, this.p.y, 0, this.size, this.size, this.p.w / 2, this.p.h / 2)
		love.graphics.setColor(color.r, color.g, color.b, color.a)
	end,
}
setmetatable(w.c.deathclass, {__index = w.c.effectclass})
w.c.death = function(proto)
	proto = proto or {}
	proto.v = proto.v or {x = 0, y = -64}
	proto.img = proto.img or 'object.png'
	proto.alpha = proto.alpha or 255
	local obj = w.c.effect(proto)
	return setmetatable(obj, {__index = w.c.deathclass})
end

-- PHYSICS
w.c.physicsclass = {
	update = function(this, dt)
		-- inertia
		this.p.x = this.p.x + (this.v.x * dt)
		this.p.y = this.p.y + (this.v.y * dt)
		-- collision
		this.carrier = this:collide('platform')
		if this.carrier then
			-- falling
			if this.v.y >= 0 then
				-- landing
				if (this.p.y + this.p.h) - (this.v.y * dt) <= this.carrier.p.y then
					this.p.y = this.carrier.p.y - this.p.h
					this.v.y = 0
					--this.offset = {x = this.p.x - this.carrier.p.x, y = this.p.y - this.carrier.p.y}
					--this.p.x = this.carrier.p.x + this.offset.x
					--this.p.y = this.carrier.p.y + this.offset.y
				else
					this.carrier = false
				end
			else
				this.carrier = false
			end
		end
		-- gravity
		if not this.carrier and this.v.y < world.gravity then
			this.v.y = math.min(this.v.y + (world.gravity * dt), world.gravity)
		end
		-- friction
		if this.v.x > 0 then
			this.v.x = math.max(this.v.x - (world.gravity * dt), 0)
		end
		if this.v.x < 0 then
			this.v.x = math.min(this.v.x + (world.gravity * dt), 0)
		end
		--wrap
		if this.p.x < world.objects[1].p.x + 128 then
			this.p.x = (world.objects[1].p.x + world.objects[1].p.w) - 128
		end
		if this.p.x > world.objects[1].p.w - 128 then
			this.p.x = world.objects[1].p.x + 128
		end
	end,
}
setmetatable(w.c.physicsclass, {__index = w.c.objectclass})
w.c.physicsobject = function(proto)
	proto = proto or {}
	proto.v = proto.v or {x = 0, y = 0}
	local obj = w.c.object(proto)
	return setmetatable(obj, {__index = w.c.physicsclass})
end

-- ENTITY
w.c.entityclass = {
	update = function(this, dt)
		if this.hp <= 0 then
			table.insert(world.effects, w.c.death({p = this.p, img = this.img}))
			world:remobject(this)
			return
		end
		w.c.physicsclass.update(this, dt)
	end,
	draw = function(this)
		local color = {}
		color.r, color.g, color.b, color.a = love.graphics.getColor()
		love.graphics.setColor(128, 255 * (this.hp / this.ohp), 0, 255)
		love.graphics.quad('fill', this.p.x, this.p.y - 32, this.p.x + (this.p.w * (this.hp / this.ohp)), this.p.y - 32, this.p.x + (this.p.w * (this.hp / this.ohp)), this.p.y - 16, this.p.x, this.p.y - 16)
		love.graphics.setColor(color.r, color.g, color.b, color.a)
		w.c.physicsclass.draw(this)
	end,
	left = function(this, dt)
		this.v.x = math.max(0 - this.speed, (this.v.x + (0 - ((world.gravity + this.speed) * dt))))
	end,
	right = function(this, dt)
		this.v.x = math.min(this.speed, this.v.x + ((world.gravity + this.speed) * dt))
	end,
	jump = function(this, dt)
		if this.carrier then
			this.v.y = 0 - (this.speed * 1.5)
		end
	end,
}
setmetatable(w.c.entityclass, {__index = w.c.physicsclass})
w.c.entity = function(proto)
	proto = proto or {}
	proto.p = proto.p or {x = 128, y = -128, w = 0, h = 0}
	proto.ohp = proto.hp or 100
	proto.hp = proto.hp or proto.ohp
	proto.speed = proto.speed or 256
	local obj = w.c.physicsobject(proto)
	return setmetatable(obj, {__index = w.c.entityclass})
end

w.c.playerclass = {
	update = function(this, dt)
		if this.hp < this.ohp then
			this.hp = math.min(this.hp + (dt * 4), this.ohp)
		end
		w.c.entityclass.update(this, dt)
	end,
	fire = function(this, orig, dir)
		table.insert(world.effects, w.c.proj({p = orig, v = dir, orig = this}))
	end,
}
setmetatable(w.c.playerclass, {__index = w.c.entityclass})
w.c.player = function(proto)
	proto = proto or {}
	proto.p = proto.p or {x = 128, y = -512, w = 0, h = 0}
	proto.type = 'player'
	proto.img = 'player.png'
	local obj = w.c.entity(proto)
	return setmetatable(obj, {__index = w.c.playerclass})
end

w.c.enemyclass = {
	update = function(this, dt)
		if this.updateclock > this.updateinterval then
			this.updateclock = 0
			local action = math.random() * 5
			if action < 2 then
				this:jump()
			elseif action < 4 then
				this:left()
			elseif action < 5 then
				this:right()
			else
				-- yeah, right
			end
		else
			local target = this:collide('player')
			if target then
				target.hp = target.hp - (this.damage * dt)
			end
			this.updateclock = this.updateclock + dt
		end
		w.c.entityclass.update(this, dt)
	end,
	left = function(this, dt)
		this.v.x = 0 - this.speed
	end,
	right = function(this, dt)
		this.v.x = this.speed
	end,
}
setmetatable(w.c.enemyclass, {__index = w.c.entityclass})
w.c.enemy = function(proto)
	proto = proto or {}
	proto.type = 'enemy'
	proto.img = proto.img or 'enemy1.png'
	proto.damage = proto.damage or 32
	proto.updateinterval = proto.updateinterval or 1
	proto.updateclock = proto.updateclock or 1
	local obj = w.c.entity(proto)
	return setmetatable(obj, {__index = w.c.enemyclass})
end

w.c.spawnclass = {
	update = function(this, dt)
		if this.updateclock > this.updateinterval then
			this.updateclock = 0
			if this.hp < this.ohp then
				this.hp = this.ohp
			else
				table.insert(world.objects, w.c.enemy({p = {x = this.p.x, y = this.p.y}}))
			end
		else
			-- need enemy class
			local target = this:collide('player')
			if target then
				target.hp = target.hp - (this.damage * dt)
			end
			this.updateclock = this.updateclock + dt
		end
		w.c.entityclass.update(this, dt)
	end,
}
setmetatable(w.c.spawnclass, {__index = w.c.entityclass})
w.c.spawn = function(proto)
	proto = proto or {}
	proto.type = 'enemy'
	proto.img = proto.img or 'spawn1.png'
	proto.hp = proto.hp or 500
	proto.damage = proto.damage or 16
	proto.updateinterval = proto.updateinterval or 8
	proto.updateclock = proto.updateclock or 6
	local obj = w.c.entity(proto)
	return setmetatable(obj, {__index = w.c.spawnclass})
end

return w