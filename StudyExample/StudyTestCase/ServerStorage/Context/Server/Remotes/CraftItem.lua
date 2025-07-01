--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local ContentLibrary = require(ReplicatedStorage.Modules.Shared.ContentLibrary)
local CountTotalCopies = require(ReplicatedStorage.Modules.Shared.countTotalCopies)
local GetMaxCraftable = require(ReplicatedStorage.Modules.Shared.getMaxCraftable)

local GameConfig = require(ReplicatedStorage.GameConfig)

local GiveItemWithAmount = require(ServerStorage.Modules.Server.giveItemWithAmount)
local RemoveItemWithAmount = require(ServerStorage.Modules.Server.removeItemWithAmount)

--> Variables
local Remotes = {}

local Libraries = {}
for _, Module in ServerStorage.Modules.Libraries["items [Subcategories]"]:GetChildren() do
	Libraries[Module.Name] = require(Module)
end

--------------------------------------------------------------------------------

if not GameConfig.EnabledFeatures.Crafting then
	return {}
end

-- Modify this function in order to change remote callback
function Remotes:OnEvent(Player, Data, Smithery, Amount)
	if not Data or not Smithery then return end
	if typeof(Data) ~= "table" then return end
	
	local Config = Smithery:FindFirstChild("Config") and require(Smithery.Config)
	if not Config or not Config.Smithery then 
		return false, "Smithery does not exist"
	end
	
	local ItemData = nil
	for _, NewData in Config.Smithery do
		if NewData.Item[1] == Data[1] and NewData.Item[2] == Data[2]  then
			ItemData = NewData
			break
		end
	end
	
	local InvalidNumber = math.floor(Amount) ~= Amount 
		or Amount ~= Amount 
		or typeof(Amount) ~= "number" 
		or math.abs(Amount) ~= Amount 

	if InvalidNumber then
		return false, "Invalid amount"
	end
	
	if ItemData then
		local pData = PlayerData:FindFirstChild(Player.UserId)
		local ContentItem = ContentLibrary[Data[1]] and ContentLibrary[Data[1]][Data[2]]
		if not pData or not ContentItem then 
			return false, "Incorrect data was passed through"
		end
		
		Amount = math.min(Amount, GameConfig.Categories[ContentItem.Type].BulkBuyMax)
		
		local Level = pData.Stats.Level
		if Level.Value < ItemData.Level or Level.Value < Config.Level then
			return false, "Your level is too low to craft this item"
		end
		
		if not ItemData.CraftMultiple and (CountTotalCopies(ContentItem, Player) >= 1 or Amount > 1) then 
			return false, "You already own this item"
		end
		
		local MaxPossibleCrafts = GetMaxCraftable(ItemData, Player)
		if MaxPossibleCrafts <= 0 then 
			return false, "You aren't able to craft this item"
		end
		
		local Stats = pData:FindFirstChild("Stats")
		for Category, Items in ItemData.Recipe do
			local IsStatistics = Category == "Statistics"
			if IsStatistics then
				for _, Stat in Items do
					local Statistic = Stats:FindFirstChild(Stat[1])
					Statistic.Value -= (Stat[2] * Amount)
				end
			elseif not IsStatistics then
				for _, Item in Items do
					local ContentItem = ContentLibrary[Category][Item[1]]
					RemoveItemWithAmount(Player, ContentItem.Config.Type, Item[1], (Item[2] * Amount))
				end
			end
		end
		
		GiveItemWithAmount(Player, ContentItem.Config.Type, ContentItem.Name, Amount)
		return true, Amount
	else
		return false, "Item does not exist"
	end
end

return Remotes
