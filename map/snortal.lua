local def = {
	snortal = {
		parent = 'object',
		load = function(this, Gclass, proto, class) -- this is actually the class implementation instance
			class = class or 'snortal' -- the class which this object will inherit from. object doesn't know where the call came from
			proto = proto or {} -- a new object
			
			proto.type = 'snortal' -- filter group
			-- note : 'snortal' is not a recognised group, but 'platform', 'player', 'friendly', and 'enemy' are
			
			proto.img = proto.img or 'portal.png'
			
			return classes.object(proto, class) -- ask constructor for a conforming object with dependency
		end,
		update = function(this, dt) -- this was called from the object
			classes.object.update(this, dt) -- constructor overrode parent with a reference to the parent class
		end,
	},
}
return def