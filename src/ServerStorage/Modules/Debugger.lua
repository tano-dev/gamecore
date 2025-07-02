local Debugger = {}

-- Load modules using the proper pattern
local ServerModules = require(script.Parent)
local ItemConverter = ServerModules("ItemConverter") -- Changed from ItemDictionaryHandler

-- General initialization function for the debugger
function Debugger.init()
    print("🔧 Debugger module initialized")
    print("Available debug functions:")
    print("  - Debugger.testItemDictionary(playerName, slotNumber)")
    print("  - Debugger.testAllPlayerSlots(playerName)")
    print("  - Debugger.testItemConversion(playerName, slotNumber)")
    print("  - Debugger.debugPlayerInventory(playerName)")
    print("  - Debugger.logError(message, context)")
    print("  - Debugger.logInfo(message)")
end

-- Specific ItemConverter testing function
function Debugger.testItemDictionary(playerName, slotNumber)
    print("🧪 Testing ItemConverter for player:", playerName, "slot:", slotNumber)
    
    local success, result = pcall(function()
        -- Safe player lookup
        local player = game.Players:FindFirstChild(playerName)
        if not player then
            error("Player '" .. playerName .. "' not found")
        end
        
        -- Safe inventory navigation
        local inventory = player:FindFirstChild("Inventory")
        if not inventory then
            error("Player has no inventory")
        end
        
        local equipments = inventory:FindFirstChild("Equipments")
        if not equipments then
            error("No equipment folder found")
        end
        
        local slot = equipments:FindFirstChild("Slot_" .. slotNumber)
        if not slot then
            error("Slot_" .. slotNumber .. " not found")
        end
        
        local item = slot:FindFirstChildOfClass("NumberValue")
        if not item then
            error("No item found in Slot_" .. slotNumber)
        end
        
        -- Convert to dictionary
        local dict = ItemConverter.ItemToDictionary(item) -- Changed from ItemDictionaryHandler
        if not dict then
            error("Failed to convert item to dictionary")
        end
        
        return dict
    end)
    
    if success then
        print("✅ Successfully converted item!")
        Debugger.printItemDetails(result)
        return result
    else
        warn("❌ Error:", result)
        return nil, result
    end
end

-- Test all equipment slots for a player
function Debugger.testAllPlayerSlots(playerName)
    print("🔍 Testing all equipment slots for player:", playerName)
    
    local player = game.Players:FindFirstChild(playerName)
    if not player then
        warn("❌ Player not found:", playerName)
        return
    end
    
    local itemCount = 0
    local emptySlots = {}
    
    for i = 1, 25 do
        local dict, error = Debugger.testItemDictionary(playerName, i)
        if dict then
            itemCount = itemCount + 1
            print(string.format("  📦 Slot %d: %s (ID: %d)", i, dict.CustomName or "Unnamed", dict.ID))
        else
            table.insert(emptySlots, i)
        end
    end
    
    print(string.format("📊 Summary: %d items found, %d empty slots", itemCount, #emptySlots))
    if #emptySlots > 0 then
        print("Empty slots:", table.concat(emptySlots, ", "))
    end
end

-- Test item conversion cycle (Item -> Dictionary -> Data -> Dictionary -> Item)
function Debugger.testItemConversion(playerName, slotNumber)
    print("🔄 Testing full item conversion cycle...")
    
    local originalDict = Debugger.testItemDictionary(playerName, slotNumber)
    if not originalDict then
        return false
    end
    
    -- Test Dictionary to Data
    local data = ItemConverter.DictionaryToData(originalDict) -- Changed from ItemDictionaryHandler
    if not data then
        warn("❌ Failed to convert dictionary to data")
        return false
    end
    print("✅ Dictionary -> Data conversion successful")
    
    -- Test Data to Dictionary
    local restoredDict = ItemConverter.DataToDictionary(data) -- Changed from ItemDictionaryHandler
    if not restoredDict then
        warn("❌ Failed to convert data back to dictionary")
        return false
    end
    print("✅ Data -> Dictionary conversion successful")
    
    -- Compare original and restored
    local matches = Debugger.compareDictionaries(originalDict, restoredDict)
    if matches then
        print("✅ Full conversion cycle successful - data integrity maintained")
    else
        warn("❌ Data integrity lost during conversion cycle")
    end
    
    return matches
end

-- Debug player's entire inventory structure
function Debugger.debugPlayerInventory(playerName)
    print("🏠 Debugging inventory structure for player:", playerName)
    
    local player = game.Players:FindFirstChild(playerName)
    if not player then
        warn("❌ Player not found:", playerName)
        return
    end
    
    local inventory = player:FindFirstChild("Inventory")
    if not inventory then
        warn("❌ No inventory found")
        return
    end
    
    print("📁 Inventory structure:")
    for _, child in pairs(inventory:GetChildren()) do
        print("  📂", child.Name, "(" .. child.ClassName .. ")")
        if child:IsA("Folder") then
            for _, subChild in pairs(child:GetChildren()) do
                local itemCount = #subChild:GetChildren()
                print("    📄", subChild.Name, "- Items:", itemCount)
            end
        end
    end
end

-- General logging functions
function Debugger.logError(message, context)
    local timestamp = os.date("%H:%M:%S")
    warn(string.format("🚨 [%s] ERROR: %s", timestamp, message))
    if context then
        warn("📍 Context:", context)
    end
end

function Debugger.logInfo(message)
    local timestamp = os.date("%H:%M:%S")
    print(string.format("ℹ️ [%s] INFO: %s", timestamp, message))
end

-- Utility function to compare two dictionaries
function Debugger.compareDictionaries(dict1, dict2)
    if type(dict1) ~= type(dict2) then
        return false
    end
    
    if type(dict1) ~= "table" then
        return dict1 == dict2
    end
    
    for key, value in pairs(dict1) do
        if not Debugger.compareDictionaries(value, dict2[key]) then
            print("❌ Mismatch at key:", key, "Expected:", value, "Got:", dict2[key])
            return false
        end
    end
    
    for key in pairs(dict2) do
        if dict1[key] == nil then
            print("❌ Extra key in dict2:", key)
            return false
        end
    end
    
    return true
end

-- Enhanced item details printing
function Debugger.printItemDetails(dict)
    print("\n📋 === Item Details ===")
    print("🆔 ID:", dict.ID)
    print("📛 Name:", dict.CustomName or "Default")
    print("📜 Lore:", dict.CustomLore or "No description")
    print("💎 Purity:", dict.Purity .. "%")
    print("👤 Owner:", dict.Owner)
    print("📍 Current Slot:", dict.CurrentSlot)
    print("🔒 Locked:", dict.Locked and "Yes" or "No")
    
    -- Print enchants if any
    if dict.Enchants then
        local hasEnchants = false
        print("\n✨ Enchants:")
        for slotName, enchant in pairs(dict.Enchants) do
            if enchant.ID and tonumber(enchant.ID) > 0 then
                print("  🔮", slotName .. ": ID=" .. enchant.ID .. ", Level=" .. enchant.Level)
                hasEnchants = true
            end
        end
        if not hasEnchants then
            print("  ❌ None")
        end
    end
    
    -- Print upgrades if any
    if dict.Upgrades then
        local hasUpgrades = false
        print("\n⬆️ Upgrades:")
        for statName, value in pairs(dict.Upgrades) do
            if tonumber(value) and tonumber(value) > 0 then
                print("  📈", statName .. ": +" .. value)
                hasUpgrades = true
            end
        end
        if not hasUpgrades then
            print("  ❌ None")
        end
    end
    
    -- Print gems if any
    if dict.Gems then
        local hasGems = false
        print("\n💎 Gems:")
        for slotName, gem in pairs(dict.Gems) do
            if gem.ID and tonumber(gem.ID) > 0 then
                print("  💠", slotName .. ": ID=" .. gem.ID)
                hasGems = true
            end
        end
        if not hasGems then
            print("  ❌ None")
        end
    end
    
    print("=" .. string.rep("=", 20) .. "=")
end

-- Quick access functions for common debugging tasks
function Debugger.quickTest(playerName, slotNumber)
    return Debugger.testItemDictionary(playerName or "tano", slotNumber or 1)
end

function Debugger.quickScan(playerName)
    return Debugger.testAllPlayerSlots(playerName or "tano")
end

return Debugger