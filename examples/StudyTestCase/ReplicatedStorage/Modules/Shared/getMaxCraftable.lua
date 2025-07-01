--[[
	ej0w @ October 2024
	GetMaxCraftable
	
	Used both for serverside validation & clientside display of max
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--> Player
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local CountTotalCopies = require(ReplicatedStorage.Modules.Shared.countTotalCopies)
local ContentLibrary = require(ReplicatedStorage.Modules.Shared.ContentLibrary)

local GameConfig = require(ReplicatedStorage.GameConfig)

--------------------------------------------------------------------------------

return function(Data, Player)
	local Player = Player or Players.LocalPlayer
	local pData = PlayerData:WaitForChild(Player.UserId)
	
	local CanCraftMultiple =  Data.CraftMultiple
	if CanCraftMultiple then
		local MinimumAmountCanCraft = math.huge
		
		for Category, Items in Data.Recipe do
			local DataLibrary = pData.Items:FindFirstChild(Category)

			for _, Stat in Items do
				local IsStatistics = Category == "Statistics"
				if IsStatistics then
					local Value = pData.Stats:FindFirstChild(Stat[1])
					
					local AmountCraftable = Value.Value / Stat[2]
					if AmountCraftable < MinimumAmountCanCraft then
						MinimumAmountCanCraft = AmountCraftable
					end
				elseif not IsStatistics then
					local Item = ContentLibrary[Category][Stat[1]]
					local AmountOwned = CountTotalCopies(Item, Player)
					
					local AmountCraftable = AmountOwned / Stat[2]
					if AmountCraftable < MinimumAmountCanCraft then
						MinimumAmountCanCraft = AmountCraftable
					end
				end
			end
		end
		
		return math.floor(MinimumAmountCanCraft)
	elseif not CanCraftMultiple then
		local TotalRequested = 0
		local CurrentAmount = 0
		
		if pData.Items[Data.Item[1]]:FindFirstChild(Data.Item[2]) then
			return 0
		end
		
		for Category, Items in Data.Recipe do
			local DataLibrary = pData.Items:FindFirstChild(Category)
			
			for _, Stat in Items do
				local IsStatistics = Category == "Statistics"
				if IsStatistics then
					local Value = pData.Stats:FindFirstChild(Stat[1])
					if Value.Value >= Stat[2] then
						CurrentAmount += 1
					end
					
					TotalRequested += 1
				elseif not IsStatistics then
					local Item = ContentLibrary[Category][Stat[1]]
					local AmountOwned = CountTotalCopies(Item, Player)
					if AmountOwned >= Stat[2] then
						CurrentAmount += 1
					end
					
					TotalRequested += 1
				end
			end
		end
		
		return ((CurrentAmount >= TotalRequested) and 1) or 0
	end
end
