def = {
	platform = {
		parent = 'object',
		load = function(this, proto, class)
			class = class or 'platform'
			proto = proto or {}
			proto.type = 'platform'
			proto.img = proto.img or 'platform4.png'
			
			return classes.object(proto, class)
		end,
	},

	scenery = {
		parent = 'platform',
		load = function(this, proto, class)
			class = class or 'scenery'
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
			
			return classes.platform(proto, class)
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
			classes.object.draw(this)
		end,
	},

	-- EFFECT
	effect = {
		parent = 'object',
		load = function(this, proto, class)
			class = class or 'effect'
			proto = proto or {}
			proto.v = proto.v or {x = 0, y = 0}
			
			return classes.object(proto, class)
		end,
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
		end
	},

	proj = {
		parent = 'object',
		load = function(this, proto, class)
			class = class or 'proj'
			proto = proto or {}
			proto.type = 'proj'
			proto.img = proto.img or 'bullet.png'
			proto.v = proto.v or {x = 0, y = 0}
			proto.age = proto.age or 0
			proto.life = proto.life or 1
			proto.speed = proto.speed or 512
			proto.damage = proto.damage or 16
			
			return classes.object(proto, class)
		end,
		update = function(this, dt)
			this.age = this.age + dt
			if this.age > this.life then
				world:remeffect(this)
				return
			end
			this.p.x = this.p.x + ((this.v.x * this.speed) * dt)
			this.p.y = this.p.y + ((this.v.y * this.speed) * dt)
			this.target = this:collide('obj.type ~= "portal"')
			if this.target and this.target ~= this.orig then
				if this.target.hp then
					this.target.hp = this.target.hp - this.damage
				end
				table.insert(world.effects, classes.hit({p = {x = this.p.x, y = this.p.y}}))
				world:remeffect(this)
				return
			end
		end,
	},

	hit = {
		parent = 'effect',
		load = function(this, proto, class)
			class = class or 'hit'
			proto = proto or {}
			proto.img = proto.img or 'hit.png'
			proto.v = proto.v or {x = 0, y = -128}
			proto.scale = proto.scale or 0.1
			proto.alpha = proto.alpha or 255
			
			return classes.object(proto, class)
		end,
		update = function(this, dt)
			this.scale = this.scale + (dt * 2)
			this.alpha = this.alpha - (255 * (dt * 2))
			if this.alpha <= 0 then
				world:remeffect(this)
			end
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
				if this.p.y + (this.p.h * this.scale) >= obj.p.y and this.p.y <= obj.p.y + (this.p.h * this.scale) then
					return true
				end
			end
		end,
	},

	heal = {
		parent = 'hit',
		load = function(this, proto, class)
			class = class or 'heal'
			proto = proto or {}
			proto.img = proto.img or 'heal.png'
			proto.scale = proto.scale or 0.2
			
			return classes.hit(proto, class)
		end
	},

	AOEheal = {
		parent = 'hit',
		load = function(this, proto, class)
			class = class or 'AOEheal'
			proto = proto or {}
			proto.img = proto.img or 'heal.png'
			proto.healing = proto.healing or 16
			proto.scale = proto.scale or 1
			
			return classes.hit(proto, class)
		end,
		update = function(this, dt)
			this.target = this:collide('obj == player')
			if this.target then
				if this.target.hp then
					this.target.hp = math.min(this.target.hp + (this.healing * dt), this.target.ohp)
				end
			end
			classes.hit.update(this, dt)
		end,
	},

	enemyAOEheal = {
		parent = 'hit',
		load = function(this, proto, class)
			class = class or 'enemyAOEheal'
			proto = proto or {}
			proto.img = proto.img or 'heal.png'
			proto.healing = proto.healing or 16
			proto.scale = proto.scale or 1
			
			return classes.hit(proto, class)
		end,
		update = function(this, dt)
			this.target = this:collide('obj.type == "enemy"')
			if this.target then
				if this.target.hp then
					this.target.hp = math.min(this.target.hp + (this.healing * dt), this.target.ohp)
				end
			end
			classes.hit.update(this, dt)
		end,
	},

	AOEpoison = {
		parent = 'hit',
		load = function(this, proto, class)
			class = class or 'AOEpoison'
			proto = proto or {}
			proto.img = proto.img or 'poison.png'
			proto.damage = proto.damage or 16
			proto.scale = proto.scale or 0.5
			
			return classes.hit(proto, class)
		end,
		update = function(this, dt)
			this.target = this:collide('obj == player')
			if this.target then
				if this.target.hp then
					this.target.hp = this.target.hp - (this.damage * dt)
				end
			end
			classes.hit.update(this, dt)
		end,
	},

	death = {
		parent = 'effect',
		load = function(this, proto, class)
			class = class or 'death'
			proto = proto or {}
			proto.v = proto.v or {x = 0, y = -64}
			proto.img = proto.img or 'object.png'
			proto.alpha = proto.alpha or 255
			
			return classes.effect(proto, class)
		end,
		update = function(this, dt)
			this.alpha = this.alpha - (128 * dt)
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
		draw = function(this)
			local color = {}
			color.r, color.g, color.b, color.a = love.graphics.getColor()
			love.graphics.setColor(255, 255, 255, math.floor(this.alpha))
			love.graphics.draw(img[this.img], this.p.x, this.p.y, 0, this.size, this.size, this.p.w / 2, this.p.h / 2)
			love.graphics.setColor(color.r, color.g, color.b, color.a)
		end,
	},

	-- PHYSICS
	physics = {
		parent = 'object',
		load = function(this, proto, class)
			class = class or 'physics'
			proto = proto or {}
			proto.v = proto.v or {x = 0, y = 0}
			proto.mass = proto.mass or 1
			
			return classes.object(proto, class)
		end,
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
			this.carrier = this:collide('obj.type == "platform"')
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
			
			classes.object.update(this, dt)
		end,
	},

	portal = {
		parent = 'physics',
		load = function(this, proto, class)
			class = class or 'portal'
			proto = proto or {}
			proto.type = 'portal'
			proto.img = proto.img or 'portal.png'
			
			return classes.physics(proto, class)
		end,
		update = function(this, dt)
			classes.physics.update(this, dt)
		end,
	},

	-- ENTITY
	entity = {
		parent = 'physics',
		load = function(this, proto, class)
			class = class or 'entity'
			proto = proto or {}
			proto.p = proto.p or {x = 128, y = -128, w = 0, h = 0}
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
			-- constrain
			if this.p.y < world.ceiling then
				this.p.y = world.ceiling
			end
			
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
	},

	player = {
		parent = 'entity',
		load = function(this, proto, class)
			class = class or 'player'
			proto = proto or {}
			proto.p = {x = 128, y = -256, w = 0, h = 0}
			proto.hp = proto.hp or 100
			proto.type = 'player'
			proto.img = 'player.png'
			
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
		use = function(this, dt, key, label)
			portal = this:collide('obj.type == "portal"')
			if portal then
				if portal.level then
					local levelfile = 'map/'..portal.level..'.lvl'
					if love.filesystem.exists(levelfile) then
						world:load(levelfile)
					else
						world:unload()
						state.current = 'map'
					end
				else
					world:unload()
					if state.mapfile then
						state.current = 'map'
					else
						state.current = 'loadmap'
					end
				end
			end
		end,
	},

	healtree = {
		parent = 'entity',
		load = function(this, proto, class)
			class = class or 'healtree'
			proto = proto or {}
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
		heal = function(this)
			table.insert(world.effects, classes.AOEheal({p = {x = this.p.x + (this.p.w / 2), y = this.p.y}, v = {x = (math.random() * 512) - 256, y = 0}, healing = this.healing}))
		end,
	},

	enemy = {
		parent = 'entity',
		load = function(this, proto, class)
			class = class or 'healtree'
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
			local target = this:collide('obj == player')
			if target then
				target.hp = target.hp - (this.damage * dt)
			end
			
			classes.entity.update(this, dt)
		end,
		left = function(this, dt)
			this.v.x = 0 - this.speed
		end,
		right = function(this, dt)
			this.v.x = this.speed
		end,
	},
}

return def