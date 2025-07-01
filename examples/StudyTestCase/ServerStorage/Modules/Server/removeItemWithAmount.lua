--[[
	ej0w @ October 2024
	RemoveItemWithAmount
	
	Simple utility to change add/remove based off of an amount
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

--> Player
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local ContentLibrary = require(ReplicatedStorage.Modules.Shared.ContentLibrary)

--> Variables
local Libraries = {}
for _, Module in ServerStorage.Modules.Libraries["items [Subcategories]"]:GetChildren() do
	Libraries[Module.Name] = require(Module)
end

--------------------------------------------------------------------------------

return function(Player, ItemType: string, ItemName: string, Amount)
	local pData = PlayerData:FindFirstChild(Player.UserId)
	local Item = ContentLibrary[ItemType] and ContentLibrary[ItemType][ItemName]

	local IsNumberValue = Item.Instance.ClassName == "NumberValue"
	if IsNumberValue then
		Libraries[ItemType]:Trash(Player, Item, Amount)
	elseif not IsNumberValue then
		for Iteration = 1, Amount do
			Libraries[ItemType]:Trash(Player, Item)
		end
	end
end