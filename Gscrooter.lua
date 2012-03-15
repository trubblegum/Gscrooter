vector = require('vector')
camera = require('camera')

local w = {
	c = {}, -- classes
	gravity = 512,
	ceiling = -1024,
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
	load = function(this, levelfile)
		if love.filesystem.exists(levelfile) then
			for line in love.filesystem.lines(levelfile) do
				local i = line:find(' ', 1)
				if i then
					local def = line:sub(1, i - 1)
					local obj = line:sub(i + 1)
					--print('def = "'..def..'" obj = "'..obj..'"')
					if this.c[def] then
						obj = loadstring('return '..obj)
						obj = obj()
						table.insert(this.objects, this.c[def](obj))
					end
				end
			end
			this.player = this.c.player()
			table.insert(this.objects, this.player)
		else
			this:unload()
			state.current = 'menu'
		end
		this.ctrl = {
			{key = 'a', cmd = this.player.left},
			{key = 'd', cmd = this.player.right},
			{key = 'w', cmd = this.player.jump},
			{key = 's', cmd = this.player.use},
		}
		love.audio.play(snd.load)
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
		local ground = this.objects[1]
		this.cam.pos = vector(math.min(math.max((this.player.p.x + (this.player.p.w / 2)) - (this.player.v.x * dt), ground.p.x + (love.graphics.getWidth() / 2)), (ground.p.x + ground.p.w) - (love.graphics.getWidth() / 2)), (this.player.p.y + this.player.p.h) - (this.player.v.y * dt))
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
				if this.v then
					if this.v.x < 0 then
						this.s = 1
					elseif this.v.x > 0 then
						this.s = -1
					end
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
}
-- object inherits nothing
w.c.object = function(proto)
	local obj = {img = nil, p = {x = 0, y = 0}, s = 1}
	if type(proto) == 'table' then
		for k, v in pairs(proto) do
			obj[k] = v
		end
	end
	obj.p.w = obj.p.w or 0
	obj.p.h = obj.p.h or 0
	
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

w.c.sceneryclass = {
	update = function(this, dt)
		w.c.platformclass.update(this, dt)
	end,
	draw = function(this)
		if this.bg then
			local y = img[this.bg]:getHeight() - this.p.h
			local x = (this.p.w - img[this.bg]:getWidth()) / 2
			if this.s < 0 then
				love.graphics.draw(img[this.bg], this.p.x + this.p.w - x, this.p.y - y, 0, -1, 1)
			else
				love.graphics.draw(img[this.bg], this.p.x + x, this.p.y - y)
			end
		end
		w.c.platformclass.draw(this)
	end,
}
setmetatable(w.c.sceneryclass, {__index = w.c.platformclass})
w.c.scenery = function(proto)
	proto = proto or {}
	proto.img = proto.img or 'tree1.png'
	proto.bg = proto.bg or 'treetop1.png'
	if type(proto.bg) == 'string' and not img[proto.bg] then
		if love.filesystem.exists('img/'..proto.bg) then
			img[proto.bg] = love.graphics.newImage('img/'..proto.bg)
		else
			proto.bg = nil
		end
	end
	local obj = w.c.platform(proto)
	return setmetatable(obj, {__index = w.c.sceneryclass})
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
	proto.life = proto.life or 1
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
		-- resistance
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
	collide = function(this, target)
		target = target or 'none'
		for i, obj in ipairs(world.objects) do
			if obj ~= this and ((type(target) == 'string' and (target == 'none' or obj.type == target)) or (type(target) == 'table' and obj == target)) then
				-- print('check '..this.type..' for '..target)
				if this.p.x + (this.p.w * this.scale) >= obj.p.x then
					if this.p.x <= obj.p.x + (this.p.w * this.scale) then
						if this.p.y + (this.p.h * this.scale) >= obj.p.y then
							if this.p.y <= obj.p.y + (this.p.h * this.scale) then
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

w.c.healclass = {
}
setmetatable(w.c.healclass, {__index = w.c.hitclass})
w.c.heal = function(proto)
	proto = proto or {}
	proto.img = proto.img or 'heal.png'
	proto.scale = proto.scale or 0.2
	local obj = w.c.hit(proto)
	return setmetatable(obj, {__index = w.c.hitclass})
end

w.c.AOEhealclass = {
	update = function(this, dt)
		this.scale = this.scale + (dt * 2)
		this.alpha = this.alpha - (255 * dt)
		if this.alpha <= 0 then
			world:remeffect(this)
			return
		end
		this.target = this:collide('player')
		if this.target then
			if this.target.hp then
				this.target.hp = math.min(this.target.hp + (this.healing * dt), this.target.ohp)
			end
		end
		w.c.effectclass.update(this, dt)
	end,
}
setmetatable(w.c.AOEhealclass, {__index = w.c.hitclass})
w.c.AOEheal = function(proto)
	proto = proto or {}
	proto.img = proto.img or 'heal.png'
	proto.healing = proto.healing or 16
	proto.scale = proto.scale or 1
	local obj = w.c.hit(proto)
	return setmetatable(obj, {__index = w.c.AOEhealclass})
end

w.c.enemyAOEhealclass = {
	update = function(this, dt)
		this.scale = this.scale + (dt * 2)
		this.alpha = this.alpha - (255 * dt)
		if this.alpha <= 0 then
			world:remeffect(this)
			return
		end
		this.target = this:collide('enemy')
		if this.target then
			if this.target.hp then
				this.target.hp = math.min(this.target.hp + (this.healing * dt), this.target.ohp)
			end
		end
		w.c.effectclass.update(this, dt)
	end,
}
setmetatable(w.c.enemyAOEhealclass, {__index = w.c.hitclass})
w.c.enemyAOEheal = function(proto)
	proto = proto or {}
	proto.img = proto.img or 'heal.png'
	proto.healing = proto.healing or 16
	proto.scale = proto.scale or 1
	local obj = w.c.hit(proto)
	return setmetatable(obj, {__index = w.c.enemyAOEhealclass})
end

w.c.AOEpoisonclass = {
	update = function(this, dt)
		this.scale = this.scale + (dt * 2)
		this.alpha = this.alpha - (255 * dt)
		if this.alpha <= 0 then
			world:remeffect(this)
			return
		end
		this.target = this:collide('player')
		if this.target then
			if this.target.hp then
				this.target.hp = this.target.hp - (this.damage * dt)
			end
		end
		w.c.effectclass.update(this, dt)
	end,
}
setmetatable(w.c.AOEpoisonclass, {__index = w.c.hitclass})
w.c.AOEpoison = function(proto)
	proto = proto or {}
	proto.img = proto.img or 'poison.png'
	proto.damage = proto.damage or 16
	proto.scale = proto.scale or 0.5
	local obj = w.c.hit(proto)
	return setmetatable(obj, {__index = w.c.AOEpoisonclass})
end

w.c.deathclass = {
	update = function(this, dt)
		this.alpha = this.alpha - (128 * dt)
		if this.alpha <= 0 then
			if this.type == 'player' then
				world:unload()
				if state.mapfile then
					state.current = 'map'
				else
					state.current = 'load'
				end
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
		--wrap
		local ground = world.objects[1]
		if this.p.x < ground.p.x then
			this.p.x = (ground.p.x + ground.p.w) - this.p.w
		elseif this.p.x + this.p.w > ground.p.x + ground.p.w then
			this.p.x = ground.p.x
		end
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
		if not this.carrier then
			if this.v.y < world.gravity * this.mass then
				this.v.y = math.min(this.v.y + (world.gravity * this.mass * dt), world.gravity * this.mass)
			elseif this.v.y > world.gravity * this.mass then
				this.v.y = math.max(this.v.y - (world.gravity * this.mass * dt), world.gravity * this.mass)
			end
		end
		-- resistance
		if this.v.x > 0 then
			this.v.x = math.max(this.v.x - (world.gravity * dt), 0)
		elseif this.v.x < 0 then
			this.v.x = math.min(this.v.x + (world.gravity * dt), 0)
		end
	end,
}
setmetatable(w.c.physicsclass, {__index = w.c.objectclass})
w.c.physicsobject = function(proto)
	proto = proto or {}
	proto.v = proto.v or {x = 0, y = 0}
	proto.mass = proto.mass or 1
	local obj = w.c.object(proto)
	return setmetatable(obj, {__index = w.c.physicsclass})
end

w.c.portalclass = {
	update = function(this, dt)
		w.c.physicsclass.update(this, dt)
	end,
}
setmetatable(w.c.portalclass, {__index = w.c.physicsclass})
w.c.portal = function(proto)
	proto = proto or {}
	proto.type = 'portal'
	proto.img = proto.img or 'portal.png'
	local obj = w.c.physicsobject(proto)
	return setmetatable(obj, {__index = w.c.portalclass})
end

-- ENTITY
w.c.entityclass = {
	update = function(this, dt)
		if this.hp <= 0 then
			table.insert(world.effects, w.c.death(this))
			world:remobject(this)
			return
		end
		if this.p.y < world.ceiling then
			this.p.y = world.ceiling
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
		this.v.x = math.max(0 - this.speed, this.v.x + (0 - ((world.gravity + this.speed) * dt)))
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
	proto.hp = proto.hp or 128
	proto.ohp = proto.ohp or proto.hp
	proto.speed = proto.speed or 256
	proto.updateinterval = proto.updateinterval or 4
	proto.updateclock = proto.updateclock or 0
	local obj = w.c.physicsobject(proto)
	return setmetatable(obj, {__index = w.c.entityclass})
end

w.c.playerclass = {
	update = function(this, dt)
		if this.hp < this.ohp then
			--this.hp = math.min(this.hp + (dt * 4), this.ohp)
		end
		w.c.entityclass.update(this, dt)
	end,
	fire = function(this, orig, dir)
		table.insert(world.effects, w.c.proj({p = orig, v = dir, orig = this}))
	end,
	use = function(this)
		portal = this:collide('portal')
		if portal then
			world:unload()
			if portal.level then
				local levelfile = 'map/'..portal.level..'.lvl'
				if love.filesystem.exists(levelfile) then
					world:load(levelfile)
					return
				end
			end
			if state.mapfile then
				state.current = 'map'
			else
				state.current = 'load'
			end
		end
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

w.c.healtreeclass = {
	update = function(this, dt)
		if this.updateclock > this.updateinterval then
			this.updateclock = 0
			this:heal()
		else
			this.updateclock = this.updateclock + dt
		end
		w.c.entityclass.update(this, dt)
	end,
	heal = function(this)
		table.insert(world.effects, w.c.AOEheal({p = {x = this.p.x + (this.p.w / 2), y = this.p.y}, v = {x = (math.random() * 512) - 256, y = 0}, healing = this.healing}))
	end,
}
setmetatable(w.c.healtreeclass, {__index = w.c.entityclass})
w.c.healtree = function(proto)
	proto = proto or {}
	proto.type = 'friendly'
	proto.img = proto.img or 'healtree.png'
	proto.healing = proto.healing or 16
	proto.updateinterval = proto.updateinterval or 2
	proto.updateclock = proto.updateclock or 1
	local obj = w.c.entity(proto)
	return setmetatable(obj, {__index = w.c.healtreeclass})
end

w.c.enemyclass = {
	update = function(this, dt)
		local target = this:collide('player')
		if target then
			target.hp = target.hp - (this.damage * dt)
		end
		this.updateclock = this.updateclock + dt
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
	proto.img = proto.img or 'enemy.png'
	proto.hp = proto.hp or 64
	proto.damage = proto.damage or 32
	proto.updateinterval = proto.updateinterval or 1
	proto.updateclock = proto.updateclock or 1
	local obj = w.c.entity(proto)
	return setmetatable(obj, {__index = w.c.enemyclass})
end

w.c.hopperclass = {
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
		end
		w.c.enemyclass.update(this, dt)
	end,
}
setmetatable(w.c.hopperclass, {__index = w.c.enemyclass})
w.c.hopper = function(proto)
	proto = proto or {}
	proto.img = proto.img or 'hopper.png'
	proto.damage = proto.damage or 32
	proto.updateinterval = proto.updateinterval or 1
	proto.updateclock = proto.updateclock or 1
	local obj = w.c.enemy(proto)
	return setmetatable(obj, {__index = w.c.hopperclass})
end

w.c.hopperspawnclass = {
	update = function(this, dt)
		if this.updateclock > this.updateinterval then
			this.updateclock = 0
			local action = math.random() * 3
			if action < 1 then
				this:heal()
			elseif action < 3 then
				this:spawn()
			else
				-- yeah, right
			end
		end
		w.c.enemyclass.update(this, dt)
	end,
	heal = function(this)
		table.insert(world.effects, w.c.enemyAOEheal({p = {x = this.p.x + (this.p.w / 2), y = this.p.y}, v = {x = (math.random() * 512) - 256, y = 0}, healing = this.healing}))
	end,
	spawn = function(this)
		table.insert(world.objects, w.c.hopper({p = {x = this.p.x, y = this.p.y}}))
	end
}
setmetatable(w.c.hopperspawnclass, {__index = w.c.enemyclass})
w.c.hopperspawn = function(proto)
	proto = proto or {}
	proto.img = proto.img or 'hopperspawn.png'
	proto.hp = proto.hp or 512
	proto.damage = proto.damage or 16
	proto.updateinterval = proto.updateinterval or 8
	proto.updateclock = proto.updateclock or 6
	local obj = w.c.enemy(proto)
	return setmetatable(obj, {__index = w.c.hopperspawnclass})
end

w.c.buzzerclass = {
	update = function(this, dt)
		if this.updateclock > this.updateinterval then
			this.updateclock = 0
			local action = math.random() * 5
			if action < 1 then
				this:dive()
			elseif action < 3 then
				this:left()
			elseif action < 5 then
				this:right()
			else
				-- yeah, right
			end
		end
		w.c.enemyclass.update(this, dt)
	end,
	dive = function(this)
		this.v.y = this.speed * 4
	end,
	left = function(this, dt)
		this.v.x = 0 - this.speed
		this.v.y = 0 - this.speed
	end,
	right = function(this, dt)
		this.v.x = this.speed
		this.v.y = 0 - this.speed
	end,
}
setmetatable(w.c.buzzerclass, {__index = w.c.enemyclass})
w.c.buzzer = function(proto)
	proto = proto or {}
	proto.img = proto.img or 'buzzer.png'
	proto.mass = proto.mass or 0.5
	proto.hp = proto.hp or 32
	proto.updateinterval = proto.updateinterval or 1
	local obj = w.c.enemy(proto)
	return setmetatable(obj, {__index = w.c.buzzerclass})
end

w.c.buzzerspawnclass = {
	update = function(this, dt)
		if this.updateclock > this.updateinterval then
			this.updateclock = 0
			local action = math.random() * 5
			if action < 1 then
				this:spawn()
			elseif action < 3 then
				this:left()
			elseif action < 5 then
				this:right()
			else
				-- yeah, right
			end
		end
		w.c.enemyclass.update(this, dt)
	end,
	spawn = function(this)
		table.insert(world.objects, w.c.buzzer({p = {x = this.p.x, y = this.p.y}}))
	end,
}
setmetatable(w.c.buzzerspawnclass, {__index = w.c.buzzerclass})
w.c.buzzerspawn = function(proto)
	proto = proto or {}
	proto.img = proto.img or 'buzzerspawn.png'
	proto.hp = proto.hp or 256
	proto.updateinterval = proto.updateinterval or 1.5
	local obj = w.c.buzzer(proto)
	return setmetatable(obj, {__index = w.c.buzzerspawnclass})
end

w.c.slitherclass = {
	update = function(this, dt)
		if this.updateclock > this.updateinterval then
			this.updateclock = 0
			local action = math.random() * 5
			if action < 2 then
				this:spit()
			elseif action < 4 then
				this:left()
			elseif action < 5 then
				this:right()
			else
				-- yeah, right
			end
		end
		w.c.enemyclass.update(this, dt)
	end,
	spit = function(this)
		table.insert(world.effects, w.c.AOEpoison({p = {x = this.p.x, y = this.p.y}, v = {x = (math.random() * 512) - 256, y = -256}}))
	end,
}
setmetatable(w.c.slitherclass, {__index = w.c.hopperclass})
w.c.slither = function(proto)
	proto = proto or {}
	proto.img = proto.img or 'slither.png'
	proto.damage = proto.damage or 32
	proto.updateinterval = proto.updateinterval or 1
	proto.updateclock = proto.updateclock or 1
	local obj = w.c.enemy(proto)
	return setmetatable(obj, {__index = w.c.slitherclass})
end

w.c.slitherspawnclass = {
	update = function(this, dt)
		if this.updateclock > this.updateinterval then
			this.updateclock = 0
			local action = math.random() * 3
			if action < 1 then
				this:heal()
			elseif action < 3 then
				this:spawn()
			else
				-- yeah, right
			end
		end
		w.c.enemyclass.update(this, dt)
	end,
	heal = function(this)
		table.insert(world.effects, w.c.enemyAOEheal({p = {x = this.p.x + (this.p.w / 2), y = this.p.y}, v = {x = (math.random() * 512) - 256, y = 0}, healing = this.healing}))
	end,
	spawn = function(this)
		table.insert(world.objects, w.c.slither({p = {x = this.p.x, y = this.p.y}}))
	end
}
setmetatable(w.c.slitherspawnclass, {__index = w.c.enemyclass})
w.c.slitherspawn = function(proto)
	proto = proto or {}
	proto.img = proto.img or 'slitherspawn.png'
	proto.hp = proto.hp or 512
	proto.damage = proto.damage or 16
	proto.updateinterval = proto.updateinterval or 8
	proto.updateclock = proto.updateclock or 6
	local obj = w.c.enemy(proto)
	return setmetatable(obj, {__index = w.c.slitherspawnclass})
end

return w