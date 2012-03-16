function love.conf(t)
	t.title = "Gscrooter"				-- The title of the window the game is in (string)
	t.author = "trubblegum"				-- The author of the game (string)
	t.identity = "Gscrooter"			-- The name of the save directory (string)
	t.version = "0.7.2"					-- The L�VE version this game was made for (number)
	t.console = false					-- Attach a console (boolean, Windows only)
	t.screen.width = 960				-- The window width (number)
	t.screen.height = 640--480				-- The window height (number)
	t.screen.fullscreen = false			-- Enable fullscreen (boolean)
	t.screen.vsync = false				-- Enable vertical sync (boolean)
	t.screen.fsaa = 0					-- The number of FSAA-buffers (number)
	t.modules.joystick = false			-- Enable the joystick module (boolean)
	t.modules.audio = true				-- Enable the audio module (boolean)
	t.modules.keyboard = true			-- Enable the keyboard module (boolean)
	t.modules.event = true				-- Enable the event module (boolean)
	t.modules.image = true				-- Enable the image module (boolean)
	t.modules.graphics = true			-- Enable the graphics module (boolean)
	t.modules.timer = true				-- Enable the timer module (boolean)
	t.modules.mouse = true				-- Enable the mouse module (boolean)
	t.modules.sound = true				-- Enable the sound module (boolean)
	t.modules.physics = false			-- Enable the physics module (boolean)
end