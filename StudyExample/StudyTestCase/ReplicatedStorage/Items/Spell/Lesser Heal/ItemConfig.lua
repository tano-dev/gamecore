return {
	-- General
	Type = "Spell",
	Tip = nil,
	
	Level = 5,
	IconId = 61885374, -- Leave as 'nil' for no icon (show text)
	
	Cost = {"Statistic", "Gold", 80}, -- Cost & Sell can either be nil (can't be bought / sold)
	Sell = nil, -- Same as above, but if Sell is nil, but Cost isn't, then Sell is automatically 50% the Cost price
	-- * {Type, Name, Cost, OnlyOnce*} --> (Type == "Statistic" if a statistic like Gold) *OnlyOnce is for buying items, optional
	
	-- Spell
	Suite = {"Health", { -- Properties, suite name
		Additive = 0.4,
		Duration = 30,
		Percentage = 0.25,
	}},
	
	WeaponType = "Spell",
	ManaCost = 70,
	Cooldown = 15,
	
	Throwable = false,
	Autofire = true,
	
	-- Other
	Animations = {
		Activate = {61887471},

		Equip = nil,
		Unequip = nil,

		Walk = nil,
		Idle = nil,
		Jump = nil,
		Fall = nil,
	},
	
	ActivateSound = {9116394756, 0.3}, -- Content Id format of sound on weapon activation (ex. rbxassetid://123456789)
	EquipSound = {9116394545, 0.3}, -- Same as above, but for equipping (unsheath)
	
	CustomBackground = nil, -- UIGradient name under RS --> Assets --> Gradients (first color in gradient used for tooltip color)
	SpecialColor = nil, -- Border color for the item icon - primarily used for secret/seasonal items
}