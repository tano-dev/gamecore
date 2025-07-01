--[[
	ej0w @ October 2024
	InformSpawnedBoss
	
	Sends an alert via Alert UI for spawned bosses
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

--> Player
local Player = Players.LocalPlayer

local PlayerGui = Player:WaitForChild("PlayerGui")
local Alerts = PlayerGui:WaitForChild("Alerts")

--> Dependencies
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)

local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local Remotes = {}

--------------------------------------------------------------------------------

-- Modify this function in order to change remote callback
function Remotes:OnEvent(Color, Text)
	if not GameConfig.EnabledFeatures.SpawnedBossUI then
		return
	end
	
	-- Create UI
	local BossAlert = Alerts:WaitForChild("Boss"):WaitForChild("BossAlert"):Clone()
	BossAlert.Name = Text
	BossAlert.GroupColor3 = Color
	BossAlert.Display.Text = Text
	BossAlert.GroupTransparency = 1
	BossAlert.UIPadding.PaddingTop = UDim.new(0, -10)
	
	BossAlert.Visible = true
	BossAlert.Parent = Alerts.Boss
	
	-- Fade UI
	Tween:Play(BossAlert.UIPadding, {0.5, "Back", "Out"}, {PaddingTop =  UDim.new(0, 10)})
	Tween:Play(BossAlert, {0.5, "Circular"}, {GroupTransparency = 0})
	task.delay(3, function()
		Tween:Play(BossAlert.UIPadding, {0.5, "Circular"}, {PaddingTop =  UDim.new(0, -10)})
		Tween:Play(BossAlert, {0.5, "Circular"}, {GroupTransparency = 1})
	end)

	Debris:AddItem(BossAlert, 3.5)
end

return Remotes