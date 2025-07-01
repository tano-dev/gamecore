--[[
	ej0w @ May 2024
	Fireworks
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")
local Modules = ReplicatedStorage.Modules

--> Dependencies
local RbxUtility = require(Modules.Shared.RbxUtility)
local SFX = require(Modules.Shared.SFX)

local GameConfig = require(ReplicatedStorage.GameConfig)

--------------------------------------------------------------------------------

local pData = PlayerData:WaitForChild(Player.UserId, 30)
local Stats = pData and pData:WaitForChild("Stats", 30)

if RbxUtility.SoftAssert(Stats, "value type 'Stats' does not exist. (Player loaded in without data)") then
	return
end

local Level = Stats.Level
local Previous = Level.Value

Level.Changed:Connect(function()
	if Level.Value > Previous then
		if Level.Value < 1_000 then
			SFX:Play2D(GameConfig.LevelUpSFX[1], {Volume = GameConfig.LevelUpSFX[2]})
		end
		
		RbxUtility.Fireworks(Player.Character.HumanoidRootPart.Position, math.random(15, 25))
	end
	
	Previous = Level.Value
end)

return {}