return {
	-- General
	Level = 5,
	IconId = 91748761757314, -- Leave as 'nil' for no icon (show text)
	
	Cost = nil, -- Cost & Sell can either be nil (can't be bought / sold)
	Sell = {"Statistic", "Gold", 50}, -- Same as above, but if Sell is nil, but Cost isn't, then Sell is automatically 50% the Cost price
	-- * {Type, Name, Cost, OnlyOnce*} --> (Type == "Statistic" if a statistic like Gold) *OnlyOnce is for buying items, optional
	
	-- Behavior
	Type = "Consumable",
	Tip = nil,

	Suite = {"Mana", { -- Properties, suite name
		Addition = 200,
		Duration = 60,
	}},

	WeaponType = "Food",
	IsPotion = true,
	
	Cooldown = 1,
	Reusable = false, -- Set to true for the consumable to be usable an infinite amount of times (w/ cooldown)
	Autofire = true,	
	
	-- Other
	ConsumeDelay = 0.5,
	
	ActivateAnimations = {}, -- Insert animation IDs here
	ActivateSound = {10722059, 0.3}, -- Raw Id format of sound on weapon activation (ex. 123456789)
	
	CustomBackground = nil, -- UIGradient name under RS --> Assets --> Gradients (first color in gradient used for tooltip color)
	SpecialColor = Color3.fromRGB(97, 131, 255), -- Border color for the item icon - primarily used for secret/seasonal items
}