--[[
	Evercyan @ March 2023
	PlayerLeveling
	
	Some simple functions relating to player leveling is housed here to be used
	in the ServerMain script.
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

local LevelUp = {}
for _, Module in script.LevelUp:GetChildren() do
	LevelUp[Module.Name] = require(Module)
end

--> Variables
local PlayerLeveling = {}

local CONFIG_AMOUNT = GameConfig.PointValueIncrease[1]
local CONFIG_TYPE = GameConfig.PointValueIncrease[2]

--------------------------------------------------------------------------------

-- Levels up the player if they have enough experience to do so.
function PlayerLeveling:TryLevelUp(Player: Player, Level, XP)
	local pData = ReplicatedStorage:WaitForChild("PlayerData"):WaitForChild(Player.UserId)
	local Points = pData.Points
	local Attributes = pData.Attributes
	
	local XPRequirement = math.ceil((GameConfig.XPModifier == "Multiply" and Level.Value * GameConfig.XPPerLevel)
		or  (GameConfig.XPModifier == "Exponential" and GameConfig.XPPerLevel ^ Level.Value))
	
	if XP.Value >= XPRequirement and Level.Value < GameConfig.MaxLevel then
		local Clamp = if CONFIG_TYPE == "Magnitude" 
			then math.clamp(math.floor((Level.Value * CONFIG_AMOUNT) - 1), 1, math.huge) 
			else Level.Value * 10
		
		local Plus = math.clamp(math.floor(XP.Value / XPRequirement), 0, Clamp)
		local SpentXP = Plus * XPRequirement
		
		local Remainder = math.clamp(math.floor(XP.Value - SpentXP), 0, math.huge)
		
		-- Update levels / XP
		if Remainder ~= Remainder then
			Remainder = 0 -- nan xp
		end
		
		Level.Value = math.clamp(Level.Value + Plus, 1, math.huge)
		XP.Value = Remainder
		
		-- Update attribute points
		if CONFIG_TYPE == "Linear" then
			if math.floor(Level.Value / CONFIG_AMOUNT) == Level.Value / CONFIG_AMOUNT then
				Points.Value += Plus
			end
		elseif CONFIG_TYPE == "Magnitude" then
			local Total = Points.Value
			for _, Attribute in Attributes:GetChildren() do
				Total += Total.Value
			end
			if CONFIG_AMOUNT ^ (Total + 1) >= Level.Value then
				Points.Value += 1
			end
		end
		
		-- Everything else
		for _, Callback in LevelUp do
			task.spawn(Callback, Player, Level)
		end
	end
end

return PlayerLeveling