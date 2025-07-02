-- ItemSlotHandler - Optimized Version
--[[
Main APIs:
    CorrectSlotNumber(Player, Mode)
    GetSlots(Player, IfCheck, Mode)
    MoveToSlot(Player, Dictionary, IsBank)
    GetEmptySlots(Player, Mode, Order)
    EquipItem(Player, SelectedSlot, Slot)
    UnequipItem(Player, SelectedSlot, IsBank)
    SwapSlots(Player, Slot1, Slot2)
    SplitSlot(Player, SelectedSlot, Amounts)
    MoveItem(Player, SelectedSlot, NewSlot)
]]

local ItemSlotHandler = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
-- Dependencies
local CopyTable = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("CopyTable"))
local ItemConverter = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("ItemConverter"))
local EquippedFormat = require(game:GetService("ServerStorage"):WaitForChild("Format"):WaitForChild("EquippedFormat"))

-- Storage references
local ItemStorage = game:GetService("ReplicatedStorage"):WaitForChild("GameItems")
local StorageContainers = {
    [1] = ItemStorage:WaitForChild("Equipments"),
    [2] = ItemStorage:WaitForChild("Consumables"),
    [3] = ItemStorage:WaitForChild("Materials")
}

-- Constants
local SLOT_LIMITS = {
    Equipment = 25,
    Consumable = 36,
    Material = 36
}

local ITEM_TYPES = {
    EQUIPMENT = 1,
    CONSUMABLE = 2,
    MATERIAL = 3
}

local WEAPON_TYPES = {"Longsword", "Rapier", "Katana", "Dagger", "Staff", "Axe", "Hoe", "Fishing Rod", "Pickaxe"}
local TOOL_TYPES = {"Axe", "Hoe", "Fishing Rod", "Pickaxe"}

local STRING_PATTERN = "(%a+)%s?_%s?(%d+)"
local EQUIPPED_TABS = {
    "Weapon", "Offhand", "Aura", "Pet", "Helmet", "Chestplate", "Boots", "Tool", "Accessory", "Bow", "Fishing"
}

-- Utility functions
local function getLowest(tbl)
    local minIndex, minValue
    for i, v in pairs(tbl) do
        local num = tonumber(v)
        if num and (not minValue or num < minValue) then
            minValue = num
            minIndex = i
        end
    end
    return minIndex, minValue
end

local function getHighest(tbl)
    local maxIndex, maxValue
    for i, v in pairs(tbl) do
        local num = tonumber(v)
        if num and (not maxValue or num > maxValue) then
            maxValue = num
            maxIndex = i
        end
    end
    return maxIndex, maxValue
end

-- Enhanced player data getter with error handling and caching
local playerInventoryCache = {}
local function getPlayerInventory(player)
    -- Check cache first
    if playerInventoryCache[player] then
        local cached = playerInventoryCache[player]
        -- Validate cache is still valid
        if cached.Bank and cached.Bank.Parent then
            return cached
        else
            playerInventoryCache[player] = nil
        end
    end
    
    local success, result = pcall(function()
        return {
            Bank = player:WaitForChild("Bank"),
            Inventory = player:WaitForChild("Inventory"),
            Equipments = player:WaitForChild("Inventory"):WaitForChild("Equipments"),
            Consumables = player:WaitForChild("Inventory"):WaitForChild("Consumables"),
            Materials = player:WaitForChild("Inventory"):WaitForChild("Materials"),
            Equipped = player:WaitForChild("Inventory"):WaitForChild("Equipped"),
            MainTab = player:WaitForChild("Inventory"):WaitForChild("Equipped"):WaitForChild("Main"),
            AccessoryTab = player:WaitForChild("Inventory"):WaitForChild("Equipped"):WaitForChild("Accessory"),
            BowTab = player:WaitForChild("Inventory"):WaitForChild("Equipped"):WaitForChild("Bow"),
            FishingTab = player:WaitForChild("Inventory"):WaitForChild("Equipped"):WaitForChild("Fishing")
        }
    end)
    
    if not success then
        warn("Failed to get player inventory for", player.Name, ":", result)
        return nil
    end
    
    -- Cache the result
    playerInventoryCache[player] = result
    
    -- Clean up cache when player leaves
    game.Players.PlayerRemoving:Connect(function(leavingPlayer)
        if leavingPlayer == player then
            playerInventoryCache[player] = nil
        end
    end)
    
    return result
end

-- Optimized slot correction function with better error handling
local function processInventorySlots(container, occupiedSlots, emptySlots, isStackable)
    if not container then
        warn("[ItemSlotHandler]: processInventorySlots - Invalid container")
        return
    end
    
    for _, slot in pairs(container:GetChildren()) do
        local itemCount = #slot:GetChildren()
        local _, slotNumber = string.match(slot.Name, STRING_PATTERN)
        slotNumber = tonumber(slotNumber)
        
        if not slotNumber then
            warn("[ItemSlotHandler]: Invalid slot name format:", slot.Name)
            continue
        end
        
        if itemCount >= 2 then
            -- Move excess items to occupied list
            local itemsToMove = {}
            for i, item in pairs(slot:GetChildren()) do
                if i > 1 then
                    table.insert(itemsToMove, item)
                else
                    item:SetAttribute("CurrentSlot", slotNumber)
                end
            end
            
            for _, item in pairs(itemsToMove) do
                local success, newItem = pcall(ItemConverter.ItemToDictionary, item)
                if success and newItem then
                    table.insert(occupiedSlots, newItem)
                    item:Destroy()
                else
                    warn("[ItemSlotHandler]: Failed to convert item to dictionary:", item.Name)
                end
            end
            
        elseif itemCount == 1 then
            local item = slot:GetChildren()[1]
            
            -- Handle stackable items
            if isStackable then
                local itemContainer = StorageContainers[isStackable]
                local itemModule = itemContainer and itemContainer:FindFirstChild(item.Name)
                
                if itemModule then
                    local success, itemData = pcall(require, itemModule)
                    if success and itemData and itemData.Stackable then
                        local amounts = item:GetAttribute("Amounts") or 1
                        
                        while amounts > itemData.StackSize do
                            amounts = amounts - itemData.StackSize
                            local convertSuccess, newItem = pcall(ItemConverter.ItemToDictionary, item)
                            if convertSuccess and newItem then
                                newItem.Amounts = itemData.StackSize
                                table.insert(occupiedSlots, newItem)
                            end
                        end
                        
                        if amounts <= 0 then
                            item:Destroy()
                        else
                            item:SetAttribute("Amounts", amounts)
                            item:SetAttribute("CurrentSlot", slotNumber)
                        end
                    else
                        item:SetAttribute("CurrentSlot", slotNumber)
                    end
                else
                    item:SetAttribute("CurrentSlot", slotNumber)
                end
            else
                item:SetAttribute("CurrentSlot", slotNumber)
            end
            
        else
            table.insert(emptySlots, slotNumber)
        end
    end
end

-- Main correction function with improved error handling
function ItemSlotHandler.CorrectSlotNumber(Player, Mode)
    if not Player or not Player.Parent then
        warn("[ItemSlotHandler]: Invalid player in CorrectSlotNumber")
        return false
    end
    
    local selectedMode = Mode or 1
    local inventory = getPlayerInventory(Player)
    if not inventory then return false end
    
    local function redistributeItems(container, occupiedItems, emptySlots)
        for _, itemDict in pairs(occupiedItems) do
            if #emptySlots == 0 then
                local success = pcall(ItemConverter.DictionaryToItem, itemDict, inventory.Bank)
                if not success then
                    warn("[ItemSlotHandler]: Failed to move item to bank")
                end
            else
                local _, lowestSlot = getLowest(emptySlots)
                if lowestSlot then
                    local newSlot = container:FindFirstChild("Slot_" .. tostring(lowestSlot))
                    if newSlot then
                        itemDict.CurrentSlot = lowestSlot
                        local success = pcall(ItemConverter.DictionaryToItem, itemDict, newSlot)
                        if success then
                            -- Remove used slot from empty slots
                            for i, slot in pairs(emptySlots) do
                                if slot == lowestSlot then
                                    table.remove(emptySlots, i)
                                    break
                                end
                            end
                        else
                            warn("[ItemSlotHandler]: Failed to place item in slot", lowestSlot)
                        end
                    end
                end
            end
        end
    end
    
    -- Process different inventory types based on mode
    if selectedMode == 1 or selectedMode == 2 then -- Equipments
        local occupiedEquipments, emptyEquipmentSlots = {}, {}
        processInventorySlots(inventory.Equipments, occupiedEquipments, emptyEquipmentSlots, false)
        redistributeItems(inventory.Equipments, occupiedEquipments, emptyEquipmentSlots)
    end
    
    if selectedMode == 1 or selectedMode == 3 then -- Consumables
        local occupiedConsumables, emptyConsumableSlots = {}, {}
        processInventorySlots(inventory.Consumables, occupiedConsumables, emptyConsumableSlots, ITEM_TYPES.CONSUMABLE)
        redistributeItems(inventory.Consumables, occupiedConsumables, emptyConsumableSlots)
    end
    
    if selectedMode == 1 or selectedMode == 4 then -- Materials
        local occupiedMaterials, emptyMaterialSlots = {}, {}
        processInventorySlots(inventory.Materials, occupiedMaterials, emptyMaterialSlots, ITEM_TYPES.MATERIAL)
        redistributeItems(inventory.Materials, occupiedMaterials, emptyMaterialSlots)
    end
    
    if selectedMode == 1 or selectedMode == 5 then -- Equipped items
        local equippedContainers = {inventory.MainTab, inventory.BowTab, inventory.FishingTab, inventory.AccessoryTab}
        
        for _, container in pairs(equippedContainers) do
            for _, slot in pairs(container:GetChildren()) do
                local itemCount = #slot:GetChildren()
                
                if itemCount >= 2 then
                    -- Move excess equipped items back to inventory
                    for i, item in pairs(slot:GetChildren()) do
                        if i > 1 then
                            item:SetAttribute("CurrentSlot", 0)
                            local success, newEquipped = pcall(ItemConverter.ItemToDictionary, item)
                            if success and newEquipped then
                                item:Destroy()
                                ItemSlotHandler.MoveToSlot(Player, newEquipped)
                            end
                        else
                            item:SetAttribute("CurrentSlot", -1)
                        end
                    end
                elseif itemCount == 1 then
                    slot:GetChildren()[1]:SetAttribute("CurrentSlot", -1)
                end
            end
        end
    end
    
    if selectedMode == 6 then -- Bank
        for _, item in pairs(inventory.Bank:GetChildren()) do
            item:SetAttribute("CurrentSlot", 0)
        end
    end
    
    return true
end

-- Optimized GetSlots function with better error handling
function ItemSlotHandler.GetSlots(Player, CorrectSlots, Mode)
    if not Player or not Player.Parent then
        warn("[ItemSlotHandler]: Invalid player in GetSlots")
        return nil
    end
    
    local inventory = getPlayerInventory(Player)
    if not inventory then return nil end
    
    if CorrectSlots then
        ItemSlotHandler.CorrectSlotNumber(Player)
    end
    
    local function processContainerItems(container)
        local items = {}
        if not container then return items end
        
        for _, slot in pairs(container:GetChildren()) do
            for _, item in pairs(slot:GetChildren()) do
                local success, newItem = pcall(ItemConverter.ItemToDictionary, item)
                if success and newItem then
                    table.insert(items, newItem)
                else
                    warn("[ItemSlotHandler]: Failed to process item in slot:", slot.Name)
                end
            end
        end
        return items
    end
    
    local function processEquippedItems()
        local equippedTable = CopyTable.Copy(EquippedFormat)
        
        -- Process main equipped items
        for _, slot in pairs(inventory.MainTab:GetChildren()) do
            if #slot:GetChildren() == 1 then
                local item = slot:GetChildren()[1]
                local success, newItem = pcall(ItemConverter.ItemToDictionary, item)
                if success and newItem then
                    equippedTable[slot.Name] = newItem
                end
            end
        end
        
        -- Process accessory, bow, and fishing slots
        local specialTabs = {
            {container = inventory.AccessoryTab, target = equippedTable.Accessory},
            {container = inventory.BowTab, target = equippedTable.Bow},
            {container = inventory.FishingTab, target = equippedTable.Fishing}
        }
        
        for _, tabInfo in pairs(specialTabs) do
            if tabInfo.container and tabInfo.target then
                for _, slot in pairs(tabInfo.container:GetChildren()) do
                    if #slot:GetChildren() == 1 then
                        local item = slot:GetChildren()[1]
                        local success, newItem = pcall(ItemConverter.ItemToDictionary, item)
                        if success and newItem then
                            local _, slotNumber = string.match(slot.Name, STRING_PATTERN)
                            if slotNumber then
                                tabInfo.target["Slot" .. slotNumber] = newItem
                            end
                        end
                    end
                end
            end
        end
        
        return equippedTable
    end
    
    -- Return based on mode
    if Mode == 1 then -- All
        return processContainerItems(inventory.Equipments),
               processContainerItems(inventory.Consumables),
               processContainerItems(inventory.Materials),
               processContainerItems(inventory.Bank),
               processEquippedItems()
    elseif Mode == 2 then -- Equipment only
        return processContainerItems(inventory.Equipments)
    elseif Mode == 3 then -- Consumables only
        return processContainerItems(inventory.Consumables)
    elseif Mode == 4 then -- Materials only
        return processContainerItems(inventory.Materials)
    elseif Mode == 5 then -- Bank only
        return processContainerItems(inventory.Bank)
    elseif Mode == 6 then -- Equipped only
        return processEquippedItems()
    end
end

-- Improved MoveToSlot function
function ItemSlotHandler.MoveToSlot(Player, Dictionary, IsBank)
    if not Player or not Player.Parent then
        warn("[ItemSlotHandler]: Invalid player in MoveToSlot")
        return false
    end
    
    if not Dictionary or not Dictionary.ID then
        warn("[ItemSlotHandler]: Invalid dictionary in MoveToSlot")
        return false
    end
    
    local inventory = getPlayerInventory(Player)
    if not inventory then return false end
    
    local _, itemType = ItemConverter.IDToName(Dictionary.ID)
    if not itemType then
        warn("[ItemSlotHandler]: Invalid item ID in MoveToSlot:", Dictionary.ID)
        return false
    end
    
    if IsBank then
        local success = pcall(ItemConverter.DictionaryToItem, Dictionary, inventory.Bank)
        return success
    end
    
    local currentSlot = tonumber(Dictionary.CurrentSlot)
    local targetContainer, slotLimit
    
    if itemType == ITEM_TYPES.EQUIPMENT then
        targetContainer = inventory.Equipments
        slotLimit = SLOT_LIMITS.Equipment
    elseif itemType == ITEM_TYPES.CONSUMABLE then
        targetContainer = inventory.Consumables
        slotLimit = SLOT_LIMITS.Consumable
    elseif itemType == ITEM_TYPES.MATERIAL then
        targetContainer = inventory.Materials
        slotLimit = SLOT_LIMITS.Material
    else
        Dictionary.CurrentSlot = 0
        local success = pcall(ItemConverter.DictionaryToItem, Dictionary, inventory.Bank)
        return success
    end
    
    if currentSlot and currentSlot >= 1 and currentSlot <= slotLimit then
        local targetSlot = targetContainer:FindFirstChild("Slot_" .. currentSlot)
        if targetSlot then
            local success = pcall(ItemConverter.DictionaryToItem, Dictionary, targetSlot)
            return success
        end
    end
    
    -- Fallback to bank
    Dictionary.CurrentSlot = 0
    local success = pcall(ItemConverter.DictionaryToItem, Dictionary, inventory.Bank)
    return success
end

-- Optimized GetEmptySlots function
function ItemSlotHandler.GetEmptySlots(Player, Mode, Order)
    if not Player or not Player.Parent then
        warn("[ItemSlotHandler]: Invalid player in GetEmptySlots")
        return false
    end
    
    local inventory = getPlayerInventory(Player)
    if not inventory then return false end
    
    local function getEmptySlotsForContainer(container)
        local emptySlots = {}
        if not container then return emptySlots end
        
        for i, slot in pairs(container:GetChildren()) do
            if #slot:GetChildren() == 0 then
                local _, slotNumber = string.match(slot.Name, STRING_PATTERN)
                local num = tonumber(slotNumber)
                if num then
                    table.insert(emptySlots, num)
                end
            end
        end
        return emptySlots
    end
    
    local function processOrder(slots, order)
        if #slots == 0 then return false end
        
        if order == "GetLowest" then
            local _, value = getLowest(slots)
            return value and true or false, value
        elseif order == "GetHighest" then
            local _, value = getHighest(slots)
            return value and true or false, value
        else
            return true, slots
        end
    end
    
    if Mode == 1 then -- Equipment slots
        local emptySlots = getEmptySlotsForContainer(inventory.Equipments)
        return processOrder(emptySlots, Order)
    elseif Mode == 2 then -- Consumable slots
        local emptySlots = getEmptySlotsForContainer(inventory.Consumables)
        return processOrder(emptySlots, Order)
    elseif Mode == 3 then -- Material slots
        local emptySlots = getEmptySlotsForContainer(inventory.Materials)
        return processOrder(emptySlots, Order)
    elseif Mode == 4 then -- All inventory slots
        local equipEmpty = getEmptySlotsForContainer(inventory.Equipments)
        local consumEmpty = getEmptySlotsForContainer(inventory.Consumables)
        local materialEmpty = getEmptySlotsForContainer(inventory.Materials)
        
        local hasEmpty = #equipEmpty > 0 or #consumEmpty > 0 or #materialEmpty > 0
        return hasEmpty, equipEmpty, consumEmpty, materialEmpty
    elseif Mode == 5 then -- Equipped slots
        local function getEmptyEquippedSlots(container, isNumbered)
            local empty = {}
            if not container then return empty end
            
            for _, slot in pairs(container:GetChildren()) do
                if #slot:GetChildren() == 0 then
                    if isNumbered then
                        local _, slotNumber = string.match(slot.Name, STRING_PATTERN)
                        if slotNumber then
                            table.insert(empty, slotNumber)
                        end
                    else
                        table.insert(empty, slot.Name)
                    end
                end
            end
            return empty
        end
        
        return getEmptyEquippedSlots(inventory.MainTab, false),
               getEmptyEquippedSlots(inventory.AccessoryTab, true),
               getEmptyEquippedSlots(inventory.FishingTab, true),
               getEmptyEquippedSlots(inventory.BowTab, true)
    end
    
    return false
end

-- Enhanced EquipItem function
function ItemSlotHandler.EquipItem(Player, SelectedSlot, EquipSlot, IsSwap)
    if not Player or not Player.Parent then
        warn("[ItemSlotHandler]: Invalid player in EquipItem")
        return false, "Invalid player"
    end
    
    local inventory = getPlayerInventory(Player)
    if not inventory then return false, "Failed to get inventory" end
    
    local selectedName, selectedNumber = string.match(SelectedSlot, STRING_PATTERN)
    local equipSlotName, equipSlotNumber = string.match(EquipSlot, STRING_PATTERN)
    
    if not selectedName or not selectedNumber then
        return false, "Invalid SelectedSlot format"
    end
    
    -- Get source slot
    local sourceSlot
    if selectedName == "Equipments" then
        sourceSlot = inventory.Equipments:FindFirstChild("Slot_" .. selectedNumber)
    elseif selectedName == "Consumables" then
        sourceSlot = inventory.Consumables:FindFirstChild("Slot_" .. selectedNumber)
    else
        return false, "Invalid source slot type"
    end
    
    if not sourceSlot or #sourceSlot:GetChildren() ~= 1 then
        return false, "Source slot is empty or contains multiple items"
    end
    
    local item = sourceSlot:GetChildren()[1]
    if not item or not item.Value then
        return false, "Invalid item in source slot"
    end
    
    local itemName, itemType, itemSubType = ItemConverter.IDToName(item.Value)
    if not itemName then
        return false, "Invalid item ID"
    end
    
    -- Validate equipment compatibility
    local function canEquipToSlot(subType, targetSlot)
        if equipSlotName == "Accessory" then
            return subType == "Accessory"
        elseif targetSlot == "Weapon" then
            return table.find(WEAPON_TYPES, subType) ~= nil
        elseif targetSlot == "Offhand" then
            return subType == "Longsword" or subType == "Dagger"
        else
            return subType == targetSlot
        end
    end
    
    if not canEquipToSlot(itemSubType, EquipSlot) then
        return false, "Item cannot be equipped to this slot"
    end
    
    -- Handle equipping
    local targetSlot
    if equipSlotName == "Accessory" and equipSlotNumber then
        targetSlot = inventory.AccessoryTab:FindFirstChild("AccessorySlot_" .. equipSlotNumber)
    else
        targetSlot = inventory.MainTab:FindFirstChild(EquipSlot)
    end
    
    if not targetSlot then
        return false, "Target slot not found"
    end
    
    if #targetSlot:GetChildren() > 0 then
        if IsSwap then
            return ItemSlotHandler.SwapSlots(Player, SelectedSlot, EquipSlot)
        else
            return false, "Target slot is occupied"
        end
    end
    
    -- Equip the item
    item:SetAttribute("CurrentSlot", -1)
    item.Parent = targetSlot
    
    return true, "Item equipped successfully"
end

-- Enhanced UnequipItem function
function ItemSlotHandler.UnequipItem(Player, SelectedSlot, IfBank)
    if not Player or not Player.Parent then
        warn("[ItemSlotHandler]: Invalid player in UnequipItem")
        return false, "Invalid player"
    end
    
    local inventory = getPlayerInventory(Player)
    if not inventory then return false, "Failed to get inventory" end
    
    local sourceSlot
    if table.find(EQUIPPED_TABS, SelectedSlot) then
        sourceSlot = inventory.MainTab:FindFirstChild(SelectedSlot)
    else
        local _, slotNumber = string.match(SelectedSlot, STRING_PATTERN)
        if slotNumber then
            sourceSlot = inventory.AccessoryTab:FindFirstChild("AccessorySlot_" .. slotNumber)
        end
    end
    
    if not sourceSlot or #sourceSlot:GetChildren() ~= 1 then
        return false, "Invalid source slot or empty"
    end
    
    local item = sourceSlot:GetChildren()[1]
    if not item or not item.Value then
        return false, "Invalid item in source slot"
    end
    
    local _, itemType = ItemConverter.IDToName(item.Value)
    if not itemType then
        return false, "Invalid item ID"
    end
    
    -- Find empty slot in appropriate inventory
    local success, emptySlot = ItemSlotHandler.GetEmptySlots(Player, itemType, "GetLowest")
    
    if success and type(emptySlot) == "number" then
        local targetContainer = itemType == ITEM_TYPES.EQUIPMENT and inventory.Equipments
            or itemType == ITEM_TYPES.CONSUMABLE and inventory.Consumables
            or inventory.Materials
        
        local targetSlot = targetContainer:FindFirstChild("Slot_" .. emptySlot)
        if targetSlot then
            item:SetAttribute("CurrentSlot", emptySlot)
            item.Parent = targetSlot
            return true, "Item unequipped successfully"
        end
    elseif IfBank then
        item:SetAttribute("CurrentSlot", 0)
        item.Parent = inventory.Bank
        return true, "Item moved to bank"
    end
    
    return false, "No empty slots available"
end

-- Enhanced SwapSlots function with better error handling
function ItemSlotHandler.SwapSlots(Player, SelectedSlot, NewSlot)
    if not Player or not Player.Parent then
        warn("[ItemSlotHandler]: Invalid player in SwapSlots")
        return false, "Invalid player"
    end
    
    local inventory = getPlayerInventory(Player)
    if not inventory then return false, "Failed to get inventory" end
    
    if SelectedSlot == NewSlot then
        return false, "Cannot swap slot with itself"
    end
    
    -- Helper function to get slot reference
    local function getSlotReference(slotName)
        local name, number = string.match(slotName, STRING_PATTERN)
        
        if table.find(EQUIPPED_TABS, slotName) then
            return inventory.MainTab:FindFirstChild(slotName)
        elseif name == "Accessory" and number then
            return inventory.AccessoryTab:FindFirstChild("AccessorySlot_" .. number)
        elseif name == "Equipments" and number then
            return inventory.Equipments:FindFirstChild("Slot_" .. number)
        elseif name == "Consumables" and number then
            return inventory.Consumables:FindFirstChild("Slot_" .. number)
        elseif name == "Materials" and number then
            return inventory.Materials:FindFirstChild("Slot_" .. number)
        end
        
        return nil
    end
    
    local slot1 = getSlotReference(SelectedSlot)
    local slot2 = getSlotReference(NewSlot)
    
    if not slot1 or not slot2 then
        return false, "Invalid slot reference"
    end
    
    if #slot1:GetChildren() ~= 1 or #slot2:GetChildren() ~= 1 then
        return false, "Both slots must contain exactly one item"
    end
    
    local item1 = slot1:GetChildren()[1]
    local item2 = slot2:GetChildren()[1]
    
    -- Perform the swap
    item1.Parent = slot2
    item2.Parent = slot1
    
    -- Update slot attributes if needed
    ItemSlotHandler.CorrectSlotNumber(Player)
    
    return true, "Items swapped successfully"
end

-- Enhanced SplitSlot function
function ItemSlotHandler.SplitSlot(Player, SelectedSlot, Amounts)
    if not Player or not Player.Parent then
        warn("[ItemSlotHandler]: Invalid player in SplitSlot")
        return false, "Invalid player"
    end
    
    local inventory = getPlayerInventory(Player)
    if not inventory then return false, "Failed to get inventory" end
    
    local selectedName, selectedNumber = string.match(SelectedSlot, STRING_PATTERN)
    local itemType = selectedName == "Consumables" and ITEM_TYPES.CONSUMABLE
        or selectedName == "Materials" and ITEM_TYPES.MATERIAL
        or nil
    
    if not itemType then
        return false, "Invalid slot type for splitting"
    end
    
    local container = itemType == ITEM_TYPES.CONSUMABLE and inventory.Consumables or inventory.Materials
    local sourceSlot = container:FindFirstChild("Slot_" .. selectedNumber)
    
    if not sourceSlot or #sourceSlot:GetChildren() ~= 1 then
        return false, "Invalid source slot"
    end
    
    local item = sourceSlot:GetChildren()[1]
    if not item or not item.Name then
        return false, "Invalid item in source slot"
    end
    
    local itemContainer = StorageContainers[itemType]
    local itemModule = itemContainer and itemContainer:FindFirstChild(item.Name)
    
    if not itemModule then
        return false, "Item data not found"
    end
    
    local success, serverItemData = pcall(require, itemModule)
    if not success or not serverItemData then
        return false, "Failed to load item data"
    end
    
    if not serverItemData.Stackable then
        return false, "Item is not stackable"
    end
    
    local currentAmounts = item:GetAttribute("Amounts") or 1
    if currentAmounts <= Amounts then
        return false, "Cannot split more than current amount"
    end
    
    local hasEmpty, emptySlot = ItemSlotHandler.GetEmptySlots(Player, itemType, "GetLowest")
    if not hasEmpty then
        return false, "No empty slots available"
    end
    
    -- Create new item dictionary for split
    local convertSuccess, newItem = pcall(ItemConverter.ItemToDictionary, item)
    if not convertSuccess or not newItem then
        return false, "Failed to convert item to dictionary"
    end
    
    newItem.Amounts = Amounts
    newItem.CurrentSlot = emptySlot
    
    -- Update original item
    item:SetAttribute("Amounts", currentAmounts - Amounts)
    
    -- Move new item to empty slot
    local moveSuccess = ItemSlotHandler.MoveToSlot(Player, newItem)
    if not moveSuccess then
        return false, "Failed to move split item"
    end
    
    return true, "Item split successfully"
end

-- Enhanced MoveItem function
function ItemSlotHandler.MoveItem(Player, SelectedSlot, NewSlot)
    if not Player or not Player.Parent then
        warn("[ItemSlotHandler]: Invalid player in MoveItem")
        return false, "Invalid player"
    end
    
    local inventory = getPlayerInventory(Player)
    if not inventory then return false, "Failed to get inventory" end
    
    local selectedName, selectedNumber = string.match(SelectedSlot, STRING_PATTERN)
    local newName, newNumber = string.match(NewSlot, STRING_PATTERN)
    
    if not selectedName or not selectedNumber or not newName or not newNumber then
        return false, "Invalid slot format"
    end
    
    if selectedName ~= newName then
        return false, "Cannot move between different inventory types"
    end
    
    local container = inventory[selectedName]
    if not container then
        return false, "Invalid container"
    end
    
    local sourceSlot = container:FindFirstChild("Slot_" .. selectedNumber)
    local targetSlot = container:FindFirstChild("Slot_" .. newNumber)
    
    if not sourceSlot or not targetSlot then
        return false, "Invalid slot reference"
    end
    
    local sourceItem = sourceSlot:FindFirstChildOfClass("NumberValue")
    if not sourceItem then
        return false, "No item found in source slot"
    end
    
    if #targetSlot:GetChildren() == 1 then
        -- Swap items
        return ItemSlotHandler.SwapSlots(Player, SelectedSlot, NewSlot)
    elseif #targetSlot:GetChildren() == 0 then
        -- Move to empty slot
        sourceItem:SetAttribute("CurrentSlot", tonumber(newNumber))
        sourceItem.Parent = targetSlot
        return true, "Item moved successfully"
    else
        return false, "Target slot contains multiple items"
    end
end

return ItemSlotHandler