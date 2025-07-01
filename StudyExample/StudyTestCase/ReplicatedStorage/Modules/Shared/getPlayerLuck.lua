--[[
	ej0w @ October 2024
	GetPlayerLuck
	
	Get luck modifier, modify this script in the event of anything new.
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

--------------------------------------------------------------------------------

return function(Products)
	local AllocatedLuck = 1
	
	-- Products
	local ProductMultiplier = 0
	for _, Product in Products do
		local Buffs = Product.Buffs
		if (not Buffs) or (not Buffs.Luck) then
			continue
		end
		ProductMultiplier += Buffs.Luck
	end
	
	-- Game luck
	ProductMultiplier = GameConfig.LuckMultiplier * (1 + ProductMultiplier)
	
	-- Add & return
	AllocatedLuck = AllocatedLuck * ProductMultiplier
	return AllocatedLuck
end