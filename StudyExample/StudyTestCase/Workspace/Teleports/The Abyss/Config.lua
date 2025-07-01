return {
	Name = "The Abyss", -- Name of the destination (shown in interfaces)
	Level = 10, -- Level needed to use the portal
	Items = {{"Tool", "Bronze Sword", 1}}, -- Set to nil to disable
	
	TP = Vector3.new(0.494, 1, 35.257), -- Position that the player will be teleported to
	Color = script.Parent:WaitForChild("Base").Color -- The color used in the teleport transition / Color3.fromRGB(x,x,x)
}