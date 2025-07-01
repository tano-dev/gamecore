--[[
	Evercyan @ March 2023
	ContentLibrary
	
	ContentLibrary is a module used to easily access the Instance & Configuration of game items (tools, armor).
	Some functions, especially server-sided functions, may require you to pass a Class of an item, instead of its physical instance.
	
	---- Accessing an Armor's configuration
	ContentLibrary.Armor["Iron Armor"].Config --> table
	
	---- Accessing a ToolInstance (IsA Tool)
	ContentLibrary.Tool["Iron Sword"].Instance --> Tool
	
	This doesn't just make it easier to access information on items, but makes it easier to iterate over them. This means you can
	nest items under ReplicatedStorage.Items as deep as you want, with any structure, as long as it's a descendant of its item folder.
	
	I decided to keep storing items under ReplicatedStorage so it's easier for you to access & expand upon them.
	This may sound like a 'stupid' conclusion, but this only comes with two notable cons.
	
	---- Cons of storing in ReplicatedStorage (shared) compared to ServerStorage (server)
	1. Items may be tampered with by exploiters.
	This won't mean they can use items. They can view the instances and place them into their character client-sided.
	These changes won't replicate, but if you want to keep the existence of certain tools a secret, you may want to
	find a solution to store your items on the server side if you know what you're doing. They cannot access server code in tools.
	
	2. Items will be replicated to every client, even if they don't own it, equating to higher client memory usage.
	Each instance & script code is stored and accessed in your computer's RAM (memory).
	This is typically less of a concern compared to loading all tools a client owns into their Backpack each time their character is loaded.
	For Infinity (my RPG), this caused lag spikes when the player would refresh if they own hundreds of tools.
	If you wish to use a server-sided approach, I highly recommend to only create tools as they equip them, or you may not benefit fully from it.
	
	
	I believe the pros of having this in ReplicatedStorage outweigh the cons for this kit, but if you feel that the two cons above may
	be a deal breaker to you, I'd recommend finding another solution. I wouldn't worry about it too much though in 99% of cases.
	
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.GameConfig)

-----------------------------------------

-- Iterates over children of the given Instance and any nested folder, regardless of the depth.
-- Returns an array with all the instances that passed the conditional.
function GetNestedInstances(Instance: Instance, Conditional)
	local Instances = {}
	
	local function Iterate(Instance)
		for _, Child in Instance:GetChildren() do
			local Conditional = Conditional(Child)
			if Conditional then
				table.insert(Instances, Child)
			elseif Child:IsA("Folder") then
				Iterate(Child)
			end
		end
	end
	
	Iterate(Instance)
	
	return Instances
end

local ContentLibrary = {}

for ItemType in GameConfig.Categories do
	ContentLibrary[ItemType] = {}
	
	local FoundItems = GetNestedInstances(ReplicatedStorage.Items[ItemType], function(Item)
		return Item:FindFirstChild("ItemConfig") and require(Item.ItemConfig).Type == ItemType
	end)
	
	for _, Item in FoundItems do
		local ItemConfig = require(Item.ItemConfig)
		
		local Class = {}
		Class.Type = ItemConfig.Type
		Class.Name = Item.Name
		Class.Instance = Item
		Class.Config = ItemConfig
		
		ContentLibrary[ItemType][Item.Name] = Class
	end
end

export type ItemConfig = {
	Type: string,
	Level: number,
	IconId: number,
	Cost: {string | number}
}

return ContentLibrary