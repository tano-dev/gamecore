return {
	-- General
	Type = "Tool",
	Tip = nil,
	
	Level = 5,
	Tier = 2,
	IconId = 123564554578797, -- Leave as 'nil' for no icon (show text)
	
	Cost = nil, -- Cost & Sell can either be nil (can't be bought / sold)
	Sell = {"Statistic", "Gold", 70}, -- Same as above, but if Sell is nil, but Cost isn't, then Sell is automatically 50% the Cost price
	-- * {Type, Name, Cost, OnlyOnce*} --> (Type == "Statistic" if a statistic like Gold) *OnlyOnce is for buying items, optional
	
	-- Weapon
	WeaponType = "Melee",
	
	ToolType = "Pickaxe",
	ValidPropTypes = {"Ore"}, -- PropTypes the tool can mine/destroy
	
	Damage = {2, 5}, -- Can be a table ({Min Damage, Max Damage}) or a number (Damage)
	Cooldown = 1, -- (in seconds)
	
	DelayedSwing = {0.25, 0.5}, -- In seconds, how much before damage is activated, and how much before de-activated (hits are valid within this time range), set to nil to disable
	
	ToolLook = false, -- The character's arm will point to the mouse on the Y axis
	Autofire = true, -- Autofire lets you hold down the mouse button to continuously use the weapon
	
	CallbackName = nil, -- Set to a string name to override the module's name being used in Callbacks (for example, making it 'Default' uses the moduled named so) 
	
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
	SpecialColor = nil, -- Border color for the item icon - primarily used for secret/seasonal items
}