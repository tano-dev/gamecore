return {
	-- General
	Name = "Iron Ore Deposit", -- Name of the mob shown in its interface
	PropType = "Ore",
	
	Level = {0, 1}, -- Mob Level, followed by Min Level (req to kill/access the mob - this is typically the realm level / boss portal level)
	Tier = 1, -- Required (or above) pickaxe tier to mine ore
	
	-- Data
	Color = Color3.fromRGB(255, 176, 131), -- Color for text & material
	
	HealthBarColor = nil, -- Set to use custom healthbar color
	HighlightColor = nil, -- Set to use custom damage highlight color
	
	StrikeSounds = {7650217335, 7650220708, 7650230644, 7650226201},
	
	PropEffectName = nil, -- Set to a string to use a prop effect based off of module name, else, tries with the mob's name, or default.
	
	-- Statistics
	Health = 25, -- Amount of max health the mob spawns with
	
	-- Behavior
	RespawnTime = 7, -- Time (in seconds) until the mob respawns after death
	
	KeepPosition = true, -- Whether the entity will always spawn at the same position
	RespawnRadius = 5, -- In studs, how far away could the ore spawn from origin
	
	-- On Death
	Drops = {
		Statistics = { -- {Name, Amount (range/number)*, Chance (xx/yy)*, OnlyOnce*}
			{"XP", 10}, 
			{"Gold", 5}
		},
		
		Items = { -- {Type, Name, Amount (range/number)*, Chance (xx/yy)*, OnlyOnce*}
			{"Material", "Iron", {1, 2}}
		},
	},
}