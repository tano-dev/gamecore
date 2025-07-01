--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

--> Configuration
local INTEL_REGEN_BOOST = GameConfig.Attributes.Intelligence.Boost[2]

--------------------------------------------------------------------------------

return function(Player, ManaIncrease)
	local pData = PlayerData:WaitForChild(Player.UserId)
	local Attributes = pData:WaitForChild("Attributes")

	local Boost = INTEL_REGEN_BOOST * Attributes.Intelligence.Value * GameConfig.Attributes.Intelligence.Amplifier
	return ManaIncrease * math.clamp(1 + Boost, 1, 5)
end