--[[
	Evercyan @ March 2023
	ToolLib
	
	ToolLib is an item library that houses code that can be ran on the server relating
	to Tools, such as ToolLib:Give(Player, Tool (ContentLib.Tool[...]))
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local ContentLibrary = require(ReplicatedStorage.Modules.Shared.ContentLibrary)

local CreateValue = require(ServerStorage.Modules.Server.createValue)
local RemoveValue = require(ServerStorage.Modules.Server.removeValue)

local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local Library = script.Name
local ToolLib = {}

--------------------------------------------------------------------------------

function ToolLib:Give(Player: Player, Item, DontSave, ShopBought, Amount)
	local pData = PlayerData:WaitForChild(Player.UserId, 5)
	
	local isItem = typeof(Item) == "table" 
	if not isItem then
		warn(`Item {Library} --> {tostring(Item) or "nil"} doesn't exist as a table, try using ContentLibrary.`)
		return
	end
	
	if pData then
		CreateValue(pData, Item, DontSave, Amount, Library)
		return true
	else
		warn(("pData for Player '%s' doesn't exist! Did they leave?"):format(Player.Name))
	end
end

function ToolLib:Trash(Player: Player, Item, Amount)
	Amount = Amount or 1
	
	local pData = PlayerData:WaitForChild(Player.UserId, 5)
	if pData then
		RemoveValue(pData, Item, Amount, Library)
	else
		warn(("pData for Player '%s' doesn't exist! Did they leave?"):format(Player.Name))
	end
end

return ToolLib