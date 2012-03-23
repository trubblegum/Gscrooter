local def = {

	hopper = {
		parent = 'enemy',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.p = classes.position(proto.p, {w = 64, h = 64})
			proto.img = proto.img or 'hopper.png'
			proto.damage = proto.damage or 32
			proto.updateinterval = proto.updateinterval or 1
			proto.updateclock = proto.updateclock or 1
			
			return classes.enemy(proto, class)
		end,
		update = function(this, dt)
			if this.updateclock > this.updateinterval then
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
				this.updateclock = 0
			end
			classes.enemy.update(this, dt)
		end,
	},

	hopperspawn = {
		parent = 'enemy',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.p = classes.position(proto.p, {w = 128, h = 64})
			proto.img = proto.img or 'hopperspawn.png'
			proto.hp = proto.hp or 512
			proto.damage = proto.damage or 16
			proto.updateinterval = proto.updateinterval or 4
			proto.updateclock = proto.updateclock or 4
			
			return classes.enemy(proto, class)
		end,
		update = function(this, dt)
			if this.updateclock > this.updateinterval then
				local action = math.random() * 3
				if action < 1 then
					this:heal()
				elseif action < 3 then
					this:spawn()
				else
					-- yeah, right
				end
				this.updateclock = 0
			end
			classes.enemy.update(this, dt)
		end,
		heal = function(this)
			table.insert(world.effects, classes.enemyAOEheal({p = {x = this.p.x + (this.p.w / 2), y = this.p.y}, v = {x = (math.random() * 512) - 256, y = 0}, healing = this.healing}))
		end,
		spawn = function(this)
			table.insert(world.objects, classes.hopper({p = {x = this.p.x, y = this.p.y}}))
		end
	},

	bommer = {
		parent = 'enemy',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.p = classes.position(proto.p, {w = 96, h = 64})
			proto.img = proto.img or 'bommer.png'
			proto.mass = proto.mass or 0.5
			proto.hp = proto.hp or 32
			proto.updateinterval = proto.updateinterval or 1
			
			return classes.enemy(proto, class)
		end,
		update = function(this, dt)
			if this.updateclock > this.updateinterval then
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
				this.updateclock = 0
			end
			classes.enemy.update(this, dt)
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
	},

	bommerspawn = {
		parent = 'bommer',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.p = classes.position(proto.p, {w = 96, h = 128})
			proto.img = proto.img or 'bommerspawn.png'
			proto.mass = proto.mass or 0.4
			proto.bounce = proto.bounce or 1
			proto.hp = proto.hp or 256
			proto.updateinterval = proto.updateinterval or 2
			
			return classes.bommer(proto, class)
		end,
		update = function(this, dt)
			if this.updateclock > this.updateinterval then
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
				this.updateclock = 0
			end
			classes.enemy.update(this, dt)
		end,
		spawn = function(this)
			table.insert(world.objects, classes.bommer({p = {x = this.p.x, y = this.p.y}}))
		end,
	},

	buzzer = {
		parent = 'enemy',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.p = classes.position(proto.p, {w = 64, h = 32})
			proto.img = proto.img or 'buzzer.png'
			proto.speed = proto.speed or 512
			proto.mass = proto.mass or 0.5
			proto.hp = proto.hp or 32
			proto.updateinterval = proto.updateinterval or 0.5
			
			return classes.enemy(proto, class)
		end,
		update = function(this, dt)
			if this.updateclock > this.updateinterval then
				local action = math.random() * 6
				if action < 1 then
					this:jump()
				elseif action < 3 then
					this:left()
				elseif action < 5 then
					this:right()
				else
					-- yeah, right
				end
				this.updateclock = 0
			end
			classes.enemy.update(this, dt)
		end,
		jump = function(this, dt)
			this.v.y = 0 - (this.speed / 4)
		end,
		left = function(this, dt)
			this.v.x = 0 - this.speed
			this.v.y = 0 - (this.speed / 8)
		end,
		right = function(this, dt)
			this.v.x = this.speed
			this.v.y = 0 - (this.speed / 8)
		end,
	},

	buzzerspawn = {
		parent = 'buzzer',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.p = classes.position(proto.p, {w = 128, h = 64})
			proto.img = proto.img or 'buzzerspawn.png'
			proto.speed = proto.speed or 256
			proto.hp = proto.hp or 256
			proto.updateinterval = proto.updateinterval or 1
			
			return classes.buzzer(proto, class)
		end,
		update = function(this, dt)
			if this.updateclock > this.updateinterval then
				local action = math.random() * 3
				if action < 1 then
					this:spawn()
				elseif action < 2 then
					this:left()
				elseif action < 3 then
					this:right()
				else
					-- yeah, right
				end
				this.updateclock = 0
			end
			classes.enemy.update(this, dt)
		end,
		spawn = function(this)
			table.insert(world.objects, classes.buzzer({p = {x = this.p.x, y = this.p.y}}))
		end,
		left = function(this, dt)
			this.v.x = 0 - this.speed
			this.v.y = 0 - (this.speed / 2)
		end,
		right = function(this, dt)
			this.v.x = this.speed
			this.v.y = 0 - (this.speed / 2)
		end,
	},

	slither = {
		parent = 'enemy',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.p = classes.position(proto.p, {w = 64, h = 32})
			proto.img = proto.img or 'slither.png'
			proto.damage = proto.damage or 32
			proto.updateinterval = proto.updateinterval or 1
			proto.updateclock = proto.updateclock or 1
			
			return classes.enemy(proto, class)
		end,
		update = function(this, dt)
			if this.updateclock > this.updateinterval then
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
				this.updateclock = 0
			end
			classes.enemy.update(this, dt)
		end,
		spit = function(this)
			table.insert(world.effects, classes.AOEpoison({p = {x = this.p.x, y = this.p.y}, v = {x = (math.random() * 512) - 256, y = -256}}))
		end,
	},

	slitherspawn = {
		parent = 'enemy',
		load = function(this, proto, class)
			class = class or this
			proto = proto or {}
			proto.p = classes.position(proto.p, {w = 128, h = 64})
			proto.img = proto.img or 'slitherspawn.png'
			proto.hp = proto.hp or 512
			proto.damage = proto.damage or 16
			proto.updateinterval = proto.updateinterval or 8
			proto.updateclock = proto.updateclock or 6
			
			return classes.enemy(proto, class)
		end,
		update = function(this, dt)
			if this.updateclock > this.updateinterval then
				local action = math.random() * 3
				if action < 1 then
					this:heal()
				elseif action < 3 then
					this:spawn()
				else
					-- yeah, right
				end
				this.updateclock = 0
			end
			classes.enemy.update(this, dt)
		end,
		heal = function(this)
			table.insert(world.effects, classes.enemyAOEheal({p = {x = this.p.x + (this.p.w / 2), y = this.p.y}, v = {x = (math.random() * 512) - 256, y = 0}, healing = this.healing}))
		end,
		spawn = function(this)
			table.insert(world.objects, classes.slither({p = {x = this.p.x, y = this.p.y}}))
		end
	},
}

return def