return {
	-- General
	Type = "Tool",
	Tip = nil,
	
	Level = 10,
	IconId = 33649924, -- Leave as 'nil' for no icon (show text)
	
	Cost = nil, -- Cost & Sell can either be nil (can't be bought / sold)
	Sell = {"Statistic", "Gold", 100}, -- Same as above, but if Sell is nil, but Cost isn't, then Sell is automatically 50% the Cost price
	-- * {Type, Name, Cost, OnlyOnce*} --> (Type == "Statistic" if a statistic like Gold) *OnlyOnce is for buying items, optional
	
	-- Weapon
	WeaponType = "Ranged",
	Damage = 17, -- Can be a table ({Min Damage, Max Damage}) or a number (Damage)
	Cooldown = 3, -- (in seconds)
	
	ToolLook = true, -- The character's arm will point to the mouse on the Y axis
	Autofire = true, -- Autofire lets you hold down the mouse button to continuously use the weapon
	
	-- [CLIENTSIDE] Advanced - allows you to customize what happens to your projectile after it has gone out of the players' hands.
	CollisionFunction = function(Projectile, Ended, Position, Hit, HitMob)
		if Ended then 
			local Impacts = game:GetService("ReplicatedStorage").Assets.Effects.Impacts
			local Debris = game:GetService("Debris")
			
			local Part = Instance.new("Part")
			Part.Parent = workspace:WaitForChild("Temporary")
			Part.Size = Vector3.zero
			Part.Transparency = 1
			Part.CanCollide = false
			Part.Anchored = true
			Part.Position = Position
			Debris:AddItem(Part, 2)
			
			local Particle = Impacts.Rock:Clone()
			Particle.Parent = Part
			
			local Color = Projectile.UserData.CastingMesh.Color
			Particle.Color = ColorSequence.new(Color)
			Particle:Emit(Part:GetAttribute("Emit"))
		end		
	end,
	
	CriticalChance = {1, 5}, -- 1/xx (doesn't show in tooltip if the same as GameConfig's chance)
	DefensePenetration = {2, true}, -- The amount of defense does the weapon ignores from mobs w/ defense (compatible to both % and damage point defenses)
	-- [[ Value 2: Set to true if defense reduction is by damage points instead of multiplier]]
	
	CastingMesh = "Cannonball",
	Velocity = 420,
	Acceleration = Vector3.new(0, -workspace.Gravity/15, 0),
	SpreadAngle = NumberRange.new(0, 2),
	
	Shoot = 1, -- How many projectiles this item shoots
	Pierce = 3, -- 1 for no piercing, math.huge for only, inbetween for an amount
	Dropoff = 1, -- * per pierce, 1 for none
	
	Keybinds = nil, -- Set to {[Key (ie. "R")] = {"Keybind Name", Cooldown: Number, IconID: Number?, HoldTime: Number?}}: Called through Libraries --> Keybinds
	DamageTypes = nil, -- If a mob has one of these types, it'll do * more/less damage. Multiple can be added via {{Name, Multiplier}, ...}, set to nil to disable.
	
	CallbackName = nil, -- Set to a string name to override the module's name being used in Callbacks (for example, making it 'Default' uses the moduled named so) 
	
	-- Other
	Animations = {
		Activate = {220829805},

		Equip = nil,
		Unequip = nil,

		Walk = nil,
		Idle = nil,
		Jump = nil,
		Fall = nil,
	},
	
	Motor6D = nil, -- Set to nil to not use. Basically, animate a motor called 'Converted_Motor6D' connected to a tool handle, use these ^^ and you're set
	
	ActivateSound = {18425374322, 0.3}, -- Content Id format of sound on weapon activation (ex. rbxassetid://123456789)
	EquipSound = nil, -- Same as above, but for equipping (unsheath)
	
	CustomBackground = "Boss", -- UIGradient name under RS --> Assets --> Gradients (first color in gradient used for tooltip color)
	SpecialColor = nil, -- Border color for the item icon - primarily used for secret/seasonal items
}