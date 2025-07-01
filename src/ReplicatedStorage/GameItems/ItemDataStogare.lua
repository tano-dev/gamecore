--[[
	ItemData - Unified Item Database
	
	Supports both ID and Name lookups:
	- ItemData.ByID[1] -> Get item by ID
	- ItemData.ByName["Sword"] -> Get item by name
	- ItemData.GetByID(1) -> Function to get by ID with validation
	- ItemData.GetByName("Sword") -> Function to get by name with validation
]]

local ItemDatabase = {
	-- Raw item data (ID-indexed)
	[1] = {Name = "Sword", ItemType = 1, SubType = "Longsword"},
	[2] = {Name = "Wood", ItemType = 3, SubType = "Material"},
	[3] = {Name = "Sugoi Mushroom", ItemType = 2, SubType = "Food"},
	[4] = {Name = "Common Upgrade Crystal", ItemType = 2, SubType = "Upgrader"},
	[5] = {Name = "Steel", ItemType = 3, SubType = "Material"},
	[6] = {Name = "Iron", ItemType = 3, SubType = "Material"},
	[7] = {Name = "Steel Sword", ItemType = 1, SubType = "Longsword"},
	[8] = {Name = "Enchanted Wood", ItemType = 3, SubType = "Material"},
	[9] = {Name = "Woodcutting Trinket", ItemType = 1, SubType = "Accessory"},
	[10] = {Name = "Steel Bowstring", ItemType = 1, SubType = "Bowstring"},
	[11] = {Name = "Firefly Float", ItemType = 1, SubType = "Float"},
	[12] = {Name = "Firefly Reel", ItemType = 1, SubType = "Reel"},
	[14] = {Name = "Minnow Bait", ItemType = 2, SubType = "Bait"},
	[97] = {Name = "Fireveil Arrow", ItemType = 2, SubType = "Arrow"},
	[98] = {Name = "Light Essense", ItemType = 3, SubType = "Material"},
	[99] = {Name = "Dark Essense", ItemType = 3, SubType = "Material"},
	[100] = {Name = "Purity Crystal", ItemType = 2, SubType = "Upgrader"},
	[101] = {Name = "Dark Crystal", ItemType = 2, SubType = "Upgrader"},
	[102] = {Name = "Unstable Power Crystal", ItemType = 2, SubType = "Upgrader"},
	[103] = {Name = "Reciprem Crystal", ItemType = 2, SubType = "Upgrader"},
	[104] = {Name = "Reciprism Scroll", ItemType = 2, SubType = "Upgrader"},
	[105] = {Name = "Holy Essense", ItemType = 3, SubType = "Material"},
	[106] = {Name = "Nightmare Essense", ItemType = 3, SubType = "Material"},
	[998] = {Name = "Aetheric Surge Crystal", ItemType = 2, SubType = "Upgrader"},
	[999] = {Name = "Test Scroll", ItemType = 2, SubType = "Upgrader"},
	[1000] = {Name = "Manarias", ItemType = 1, SubType = "Longsword"},
}

-- Create lookup tables
local ItemData = {
	ByID = {},
	ByName = {},
}

-- Populate lookup tables and add ID to each item
for id, itemData in pairs(ItemDatabase) do
	-- Add ID to item data
	local item = table.clone(itemData)
	item.ID = id
	
	-- Store in both lookup tables
	ItemData.ByID[id] = item
	ItemData.ByName[itemData.Name] = item
end

-- Utility functions
function ItemData.GetByID(id)
	if type(id) ~= "number" then
		warn("[ItemData]: GetByID expects a number, got " .. type(id))
		return nil
	end
	return ItemData.ByID[id]
end

function ItemData.GetByName(name)
	if type(name) ~= "string" then
		warn("[ItemData]: GetByName expects a string, got " .. type(name))
		return nil
	end
	return ItemData.ByName[name]
end

-- Get all items of a specific type (OPTIMIZED for large datasets)
function ItemData.GetByType(itemType)
	local result = {}
	local count = 0
	for _, item in pairs(ItemData.ByID) do
		if item.ItemType == itemType then
			count = count + 1
			result[count] = item
		end
	end
	return result
end

-- Get all items of a specific subtype (OPTIMIZED for large datasets)
function ItemData.GetBySubType(subType)
	local result = {}
	local count = 0
	for _, item in pairs(ItemData.ByID) do
		if item.SubType == subType then
			count = count + 1
			result[count] = item
		end
	end
	return result
end

-- Check if item exists
function ItemData.Exists(identifier)
	if type(identifier) == "number" then
		return ItemData.ByID[identifier] ~= nil
	elseif type(identifier) == "string" then
		return ItemData.ByName[identifier] ~= nil
	end
	return false
end

-- Get all item IDs
function ItemData.GetAllIDs()
	local ids = {}
	for id, _ in pairs(ItemData.ByID) do
		table.insert(ids, id)
	end
	table.sort(ids)
	return ids
end

-- Get all item names
function ItemData.GetAllNames()
	local names = {}
	for name, _ in pairs(ItemData.ByName) do
		table.insert(names, name)
	end
	table.sort(names)
	return names
end

return ItemData
