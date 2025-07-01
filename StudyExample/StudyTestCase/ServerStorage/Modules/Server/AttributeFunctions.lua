--[[
	ej0w @ September 2024
	AttributeFunctions
	
	Handles longterm changes via attributes, accordance to MaxHealth, MaxMP, WalkSpeed, etc.
	Detects changes, returns callback function
	*Works similarly to Boostfunctions
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local AttributeFunctions = {}

--> Configuration
local CONST_HEALTH_ADD = GameConfig.Attributes.Constitution.Boost[1]
local INTEL_MANA_ADD = GameConfig.Attributes.Intelligence.Boost[1]

local CONST_HEALTH_MUL = GameConfig.Attributes.Constitution.Boost[2]
local INTEL_MANA_MUL = GameConfig.Attributes.Intelligence.Boost[2]

--------------------------------------------------------------------------------

function AttributeFunctions:Constitution(Player, Attributes)
	local Character = Player.Character or Player.CharacterAdded:Wait()

	local Humanoid = Character and Character:WaitForChild("Humanoid") :: Humanoid
	local HumanoidAttributes = Humanoid and Humanoid:WaitForChild("Attributes", 1)
	if not HumanoidAttributes or Humanoid.Health <= 0 then return end
	
	local HealthStatistic = HumanoidAttributes.Health
	local Points = Attributes.Constitution.Value
	
	local ConstitutionAmplifier = GameConfig.Attributes.Constitution.Amplifier
	local MethodOfGain = GameConfig.Attributes.Constitution.MethodOfGain
	
	-- Adjust health max
	if MethodOfGain == "Add" then
		local Boost = CONST_HEALTH_ADD * Points * ConstitutionAmplifier
		HealthStatistic:SetAttribute("Attribute", math.round(Boost))
	elseif MethodOfGain == "Multiply" then
		local MaxHealth = 100
		for Name, Value in HealthStatistic:GetAttributes() do
			if Name ~= "Attribute" then
				MaxHealth += Value
			end
		end
		
		local Boost = MaxHealth * (CONST_HEALTH_MUL * Points * ConstitutionAmplifier)
		HealthStatistic:SetAttribute("Attribute", math.round(Boost))
	end
	
	-- Adjust health to max
	local MaxHealth = 100
	for Name, Value in HealthStatistic:GetAttributes() do
		MaxHealth += Value
	end
	
	if Humanoid.Health > MaxHealth then
		Humanoid.Health = MaxHealth
	end
end

function AttributeFunctions:Intelligence(Player, Attributes)
	local Character = Player.Character or Player.CharacterAdded:Wait()
	
	local Humanoid = Character and Character:WaitForChild("Humanoid") :: Humanoid
	local ManaAttributes = Humanoid:WaitForChild("Mana")
	if not ManaAttributes or Humanoid.Health <= 0 then return end

	local MaxMana = ManaAttributes.MaxMana
	local Points = Attributes.Intelligence.Value

	local IntelligenceAmplifier = GameConfig.Attributes.Intelligence.Amplifier
	local MethodOfGain = GameConfig.Attributes.Intelligence.MethodOfGain

	-- Adjust MP max
	if MethodOfGain == "Add" then
		local Boost = INTEL_MANA_ADD * Points * IntelligenceAmplifier
		MaxMana:SetAttribute("Attribute", math.round(Boost))
	elseif MethodOfGain == "Multiply" then
		local Mana = 100
		for Name, Value in MaxMana:GetAttributes() do
			if Name ~= "Attribute" then
				Mana += Value
			end
		end

		local Boost = Mana * (INTEL_MANA_MUL * Points * IntelligenceAmplifier)
		MaxMana:SetAttribute("Attribute", math.round(Boost))
	end
end

return AttributeFunctions