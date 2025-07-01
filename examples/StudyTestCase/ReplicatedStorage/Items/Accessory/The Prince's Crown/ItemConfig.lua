return {
	-- General
	Type = "Accessory",
	Level = 15,
	IconId = 130230582353932, -- Leave as 'nil' for no icon (show text)
	
	Cost = {"Statistic", "Gold", 1_000, true}, -- Cost & Sell can either be nil (can't be bought / sold)
	Sell = nil, -- Same as above, but if Sell is nil, but Cost isn't, then Sell is automatically 50% the Cost price
	-- * {Type, Name, Cost, OnlyOnce*} --> (Type == "Statistic" if a statistic like Gold) *OnlyOnce is for buying items, optional
	
	-- Armor (Relative +/- Values)
	Health = 200,
	WalkSpeed = 0,
	JumpPower = 0,
	Mana = 750,
	
	Keybinds = nil, -- Set to {[Key (ie. "R")] = {"Keybind Name", Cooldown: Number, IconID: Number?, HoldTime: Number?}}: Called through Libraries --> Keybinds
	
	-- Morph
	AccessoryTypesVisible = { -- Are the character's accessories shown? (say you want them hidden if they're wearing a helmet)
		["Hat"] = true,
		["Hair"] = true,
		["Face"] = true,
		["Back"] = true,
		["Front"] = true,
		["Waist"] = true,
		["Shoulder"] = true,
	},
	
	-- Other
	CustomBackground = nil, -- UIGradient name under RS --> Assets --> Gradients (first color in gradient used for tooltip color)
	SpecialColor = nil, -- Border color for the item icon - primarily used for secret/seasonal items
}