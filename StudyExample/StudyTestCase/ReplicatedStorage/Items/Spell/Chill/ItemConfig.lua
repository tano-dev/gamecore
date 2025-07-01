return {
	-- General
	Type = "Spell",
	Tip = "Slows",
	
	Level = 8,
	IconId = 2582781092, -- Leave as 'nil' for no icon (show text)
	
	Cost = {"Statistic", "Gold", 150}, -- Cost & Sell can either be nil (can't be bought / sold)
	Sell = nil, -- Same as above, but if Sell is nil, but Cost isn't, then Sell is automatically 50% the Cost price
	-- * {Type, Name, Cost, OnlyOnce*} --> (Type == "Statistic" if a statistic like Gold) *OnlyOnce is for buying items, optional
	
	-- Spell
	Suite = {"Freeze", { -- Properties, suite name
		Projectile = "Iceball",
		Velocity = 180,
		Acceleration = Vector3.new(0, -workspace.Gravity/8, 0),
		
		Damage = 1, -- Per tick
		Proportionate = false, -- If set to true, *x damage of the player's best weapon.
		
		Delay = 0.75, -- Tick duration
		Ticks = 5,
	}},
	
	WeaponType = "Spell",
	ManaCost = 85,
	Cooldown = 2.5,
	
	Throwable = true,
	Autofire = true,
	
	-- Other
	Animations = {
		Activate = {186934658, 186934753},

		Equip = nil,
		Unequip = nil,

		Walk = nil,
		Idle = nil,
		Jump = nil,
		Fall = nil,
	},
	
	ActivateSound = {3356359494, 0.3}, -- Content Id format of sound on weapon activation (ex. rbxassetid://123456789)
	EquipSound = {9116394545, 0.3}, -- Same as above, but for equipping (unsheath)
	
	CustomBackground = nil, -- UIGradient name under RS --> Assets --> Gradients (first color in gradient used for tooltip color)
	SpecialColor = nil, -- Border color for the item icon - primarily used for secret/seasonal items
}