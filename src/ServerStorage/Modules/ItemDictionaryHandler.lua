--APIs
--[[
Main APIs:
 MainUsage
	IDToName(ID)
		> return Name, Type, SubType
	NameToID(Name)
		> return ID, Type, SubType
	ItemToDictionary(Item)
		> return Dictionary
	DictionaryToItem(Dictionary,ItemParent)
		> yield error if wrong slot
 DataStoreUsage
 	DictionaryToData(Dictionary)
 		> return Data for saving
 	DataToDictionary(Data)
 		> return Dictionary for loading
 Item Crafting/DismantlingUsage
 	GetStats(Dictionary,Mode)
 		>return specific stats
 		Mode 1-all upgrade related
 		2-upgreade
 		3-enchant
 		4-gem
 		0-remove status
	
]]
--Usage 
--[[
local a = require(game.ReplicatedStorage.Modules.ItemDictionaryHandler) 
local b = a.ItemToDictionary(game.Players.tano.Inventory.Equipments.Slot_4:FindFirstChildOfClass("NumberValue")) 
print(b)



]]
local ItemDictionaryHandler = {}
local ConverterPattern = "(%d+)%s?:%s?(%d+)"
local NameOrIDConverter = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("NameOrIDConverter"))
local CopyTable = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("CopyTable"))
local Priority ={
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
--Formats
local ItemData = require(game:GetService("ReplicatedStorage"):WaitForChild("GameItems"):WaitForChild("ItemData"))
local ItemDataStogare = require(game:GetService("ReplicatedStorage"):WaitForChild("GameItems"):WaitForChild("ItemDataStogare"))
local EquipmentFormat = require(game:GetService("ReplicatedStorage"):WaitForChild("Format"):WaitForChild("EquipmentFormat"))
local EquipmentData = require(game:GetService("ReplicatedStorage"):WaitForChild("Format"):WaitForChild("EquipmentData"))
local StatsPriority = require(game:GetService("ReplicatedStorage"):WaitForChild("Format"):WaitForChild("StatsPriority"))
local StatsIndex = require(game:GetService("ReplicatedStorage"):WaitForChild("Format"):WaitForChild("StatsIndex"))
local Material_ConsumableFormat = require(game:GetService("ReplicatedStorage"):WaitForChild("Format"):WaitForChild("Material_ConsumableFormat"))
local Material_ConsumableData = require(game:GetService("ReplicatedStorage"):WaitForChild("Format"):WaitForChild("Material_ConsumableData"))


function ItemDictionaryHandler.IDToName(ID:number)
	local itemvalue = ItemData[ID]
	return itemvalue.Name,itemvalue.ItemType,itemvalue.SubType
end
--function ItemDictionaryHandler.NameToID(Name)
--	for i,v in pairs(ItemDataStogare) do
--		if i == Name then
--			return v.ID , v.ItemType, v.SubType
--		end
--	end
--end


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
	if Type == 1 then
		local FormatDictionary = CopyTable.Copy(EquipmentFormat)
		FormatDictionary.ID = Item.Value 
		--CopyTable to Format
		for n,v in pairs(Item:GetAttributes()) do
			FormatDictionary[n] = v
		end
		--Get Children from copied format
		for i,v in pairs(Item:GetChildren()) do
			if v.Name == "Upgrades" then
				FormatDictionary.UpgradeAttemptUsed = v.Value
				for n,v in pairs(v:GetAttributes()) do
					FormatDictionary.Upgrades[n] = v
				end
			end
			if v.Name == "Enchants" then
				FormatDictionary.EnchantSlotUsed = v.Value
				for n,v in pairs(v:GetAttributes()) do
					--string convert
					local EnchantID, Level = string.match(v,ConverterPattern)
					FormatDictionary.Enchants[n]["ID"] = EnchantID
					FormatDictionary.Enchants[n]["Level"] = Level
				end
			end
			if v.Name == "Gems" then
				FormatDictionary.GemSlotUsed = v.Value
				for n,v in pairs(v:GetAttributes()) do
					FormatDictionary.Gems[n]["ID"] = v
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
	--Setting Values
	local NewItem = Instance.new("NumberValue",ItemParent)
	NewItem.Name = Name
	if Type == 1 then
		--if ItemParent.Parent.Name ~= "Equipments" then
		--	NewItem:Destroy()
		--	return false, ("wrong type? 137 ItemDictionaryHandler")
		--end
		NewItem.Value = Dictionary.ID
		local Enchants  = Instance.new("NumberValue",NewItem)
		Enchants.Name = "Enchants"
		Enchants.Value = tonumber(Dictionary.EnchantSlotUsed)
		local Upgrades  = Instance.new("NumberValue",NewItem)
		Upgrades.Name = "Upgrades"
		Upgrades.Value = tonumber(Dictionary.UpgradeAttemptUsed)
		local Gems  = Instance.new("NumberValue",NewItem)
		Gems.Name = "Gems"
		Gems.Value = tonumber(Dictionary.GemSlotUsed)
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
					for a,b in pairs(v:split(":")) do
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
	local Name, Type = ItemDictionaryHandler.IDToName(Data[1])
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
		for i,v in pairs(Data[17]) do
			NewDictionary.Enchants["Slot"..i].ID = v[1]
			NewDictionary.Enchants["Slot"..i].Level = v[2]
		end
		for i,v in pairs(Data[18]) do
			NewDictionary.Gems["Slot"..i].ID = v
		end
		for a,b in pairs(Data[19]:split("-")) do
			local c = b:split(":")
			for e,f in pairs(StatsPriority) do
				if tonumber(c[1]) == f then
					NewDictionary.Upgrades[e] = c[2]
				end
			end
		end

		local Str
		if type(Data[20]) then
			if #Data[20] == 0 then
				Str = ""
			elseif #Data[20] > 0 then
				for i,v in pairs(Data[20]) do
					if Str == nil then
						Str = v 
					else
						Str = Str..":"..v
					end
				end
			else Str = ""
			end
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
function ItemDictionaryHandler.DataToItem(Player,Data)
	local Bank = Player:FindFirstChild("Bank")
	local Inventory = Player:FindFirstChild("Inventory")
	local Equipments = Inventory:FindFirstChild("Equipments")
	local Consumables = Inventory:FindFirstChild("Consumables")
	local Materials = Inventory:FindFirstChild("Materials")
	local Equipped = Inventory:FindFirstChild("Equipped")
	
	local Name, Type = ItemDictionaryHandler.IDToName(Data[1])
	--Setting Values
	local NewItem = Instance.new("NumberValue")
	NewItem.Name = Name
	if Type == 1 then
		--if ItemParent.Parent.Name ~= "Equipments" then
		--	NewItem:Destroy()
		--	return false, ("wrong type? 137 ItemDictionaryHandler")
		--end
		NewItem.Value = Data[1]
		local Enchants  = Instance.new("NumberValue",NewItem)
		Enchants.Name = "Enchants"
		Enchants.Value = tonumber(Data[11])
		local Upgrades  = Instance.new("NumberValue",NewItem)
		Upgrades.Name = "Upgrades"
		Upgrades.Value = tonumber(Data[9])
		local Gems  = Instance.new("NumberValue",NewItem)
		Gems.Name = "Gems"
		Gems.Value = tonumber(Data[12])
		--Setting Attributes
		NewItem:SetAttribute("CurrentSlot",Data[16])
		NewItem:SetAttribute("CustomLore",Data[3])
		NewItem:SetAttribute("CustomName",Data[2])
		NewItem:SetAttribute("EnchantSlots",Data[5])
		NewItem:SetAttribute("GemSlots",Data[6])
		NewItem:SetAttribute("Owner",Data[14])
		NewItem:SetAttribute("Purity",Data[7])
		NewItem:SetAttribute("Corruption",Data[8])
		NewItem:SetAttribute("UpgradeAttempts",Data[4])
		NewItem:SetAttribute("UpgradeAttemptSuccessed",Data[10])
		NewItem:SetAttribute("Reforge",Data[13])
		NewItem:SetAttribute("Locked",Data[15])

		NewItem:SetAttribute("Enlightment",Data[21])
		NewItem:SetAttribute("Aura",Data[22] or 0)
		NewItem:SetAttribute("NBT",Data[23] or 0)
		Enchants:SetAttribute("Slot1",Data[17][1][1]..":"..Data[17][1][2])
		Enchants:SetAttribute("Slot2",Data[17][2][1]..":"..Data[17][2][2])
		Enchants:SetAttribute("Slot3",Data[17][3][1]..":"..Data[17][3][2])
		Gems:SetAttribute("Slot1",Data[18][1])
		Gems:SetAttribute("Slot2",Data[18][2])
		Gems:SetAttribute("Slot3",Data[18][3])
		local Str
		if type(Data[20]) then
			if #Data[20] == 0 then
				Str = ""
			elseif #Data[20] > 0 then
				for i,v in pairs(Data[20]) do
					if Str == nil then
						Str = v 
					else
						Str = Str..":"..v
					end
				end
			else Str = ""
			end
		end
		NewItem:SetAttribute("State",Str)
		--Upgrade filling
		--for name,value in pairs(Dictionary.Upgrades) do
		--	Upgrades:SetAttribute(name,value)
		--end
		print(Data[19])
		if Data[19] ~= "" then	
			for index1,upgradeString in pairs(Data[19]:split("-")) do
				local values = upgradeString:split(":")
				--for e,f in pairs(StatsPriority) do
				--	if tonumber(values[1]) == f then
				--		NewDictionary.Upgrades[e] = values[2]
				--	end
				--end
				print(values)
				Upgrades:SetAttribute(StatsIndex[tonumber(values[1])],values[2])
			end
		end

		if Data[16] <= 25 and Data[16] >= 1 then
			NewItem.Parent = Equipments:FindFirstChild("Slot_"..tostring(Data[16]))
			--elseif Type == 2 and tonumber(Dictionary.CurrentSlot) <= 36 and tonumber(Dictionary.CurrentSlot) >= 1  then
			--	--local NewSlot = Consumables:WaitForChild("Slot_"..Dictionary.CurrentSlot)
			--	--ItemDictionaryHandler.DictionaryToItem(Dictionary,NewSlot)
			--	ItemDictionaryHandler.DictionaryToItem(Dictionary,Consumables:WaitForChild("Slot_"..Dictionary.CurrentSlot))
			--elseif Type == 3 and tonumber(Dictionary.CurrentSlot) <= 36 and tonumber(Dictionary.CurrentSlot) >= 1  then
			--	--local NewSlot = Materials:WaitForChild("Slot_"..Dictionary.CurrentSlot)
			--	--ItemDictionaryHandler.DictionaryToItem(Dictionary,NewSlot)
			--	ItemDictionaryHandler.DictionaryToItem(Dictionary,Materials:WaitForChild("Slot_"..Dictionary.CurrentSlot))
		
		elseif Data[16] == -1 then
			NewItem.Parent = Equipped.Main.Weapon
		elseif Data[16] == -2 then
			NewItem.Parent = Equipped.Main.Offhand
		elseif Data[16] == -3 then
			NewItem.Parent = Equipped.Main.Tool
		elseif Data[16] == -4 then
			NewItem.Parent = Equipped.Main.Helmet
		elseif Data[16] == -5 then
			NewItem.Parent = Equipped.Main.Chestplate
		elseif Data[16] == -6 then
			NewItem.Parent = Equipped.Main.Boots
		elseif Data[16] == -7 then
			NewItem.Parent = Equipped.Main.Pet
		else
			NewItem.Parent = Bank
		end
	elseif Type == 2 or Type == 3 then
		--if Type == 2 and ItemParent.Parent.Name ~= "Consumables"  then
		--	return false, ("wrong type? 177 ItemDictionaryHandler")
		--elseif Type == 3 and ItemParent.Parent.Name ~= "Materials"  then
		--	return false, ("wrong type? 179 ItemDictionaryHandler")
		--end

		NewItem.Value = tonumber(Data[1])
		NewItem:SetAttribute("CustomName",Data[2])
		NewItem:SetAttribute("CustomLore",Data[3])
		NewItem:SetAttribute("Amounts",tonumber(Data[4]))
		NewItem:SetAttribute("CurrentSlot",tonumber(Data[5]))
		if Type == 2 and Data[5] <= 36 and Data[5] >= 1 then
			NewItem.Parent = Consumables:FindFirstChild("Slot_"..tostring(Data[5]))
			--elseif Type == 2 and tonumber(Dictionary.CurrentSlot) <= 36 and tonumber(Dictionary.CurrentSlot) >= 1  then
			--	--local NewSlot = Consumables:WaitForChild("Slot_"..Dictionary.CurrentSlot)
			--	--ItemDictionaryHandler.DictionaryToItem(Dictionary,NewSlot)
			--	ItemDictionaryHandler.DictionaryToItem(Dictionary,Consumables:WaitForChild("Slot_"..Dictionary.CurrentSlot))
			--elseif Type == 3 and tonumber(Dictionary.CurrentSlot) <= 36 and tonumber(Dictionary.CurrentSlot) >= 1  then
			--	--local NewSlot = Materials:WaitForChild("Slot_"..Dictionary.CurrentSlot)
			--	--ItemDictionaryHandler.DictionaryToItem(Dictionary,NewSlot)
			--	ItemDictionaryHandler.DictionaryToItem(Dictionary,Materials:WaitForChild("Slot_"..Dictionary.CurrentSlot))
		elseif Type == 3 and Data[5] <= 36 and Data[5] >= 1 then
			NewItem.Parent = Materials:FindFirstChild("Slot_"..tostring(Data[5]))
		elseif Type == 2 and Data[5] == -8 then
			NewItem.Parent = Equipped.Main.Aura
		else
			NewItem.Parent = Bank
		end
	end
end
function ItemDictionaryHandler.ItemToData(Item)
	local Name, Type = ItemDictionaryHandler.IDToName(Item.Value)
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
			for a,b in pairs(Item:GetAttribute("State"):split(":")) do
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
	local ItemName,ItemType,ItemSubType = ItemDictionaryHandler.IDToName(Dictionary.ID)
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
