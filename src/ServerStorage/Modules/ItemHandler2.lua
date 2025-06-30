local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local NotifyHolder = ReplicatedStorage.PlayerDataHolder.Notify
local ItemDictionaryHandler = require(ServerStorage.Modules.ItemDictionaryHandler)
local ItemSlotHandler = require(ServerStorage.Modules.ItemSlotHandler)
local EquipmentFormat = require(ReplicatedStorage.Format.EquipmentFormat)
local Material_ConsumableFormat = require(ReplicatedStorage.Format.Material_ConsumableFormat)
local FormatFolder = ReplicatedStorage.Format
local Equipment = FormatFolder.Equipment
local Material_Consumable = FormatFolder.Material_Consumable
local GameItems = ReplicatedStorage.GameItems
local ItemStateData = require(GameItems.ItemStateData)
local RemoteFunc = require(ReplicatedStorage.Modules.RemoteFunc)

local ItemHandler = {}

local function setAttributes(item, attributes)
	for name, value in pairs(attributes) do
		if type(value) == "table" then
			local folder = item:WaitForChild(name)
			for subName, subValue in pairs(value) do
				if name == "Enchants" then
					folder:SetAttribute(subName, subValue.ID .. ":" .. subValue.Level)
				elseif name == "Gems" then
					folder:SetAttribute(subName, subValue.ID)
				else
					folder:SetAttribute(subName, subValue)
				end
			end
		elseif name == "UpgradeAttemptUsed" then
			item.Upgrades.Value = tonumber(value)
		elseif name == "GemSlotUsed" then
			item.Gems.Value = tonumber(value)
		elseif name == "EnchantSlotUsed" then
			item.Enchants.Value = tonumber(value)
		elseif name == "ID" then
			item.Value = value
		else
			item:SetAttribute(name, value)
		end
	end
end

function ItemHandler.Create(ID, AutoFill, Parent, IsNotify, Custom)
	local Name, Type, SubType = ItemDictionaryHandler.IDToName(ID)
	local NewItem

	if Type == 1 then
		NewItem = Equipment:Clone()
		NewItem.Name = Name
		setAttributes(NewItem, EquipmentFormat)
	elseif Type == 2 or Type == 3 then
		NewItem = Material_Consumable:Clone()
		NewItem.Name = Name
		setAttributes(NewItem, Material_ConsumableFormat)
	end

	if type(Custom) == "table" then
		setAttributes(NewItem, Custom)
	end

	if AutoFill and type(Parent) == "Instance" then
		local success, value = ItemSlotHandler.GetEmptySlots(Parent, Type, "GetLowest")
		if success then
			local inventoryFolder = Type == 1 and "Equipments" or (Type == 2 and "Consumables" or "Materials")
			NewItem.Parent = Parent.Inventory[inventoryFolder]["Slot_" .. value]
			NewItem:SetAttribute("CurrentSlot", value)
		else
			NewItem.Parent = Parent.Bank
			NewItem:SetAttribute("CurrentSlot", 0)

			if Type ~= 1 then
				local itemData = require(GameItems[Type == 2 and "Consumables" or "Materials"][Name])
				if itemData.Stackable then
					local amounts = (Custom and Custom.Amounts) or 1
					ItemHandler.StackItem(Parent, NewItem, amounts, itemData)
				end
			end
		end
	else
		NewItem.Parent = Parent
	end

	if IsNotify and Parent:IsA("Player") then
		local itemModule = require(GameItems.Equipments[Name])
		local createNotify = Instance.new("ObjectValue")
		createNotify.Name = Name
		createNotify.Parent = NotifyHolder[Parent.Name]
		createNotify:SetAttribute("Rarity", itemModule.Rarity)
		createNotify:SetAttribute("Type", 1)
		createNotify:AddTag("Notify")
	end

	return NewItem
end

function ItemHandler.StackItem(Player, Item, Amounts, ItemData)
	for _, existingItem in ipairs(Player.Bank:GetChildren()) do
		if existingItem.Name == Item.Name and existingItem.Value == Item.Value then
			local isExact = true
			for attrName, attrValue in pairs(Item:GetAttributes()) do
				if existingItem:GetAttribute(attrName) ~= attrValue and attrName ~= "Amounts" then
					isExact = false
					break
				end
			end

			if isExact and existingItem:GetAttribute("Amounts") < ItemData.StackSize then
				local spaceLeft = ItemData.StackSize - existingItem:GetAttribute("Amounts")
				local amountToAdd = math.min(Amounts, spaceLeft)
				existingItem:SetAttribute("Amounts", existingItem:GetAttribute("Amounts") + amountToAdd)
				Amounts = Amounts - amountToAdd

				if Amounts == 0 then
					Item:Destroy()
					return
				end
			end
		end
	end

	if Amounts > 0 then
		Item:SetAttribute("Amounts", Amounts)
	end
end

function ItemHandler.ItemIncrement(ID, Player, Amounts, IsNotify, CustomCondition)
	local ItemName, ItemType = ItemDictionaryHandler.IDToName(ID)
	if ItemType == 1 then
		return false, "Cannot increase Equipment."
	end

	local itemData = require(GameItems[ItemType == 2 and "Consumables" or "Materials"][ItemName])
	if not itemData.Stackable then
		ItemHandler.Create(ID, true, Player, IsNotify, CustomCondition)
		return true, "Item created."
	end

	local inventoryFolder = Player.Inventory[ItemType == 2 and "Consumables" or "Materials"]
	local itemsToUpdate = ItemHandler.FindMatchingItems(inventoryFolder, ID, CustomCondition)

	for _, item in ipairs(itemsToUpdate) do
		local currentAmount = item:GetAttribute("Amounts")
		local spaceLeft = itemData.StackSize - currentAmount
		local amountToAdd = math.min(Amounts, spaceLeft)

		item:SetAttribute("Amounts", currentAmount + amountToAdd)
		Amounts = Amounts - amountToAdd

		if Amounts == 0 then
			break
		end
	end

	if Amounts > 0 then
		local newItem = ItemHandler.Create(ID, true, Player, IsNotify, CustomCondition)
		newItem:SetAttribute("Amounts", Amounts)
	end

	return true, "Item(s) increased."
end

function ItemHandler.ItemReduction(ID, Player, Amounts, IsNotify, CustomCondition)
	local ItemName, ItemType = ItemDictionaryHandler.IDToName(ID)
	if ItemType == 1 then
		return false, "Cannot decrease Equipment."
	end

	local inventoryFolder = Player.Inventory[ItemType == 2 and "Consumables" or "Materials"]
	local itemsToUpdate = ItemHandler.FindMatchingItems(inventoryFolder, ID, CustomCondition)

	local totalAvailable = 0
	for _, item in ipairs(itemsToUpdate) do
		totalAvailable = totalAvailable + item:GetAttribute("Amounts")
	end

	if totalAvailable < Amounts then
		return false, "Not enough items to decrease."
	end

	for _, item in ipairs(itemsToUpdate) do
		local currentAmount = item:GetAttribute("Amounts")
		local amountToRemove = math.min(Amounts, currentAmount)

		if amountToRemove == currentAmount then
			item:Destroy()
		else
			item:SetAttribute("Amounts", currentAmount - amountToRemove)
		end

		Amounts = Amounts - amountToRemove

		if Amounts == 0 then
			break
		end
	end

	return true, "Item(s) decreased."
end

function ItemHandler.FindMatchingItems(folder, ID, customCondition)
	local matchingItems = {}

	for _, slot in ipairs(folder:GetChildren()) do
		local item = slot:FindFirstChildOfClass("NumberValue")
		if item and item.Value == ID then
			local isMatch = true
			if customCondition then
				for attrName, attrValue in pairs(customCondition) do
					if item:GetAttribute(attrName) ~= attrValue then
						isMatch = false
						break
					end
				end
			end
			if isMatch then
				table.insert(matchingItems, item)
			end
		end
	end

	return matchingItems
end

return ItemHandler