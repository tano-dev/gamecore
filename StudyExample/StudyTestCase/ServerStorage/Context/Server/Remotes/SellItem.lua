--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local ContentLibrary = require(ReplicatedStorage.Modules.Shared.ContentLibrary)

local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local Remotes = {}

local Libraries = {}
for _, Module in ServerStorage.Modules.Libraries["items [Subcategories]"]:GetChildren() do
	Libraries[Module.Name] = require(Module)
end

--------------------------------------------------------------------------------

if not GameConfig.EnabledFeatures.PawnShop then
	return {}
end

-- Callbacks
local function GiveMultipleOfItem(Player, ItemType: string, ItemName: string, Amount: number)
	local pData = PlayerData:FindFirstChild(Player.UserId)
	local Item = ContentLibrary[ItemType] and ContentLibrary[ItemType][ItemName]
	if not Item then return end

	Libraries[ItemType]:Give(Player, Item, nil, "Force", Amount)
	return true
end

local function SellMultipleOfItem(Player, ItemType: string, ItemName: string, Amount: number)
	local pData = PlayerData:WaitForChild(Player.UserId)
	local Item = ContentLibrary[ItemType] and ContentLibrary[ItemType][ItemName]
	if not Item then return end
	
	Amount = math.min(Amount, GameConfig.Categories[Item.Type].BulkSellMax)
	Libraries[ItemType]:Trash(Player, Item, Amount)
	
	-- Add currency
	local SellType = Item.Config.Sell and Item.Config.Sell[1] or Item.Config.Cost[1]
	local SellName = Item.Config.Sell and Item.Config.Sell[2] or Item.Config.Cost[2]
	
	local Return = Item.Config.Sell and Item.Config.Sell[3] or math.floor(Item.Config.Cost[3] / 2)
	local GivenAmount = Return * Amount
	
	if SellType == "Statistic" then
		local Currency = pData.Stats[SellName]
		Currency.Value += GivenAmount
	else
		GiveMultipleOfItem(Player, SellType, SellName, GivenAmount)
	end

	return true
end

-- Modify this function in order to change remote callback
function Remotes:OnEvent(Player, ItemType: string, ItemName: string, Amount: number)
	if not ItemType or not ItemName then return end
	if typeof(ItemType) ~= "string" or typeof(ItemName) ~= "string" then return end
	
	local pData = PlayerData:FindFirstChild(Player.UserId)
	local Item = ContentLibrary[ItemType] and ContentLibrary[ItemType][ItemName]
	if not pData or not Item then return end
	
	if not Item.Config.Sell and (not Item.Config.Cost or not GameConfig.SellShopItems) then
		return false, "This item can't be sold"
	end

	if not pData.Items[ItemType]:FindFirstChild(ItemName) then
		return false, "You don't own this item"
	end
	
	if not Amount then
		return SellMultipleOfItem(Player, ItemType, ItemName, 1)
	elseif Amount then
		local InvalidNumber = math.floor(Amount) ~= Amount 
			or Amount ~= Amount 
			or typeof(Amount) ~= "number" 
			or math.abs(Amount) ~= Amount 

		if InvalidNumber then
			return false, "Invalid amount"
		end
		
		return SellMultipleOfItem(Player, ItemType, ItemName, Amount)
	end
end

return Remotes
