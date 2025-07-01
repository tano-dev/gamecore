--[[
	Compatibility Test for ItemDictionaryHandler with unified ItemDataStogare
	
	Run this script to verify that the ItemDictionaryHandler works correctly
	with the new unified item data system.
]]

local ItemDictionaryHandler = require(game.ServerStorage.Modules.ItemDictionaryHandler)
local ItemData = require(game:GetService("ReplicatedStorage").GameItems.ItemDataStogare)

print("=== ItemDictionaryHandler Compatibility Test ===")

print("\n--- Test 1: IDToName ---")
local name1, type1, subtype1 = ItemDictionaryHandler.IDToName(1)
print("ID 1:", name1, type1, subtype1)

local name2, type2, subtype2 = ItemDictionaryHandler.IDToName(999)
print("ID 999:", name2, type2, subtype2)

print("\n--- Test 2: NameToID ---")
local id1, type1b, subtype1b = ItemDictionaryHandler.NameToID("Sword")
print("Name 'Sword':", id1, type1b, subtype1b)

local id2, type2b, subtype2b = ItemDictionaryHandler.NameToID("Test Scroll")
print("Name 'Test Scroll':", id2, type2b, subtype2b)

print("\n--- Test 3: Error Handling ---")
local nameX, typeX, subtypeX = ItemDictionaryHandler.IDToName(99999)
print("Non-existent ID:", nameX, typeX, subtypeX)

local idX, typeXb, subtypeXb = ItemDictionaryHandler.NameToID("Non-existent Item")
print("Non-existent Name:", idX, typeXb, subtypeXb)

print("\n--- Test 4: Data Consistency ---")
print("Total items in ByID:", #ItemData.GetAllIDs())
print("Total items in ByName:", #ItemData.GetAllNames())
print("Items should match between lookup methods")

print("\n--- Test 5: Sample Item Data ---")
local sampleItem = ItemData.GetByID(1000)
if sampleItem then
    print("Sample item:", sampleItem.Name, "ID:", sampleItem.ID, "Type:", sampleItem.ItemType, "SubType:", sampleItem.SubType)
else
    print("ERROR: Could not retrieve sample item")
end

print("\n=== Test Complete ===")

return true
