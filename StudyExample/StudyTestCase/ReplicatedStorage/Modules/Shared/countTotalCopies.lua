--[[
	ej0w @ October 2024
	CountTotalCopies
	
	Used to check how many copies of an item someone has
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--> Player
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local GameConfig = require(ReplicatedStorage.GameConfig)

--------------------------------------------------------------------------------

return function(Item, Player)
	local Player = Player or Players.LocalPlayer
	local pData = PlayerData:WaitForChild(Player.UserId)
	
	local Count = 0
	for Category, Info in GameConfig.Categories do
		local InventoryItems = pData.Items[Category]
		local Value = InventoryItems:FindFirstChild(Item.Name)
		
		local isNumberValue = Value and Value:IsA("NumberValue")
		if isNumberValue then
			if Value then
				Count += Value.Value
			end
		elseif not isNumberValue then
			for _, Value in InventoryItems:GetChildren() do
				if Value.Name == Item.Name then
					Count += 1
				end
			end
		end
	end

	return Count
end
