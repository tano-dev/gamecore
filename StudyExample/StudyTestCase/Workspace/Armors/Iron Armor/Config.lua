return {
	Requirements = {
		Level = nil, -- Set to a (number) value if requested (preferably when RequiresDataValue == false/nil), can set to nil
		RequiresDataValue = true, -- Requires owning the item itself in order to use (if set to false, you're given the item when equipping the armor for the first time)
	},
	
	BodyPartsVisible = { -- For the armor stand itself
		["Head"] = false,
		["Left Arm"] = false,
		["Left Leg"] = false,
		["Right Arm"] = false,
		["Right Leg"] = false,
		["Torso"] = false
	},
	
	Name = script.Parent.Name,
}