--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

--> Configuration
local DEXTE_CRIT_BOOST = GameConfig.Attributes.Dexterity.Boost[2]
local DEXTE_CRIT_ADD = GameConfig.Attributes.Dexterity.Boost[1]

--------------------------------------------------------------------------------

return function(Player, Tool, UnitCriticalChance, CriticalDamage)
	local ModifiedChance = UnitCriticalChance[2]

	local pData = PlayerData:WaitForChild(Player.UserId)
	local Attributes = pData:WaitForChild("Attributes")
	
	local MethodOfGain = GameConfig.Attributes.Constitution.MethodOfGain
	local DexterityAmplifier = GameConfig.Attributes.Dexterity.Amplifier
	local Points = Attributes.Dexterity.Value
	
	-- Critical chance
	local Boost = 1 + (DEXTE_CRIT_BOOST * Points * DexterityAmplifier)
	ModifiedChance = math.clamp(ModifiedChance / Boost, 2, math.huge)
	
	-- Critical damage
	CriticalDamage *= 1 + (DEXTE_CRIT_BOOST * Points * DexterityAmplifier)
	
	return {1, ModifiedChance}, CriticalDamage
end