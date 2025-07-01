-- [SERVER]

--> Configuration
local GlobalKeybinds = {}

GlobalKeybinds.Disabled = true -- Left here for developers to have an example; set to false or remove this line for the keybind to work.

--------------------------------------------------------------------------------

function GlobalKeybinds:OnActivated(Player)
	print("Server: player has double jumped!")
end

function GlobalKeybinds:OnLetGo(Player)
	print("Server: player has let go of space bar!")
end

return GlobalKeybinds