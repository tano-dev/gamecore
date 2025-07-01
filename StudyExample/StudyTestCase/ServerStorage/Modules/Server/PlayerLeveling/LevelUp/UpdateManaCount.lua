--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

--------------------------------------------------------------------------------

return function(Player, Level)
	local Character = Player.Character
	local Humanoid = Character and Character:FindFirstChild("Humanoid")

	local Attributes = Humanoid and Humanoid:FindFirstChild("Attributes")
	if Attributes then
		Attributes.Health:SetAttribute("Level", Level.Value * GameConfig.ManaPerLevel)
	end

	local ManaAttributes = Humanoid and Humanoid:FindFirstChild("Mana")
	if ManaAttributes then
		ManaAttributes.MaxMana:SetAttribute("Level", Level.Value * GameConfig.ManaPerLevel)
	end
end