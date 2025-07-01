--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

--> Configuration
local CONST_REGEN_BOOST = GameConfig.Attributes.Constitution.Boost[2]

--------------------------------------------------------------------------------

return function(self, DeltaHealth)
	local Player = self.Player
	local pData = PlayerData:WaitForChild(Player.UserId)
	local Attributes = pData:WaitForChild("Attributes")
	
	local Boost = CONST_REGEN_BOOST * Attributes.Constitution.Value * GameConfig.Attributes.Constitution.Amplifier
	return DeltaHealth * math.clamp(1 + Boost, 1, 5)
end