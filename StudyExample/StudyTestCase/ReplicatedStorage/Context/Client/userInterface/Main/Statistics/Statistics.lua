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
	
	local Statistics = Humanoid:FindFirstChild("Statistics")
	for _, Statistic in Statistics:GetChildren() do
		local CanShow = false

		local TotalValue = 0
		local TotalPercentage = 0
		for Name, Value in Statistic:GetAttributes() do
			if Value ~= 0 then
				CanShow = true
			end
			local IsAdditive = string.find(Name, "Additive")
			if IsAdditive then
				TotalValue += Value
			elseif not IsAdditive then
				TotalPercentage += TotalPercentage
			end
		end

		local StatisticLabel = StatisticsFrame:FindFirstChild(Statistic.Name)
		if StatisticLabel then
			TotalPercentage = math.round(TotalPercentage * 1e3) / 10

			local PercentSuffix = TotalPercentage > 0 and `{TotalPercentage}%` or ""
			local ValueSuffix = TotalValue > 0 and `+{FormatNumber(TotalValue, "Suffix")}` or ""

			local Joiner = TotalValue > 0 and TotalPercentage > 0 and " & " or ""
			StatisticLabel.Text = `<b>{ValueSuffix}{Joiner}{PercentSuffix}</b> {Statistic.Name}`
			StatisticLabel.Visible = CanShow
		end
	end
end