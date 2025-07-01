return {
	-- General
	Type = "Armor",
	
	Level = 1,
	IconId = 90605715035173, -- Leave as 'nil' for no icon (show text)
	
	Cost = nil, -- Cost & Sell can either be nil (can't be bought / sold)
	Sell = nil, -- Same as above, but if Sell is nil, but Cost isn't, then Sell is automatically 50% the Cost price
	-- * {Type, Name, Cost, OnlyOnce*} --> (Type == "Statistic" if a statistic like Gold) *OnlyOnce is for buying items, optional
	
	-- Armor (Relative +/- Values)
	Health = 25,
	WalkSpeed = 0,
	JumpPower = 0,
	Mana = 0,
	
	Defense = {0, nil}, -- Set the second varible to true if the defense is point based instead of *
	
	Keybinds = nil, -- Set to {[Key (ie. "R")] = {"Keybind Name", Cooldown: Number, IconID: Number?, HoldTime: Number?}}: Called through Libraries --> Keybinds
	
	-- Classes
	DamageClass = "Ranged", -- Ranged, Mele, Magic, or All
	DamagePoints = {2, true}, -- Second variable asks whether points are added to tally instead of multiplied
	
	-- Morph
	AccessoryTypesVisible = { -- Are the character's accessories shown? (say you want them hidden if they're wearing a helmet)
		["Hat"] = false,
		["Hair"] = false,
		["Face"] = false,
		["Back"] = true,
		["Front"] = true,
		["Waist"] = true,
		["Shoulder"] = true,
	},
	
	BodyPartsVisible = { -- Toggles which body parts are visible (say you want armor that doesn't completely hide the body)
		["Head"] = true,
		["Left Arm"] = false,
		["Left Leg"] = false,
		["Right Arm"] = false,
		["Right Leg"] = false,
		["Torso"] = false
	},
	
	ShirtID = nil, -- xxx number, or set to nil to disable
	PantsID = nil, -- xxx number, or set to nil to disable
	
	CustomBackground = nil, -- UIGradient name under RS --> Assets --> Gradients (first color in gradient used for tooltip color)
	SpecialColor = nil, -- Border color for the item icon - primarily used for secret/seasonal items
}