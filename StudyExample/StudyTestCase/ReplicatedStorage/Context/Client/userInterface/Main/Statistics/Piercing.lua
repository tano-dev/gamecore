--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local Main = PlayerGui:WaitForChild("Main")
local BottomRight = Main:WaitForChild("BottomRight")
local StatisticsFrame = BottomRight:WaitForChild("Statistics")

--> Dependencies
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)

--------------------------------------------------------------------------------

return function(Character, Tool)
	local Humanoid = Character:FindFirstChild("Humanoid")
	local ItemConfig = Tool and Tool:FindFirstChild("ItemConfig")
	ItemConfig = ItemConfig and require(ItemConfig)
	
	local Defense = ItemConfig and ItemConfig.DefensePenetration
	local IsValidTool = ItemConfig and Defense and Defense[1] > 0
	if IsValidTool then
		local CanAdd = ItemConfig.DefensePenetration[2]
		if CanAdd then
			StatisticsFrame.DefenseReduction.Text = `<b>+{FormatNumber(Defense[1], "Suffix")}</b> Piercing`
		else
			StatisticsFrame.DefenseReduction.Text = `<b>{math.round(Defense[1] * 1e3) / 10}%</b> Piercing`
		end

		StatisticsFrame.DefenseReduction.Visible = true
	elseif not IsValidTool then
		StatisticsFrame.DefenseReduction.Visible = false
	end
end