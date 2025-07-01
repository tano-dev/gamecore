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

if not GameConfig.EnabledFeatures.BuyShop then
	return {}
end

-- Callbacks
local function RemoveMultipleOfItem(Player, ItemType: string, ItemName: string, Amount: number)
	local pData = PlayerData:FindFirstChild(Player.UserId)
	local Item = ContentLibrary[ItemType] and ContentLibrary[ItemType][ItemName]
	if not Item then return end
	
	Libraries[ItemType]:Trash(Player, Item, Amount)
	return true
end

local function BuyMultipleOfItem(Player, ItemType: string, ItemName: string, Amount: number)
	local pData = PlayerData:FindFirstChild(Player.UserId)
	local Item = ContentLibrary[ItemType] and ContentLibrary[ItemType][ItemName]
	if not Item then return end
	
	Amount = math.min(Amount, GameConfig.Categories[Item.Type].BulkBuyMax)
	
	-- Remove currency
	local BuyType = Item.Config.Cost[1]
	local BuyName = Item.Config.Cost[2]
	
	local GivenAmount = Item.Config.Cost[3] * Amount
	
	if BuyType == "Statistic" then
		local Currency = pData.Stats[BuyName]
		Currency.Value -= GivenAmount
	else
		RemoveMultipleOfItem(Player, BuyType, BuyName, GivenAmount)
	end
	
	Libraries[ItemType]:Give(Player, Item, nil, true, Amount)
	return true
end

-- Modify this function in order to change remote callback
function Remotes:OnEvent(Player, ItemType: string, ItemName: string, Amount)
	if not ItemType or not ItemName then return end
	if typeof(ItemType) ~= "string" or typeof(ItemName) ~= "string" then return end

	local pData = PlayerData:FindFirstChild(Player.UserId)
	local Item = ContentLibrary[ItemType] and ContentLibrary[ItemType][ItemName]
	if not pData or not Item then return end
	
	if not Item.Config.Cost then
		return false, "This item isn't for sale"
	end

	if pData.Stats.Level.Value < Item.Config.Level then
		return false, "Your level is too low to purchase this item"
	end
	
	local IsStackable = GameConfig.CanItemsStack or GameConfig.Categories[Item.Type].IsStackable
	local ItemInstance = pData.Items[ItemType]:FindFirstChild(ItemName)
	
	local isOwned = ItemInstance and (ItemInstance:IsA("NumberValue") and ItemInstance.Value > 0) 
	if (not IsStackable or Item.Config.Cost[4]) and isOwned then
		return false, "You already own this item"
	end
	
	local Currency = Item.Config.Cost[1] == "Statistic" and pData.Stats[Item.Config.Cost[2]] or pData.Items[Item.Config.Cost[1]]:FindFirstChild(Item.Config.Cost[2])
	if not Currency or Currency.Value < Item.Config.Cost[3] * (Amount or 1) then
		return false, `Your {Item.Config.Cost[1]}, {Item.Config.Cost[2]} is/are too low to purchase this item`
	end
	
	if not Amount then
		return BuyMultipleOfItem(Player, ItemType, ItemName, 1)
	elseif Amount then
		local InvalidNumber = math.floor(Amount) ~= Amount 
			or Amount ~= Amount 
			or typeof(Amount) ~= "number" 
			or math.abs(Amount) ~= Amount 
		
		if InvalidNumber then
			return false, "Invalid amount"
		end
		
		return BuyMultipleOfItem(Player, ItemType, ItemName, Amount)
	end
end

return Remotes
