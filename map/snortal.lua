local def = {
	snortal = {
		parent = 'object', -- object is the lowest level, containing basic draw and collide functions. classes:load() uses parent to assign inheritance
		load = function(this, proto, class) -- this is passed by lua, optional prototype, optional class if being called by a higher-level constructor
			class = class or this -- the class which this object will inherit from, or object() won't know where to assign dependency.
			proto = proto or {} -- start with supplied prototype, or create a new table
			
			proto.type = 'snortal' -- filter group
			-- note : 'snortal' is not an established group, but 'platform', 'player', 'friendly', 'item', and 'enemy' are
			
			proto.img = proto.img or 'portal.png' -- set the object's image, allowing override by supplied prototype
			
			proto.duration = 0
			
			return classes.object(proto, class) -- return a world-ready instance, created by the dependency chain (classes is the global class structure, where object classes live)
			-- note : all constructors must trickle down to object
		end,
		update = function(this, dt) -- update was called from the instance, so now this is our instance
			
			this:collide('durrr') -- this will cause condition() to return nil, resulting in no collisions
			this:collide('true') -- this will cause condition() to return true, resulting in collision with first object returned by intersect()
			this:collide() -- as above
			this:collide('obj.type == "platform"') -- this will cause condition() to return true if obj is a platform, resulting in collision with the first platform encountered
			this:collide('platform') -- as above, but more efficient, using a predefined condition
			this:collide(function(obj) return obj.type == 'platform' end) -- as above, but more flexible
			--this:collide(true) -- invalid
			-- Note that AOE.collide returns a table of all objects which intersect
			
			-- usage :
			local obj = this:collide('player') -- player is the player, which can be accessed from global scope
			if obj then
				this.duration = this.duration + dt
				print("you've been in my personal space for "..this.duration)
			end
			-- note : snortal is a horrible object, which just eats update cycles. try to keep calls to collide() down
			
			classes.object.update(this, dt) -- calling update() from a lower level, so we don't have to redefine basic object behaviours
		end,
	},
}
return def