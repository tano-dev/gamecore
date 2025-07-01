-- [CLIENT] --> Shared to all clients

--> Services
local Players = game:GetService("Players")

--> References
local LocalPlayer = Players.LocalPlayer

--> Configuration
local GlobalKeybinds = {
	MakeInputButton = true, -- Input button shown for the player using CustomCAS module
	CustomText = "' '", -- Set to nil to disable: sets custom text for input button
	Priority = 1, -- Order of the button
	Icon = nil, -- Set to an image ID if you wan't the input button to use an icon instead of name

	MakeClickSound = false, -- Whether activating the keybind itself make a click sound
	CanPress = false, -- Can press the input button

	ActivateCooldownWhenLetGo = false, -- If set to false, cooldown will start when the player activates OnPressed.
	Cooldown = 1, -- Cooldown, in seconds, until the user can activate again

	Key = "Space", -- Valid keybinds which will activate this function, set to nil to only use input button
}

GlobalKeybinds.Disabled = true -- Left here for developers to have an example; set to false or remove this line for the keybind to work.

--------------------------------------------------------------------------------

function GlobalKeybinds:RequestValidation(Player)
	return true
end

function GlobalKeybinds:OnActivated(Player)
	print("Client: player has double jumped!")
end

function GlobalKeybinds:OnLetGo(Player)
	print("Client: player has let go of space bar!")
end

return GlobalKeybinds