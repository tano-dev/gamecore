return {
	-- General
	Type = "Tool",
	Tip = nil,
	
	Level = 1,
	IconId = 12894186609, -- Leave as 'nil' for no icon (show text)
	
	Cost = nil, -- Cost & Sell can either be nil (can't be bought / sold)
	Sell = nil, -- Same as above, but if Sell is nil, but Cost isn't, then Sell is automatically 50% the Cost price
	-- * {Type, Name, Cost, OnlyOnce*} --> (Type == "Statistic" if a statistic like Gold) *OnlyOnce is for buying items, optional
	
	-- Weapon
	WeaponType = "Melee",
	Damage = {1, 2}, -- Can be a table ({Min Damage, Max Damage}) or a number (Damage)
	Cooldown = 0.8, -- (in seconds)
	
	Knockback = nil, -- Set to nil to disable (Knocks from player's point --> mob)
	
	ToolLook = false, -- The character's arm will point to the mouse on the Y axis
	Autofire = true, -- Autofire lets you hold down the mouse button to continuously use the weapon
	Sequential = false, -- [Melee]: Whether animations will run in a sequence, ie. 1 .. 2 .. 3 (true) or random ie 2 .. 1 .. 3 (false/nil)
	
	DelayedSwing = {0.25, 0.5}, -- In seconds, how much before damage is activated, and how much before de-activated (hits are valid within this time range), set to nil to disable
	CriticalChance = {1, 4}, -- 1/xx (doesn't show in tooltip if the same as GameConfig's chance)
	DefensePenetration = {0, true}, -- The amount of defense does the weapon ignores from mobs w/ defense (compatible to both % and damage point defenses)
	-- * Value 2: Set to true if defense reduction is by damage points instead of multiplier
	
	Keybinds = nil, -- Set to {[Key (ie. "R")] = {"Keybind Name", Cooldown: Number, IconID: Number?, HoldTime: Number?}}: Called through Libraries --> Keybinds
	DamageTypes = nil, -- If a mob has one of these types, it'll do * more/less damage. Multiple can be added via {{Name, Multiplier}, ...}, set to nil to disable.
	CallbackName = nil, -- Set to a string name to override the module's name being used in Callbacks (for example, making it 'Default' uses the moduled named so) 
	
	DamageScaling = {
		--[[
		["Kills"] = { -- Uses the item under Stats or Attributes (ie. Dexterity)
			Type = "Stats", -- "Stats" or "Attributes" (generally, any folder in pData works)
			
			Multiplier = 0.2, -- *1 + (Added amount depending on points added to stat), can set to nil
			Additive = 25, -- 25 + (Added amount depending on points added to stat), can set to nil
			
			Cap = 25, -- Maximum points allocated before effects can't reach past xx * ^^
		},
		]]
	}, 
	-- * Set to nil to disable
	
	BlockAndParry = {
		CanParry = true, -- Won't try to parry after unblocking
		Keybind = Enum.KeyCode.F,
		
		-- Block config
		DisableTime = 0.8, -- Can't use again if blocked hit / failed parry for this long
		Absorption = 0.6, -- % of damage that is absorbed when blocking (in decimal)
		
		-- Parry config
		ParryToMob = nil, -- {Animations (rbxassetid://xx)} -- If set, the mob will play this animation after being parried (make sure it has a higher priority than Action)
		Animation = {186934658, 0.2}, -- [Animation]: ID, freeze time (2nd half is played if successful parry, else, stops & weapon is disabled)
		-- * If you desire to use custom animations (hold, block, parry) simply change Animation = {xxx, xxx} for {Hold = xx, Block = xx, Parry = xx, LetGo = xx? (optional)}
	
		ParryWindow = 0.35, -- Seconds delay that the player can parry after unblocking
		Multiplier = 1.2, -- * Regular damage if successful parry
		Knockback = 3, -- Set to nil to disable
		StunTime = 1, -- Set to nil to disable
	}, 
	-- * Set to nil to disable
	
	-- Rig
	Animations = {
		Activate = {186934658, 186934753},

		Equip = nil,
		Unequip = nil,

		Walk = nil,
		Idle = nil,
		Jump = nil,
		Fall = nil,
	},
	
	Motor6D = {
		{
			ToolPart = "Handle",
			BodyPart = "Right Arm",

			C0 = nil, -- Defaults to normal C0 if nil
			C1 = nil, -- Defaults to normal C1 if nil

			OffsetC0 = nil, -- Offset related to current C0, adds (set to nil to disable)
			OffsetC1 = nil, -- Offset related to current C1, adds (set to nil to disable)
		},
	},
	-- * Set to nil to not use. Basically, animate a motor called 'Converted_Motor6D' connected to a tool handle, use these ^^ and you're set
	
	-- SFX & visual
	HitSFX = nil, -- Set to table with hit sounds, or nil to use default

	ActivateSound = {12222216, 0.3}, -- Content Id format of sound on weapon activation (ex. rbxassetid://123456789)
	EquipSound = {"rbxasset://sounds//unsheath.wav", 0.3}, -- Same as above, but for equipping (unsheath)

	CustomBackground = nil, -- UIGradient name under RS --> Assets --> Gradients (first color in gradient used for tooltip color)
	SpecialColor = nil, -- Border color for the item icon - primarily used for secret/seasonal items
}