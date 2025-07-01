--[[
	ej0w @ October 2024
	GetStatMultiplier
	
	Ported from Mob, used to determine how much of a stat a player should recieve
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

--------------------------------------------------------------------------------

return function(Products, Stat, StatCount)
	for _, Product in Products do
		local Buffs = Product.Buffs
		if not Buffs or not Buffs[Stat.Name] then
			continue
		end
		StatCount *= (1 + Buffs[Stat.Name])
	end
	
	StatCount *= (GameConfig[Stat.Name .. "Multiplier"] or 1)
	return math.round(StatCount)
end