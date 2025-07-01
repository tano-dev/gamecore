--[[
	ej0w @ September 2024
	BoostFunctions
	
	Handles any immediately accessable boosts that the player uses. Detects all changes from the attribute.
	Find these boosts from Player --> Boosts --> xxx
		- Potions
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local BoostFunctions = {}

--------------------------------------------------------------------------------

function BoostFunctions:Mana(Player, Type, Value)
	local Character = Player.Character
	local Humanoid = Character and Character:FindFirstChild("Humanoid")
	if not Humanoid or Humanoid.Health <= 0 then return end

	local ManaAttributes = Humanoid:FindFirstChild("Mana")
	if not ManaAttributes then return end
	
	ManaAttributes.MaxMana:SetAttribute("ManaPotion", Value)
	
	local MaxMana = 0
	for Name, Value in ManaAttributes.MaxMana:GetAttributes() do
		if Value ~= Value then Value = 0 end
		MaxMana += Value
	end
	
	if Value ~= 0 then
		ManaAttributes.Mana:SetAttribute("Default", MaxMana)
	end
end

function BoostFunctions:Health(Player, Type, Value)
	if Type == "Addition" then
		local Character = Player.Character
		
		local Humanoid = Character and Character:FindFirstChild("Humanoid") :: Humanoid
		local Attributes = Humanoid and Humanoid:WaitForChild("Attributes", 1)
		if not Attributes or Humanoid.Health <= 0 then return end
		
		Attributes.Health:SetAttribute("Spell", Value)
	end
end

return BoostFunctions