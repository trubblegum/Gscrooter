local def = {
	snortal = {
		parent = 'object', -- object is the lowest level, containing basic draw and collide functions
		load = function(this, proto, class) -- this is passed by lua, + optional prototype, class if being called by a higher-level constructor
			class = class or 'snortal' -- the class which this object will inherit from, or object() won't know where to assign dependency
			proto = proto or {} -- start with supplied prototype, or create a new table
			
			proto.type = 'snortal' -- filter group
			-- note : 'snortal' is not an established group, but 'platform', 'player', 'friendly', and 'enemy' are
			
			proto.img = proto.img or 'portal.png' -- set the object's image
			
			return classes.object(proto, class) -- return a world-ready instance, created by the dependency chain (classes is the global class structure, where object classes live)
			-- note : all constructors must trickle down to object
		end,
		update = function(this, dt) -- update was called from the instance, so now this is our instance
			
			this:collide('durrr') -- this will cause condition() to return nil, resulting in no collisions
			this:collide() -- as above
			this:collide('true') -- this will cause condition() to return true, resulting in collision with first object encountered
			this:collide('obj.type == "platform"') -- this will cause condition() to return true if obj is a platform, resulting in collision with the first platform encountered
			this:collide(function(obj) return obj.type == 'platform' end) -- as above, but more efficient
			--this:collide(true) -- invalid
			-- usage :
			local platform = this:collide('obj.type == "platform"')
			if platform then
				print(platform.p.w)
			end
			-- note : snortal is a horrible object, which just eats update cycles
			
			classes.object.update(this, dt) -- calling update() from a lower level, so we don't have to redefine basic object behaviours
		end,
	},
}
return def