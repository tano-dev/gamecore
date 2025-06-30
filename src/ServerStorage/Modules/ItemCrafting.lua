--Modules
local ItemDictionaryHandler = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("ItemDictionaryHandler"))
local ItemSlotHandler = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("ItemSlotHandler"))
local EquipmentFormat = require(game:GetService("ReplicatedStorage"):WaitForChild("Format"):WaitForChild("EquipmentFormat"))
local CopyTable = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("CopyTable"))
local ItemDictionaryHandler = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("ItemDictionaryHandler"))
local RngModule = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("RngModule"))
local ItemHandler =  require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("ItemHandler"))
--
local GameItems = game:GetService("ReplicatedStorage"):WaitForChild("GameItems")
local CraftingRecipes = require(GameItems:WaitForChild("CraftingRecipes"))
local StringConverterPattern = "(%d+)%s?_%s?(%d+)"
--
local function getLowest(TableGiven)
	local low = nil
	local index
	for i, v in pairs(TableGiven) do
		if typeof(v) == "string" then
			v = tonumber(v)
		end
		if typeof(low) == "nil" then
			low = v
			index = i
		end
		if v < low then
			low = v
			index = i
		end
	end
	return index, low
end
local function getHighest(TableGiven)
	local high = nil
	local index
	for i, v in pairs(TableGiven) do
		if typeof(v) == "string" then
			v = tonumber(v)
		end
		if typeof(high) == "nil" then
			high = v
			index = i
		end
		if v > high then
			high = v
			index = i
		end
	end
	return index, high
end
--
local ItemCrafting = {}
function ItemCrafting.Craft(Player,RecipeName,MainSlot)
	if not CraftingRecipes[RecipeName] then return false,"Invalid Recipe" end
	local SelectedRecipe = CraftingRecipes[RecipeName]
	local PlayerInventory = Player.Inventory
	local EquipmentsInventory = PlayerInventory.Equipments
	local MaterialsInventory = PlayerInventory.Materials
	local ConsumablesInventory = PlayerInventory.Consumables
	local CraftingLevel = Player:FindFirstChild("PlayerData"):GetAttribute("Crafting")
	local CraftingExp = Player:FindFirstChild("PlayerData"):GetAttribute("CraftingExp")
	--Check if requirement is meet or no
	for i,v in pairs(SelectedRecipe.Requirements) do
		if i == "Crafting" or i == "Alchemy" or i == "Farming" then
			local GetPlayerStat = Player:FindFirstChild("PlayerData"):GetAttribute(i)
			if GetPlayerStat < v then return false, "Requirement not met." end
		end
	end
	--Get Player inventory
	local EquipmentsTable = {}
	local ConsumablesTable = {}
	local MaterialsTable = {}
	for i,v in pairs(EquipmentsInventory:GetChildren()) do
		if v:FindFirstChildOfClass("NumberValue") then
			local slot = v.Name:split("_")
			local item = v:FindFirstChildOfClass("NumberValue")
			if EquipmentsTable[item.Name] then
				table.insert(EquipmentsTable[item.Name],slot[2])
			else
				EquipmentsTable[item.Name] = {}
				table.insert(EquipmentsTable[item.Name],slot[2])
			end
		end
	end
	for i,v in pairs(ConsumablesInventory:GetChildren()) do
		if v:FindFirstChildOfClass("NumberValue") then
			local item = v:FindFirstChildOfClass("NumberValue")
			if ConsumablesTable[item.Value] then
				local oldvalue =  ConsumablesTable[item.Value]
				ConsumablesTable[item.Value] = item:GetAttribute("Amounts") + oldvalue
			else
				ConsumablesTable[item.Value] = item:GetAttribute("Amounts")
			end
		end
	end
	for i,v in pairs(MaterialsInventory:GetChildren()) do
		if v:FindFirstChildOfClass("NumberValue") then
			local item = v:FindFirstChildOfClass("NumberValue")
			if MaterialsTable[item.Value] then
				local oldvalue =  MaterialsTable[item.Value]
				MaterialsTable[item.Value] = item:GetAttribute("Amounts") + oldvalue
			else
				MaterialsTable[item.Value] = item:GetAttribute("Amounts")
			end
		end
	end
	print(EquipmentsTable)
	print(ConsumablesTable)
	print(MaterialsTable)
	local Slot 
	local MainSlotItem 
	local ItemDictionalized 
	local GetCarriedStats
	if MainSlot then
		Slot= MainSlot:split("_")
		if Slot[1] ~= "Equipments" then return false, "MainSlot is nil" end
		local MainItem = EquipmentsInventory:FindFirstChild("Slot_"..Slot[2])
		
		if MainItem:FindFirstChildOfClass("NumberValue") then
			MainSlotItem  = MainItem:FindFirstChildOfClass("NumberValue")
		else return false, "MainItem is Empty" end
		if MainSlotItem.Name ~= SelectedRecipe.Main then return false, "MainSlot is invalid compare to the Main item recipe" end
		if not EquipmentsTable[MainSlotItem.Name] and not table.find(EquipmentsTable[MainSlotItem.Name],Slot[2]) then return false, "Cannot find MainSlot" end
		table.remove(EquipmentsTable[MainSlotItem.Name],table.find(EquipmentsTable[MainSlotItem.Name],Slot[2]))
		ItemDictionalized = ItemDictionaryHandler.ItemToDictionary(MainSlotItem)
		GetCarriedStats = ItemDictionaryHandler.GetStats(ItemDictionalized,1)
	end
	--Into the main checking part
	for i,v in pairs(SelectedRecipe.Materials) do
		local ItemID,ItemType = ItemDictionaryHandler.NameToID(i)
		local Conditions = v.Conditions:split("_")
		local FinalAmounts = v.Amounts
		if Conditions[1] == "nil" then
			FinalAmounts = v.Amounts
		else
			local SubtractedAmounts = (CraftingLevel-CraftingLevel%tonumber(Conditions[1]))/tonumber(Conditions[1])
			if v.Amounts-SubtractedAmounts < tonumber(Conditions[2]) then
				FinalAmounts = tonumber(Conditions[2]) 
			else
				FinalAmounts = v.Amounts-SubtractedAmounts 
			end
		end
		if ItemType == 1 then
			if  #EquipmentsTable[i] < FinalAmounts then
				return false, "Not enough materials"
			end
		elseif ItemType == 2 then
			if ConsumablesTable[ItemID] < FinalAmounts then
				return false, "Not enough materials"
			end
		elseif ItemType == 3 then
			if MaterialsTable[ItemID] < FinalAmounts then
				return false, "Not enough materials"
			end
		end
	end
	--Done checking, now into destroying stuffs
	for i,v in pairs(SelectedRecipe.Materials) do
		local ItemID,ItemType = ItemDictionaryHandler.NameToID(i)
		local Conditions = v.Conditions:split("_")
		local FinalAmounts = v.Amounts
		if Conditions[1] == "nil" then
			FinalAmounts = v.Amounts
		else
			local SubtractedAmounts = (CraftingLevel-CraftingLevel%tonumber(Conditions[1]))/tonumber(Conditions[1])
			if v.Amounts-SubtractedAmounts < tonumber(Conditions[2])  then
				FinalAmounts = tonumber(Conditions[2]) 
			else
				FinalAmounts = v.Amounts-SubtractedAmounts 
			end
		end
		if ItemType == 1 then
			for a=1,FinalAmounts do
				local destroyslot = EquipmentsInventory:FindFirstChild("Slot_"..EquipmentsTable[i][a])
				if destroyslot:FindFirstChildOfClass("NumberValue") then
					destroyslot:FindFirstChildOfClass("NumberValue"):Destroy()
				else return false,"Cannot find destroyslot (empty?)"
				end
			end
		elseif ItemType == 2 or ItemType == 3 then
			ItemHandler.ItemReduction(Player,ItemID,FinalAmounts)
		end
	end
	if MainSlot then
		MainSlotItem:Destroy()
	end
	--Rewarding stuffs
	local ItemID,ItemType = ItemDictionaryHandler.NameToID(RecipeName)
	if ItemType == 1 then
		if SelectedRecipe.Main then
			ItemHandler.Create(ItemID,true,Player,GetCarriedStats)
		else
			ItemHandler.Create(ItemID,true,Player)
		end
	elseif ItemType == 2 or ItemType == 3 then
		ItemHandler.ItemIncrement(Player,ItemID,1)
	end
	Player:FindFirstChild("PlayerData"):SetAttribute("CraftingExp",CraftingExp+SelectedRecipe.ExpGains)
	return true,"Crafted "..RecipeName.."."
end
return ItemCrafting
