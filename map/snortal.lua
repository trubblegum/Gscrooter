local def = {
	snortal = {
		parent = 'object', -- object is the lowest level, containing basic draw and collide functions
		load = function(this, proto, class) -- this is passed by lua, + optional prototype, class if being called by a higher-level constructor
			class = class or 'snortal' -- the class which this object will inherit from, or object below doesn't know where to assign dependency
			proto = proto or {} -- start with supplied prototype, or create a new table
			
			proto.type = 'snortal' -- filter group
			-- note : 'snortal' is not an established group, but 'platform', 'player', 'friendly', and 'enemy' are
			
			proto.img = proto.img or 'portal.png' -- set the object's image
			
			return classes.object(proto, class) -- return a world-ready instance, created by the dependency chain (classes is the global class structure, where object classes live)
			-- note : all constructors must trickle down to object
			-- note : must be a loaded class
		end,
		update = function(this, dt) -- update was called from the instance, so now this is the instance
			
			-- not userfriendly, and therefore bogus
			--if this:collide(function(this, obj) return obj.type == 'platform' end) then
			--	print('yay me!')
			--end
			-- /not
			
			classes.object.update(this, dt) -- calling update() from a lower level, so we don't have to redefine basic object behaviours
		end,
	},
}
return def