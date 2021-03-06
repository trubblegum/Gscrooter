def = {
	platform = {
		parent = 'object',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.p = classes.position(proto.p, {w = 64, h = 32})
			proto.type = 'platform'
			proto.img = proto.img or 'platform4.png'
			
			return classes.object(proto, class)
		end,
	},

	scenery = {
		parent = 'platform',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.p = classes.position(proto.p, {w = 128, h = 128})
			proto.img = proto.img or 'tree1.png'
			proto.bg = proto.bg or 'treetop1.png'
			if type(proto.bg) == 'string' and not img[proto.bg] then
				if love.filesystem.exists('img/'..proto.bg) then
					img[proto.bg] = love.graphics.newImage('img/'..proto.bg)
				else proto.bg = nil end
			end
			
			return classes.platform(proto, class)
		end,
		draw = function(this)
			if this.bg then
				local y = img[this.bg]:getHeight() - this.p.h
				local x = (this.p.w - img[this.bg]:getWidth()) / 2
				if this.sprite.dir < 0 then love.graphics.draw(img[this.bg], this.p.x + this.p.w - x, this.p.y - y, 0, -1, 1)
				else love.graphics.draw(img[this.bg], this.p.x + x, this.p.y - y) end
			end
			classes.object.draw(this)
		end,
	},

	-- EFFECT
	effect = {
		parent = 'object',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.v = proto.v or {x = 0, y = 0}
			proto.alpha = proto.alpha or 255
			
			return classes.object(proto, class)
		end,
		update = function(this, dt)
			-- inertia
			this.p.x = this.p.x + (this.v.x * dt)
			this.p.y = this.p.y + (this.v.y * dt)
			-- gravity
			if this.v.y < world.gravity then this.v.y = math.min(this.v.y + (world.gravity * dt), world.gravity) end
			-- resistance
			if this.v.x > 0 then this.v.x = math.max(this.v.x - (world.gravity * dt), 0)
			elseif this.v.x < 0 then this.v.x = math.min(this.v.x + (world.gravity * dt), 0) end
		end,
		draw = function(this)
			local color = {}
			color.r, color.g, color.b, color.a = love.graphics.getColor()
			love.graphics.setColor(255, 255, 255, math.floor(this.alpha))
			love.graphics.drawq(img[this.img], this.quad, this.p.x, this.p.y, 0, 1, 1, 0, 0)
			--love.graphics.draw(img[this.img], this.p.x, this.p.y)
			love.graphics.setColor(color.r, color.g, color.b, color.a)
		end,
	},

	bullet = {
		parent = 'effect',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.p = classes.position(proto.p, {w = 8, h = 8})
			proto.type = 'bullet'
			proto.img = proto.img or 'bullet.png'
			proto.v = proto.v or {x = 0, y = 0}
			proto.age = proto.age or 0
			proto.life = proto.life or 0.75
			proto.speed = proto.speed or 512
			proto.damage = proto.damage or 16
			
			return classes.effect(proto, class)
		end,
		update = function(this, dt)
			this.age = this.age + dt
			if this.age > this.life then
				if this.alpha < 0 then
					world:remeffect(this)
					return
				else this.alpha = this.alpha - (1024 * dt) end
			end
			this.p.x = this.p.x + ((this.v.x * this.speed) * dt)
			this.p.y = this.p.y + ((this.v.y * this.speed) * dt)
			this.target = this:collide('notportal')
			if this.target and this.target ~= this.orig then
				if this.target.hp then this.target.hp = this.target.hp - this.damage end
				table.insert(world.effects, classes.hit({p = {x = this.p.x, y = this.p.y}}))
				world:remeffect(this)
				return
			end
		end,
	},

	hit = {
		parent = 'effect',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.p = classes.position(proto.p, {w = 64, h = 64})
			proto.img = proto.img or 'hit.png'
			proto.v = proto.v or {x = 0, y = -128}
			proto.scale = proto.scale or 0.1
			
			return classes.effect(proto, class)
		end,
		update = function(this, dt)
			this.scale = this.scale + (dt * 2)
			this.alpha = this.alpha - (255 * (dt * 2))
			if this.alpha <= 0 then world:remeffect(this) end
			classes.effect.update(this, dt)
		end,
		draw = function(this)
			local color = {}
			color.r, color.g, color.b, color.a = love.graphics.getColor()
			love.graphics.setColor(255, 255, 255, math.floor(this.alpha))
			love.graphics.draw(img[this.img], this.p.x, this.p.y, 0, this.scale, this.scale, this.p.w / 2, this.p.h / 2)
			love.graphics.setColor(color.r, color.g, color.b, color.a)
		end,
		intersect = function(this, obj)
			if this.p.x + (this.p.w * this.scale) >= obj.p.x and this.p.x <= obj.p.x + (this.p.w * this.scale) then
				if this.p.y + (this.p.h * this.scale) >= obj.p.y and this.p.y <= obj.p.y + (this.p.h * this.scale) then return true end
			else return false end
		end,
	},

	heal = {
		parent = 'hit',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.img = proto.img or 'heal.png'
			proto.scale = proto.scale or 0.2
			
			return classes.hit(proto, class)
		end
	},
	
	AOE = {
		parent= 'hit',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			return classes.hit(proto, class)
		end,
		collide = function(this, condition)
			local c = this:getfilter(condition)
			local targets = {}
			for i, obj in ipairs(world.objects) do
				if c(obj) and obj ~= this and this:intersect(obj) then table.insert(targets, obj) end
			end
			if targets[1] then return targets else return false end
		end,
	},
	
	AOEheal = {
		parent = 'AOE',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.img = proto.img or 'heal.png'
			proto.healing = proto.healing or 16
			proto.scale = proto.scale or 1
			
			return classes.AOE(proto, class)
		end,
		update = function(this, dt)
			local targets = this:collide('playerorfriendly')
			if targets then
				for i, target in ipairs(targets) do
					if target.hp then target.hp = math.min(target.hp + (this.healing * dt), target.ohp) end
				end
			end
			classes.AOE.update(this, dt)
		end,
	},
	
	enemyAOEheal = {
		parent = 'AOE',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.img = proto.img or 'heal.png'
			proto.healing = proto.healing or 16
			proto.scale = proto.scale or 1
			
			return classes.AOE(proto, class)
		end,
		update = function(this, dt)
			local targets = this:collide('enemy')
			if targets then
				for i, target in ipairs(targets) do
					if target.hp then target.hp = math.min(target.hp + (this.healing * dt), target.ohp) end
				end
			end
			classes.AOE.update(this, dt)
		end,
	},
	
	AOEdamage = {
		parent = 'AOE',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.img = proto.img or 'fire.png'
			proto.damage = proto.damage or 32
			proto.scale = proto.scale or 1
			
			return classes.AOE(proto, class)
		end,
		update = function(this, dt)
			local targets = this:collide('notportal')
			if targets then
				for i, target in ipairs(targets) do
					if target.hp then target.hp = target.hp - (this.damage * dt) end
				end
			end
			classes.AOE.update(this, dt)
		end,
	},
	
	AOEpoison = {
		parent = 'AOE',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.img = proto.img or 'poison.png'
			proto.damage = proto.damage or 16
			proto.scale = proto.scale or 0.5
			
			return classes.AOE(proto, class)
		end,
		update = function(this, dt)
			local targets = this:collide(player)
			if targets then
				for i, target in ipairs(targets) do
					if target.hp then target.hp = target.hp - (this.damage * dt) end
				end
			end
			classes.AOE.update(this, dt)
		end,
	},

	death = {
		parent = 'effect',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.v = proto.v or {x = 0, y = -128}
			proto.v.y = proto.v.y - 128
			proto.img = proto.img or 'object.png'
			
			return classes.effect(proto, class)
		end,
		update = function(this, dt)
			this.alpha = this.alpha - (255 * dt)
			if this.alpha <= 0 then
				if this.type == 'player' then
					player = classes.player()
					world:unload()
					return
				end
				world:remeffect(this)
				return
			end
			classes.effect.update(this, dt)
		end,
		draw = function(this) classes.effect.draw(this) end,
	},

	-- PHYSICS
	physics = {
		parent = 'object',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.v = proto.v or {x = 0, y = 0}
			proto.mass = proto.mass or 1
			proto.bounce = proto.bounce or 0.5
			
			return classes.object(proto, class)
		end,
		update = function(this, dt)
			-- inertia
			this.p.x = this.p.x + (this.v.x * dt)
			this.p.y = this.p.y + (this.v.y * dt)
			--wrap
			local ground = world.objects[1]
			if this.p.x < ground.p.x then this.p.x = (ground.p.x + ground.p.w) - this.p.w
			elseif this.p.x + this.p.w > ground.p.x + ground.p.w then this.p.x = ground.p.x end
			-- collision
			this.surface = this:collide('platform')
			if this.surface then
				-- falling
				if this.v.y >= 0 then
					-- landing
					if (this.p.y + this.p.h) - (this.v.y * dt) <= this.surface.p.y then
						this.p.y = this.surface.p.y - this.p.h
						this.v.y = 0 - math.floor(this.v.y * this.bounce)
						--this.offset = {x = this.p.x - this.surface.p.x, y = this.p.y - this.surface.p.y}
						--this.p.x = this.surface.p.x + this.offset.x
						--this.p.y = this.surface.p.y + this.offset.y
					else this.surface = false end
				else this.surface = false end
			end
			-- gravity
			if not this.surface then
				if this.v.y < world.gravity * this.mass then this.v.y = math.min(this.v.y + ((world.gravity * this.mass) * dt), world.gravity * this.mass)
				elseif this.v.y > world.gravity * this.mass then this.v.y = math.max(this.v.y - ((world.gravity * this.mass) * dt), world.gravity * this.mass) end
			end
			-- resistance
			if this.v.x > 0 then this.v.x = math.max(this.v.x - ((world.gravity * this.mass) * dt), 0)
			elseif this.v.x < 0 then this.v.x = math.min(this.v.x + ((world.gravity * this.mass) * dt), 0) end
			
			classes.object.update(this, dt)
		end,
	},

	chest = {
		parent = 'physics',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.p = classes.position(proto.p, {w = 64, h = 64})
			proto.type = 'chest'
			proto.img = proto.img or 'chest.png'
			proto.contents = proto.contents or {}
			
			return classes.physics(proto, class)
		end,
		use = function(this)
			for i, item in ipairs(this.contents) do
				if classes[item] then table.insert(world.objects, classes[item]({item = item, p = {x = this.p.x + (this.p.w / 2), y = this.p.y}, v = {x = 256 - (math.random() * 512), y = -128}}))
				else print('attempt to create invalid item : '..item) end
			end
			this.img = 'chestopen.png'
			table.insert(world.effects, classes.death(this))
			world:remobject(this)
		end,
	},
	
	item = {
		parent = 'physics',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.p = classes.position(proto.p, {w = 32, h = 32})
			proto.type = 'item'
			proto.img = proto.img or 'object.png'
			proto.p = proto.p or {}
			proto.item = proto.item or 'item'
			proto.mass = proto.mass or 0.5
			proto.q = proto.q or 1
			proto.age = 0
			proto.life = 10
			proto.alpha = 255
			
			return classes.physics(proto, class)
		end,
		update = function(this, dt)
			this.age = this.age + dt
			if this.age > this.life then
				this.alpha = this.alpha - (255 * dt)
				if this.alpha <= 0 then
					world:remobject(this)
					return
				end
			end
			classes.physics.update(this, dt)
		end,
		draw = function(this) classes.effect.draw(this) end,
		use = function(this)
			this.q = this.q - 1
			if this.q < 1 then this = false end
		end,
	},
	
	itemheal = {
		parent = 'item',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.img = proto.img or 'itemheal.png'
			proto.item = proto.item or 'itemheal'
			proto.healing = proto.healing or 32
			
			return classes.item(proto, class)
		end,
		update = function(this, dt) classes.item.update(this, dt) end,
		use = function(this, obj)
			obj.hp = math.min(obj.hp + this.healing, obj.ohp)
			table.insert(world.effects, classes.heal({p = {x = obj.p.x + (obj.p.w / 2), y = obj.p.y}}))
			classes.item.use(this)
		end,
	},
	
	itemgrenade = {
		parent = 'item',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.img = proto.img or 'itemgrenade.png'
			proto.item = proto.item or 'itemgrenade'
			proto.healing = proto.healing or 32
			
			return classes.item(proto, class)
		end,
		update = function(this, dt)
			if this.active then
				local target = this:collide('notportal')
				if (target and target ~= this.orig) or this.age > 3 then
					table.insert(world.effects, classes.AOEdamage({p = {x = this.p.x + (this.p.w / 2), y = this.p.y}, damage = 128, scale = 2}))
					for i = 1, 8 do
						local dir = {x = 1 - (math.random() * 2), y = 1 - (math.random() * 2)}
						table.insert(world.effects, classes.bullet({p = {x = this.p.x, y = this.p.y}, v = dir}))
					end
					world:remeffect(this)
				end
			end
			classes.item.update(this, dt)
		end,
		use = function(this, obj)
			local x, y = love.mouse.getX(), love.mouse.getY()
			local c = world.cam:worldCoords(vector(x, y))
			local orig = {x = obj.p.x + (obj.p.w / 2), y = obj.p.y + (obj.p.h / 2)}
			local rel = vector(c.x - orig.x, c.y - orig.y):normalize_inplace()
			rel = rel * 512
			table.insert(world.effects, classes.itemgrenade({p = {x = obj.p.x + (obj.p.w / 2), y = obj.p.y}, v = rel, active = true, orig = player}))
			classes.item.use(this)
		end,
	},
	
	portal = {
		parent = 'physics',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.p = classes.position(proto.p, {w = 96, h = 96})
			proto.type = 'portal'
			proto.img = proto.img or 'portal.png'
			
			return classes.physics(proto, class)
		end,
		use = function(this)
			if this.level then
				local levelfile = 'map/'..this.level
				if love.filesystem.exists(levelfile..'.lvl') then world:load(levelfile)
				else
					state.current = 'map'
					world:unload()
					return
				end
			else
				if state.mapfile then state.current = 'map'
				else state.current = 'loadmap' end
				world:unload()
			end
		end,
	},

	-- ENTITY
	entity = {
		parent = 'physics',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.p = classes.position(proto.p, {x = 128, y = -128, w = 64, h = 64})
			proto.hp = proto.hp or 128
			proto.ohp = proto.ohp or proto.hp
			proto.speed = proto.speed or 256
			proto.updateinterval = proto.updateinterval or 4
			proto.updateclock = proto.updateclock or 0
			
			return classes.physics(proto, class)
		end,
		update = function(this, dt)
			-- die
			if this.hp <= 0 then
				table.insert(world.effects, classes.death(this))
				world:remobject(this)
				return
			end
			-- clock
			this.updateclock = this.updateclock + dt
			-- ceiling
			if this.p.y < world.ceiling then this.p.y = world.ceiling end
			
			classes.physics.update(this, dt)
		end,
		draw = function(this)
			local color = {}
			color.r, color.g, color.b, color.a = love.graphics.getColor()
			love.graphics.setColor(128, 255 * (this.hp / this.ohp), 0, 255)
			love.graphics.quad('fill', this.p.x, this.p.y - 32, this.p.x + (this.p.w * (this.hp / this.ohp)), this.p.y - 32, this.p.x + (this.p.w * (this.hp / this.ohp)), this.p.y - 16, this.p.x, this.p.y - 16)
			love.graphics.setColor(color.r, color.g, color.b, color.a)
			classes.object.draw(this)
		end,
		left = function(this, dt) this.v.x = math.max(0 - this.speed, this.v.x + (0 - ((world.gravity + this.speed) * dt))) end,
		right = function(this, dt) this.v.x = math.min(this.speed, this.v.x + ((world.gravity + this.speed) * dt)) end,
		jump = function(this, dt)
			if this.surface then this.v.y = 0 - (this.speed * 1.5) end
		end,
	},

	healtree = {
		parent = 'entity',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.p = classes.position(proto.p, {w = 64, h = 128})
			proto.type = 'friendly'
			proto.img = proto.img or 'healtree.png'
			proto.healing = proto.healing or 16
			proto.updateinterval = proto.updateinterval or 2
			proto.updateclock = proto.updateclock or 1
			
			return classes.entity(proto, class)
		end,
		update = function(this, dt)
			if this.updateclock > this.updateinterval then
				this:heal()
				this.updateclock = 0
			end
			classes.entity.update(this, dt)
		end,
		heal = function(this) table.insert(world.effects, classes.AOEheal({p = {x = this.p.x + (this.p.w / 2), y = this.p.y}, v = {x = (math.random() * 512) - 256, y = 0}, healing = this.healing})) end,
	},

	enemy = {
		parent = 'entity',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.type = 'enemy'
			proto.img = proto.img or 'enemy.png'
			proto.hp = proto.hp or 32
			proto.damage = proto.damage or 32
			proto.updateinterval = proto.updateinterval or 1
			proto.updateclock = proto.updateclock or 0
			
			return classes.entity(proto, class)
		end,
		update = function(this, dt)
			--damage player
			local target = this:collide(player)
			if target then target.hp = target.hp - (this.damage * dt) end
			
			classes.entity.update(this, dt)
		end,
		left = function(this, dt) this.v.x = 0 - this.speed end,
		right = function(this, dt) this.v.x = this.speed end,
	},
}

return def