--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

--> Configuration
local STREN_DAMAGE_BOOST = GameConfig.Attributes.Strength.Boost[2]
local STREN_DAMAGE_ADD = GameConfig.Attributes.Strength.Boost[1]

--------------------------------------------------------------------------------

return function(Player, Tool, Damage)
	local pData = PlayerData:WaitForChild(Player.UserId)
	local Attributes = pData:WaitForChild("Attributes")
	
	local MethodOfGain = GameConfig.Attributes.Strength.MethodOfGain
	local StrengthAmplifier = GameConfig.Attributes.Strength.Amplifier
	local Points = Attributes.Strength.Value
	
	-- Calculate new damage
	if MethodOfGain == "Add" then
		Damage += STREN_DAMAGE_ADD * Points * StrengthAmplifier
	elseif MethodOfGain == "Multiply" then
		Damage *= 1 + (STREN_DAMAGE_BOOST * Points * StrengthAmplifier)
	end
	
	return Damage
end