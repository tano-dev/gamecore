return {
	-- General
	Level = 1,
	IconId = 17536032311, -- Leave as 'nil' for no icon (show text)
	
	Cost = nil, -- Cost & Sell can either be nil (can't be bought / sold)
	Sell = {"Statistic", "Gold", 5}, -- Same as above, but if Sell is nil, but Cost isn't, then Sell is automatically 50% the Cost price
	-- * {Type, Name, Cost, OnlyOnce*} --> (Type == "Statistic" if a statistic like Gold) *OnlyOnce is for buying items, optional
	
	-- Behavior
	Type = "Consumable",
	Tip = nil,

	Suite = {"Healing", { -- Properties, suite name
		Health = 15
	}},

	WeaponType = "Food",
	IsPotion = false,
	
	Cooldown = 0.5,
	Reusable = false, -- Set to true for the consumable to be usable an infinite amount of times (w/ cooldown)
	Autofire = true,	
	
	-- Other
	ConsumeDelay = 0.5,
	
	ActivateAnimations = {}, -- Insert animation IDs here
	ActivateSound = {609587143, 0.3}, -- Raw Id format of sound on weapon activation (ex. 123456789)
	
	CustomBackground = nil, -- UIGradient name under RS --> Assets --> Gradients (first color in gradient used for tooltip color)
	SpecialColor = nil, -- Border color for the item icon - primarily used for secret/seasonal items
}