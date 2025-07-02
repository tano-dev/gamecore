--[[
ItemConverter API Overview

This module provides a unified interface for converting between different representations of in-game items:
- Item instances (Roblox objects)
- Dictionaries (Lua tables with item data)
- Data arrays (for DataStore serialization)

API Functions:

1. IDToName(ID)
    - Converts an item ID (number) to its Name, Type, and SubType.
    - Returns: Name (string), Type (number), SubType (string)
    - Example:
        local name, type, subtype = ItemConverter.IDToName(1001)

2. NameToID(Name)
    - Converts an item Name (string) to its ID, Type, and SubType.
    - Returns: ID (number), Type (number), SubType (string)
    - Example:
        local id, type, subtype = ItemConverter.NameToID("Iron Sword")

3. ItemToDictionary(Item)
    - Converts a Roblox Item instance (NumberValue) into a Lua table (dictionary) containing all its attributes and children.
    - Returns: Dictionary (table)
    - Example:
        local dict = ItemConverter.ItemToDictionary(itemInstance)

4. DictionaryToItem(Dictionary, ItemParent)
    - Creates a Roblox Item instance from a dictionary and parents it to ItemParent.
    - Returns: New Item instance or error
    - Example:
        local item = ItemConverter.DictionaryToItem(dict, inventoryFolder)

5. DictionaryToData(Dictionary)
    - Converts a dictionary to a DataStore-friendly array (table) for saving.
    - Returns: Data (table)
    - Example:
        local data = ItemConverter.DictionaryToData(dict)

6. DataToDictionary(Data)
    - Converts a DataStore array back into a dictionary for loading.
    - Returns: Dictionary (table)
    - Example:
        local dict = ItemConverter.DataToDictionary(data)

7. DataToItem(Player, Data)
    - Creates and parents an Item instance to the appropriate inventory slot for the given Player, using DataStore data.
    - Example:
        ItemConverter.DataToItem(player, data)

8. ItemToData(Item)
    - Converts an Item instance to a DataStore array.
    - Returns: Data (table)
    - Example:
        local data = ItemConverter.ItemToData(itemInstance)

9. GetStats(Dictionary, Mode)
    - Extracts specific stats from a dictionary, depending on Mode:
        Mode 1: All upgrade-related stats (enchants, gems, upgrades, slots, etc.)
        Mode 2: Only upgrade stats (upgrade attempts, upgrades, etc.)
        Mode 3: Only enchant stats (enchant slots, enchants, etc.)
        Mode 4: Only gem stats (gem slots, gems, etc.)
        Mode 0: Removes status-related fields (Locked, Corruption, Purity, State)
    - Returns: Stats table or (false, errorMessage) if not applicable
    - Example:
        local stats = ItemConverter.GetStats(dict, 1)

10. GetStatsByItem(Item, Mode)
    - Extracts specific stats from a Roblox Item instance, depending on Mode (same as GetStats).
    - Returns: Stats table or (nil, errorMessage) if not applicable
    - Example:
        local stats = ItemConverter.GetStatsByItem(itemInstance, 1)

-- Usage Examples:
--[[
-- Using ReplicatedStorage directly:
local ItemConverter = require(game.ReplicatedStorage.Modules.ItemConverter)
local dict = ItemConverter.ItemToDictionary(game.Players.tano.Inventory.Equipments.Slot_1:FindFirstChildOfClass("NumberValue"))
print(dict)

-- Using ServerModules loader pattern:
local ServerModules = require(game.ServerStorage.Modules)
local ItemConverter = ServerModules("ItemConverter") 
local dict = ItemConverter.ItemToDictionary(game.Players.tano.Inventory.Equipments.Slot_1:FindFirstChildOfClass("NumberValue")) 
print(dict)
]]


local ItemConverter = {}
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


function ItemConverter.IDToName(ID: number): (string?, number?, string?)
    if not ID or type(ID) ~= "number" then
        warn("[ItemConverter]: Invalid ID parameter - expected number, got " .. type(ID))
        return nil, nil, nil
    end
    
    local itemvalue = ItemData.GetByID(ID)
    if not itemvalue then
        warn("[ItemConverter]: Item with ID " .. tostring(ID) .. " not found")
        return nil, nil, nil
    end
    return itemvalue.Name, itemvalue.ItemType, itemvalue.SubType
end

function ItemConverter.NameToID(Name: string): (number?, number?, string?)
    if not Name or type(Name) ~= "string" then
        warn("[ItemConverter]: Invalid Name parameter - expected string, got " .. type(Name))
        return nil, nil, nil
    end
    
    local itemvalue = ItemData.GetByName(Name)
    if not itemvalue then
        warn("[ItemConverter]: Item with name '" .. tostring(Name) .. "' not found")
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
function ItemConverter.ItemToDictionary(Item)
    local Name, Type = ItemConverter.IDToName(Item.Value)
    if not Name or not Type then
        warn("[ItemConverter]: ItemToDictionary failed - invalid item ID:", Item.Value)
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
function ItemConverter.DictionaryToItem(Dictionary,ItemParent)
    local Name, Type = ItemConverter.IDToName(Dictionary.ID)
    if not Name or not Type then
        warn("[ItemConverter]: DictionaryToItem failed - invalid item ID:", Dictionary.ID)
        return false, "Invalid item ID"
    end
    
    --Setting Values
    local NewItem = Instance.new("NumberValue")
    NewItem.Parent = ItemParent
    NewItem.Name = Name
    if Type == 1 then
        --if ItemParent.Parent.Name ~= "Equipments" then
        --	NewItem:Destroy()
        --	return false, ("wrong type? 137 ItemConverter")
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
        --	return false, ("wrong type? 177 ItemConverter")
        --elseif Type == 3 and ItemParent.Parent.Name ~= "Materials"  then
        --	return false, ("wrong type? 179 ItemConverter")
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
function ItemConverter.DictionaryToData(Dictionary)
    local Name, Type = ItemConverter.IDToName(Dictionary.ID)
    if not Name or not Type then
        warn("[ItemConverter]: DictionaryToData failed - invalid item ID:", Dictionary.ID)
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
function ItemConverter.DataToDictionary(Data)
    if not Data or type(Data) ~= "table" or not Data[1] then
        warn("[ItemConverter]: Invalid Data parameter for DataToDictionary")
        return nil
    end
    
    local _, Type = ItemConverter.IDToName(Data[1])
    if not Type then
        warn("[ItemConverter]: DataToDictionary failed - invalid item ID:", Data[1])
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
function ItemConverter.DataToItem(Player, Data)
    if not Player or not Data or type(Data) ~= "table" then
        warn("[ItemConverter]: Invalid parameters for DataToItem")
        return
    end
    
    local Name, Type = ItemConverter.IDToName(Data[1])
    if not Name or not Type then
        warn("[ItemConverter]: DataToItem failed - invalid item ID:", Data[1])
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
function ItemConverter.ItemToData(Item)
    local _, Type = ItemConverter.IDToName(Item.Value)
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
function ItemConverter.GetStatsByDictionary(Dictionary,Mode)
    local Stats = {}
    local _,ItemType,ItemSubType = ItemConverter.IDToName(Dictionary.ID)
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
function ItemConverter.GetStatsByItem(Item, Mode)
    -- Enhanced parameter validation
    if not Item or not Item.Value then
        warn("[ItemConverter]: GetStatsByItem - Invalid item parameter")
        return nil, "Invalid item"
    end
    
    if not Mode or type(Mode) ~= "number" then
        warn("[ItemConverter]: GetStatsByItem - Invalid mode parameter")
        return nil, "Invalid mode"
    end
    
    local Name, ItemType, ItemSubType = ItemConverter.IDToName(Item.Value)
    if not Name then
        warn("[ItemConverter]: GetStatsByItem - Item ID not found:", Item.Value)
        return nil, "Invalid item ID"
    end
    
    if ItemType ~= 1 then
        warn("[ItemConverter]: GetStatsByItem - Only equipment items supported, got type:", ItemType)
        return nil, "Wrong item type"
    end
    
    if ItemSubType == "Pet" then
        warn("[ItemConverter]: GetStatsByItem - Pet items not supported")
        return nil, "Pet items not supported"
    end

    local Stats = {}
    
    -- Core stats (always included)
    Stats["CustomName"] = Item:GetAttribute("CustomName") or ""
    Stats["CustomLore"] = Item:GetAttribute("CustomLore") or ""
    Stats["Corruption"] = Item:GetAttribute("Corruption") or 0
    Stats["Purity"] = Item:GetAttribute("Purity") or 100
    Stats["State"] = Item:GetAttribute("State") or ""
    Stats["Owner"] = Item:GetAttribute("Owner") or ""
    Stats["Locked"] = Item:GetAttribute("Locked") or false
    Stats["Reforge"] = Item:GetAttribute("Reforge") or 0
    Stats["Enlightment"] = Item:GetAttribute("Enlightment") or 0

    if Mode == 1 then -- All upgrade-related stats
        Stats["EnchantSlots"] = Item:GetAttribute("EnchantSlots") or 0
        Stats["EnchantSlotUsed"] = Item:GetAttribute("EnchantSlotUsed") or 
                                  (Item:FindFirstChild("Enchants") and Item.Enchants.Value) or 0
        Stats["GemSlots"] = Item:GetAttribute("GemSlots") or 0
        Stats["GemSlotUsed"] = Item:GetAttribute("GemSlotUsed") or 
                              (Item:FindFirstChild("Gems") and Item.Gems.Value) or 0
        Stats["UpgradeAttempts"] = Item:GetAttribute("UpgradeAttempts") or 0
        Stats["UpgradeAttemptSuccessed"] = Item:GetAttribute("UpgradeAttemptSuccessed") or 0
        
        -- Enhanced Enchants processing
        local Enchants = {
            Slot1 = {ID = 0, Level = 0},
            Slot2 = {ID = 0, Level = 0},
            Slot3 = {ID = 0, Level = 0}
        }
        
        local enchantsChild = Item:FindFirstChild("Enchants")
        if enchantsChild then
            for i = 1, 3 do
                local slotVal = enchantsChild:GetAttribute("Slot"..i)
                if slotVal and type(slotVal) == "string" then
                    local id, lvl = string.match(slotVal, ConverterPattern)
                    Enchants["Slot"..i].ID = tonumber(id) or 0
                    Enchants["Slot"..i].Level = tonumber(lvl) or 0
                end
            end
        end
        Stats["Enchants"] = Enchants
        
        -- Enhanced Gems processing
        local Gems = {
            Slot1 = {ID = 0},
            Slot2 = {ID = 0},
            Slot3 = {ID = 0}
        }
        
        local gemsChild = Item:FindFirstChild("Gems")
        if gemsChild then
            for i = 1, 3 do
                local gemVal = gemsChild:GetAttribute("Slot"..i)
                Gems["Slot"..i].ID = tonumber(gemVal) or 0
            end
        end
        Stats["Gems"] = Gems
        
        -- Enhanced Upgrades processing
        local Upgrades = {}
        local upgradesChild = Item:FindFirstChild("Upgrades")
        if upgradesChild then
            for name, value in pairs(upgradesChild:GetAttributes()) do
                Upgrades[name] = tonumber(value) or value -- Preserve original type if not number
            end
        end
        Stats["Upgrades"] = Upgrades
        
    elseif Mode == 2 then -- Only upgrade stats
        Stats["UpgradeAttempts"] = Item:GetAttribute("UpgradeAttempts") or 0
        Stats["UpgradeAttemptSuccessed"] = Item:GetAttribute("UpgradeAttemptSuccessed") or 0
        
        local Upgrades = {}
        local upgradesChild = Item:FindFirstChild("Upgrades")
        if upgradesChild then
            for name, value in pairs(upgradesChild:GetAttributes()) do
                Upgrades[name] = tonumber(value) or value
            end
        end
        Stats["Upgrades"] = Upgrades
        
    elseif Mode == 3 then -- Only enchant stats
        Stats["EnchantSlots"] = Item:GetAttribute("EnchantSlots") or 0
        Stats["EnchantSlotUsed"] = Item:GetAttribute("EnchantSlotUsed") or 
                                  (Item:FindFirstChild("Enchants") and Item.Enchants.Value) or 0
        
        local Enchants = {
            Slot1 = {ID = 0, Level = 0},
            Slot2 = {ID = 0, Level = 0},
            Slot3 = {ID = 0, Level = 0}
        }
        
        local enchantsChild = Item:FindFirstChild("Enchants")
        if enchantsChild then
            for i = 1, 3 do
                local slotVal = enchantsChild:GetAttribute("Slot"..i)
                if slotVal and type(slotVal) == "string" then
                    local id, lvl = string.match(slotVal, ConverterPattern)
                    Enchants["Slot"..i].ID = tonumber(id) or 0
                    Enchants["Slot"..i].Level = tonumber(lvl) or 0
                end
            end
        end
        Stats["Enchants"] = Enchants
        
    elseif Mode == 4 then -- Only gem stats
        Stats["GemSlots"] = Item:GetAttribute("GemSlots") or 0
        Stats["GemSlotUsed"] = Item:GetAttribute("GemSlotUsed") or 
                              (Item:FindFirstChild("Gems") and Item.Gems.Value) or 0
        
        local Gems = {
            Slot1 = {ID = 0},
            Slot2 = {ID = 0},
            Slot3 = {ID = 0}
        }
        
        local gemsChild = Item:FindFirstChild("Gems")
        if gemsChild then
            for i = 1, 3 do
                local gemVal = gemsChild:GetAttribute("Slot"..i)
                Gems["Slot"..i].ID = tonumber(gemVal) or 0
            end
        end
        Stats["Gems"] = Gems
        
    elseif Mode == 0 then -- Remove status-related fields
        Stats["Locked"] = nil
        Stats["Corruption"] = nil
        Stats["Purity"] = nil
        Stats["State"] = nil
    else
        warn("[ItemConverter]: GetStatsByItem - Invalid mode:", Mode)
        return nil, "Invalid mode"
    end

    return Stats
end

return ItemConverter