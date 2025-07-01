--[[
	ej0w @ September 2024
	DynamicStatFunctions
	
	Displays the current attribute progress in attributes UI w/ these callbacks
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer
local pData = ReplicatedStorage:WaitForChild("PlayerData"):WaitForChild(Player.UserId)
local AttributesFolder = pData:WaitForChild("Attributes")
local PointsValue = pData:WaitForChild("Points")

--> Dependencies
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local DynamicStatFunctions = {}

--> Configuration
local MOB_MISS_MAX_CHANCE = 85

--------------------------------------------------------------------------------

function DynamicStatFunctions:Strength(Description)
	local Points = AttributesFolder.Strength.Value
	if Points > 0 then
		local MethodOfGain = GameConfig.Attributes.Strength.MethodOfGain
		local Amplifier = GameConfig.Attributes.Strength.Amplifier

		local STREN_DAMAGE_BOOST = GameConfig.Attributes.Strength.Boost[2]
		local STREN_DAMAGE_ADD = GameConfig.Attributes.Strength.Boost[1]

		if MethodOfGain == "Add" then
			local Boost = STREN_DAMAGE_ADD * Points * Amplifier
			Description.Text ..= `\n<b>+{FormatNumber(math.round(Boost), "Suffix")}</b> Damage`
		elseif MethodOfGain == "Multiply" then
			local Boost = (STREN_DAMAGE_BOOST * Points * Amplifier)
			Description.Text ..= `\n<b>+{math.round(Boost * 100)}%</b> Damage`
		end
	end
end

function DynamicStatFunctions:Constitution(Description)
	local Points = AttributesFolder.Constitution.Value
	if Points > 0 then
		local Amplifier = GameConfig.Attributes.Constitution.Amplifier

		local CONST_REGEN_BOOST = GameConfig.Attributes.Constitution.Boost[2]
		local CONST_REGEN_ADD = GameConfig.Attributes.Constitution.Boost[1]
		
		local HitOpportunity = math.clamp(Points * Amplifier, 0, MOB_MISS_MAX_CHANCE)
		Description.Text ..= `\n<b>+{math.round(HitOpportunity)}%</b> Agility`

		local Boost = CONST_REGEN_BOOST * Points * Amplifier
		local ClampedBoost = math.clamp(1 + Boost, 1, 5)
		Description.Text ..= `\n<b>x{math.round(ClampedBoost * 10) / 10}</b> Regeneration`

		local Boost = CONST_REGEN_ADD * Points * Amplifier
		Description.Text ..= `\n<b>+{FormatNumber(math.round(Boost), "Suffix")}</b> Health`
	end
end

function DynamicStatFunctions:Intelligence(Description)
	local Points = AttributesFolder.Intelligence.Value
	if Points > 0 then
		local Amplifier = GameConfig.Attributes.Intelligence.Amplifier

		local INTEL_REGEN_BOOST = GameConfig.Attributes.Intelligence.Boost[2]
		local INTEL_REGEN_ADD = GameConfig.Attributes.Intelligence.Boost[1]

		local Boost = INTEL_REGEN_BOOST * Points * Amplifier
		local ClampedBoost = math.clamp(1 + Boost, 1, 5)
		Description.Text ..= `\n<b>x{math.round(ClampedBoost * 10) / 10}</b> Regeneration`

		local Boost = INTEL_REGEN_ADD * Points * Amplifier
		Description.Text ..= `\n<b>+{FormatNumber(math.round(Boost), "Suffix")}</b> Mana`
	end
end

function DynamicStatFunctions:Dexterity(Description)
	local Points = AttributesFolder.Dexterity.Value
	if Points > 0 then
		local MethodOfGain = GameConfig.Attributes.Dexterity.MethodOfGain
		local Amplifier = GameConfig.Attributes.Dexterity.Amplifier

		local DEXTE_CRIT_BOOST = GameConfig.Attributes.Dexterity.Boost[2]

		local ModifiedBoost = 1 + (DEXTE_CRIT_BOOST * Points * Amplifier)
		Description.Text ..= `\n<b>x{math.round(ModifiedBoost * 10) / 10}</b> Critical damage`
		Description.Text ..= `\n<b>+{math.clamp(math.round((ModifiedBoost - 1) * 100), 0, 50)}%</b> Critical chance`
	end
end

return DynamicStatFunctions
