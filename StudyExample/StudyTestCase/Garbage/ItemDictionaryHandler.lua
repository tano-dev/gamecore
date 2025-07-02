--[[
ItemDictionaryHandler API Overview

This module provides a unified interface for converting between different representations of in-game items:
- Item instances (Roblox objects)
- Dictionaries (Lua tables with item data)
- Data arrays (for DataStore serialization)

API Functions:

1. IDToName(ID)
	- Converts an item ID (number) to its Name, Type, and SubType.
	- Returns: Name (string), Type (number), SubType (string)
	- Example:
		local name, type, subtype = ItemDictionaryHandler.IDToName(1001)

2. NameToID(Name)
	- Converts an item Name (string) to its ID, Type, and SubType.
	- Returns: ID (number), Type (number), SubType (string)
	- Example:
		local id, type, subtype = ItemDictionaryHandler.NameToID("Iron Sword")

3. ItemToDictionary(Item)
	- Converts a Roblox Item instance (NumberValue) into a Lua table (dictionary) containing all its attributes and children.
	- Returns: Dictionary (table)
	- Example:
		local dict = ItemDictionaryHandler.ItemToDictionary(itemInstance)

4. DictionaryToItem(Dictionary, ItemParent)
	- Creates a Roblox Item instance from a dictionary and parents it to ItemParent.
	- Returns: New Item instance or error
	- Example:
		local item = ItemDictionaryHandler.DictionaryToItem(dict, inventoryFolder)

5. DictionaryToData(Dictionary)
	- Converts a dictionary to a DataStore-friendly array (table) for saving.
	- Returns: Data (table)
	- Example:
		local data = ItemDictionaryHandler.DictionaryToData(dict)

6. DataToDictionary(Data)
	- Converts a DataStore array back into a dictionary for loading.
	- Returns: Dictionary (table)
	- Example:
		local dict = ItemDictionaryHandler.DataToDictionary(data)

7. DataToItem(Player, Data)
	- Creates and parents an Item instance to the appropriate inventory slot for the given Player, using DataStore data.
	- Example:
		ItemDictionaryHandler.DataToItem(player, data)

8. ItemToData(Item)
	- Converts an Item instance to a DataStore array.
	- Returns: Data (table)
	- Example:
		local data = ItemDictionaryHandler.ItemToData(itemInstance)

9. GetStats(Dictionary, Mode)
	- Extracts specific stats from a dictionary, depending on Mode:
		Mode 1: All upgrade-related stats
		Mode 2: Only upgrade stats
		Mode 3: Only enchant stats
		Mode 4: Only gem stats
		Mode 0: Removes status-related fields
	- Returns: Stats table
	- Example:
		local stats = ItemDictionaryHandler.GetStats(dict, 1)

Note: This module is designed to work with a unified ItemDataStogare.lua system for consistent item data management.

-- Usage Example:
--[[
--[[
local ItemDictionaryHandler = require(game.ReplicatedStorage.Modules.ItemDictionaryHandler)
local dict = ItemDictionaryHandler.ItemToDictionary(game.Players.tano.Inventory.Equipments.Slot_1:FindFirstChildOfClass("NumberValue"))
print(dict)
local ServerModules = require(game.ServerStorage.Modules)
local ItemDictionaryHandler = ServerModules("ItemDictionaryHandler") 
local dict = ItemDictionaryHandler.ItemToDictionary(game.Players.tano.Inventory.Equipments.Slot_1:FindFirstChildOfClass("NumberValue")) 
print(dict)
]]


local ItemDictionaryHandler = {}
local ConverterPattern = "(%d+)%s?:%s?(%d+)"
-- Cache ReplicatedStorage reference
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Module dependencies
local CopyTable = require(ReplicatedStorage.Modules.CopyTable)

-- Helper Functions
local function createNumberValue(name, value, parent)
	local numberValue = Instance.new("NumberValue")
	numberValue.Name = name
	numberValue.Value = value
	numberValue.Parent = parent
	return numberValue
end

local function setMultipleAttributes(instance, attributes)
	for key, value in pairs(attributes) do
		instance:SetAttribute(key, value)
	end
end

local function getSlotParent(player, itemType, slotNumber)
	local inventory = player:FindFirstChild("Inventory")
	local equipped = inventory:FindFirstChild("Equipped")
	local bank = player:FindFirstChild("Bank")
	
	if itemType == 1 then -- Equipment
		if slotNumber >= 1 and slotNumber <= 25 then
			return inventory.Equipments:FindFirstChild("Slot_" .. slotNumber)
		elseif slotNumber == -1 then
			return equipped.Main.Weapon
		elseif slotNumber == -2 then
			return equipped.Main.Offhand
		elseif slotNumber == -3 then
			return equipped.Main.Tool
		elseif slotNumber == -4 then
			return equipped.Main.Helmet
		elseif slotNumber == -5 then
			return equipped.Main.Chestplate
		elseif slotNumber == -6 then
			return equipped.Main.Boots
		elseif slotNumber == -7 then
			return equipped.Main.Pet
		end
	elseif itemType == 2 then -- Consumables
		if slotNumber >= 1 and slotNumber <= 36 then
			return inventory.Consumables:FindFirstChild("Slot_" .. slotNumber)
		elseif slotNumber == -8 then
			return equipped.Main.Aura
		end
	elseif itemType == 3 then -- Materials
		if slotNumber >= 1 and slotNumber <= 36 then
			return inventory.Materials:FindFirstChild("Slot_" .. slotNumber)
		end
	end
	
	return bank -- Default fallback
end

-- Constants - using constants instead of table lookups improves performance
local Priority = {
	ID = 1,
	CustomName = 2,
	CustomLore = 3,
	Amounts = 4,
	UpgradeAttempts = 4,
	EnchantSlots = 5,
	GemSlots = 6,
	Purity = 7,
	Corruption = 8,
	UpgradeAttemptUsed = 9,
	UpgradeAttemptSuccessed = 10,
	EnchantSlotUsed = 11,
	GemSlotUsed = 12,
	Reforge = 13,
	Owner = 14,
	Locked = 15,
	CurrentSlot = 16,
	Enchants = 17,
	Gems = 18,
	Upgrades = 19,
	State = 20,
	Enlightment = 21,
	Aura = 22,
	NBT = 23,
}

-- Format modules
local ItemData = require(ReplicatedStorage.GameItems.ItemDataStogare)
local EquipmentFormat = require(ReplicatedStorage.Format.EquipmentFormat)
local EquipmentData = require(ReplicatedStorage.Format.EquipmentData)
local StatsPriority = require(ReplicatedStorage.Format.StatsPriority)
local StatsIndex = require(ReplicatedStorage.Format.StatsIndex)
local Material_ConsumableFormat = require(ReplicatedStorage.Format.Material_ConsumableFormat)
local Material_ConsumableData = require(ReplicatedStorage.Format.Material_ConsumableData)


function ItemDictionaryHandler.IDToName(ID: number): (string?, number?, string?)
	if not ID or type(ID) ~= "number" then
		warn("[ItemDictionaryHandler]: Invalid ID parameter - expected number, got " .. type(ID))
		return nil, nil, nil
	end
	
	local itemvalue = ItemData.GetByID(ID)
	if not itemvalue then
		warn("[ItemDictionaryHandler]: Item with ID " .. tostring(ID) .. " not found")
		return nil, nil, nil
	end
	return itemvalue.Name, itemvalue.ItemType, itemvalue.SubType
end

function ItemDictionaryHandler.NameToID(Name: string): (number?, number?, string?)
	if not Name or type(Name) ~= "string" then
		warn("[ItemDictionaryHandler]: Invalid Name parameter - expected string, got " .. type(Name))
		return nil, nil, nil
	end
	
	local itemvalue = ItemData.GetByName(Name)
	if not itemvalue then
		warn("[ItemDictionaryHandler]: Item with name '" .. tostring(Name) .. "' not found")
		return nil, nil, nil
	end
	return itemvalue.ID, itemvalue.ItemType, itemvalue.SubType
end


--[[
ItemToDictionary(Item)
lấy tên, loại vật phẩm = NameOrIDConverter.IDToName
ktra
nếu loại = 1 thì
	copy format sau đó copy ID
	for do để lấy hết attribute rồi lưu vào format
	lấy phần trong của item rồi lưu vào format
	Upgrades.Value = UpgradeAttemptUsed
	Enchants.Value = EnchantSlotUsed
	Gems.Value = GemSlotUsed
	
]]
function ItemDictionaryHandler.ItemToDictionary(Item)
	local Name, Type = ItemDictionaryHandler.IDToName(Item.Value)
	if not Name or not Type then
		warn("[ItemDictionaryHandler]: ItemToDictionary failed - invalid item ID:", Item.Value)
		return nil
	end
	
	if Type == 1 then
		local FormatDictionary = CopyTable.Copy(EquipmentFormat)
		FormatDictionary.ID = Item.Value 
		--CopyTable to Format
		for n,v in pairs(Item:GetAttributes()) do
			FormatDictionary[n] = v
		end
		--Get Children from copied format
		for _,v in pairs(Item:GetChildren()) do
			if v.Name == "Upgrades" then
				FormatDictionary.UpgradeAttemptUsed = v.Value
				for n,attrValue in pairs(v:GetAttributes()) do
					FormatDictionary.Upgrades[n] = attrValue
				end
			end
			if v.Name == "Enchants" then
				FormatDictionary.EnchantSlotUsed = v.Value
				for n,attrValue in pairs(v:GetAttributes()) do
					--string convert
					local EnchantID, Level = string.match(attrValue,ConverterPattern)
					FormatDictionary.Enchants[n]["ID"] = EnchantID
					FormatDictionary.Enchants[n]["Level"] = Level
				end
			end
			if v.Name == "Gems" then
				FormatDictionary.GemSlotUsed = v.Value
				for n,attrValue in pairs(v:GetAttributes()) do
					FormatDictionary.Gems[n]["ID"] = attrValue
				end
			end
		end
		return FormatDictionary
	elseif Type == 2 or Type == 3 then
		local FormatDictionary = CopyTable.Copy(Material_ConsumableFormat)
		FormatDictionary.ID = Item.Value
		--print(Name)
		for n,v in pairs(Item:GetAttributes()) do
			--print(n.."--"..v)
			FormatDictionary[n] = v
		end
		return FormatDictionary
	end
end
function ItemDictionaryHandler.DictionaryToItem(Dictionary,ItemParent)
	local Name, Type = ItemDictionaryHandler.IDToName(Dictionary.ID)
	if not Name or not Type then
		warn("[ItemDictionaryHandler]: DictionaryToItem failed - invalid item ID:", Dictionary.ID)
		return false, "Invalid item ID"
	end
	
	--Setting Values
	local NewItem = Instance.new("NumberValue")
	NewItem.Parent = ItemParent
	NewItem.Name = Name
	if Type == 1 then
		--if ItemParent.Parent.Name ~= "Equipments" then
		--	NewItem:Destroy()
		--	return false, ("wrong type? 137 ItemDictionaryHandler")
		--end
		NewItem.Value = Dictionary.ID
		local Enchants  = Instance.new("NumberValue")
		Enchants.Name = "Enchants"
		Enchants.Value = tonumber(Dictionary.EnchantSlotUsed)
		Enchants.Parent = NewItem
		local Upgrades  = Instance.new("NumberValue")
		Upgrades.Name = "Upgrades"
		Upgrades.Value = tonumber(Dictionary.UpgradeAttemptUsed)
		Upgrades.Parent = NewItem
		local Gems  = Instance.new("NumberValue")
		Gems.Name = "Gems"
		Gems.Value = tonumber(Dictionary.GemSlotUsed)
		Gems.Parent = NewItem
		--Setting Attributes
		NewItem:SetAttribute("CurrentSlot",Dictionary.CurrentSlot)
		NewItem:SetAttribute("CustomLore",Dictionary.CustomLore)
		NewItem:SetAttribute("CustomName",Dictionary.CustomName)
		NewItem:SetAttribute("EnchantSlots",Dictionary.EnchantSlots)
		NewItem:SetAttribute("GemSlots",Dictionary.GemSlots)
		NewItem:SetAttribute("Owner",Dictionary.Owner)
		NewItem:SetAttribute("Purity",Dictionary.Purity)
		NewItem:SetAttribute("Corruption",Dictionary.Corruption)
		NewItem:SetAttribute("UpgradeAttempts",Dictionary.UpgradeAttempts)
		NewItem:SetAttribute("UpgradeAttemptSuccessed",Dictionary.UpgradeAttemptSuccessed)
		NewItem:SetAttribute("Reforge",Dictionary.Reforge)
		NewItem:SetAttribute("Locked",Dictionary.Locked)
		NewItem:SetAttribute("State",Dictionary.State)
		NewItem:SetAttribute("Enlightment",Dictionary.Enlightment)
		NewItem:SetAttribute("Aura",Dictionary.Aura or 0)
		NewItem:SetAttribute("NBT",Dictionary.NBT or 0)
		Enchants:SetAttribute("Slot1",Dictionary.Enchants.Slot1.ID..":"..Dictionary.Enchants.Slot1.Level)
		Enchants:SetAttribute("Slot2",Dictionary.Enchants.Slot2.ID..":"..Dictionary.Enchants.Slot2.Level)
		Enchants:SetAttribute("Slot3",Dictionary.Enchants.Slot3.ID..":"..Dictionary.Enchants.Slot3.Level)
		Gems:SetAttribute("Slot1",Dictionary.Gems.Slot1.ID)
		Gems:SetAttribute("Slot2",Dictionary.Gems.Slot2.ID)
		Gems:SetAttribute("Slot3",Dictionary.Gems.Slot3.ID)
		--Upgrade filling
		for name,value in pairs(Dictionary.Upgrades) do
			Upgrades:SetAttribute(name,value)
		end

	elseif Type == 2 or Type == 3 then
		--if Type == 2 and ItemParent.Parent.Name ~= "Consumables"  then
		--	return false, ("wrong type? 177 ItemDictionaryHandler")
		--elseif Type == 3 and ItemParent.Parent.Name ~= "Materials"  then
		--	return false, ("wrong type? 179 ItemDictionaryHandler")
		--end
		for i,v in pairs(Dictionary) do
			if i == "ID" then
				NewItem.Value = v
			else
				NewItem:SetAttribute(i,v)
			end
		end
	end
end
function ItemDictionaryHandler.DictionaryToData(Dictionary)
	local Name, Type = ItemDictionaryHandler.IDToName(Dictionary.ID)
	if not Name or not Type then
		warn("[ItemDictionaryHandler]: DictionaryToData failed - invalid item ID:", Dictionary.ID)
		return nil
	end
	if Type == 1 then
		local NewData = CopyTable.Copy(EquipmentData)
		for n,v in pairs(Dictionary) do
			if type(v) == "table" then
				if n == "Enchants" then
					for a,b in pairs(v) do
						if a == "Slot1" then
							NewData[Priority[n]][1] = {tonumber(b.ID),tonumber(b.Level)}
						elseif a == "Slot2" then
							NewData[Priority[n]][2] = {tonumber(b.ID),tonumber(b.Level)}
						elseif a == "Slot3" then
							NewData[Priority[n]][3] = {tonumber(b.ID),tonumber(b.Level)}
						end
					end
				elseif n == "Gems" then
					for a,b in pairs(v) do
						if a == "Slot1" then
							NewData[Priority[n]][1] = b.ID
						elseif a == "Slot2" then
							NewData[Priority[n]][2] = b.ID
						elseif a == "Slot3" then
							NewData[Priority[n]][3] = b.ID
						end
					end
				elseif n == "Upgrades" then
					local UpgradeString = ""
					--a = stat id and b = value
					for a,b in pairs(v) do
						if UpgradeString == "" then
							UpgradeString = StatsPriority[a]..":"..b
						else
							UpgradeString = UpgradeString.."-"..StatsPriority[a]..":"..b
						end
					end
					NewData[Priority[n]] = UpgradeString
				end
			elseif n == "State" then
				--print(Dictionary.State)
				--print(v)
				local newtab = {}
				if v == "" then
					newtab = {}
				else
					for _,b in pairs(v:split(":")) do
						table.insert(newtab,tonumber(b))
					end
				end
				NewData[Priority[n]] = newtab
			elseif n == "CustomName" or n == "CustomLore" then
				NewData[Priority[n]] = v
			else
				NewData[Priority[n]] = tonumber(v)
			end
		end
		return NewData
	elseif Type == 2 or Type == 3 then
		local NewData = CopyTable.Copy(Material_ConsumableData)
		for n,v in pairs(Dictionary) do
			if n == "CurrentSlot" then
				NewData[5] = tonumber(v)
			else
				NewData[Priority[n]] = v
			end

		end
		return NewData
	end
end
function ItemDictionaryHandler.DataToDictionary(Data)
	if not Data or type(Data) ~= "table" or not Data[1] then
		warn("[ItemDictionaryHandler]: Invalid Data parameter for DataToDictionary")
		return nil
	end
	
	local _, Type = ItemDictionaryHandler.IDToName(Data[1])
	if not Type then
		warn("[ItemDictionaryHandler]: DataToDictionary failed - invalid item ID:", Data[1])
		return nil
	end
	
	if Type == 1 then
		local NewDictionary = CopyTable.Copy(EquipmentFormat)
		NewDictionary.ID = Data[1]
		NewDictionary.CustomName = Data[2]
		NewDictionary.CustomLore = Data[3]
		NewDictionary.UpgradeAttempts = Data[4]
		NewDictionary.EnchantSlots = Data[5]
		NewDictionary.GemSlots = Data[6]
		NewDictionary.Purity = Data[7]
		NewDictionary.Corruption = Data[8]
		NewDictionary.UpgradeAttemptUsed = Data[9]
		NewDictionary.UpgradeAttemptSuccessed = Data[10]
		NewDictionary.EnchantSlotUsed = Data[11]
		NewDictionary.GemSlotUsed = Data[12]
		NewDictionary.Reforge = Data[13]
		NewDictionary.Owner = Data[14]
		NewDictionary.Locked = Data[15]
		NewDictionary.CurrentSlot = Data[16]
		
		-- Process enchants
		if Data[17] and type(Data[17]) == "table" then
			for i, v in pairs(Data[17]) do
				if NewDictionary.Enchants["Slot"..i] then
					NewDictionary.Enchants["Slot"..i].ID = v[1]
					NewDictionary.Enchants["Slot"..i].Level = v[2]
				end
			end
		end
		
		-- Process gems
		if Data[18] and type(Data[18]) == "table" then
			for i, v in pairs(Data[18]) do
				if NewDictionary.Gems["Slot"..i] then
					NewDictionary.Gems["Slot"..i].ID = v
				end
			end
		end
		
		-- Process upgrades
		if Data[19] and Data[19] ~= "" then
			for _, upgradeString in pairs(Data[19]:split("-")) do
				local values = upgradeString:split(":")
				if #values >= 2 then
					for statName, priority in pairs(StatsPriority) do
						if tonumber(values[1]) == priority then
							NewDictionary.Upgrades[statName] = values[2]
							break
						end
					end
				end
			end
		end

		-- Process state
		local Str = ""
		if Data[20] and type(Data[20]) == "table" and #Data[20] > 0 then
			Str = table.concat(Data[20], ":")
		end
		NewDictionary.State = Str
		
		NewDictionary.Enlightment = Data[21]
		NewDictionary.Aura = Data[22]
		NewDictionary.NBT = Data[23]
		return NewDictionary
		
	elseif Type == 2 or Type == 3 then
		local NewDictionary = CopyTable.Copy(Material_ConsumableFormat)
		NewDictionary["ID"] = tonumber(Data[1])
		NewDictionary["CustomName"] = Data[2]
		NewDictionary["CustomLore"] = Data[3]
		NewDictionary["Amounts"] = tonumber(Data[4])
		NewDictionary["CurrentSlot"] = tonumber(Data[5])
		return NewDictionary
	end
end
function ItemDictionaryHandler.DataToItem(Player, Data)
	if not Player or not Data or type(Data) ~= "table" then
		warn("[ItemDictionaryHandler]: Invalid parameters for DataToItem")
		return
	end
	
	local Name, Type = ItemDictionaryHandler.IDToName(Data[1])
	if not Name or not Type then
		warn("[ItemDictionaryHandler]: DataToItem failed - invalid item ID:", Data[1])
		return
	end
	
	local NewItem = createNumberValue(Name, Data[1], nil)
	
	if Type == 1 then -- Equipment
		local Enchants = createNumberValue("Enchants", tonumber(Data[11]), NewItem)
		local Upgrades = createNumberValue("Upgrades", tonumber(Data[9]), NewItem)
		local Gems = createNumberValue("Gems", tonumber(Data[12]), NewItem)

		-- Set basic attributes
		setMultipleAttributes(NewItem, {
			CurrentSlot = Data[16],
			CustomLore = Data[3],
			CustomName = Data[2],
			EnchantSlots = Data[5],
			GemSlots = Data[6],
			Owner = Data[14],
			Purity = Data[7],
			Corruption = Data[8],
			UpgradeAttempts = Data[4],
			UpgradeAttemptSuccessed = Data[10],
			Reforge = Data[13],
			Locked = Data[15],
			Enlightment = Data[21],
			Aura = Data[22] or 0,
			NBT = Data[23] or 0
		})

		-- Set enchant attributes
		setMultipleAttributes(Enchants, {
			Slot1 = Data[17][1][1] .. ":" .. Data[17][1][2],
			Slot2 = Data[17][2][1] .. ":" .. Data[17][2][2],
			Slot3 = Data[17][3][1] .. ":" .. Data[17][3][2]
		})

		-- Set gem attributes
		setMultipleAttributes(Gems, {
			Slot1 = Data[18][1],
			Slot2 = Data[18][2],
			Slot3 = Data[18][3]
		})

		-- Handle State attribute
		local Str = ""
		if type(Data[20]) == "table" then
			if #Data[20] > 0 then
				Str = table.concat(Data[20], ":")
			end
		end
		NewItem:SetAttribute("State", Str)

		-- Handle upgrades
		if Data[19] and Data[19] ~= "" then	
			for _, upgradeString in pairs(Data[19]:split("-")) do
				local values = upgradeString:split(":")
				if #values >= 2 then
					Upgrades:SetAttribute(StatsIndex[tonumber(values[1])], values[2])
				end
			end
		end

		-- Set parent based on slot
		NewItem.Parent = getSlotParent(Player, Type, Data[16])

	elseif Type == 2 or Type == 3 then -- Consumables or Materials
		setMultipleAttributes(NewItem, {
			CustomName = Data[2],
			CustomLore = Data[3],
			Amounts = tonumber(Data[4]),
			CurrentSlot = tonumber(Data[5])
		})

		-- Set parent based on type and slot
		NewItem.Parent = getSlotParent(Player, Type, Data[5])
	end
end
function ItemDictionaryHandler.ItemToData(Item)
	local _, Type = ItemDictionaryHandler.IDToName(Item.Value)
	if Type == 1 then
		local FormatData= CopyTable.Copy(EquipmentData)
		FormatData[1] = Item.Value 
		FormatData[2] = Item:GetAttribute("CustomName")
		FormatData[3] = Item:GetAttribute("CustomLore")
		FormatData[4] = Item:GetAttribute("UpgradeAttempts")
		FormatData[5] = Item:GetAttribute("EnchantSlots")
		FormatData[6] = Item:GetAttribute("GemSlots")
		FormatData[7] = Item:GetAttribute("Purity")
		FormatData[8] = Item:GetAttribute("Corruption")
		FormatData[9] = Item.Upgrades.Value
		FormatData[10] = Item:GetAttribute("UpgradeAttemptSuccessed")
		FormatData[11] = Item.Enchants.Value
		FormatData[12] = Item.Gems.Value
		FormatData[13] = Item:GetAttribute("Reforge")
		FormatData[14] = Item:GetAttribute("Owner")
		FormatData[15] = Item:GetAttribute("Locked")
		FormatData[16] = Item:GetAttribute("CurrentSlot")

		for i = 1,3 do
			local EnchantID, EnchantLevel = string.match(Item["Enchants"]:GetAttribute("Slot"..tostring(i)),ConverterPattern)
			FormatData[17][i][1] = tonumber(EnchantID)
			FormatData[17][i][2] = tonumber(EnchantLevel)
			local GemID = Item["Gems"]:GetAttribute("Slot"..tostring(i))
			FormatData[18][i] = GemID
		end
		local UpgradeString = ""
		for name,value in pairs(Item["Upgrades"]:GetAttributes()) do
			if UpgradeString == "" then
				UpgradeString = StatsPriority[name]..":"..value
			else
				UpgradeString = UpgradeString.."-"..StatsPriority[name]..":"..value
			end
		end
		FormatData[19] = UpgradeString
		local newtab = {}
		if Item:GetAttribute("State") ~= "" then
			for _,b in pairs(Item:GetAttribute("State"):split(":")) do
				table.insert(newtab,tonumber(b))
			end
		end
		FormatData[20] = newtab
		FormatData[21] = Item:GetAttribute("Enlightment")
		FormatData[22] = Item:GetAttribute("NBT")
		return FormatData
	elseif Type == 2 or Type == 3 then
		local FormatData = CopyTable.Copy(Material_ConsumableData)
		FormatData[1] = Item.Value
		FormatData[2] = Item:GetAttribute("CustomName")
		FormatData[3] = Item:GetAttribute("CustomLore")
		FormatData[4] = Item:GetAttribute("Amounts")
		FormatData[5] = Item:GetAttribute("CurrentSlot")
		return FormatData
	end
end
function ItemDictionaryHandler.GetStats(Dictionary,Mode)
	local Stats = {}
	local _,ItemType,ItemSubType = ItemDictionaryHandler.IDToName(Dictionary.ID)
	if ItemType ~= 1 then return false, "Wrong type" end
	if ItemSubType == "Pet" then return false, "Wrong type" end
	--Stats["ID"] = Dictionary["ID"]
	Stats["CustomName"] = Dictionary["CustomName"] 
	Stats["CustomLore"] = Dictionary["CustomLore"] 
	Stats["Corruption"] = Dictionary["Corruption"] 
	Stats["Purity"] = Dictionary["Purity"] 
	Stats["State"] = Dictionary["State"] 
	Stats["Owner"] = Dictionary["Owner"] 
	Stats["Locked"] = Dictionary["Locked"] 
	Stats["Reforge"] = Dictionary["Reforge"] 
	Stats["Enlightment"] = Dictionary["Enlightment"]
	if Mode == 1 then
		Stats["EnchantSlots"] = Dictionary["EnchantSlots"] 
		Stats["EnchantSlotUsed"] = Dictionary["EnchantSlotUsed"] 
		Stats["GemSlots"] = Dictionary["GemSlots"] 
		Stats["GemSlotUsed"] = Dictionary["GemSlotUsed"] 
		Stats["UpgradeAttempts"] = Dictionary["UpgradeAttempts"] 
		Stats["UpgradeAttemptSuccessed"] = Dictionary["UpgradeAttemptSuccessed"] 
		Stats["Enchants"] = CopyTable.Copy(Dictionary.Enchants)
		Stats["Upgrades"] = CopyTable.Copy(Dictionary.Upgrades)
		Stats["Gems"] = CopyTable.Copy(Dictionary.Gems)
	elseif Mode == 2 then
		Stats["UpgradeAttempts"] = Dictionary["UpgradeAttempts"] 
		Stats["UpgradeAttemptSuccessed"] = Dictionary["UpgradeAttemptSuccessed"] 
		Stats["Upgrades"] = CopyTable.Copy(Dictionary.Upgrades)
	elseif Mode == 3 then
		Stats["EnchantSlots"] = Dictionary["EnchantSlots"] 
		Stats["EnchantSlotUsed"] = Dictionary["EnchantSlotUsed"] 
		Stats["Enchants"] = CopyTable.Copy(Dictionary.Enchants)
	elseif Mode == 4 then
		Stats["GemSlots"] = Dictionary["GemSlots"] 
		Stats["GemSlotUsed"] = Dictionary["GemSlotUsed"] 
		Stats["Gems"] = CopyTable.Copy(Dictionary.Gems)
	elseif Mode == 0 then
		Stats["Locked"] = nil
		Stats["Corruption"] = nil
		Stats["Purity"] = nil
		Stats["State"] =nil
	end
	return Stats
end


return ItemDictionaryHandler
