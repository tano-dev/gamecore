return {
	-- General
	Type = "Armor",
	
	Level = 3,
	IconId = 100574504753020, -- Leave as 'nil' for no icon (show text)
	
	Cost = {"Statistic", "Gold", 50}, -- Cost & Sell can either be nil (can't be bought / sold)
	Sell = nil, -- Same as above, but if Sell is nil, but Cost isn't, then Sell is automatically 50% the Cost price
	-- * {Type, Name, Cost, OnlyOnce*} --> (Type == "Statistic" if a statistic like Gold) *OnlyOnce is for buying items, optional
	
	-- Armor (Relative +/- Values)
	Health = 50,
	WalkSpeed = 1,
	JumpPower = 0,
	Mana = 10,
	
	Defense = {2, true}, -- Set the second varible to true if the defense is point based instead of *
	
	Keybinds = nil, -- Set to {[Key (ie. "R")] = {"Keybind Name", Cooldown: Number, IconID: Number?, HoldTime: Number?}}: Called through Libraries --> Keybinds
	
	-- Classes
	DamageClass = "Melee", -- Ranged, Melee, Magic, All
	DamagePoints = {3, true}, -- Second variable asks whether points are added to tally instead of multiplied
	
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