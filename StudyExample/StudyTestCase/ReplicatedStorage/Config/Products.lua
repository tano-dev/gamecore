--[[
	ej0w @ October 2024
	Products

	Assetid products which can boost your stats depending on what's enabled
	Simply create a new table/modify current one (copypaste) and fill in the data how you wish
]]

--------------------------------------------------------------------------------

return {
	{
		Type = "Gamepass", -- Group, Premium, Gamepass, Badge
		AssetID = 8264081,
		
		Attributes = { -- + number [Additive]
			["Health"] = 0,
			["WalkSpeed"] = 0,
			["JumpPower"] = 0,
			["Mana"] = 0,
		},
		
		Buffs = { -- * (1 + number) [Multiply]
			["XP"] = 0.25,
			["Luck"] = 0,
			["Gold"] = 0,
			["Damage"] = 0.25,
		},
		
		Items = {{"Consumable", "Apple"}}, -- {{Type, Name}, ...}
	},
}
