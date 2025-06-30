-- Calling values
local UI = script.Parent
local TopFrame = UI:WaitForChild("NameFrame")
local NameFrame = TopFrame:WaitForChild("Name")
local NameText = NameFrame:WaitForChild("NameAndClass")
local LvlExpFrame = TopFrame:WaitForChild("LvlExp")
local ProgressExpFrame = LvlExpFrame:WaitForChild("ExpFrame"):WaitForChild("HolderFrame"):WaitForChild("Progress")
local ProgressExpText = LvlExpFrame:WaitForChild("ExpFrame"):WaitForChild("HolderFrame"):WaitForChild("ProgressText")
local LevelText = LvlExpFrame:WaitForChild("LevelFrame"):WaitForChild("Level")

local Player = game.Players.LocalPlayer
local PlayerData = Player:WaitForChild("PlayerData")
local LevelingCalculator = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("LevelingCalculator"))
--Pre-setting values
NameText.Text = Player.Name

repeat wait() until Player:FindFirstChild("DataLoaded")~=nil
LevelText.Text = "Level "..PlayerData:GetAttribute("Level")
ProgressExpText.Text = PlayerData:GetAttribute("Exp").."/"..LevelingCalculator.CalculateLevelMain(PlayerData:GetAttribute("Level"),PlayerData:GetAttribute("Superiority"))
--Setting up events


PlayerData:GetAttributeChangedSignal("Level"):Connect(function()
	print("level changed")
	LevelText.Text = "Level "..PlayerData:GetAttribute("Level")
end)
PlayerData:GetAttributeChangedSignal("Exp"):Connect(function()
	print("exp changed")
	ProgressExpText.Text = PlayerData:GetAttribute("Exp").."/"..LevelingCalculator.CalculateLevelMain(PlayerData:GetAttribute("Level"),PlayerData:GetAttribute("Superiority"))
	local ExpPercent = PlayerData:GetAttribute("Exp")/LevelingCalculator.CalculateLevelMain(PlayerData:GetAttribute("Level"),PlayerData:GetAttribute("Superiority"))
	ProgressExpFrame:TweenSize(UDim2.new(ExpPercent,0,1,0),0,0,0.25,true)
end)


