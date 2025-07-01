return {
	-- General
	Type = "Tool",
	Tip = nil,
	
	Level = 1,
	IconId = 128851111, -- Leave as 'nil' for no icon (show text)
	
	Cost = nil, -- Cost & Sell can either be nil (can't be bought / sold)
	Sell = {"Statistic", "Gold", 15}, -- Same as above, but if Sell is nil, but Cost isn't, then Sell is automatically 50% the Cost price
	-- * {Type, Name, Cost, OnlyOnce*} --> (Type == "Statistic" if a statistic like Gold) *OnlyOnce is for buying items, optional
	
	-- Weapon
	WeaponType = "Magic",
	Damage = {4, 6}, -- Can be a table ({Min Damage, Max Damage}) or a number (Damage)
	Cooldown = 0.8, -- (in seconds)
	
	ToolLook = true, -- The character's arm will point to the mouse on the Y axis
	Autofire = true, -- Autofire lets you hold down the mouse button to continuously use the weapon
	
	CriticalChance = {1, 8}, -- 1/xx (doesn't show in tooltip if the same as GameConfig's chance)
	DefensePenetration = {10, true}, -- The amount of defense does the weapon ignores from mobs w/ defense (compatible to both % and damage point defenses)
	-- [[ Value 2: Set to true if defense reduction is by damage points instead of multiplier]]
	
	Keybinds = nil, -- Set to {[Key (ie. "R")] = {"Keybind Name", Cooldown: Number, IconID: Number?, HoldTime: Number?}}: Called through Libraries --> Keybinds
	DamageTypes = nil, -- If a mob has one of these types, it'll do * more/less damage. Multiple can be added via {{Name, Multiplier}, ...}, set to nil to disable.
	
	CallbackName = nil, -- Set to a string name to override the module's name being used in Callbacks (for example, making it 'Default' uses the moduled named so) 
	
	-- Magic
	Suite = {"Arbiter", { -- Configuration, suite name
		BlastRadius = 10,
		Data = {
			CircleColors = {
				Color3.fromRGB(201, 179, 255),
				BrickColor.new("Black").Color
			},
			CircleAmount = 10,
			EffectEmit = 150,
		},
		
		Projectile = "Elemental",
		VFX = "Elemental",
	}},
	
	ManaCost = 15,
	
	-- Other
	Animations = {
		Activate = {186934753},

		Equip = nil,
		Unequip = nil,

		Walk = nil,
		Idle = nil,
		Jump = nil,
		Fall = nil,
	},
	
	Motor6D = nil, -- Set to nil to not use. Basically, animate a motor called 'Converted_Motor6D' connected to a tool handle, use these ^^ and you're set
	
	ActivateSound = {12222216, 0.3}, -- Content Id format of sound on weapon activation (ex. rbxassetid://123456789)
	EquipSound = {"rbxasset://sounds//unsheath.wav", 0.3}, -- Same as above, but for equipping (unsheath)
	
	CustomBackground = nil, -- UIGradient name under RS --> Assets --> Gradients (first color in gradient used for tooltip color)
	SpecialColor = Color3.fromRGB(97, 131, 255), -- Border color for the item icon - primarily used for secret/seasonal items
}