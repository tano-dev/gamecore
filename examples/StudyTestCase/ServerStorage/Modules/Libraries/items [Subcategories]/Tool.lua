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

function ToolLib:Give(Player: Player, Tool, DontSave, ShopBought, Amount)
	local pData = PlayerData:WaitForChild(Player.UserId, 5)
	
	local isItem = typeof(Tool) == "table" 
	if not isItem then
		warn(`Item {Library} --> {tostring(Tool) or "nil"} doesn't exist as a table, try using ContentLibrary.`)
		return
	end
	
	if pData then
		local Found = pData.Items[Library]:FindFirstChild(Tool.Name)
		
		local IsStackable = GameConfig.CanItemsStack or GameConfig.Categories[Library].IsStackable
		local CanGive = ((not Found) or IsStackable)
		
		local CanBuyMultiple = ShopBought == "Force" or (ShopBought and (not Tool.Config.Cost[4]) and IsStackable)
		if CanGive or CanBuyMultiple then
			CreateValue(pData, Tool, DontSave, Amount, Library)

			local StarterGear = Player:FindFirstChild("StarterGear")
			if StarterGear and not StarterGear:FindFirstChild(Tool.Name) then
				Tool.Instance:Clone().Parent = StarterGear
			end

			local Backpack = Player:WaitForChild("Backpack")
			if Backpack and not Backpack:FindFirstChild(Tool.Name) then
				Tool.Instance:Clone().Parent = Backpack
			end

			return true
		end
	else
		warn(("pData for Player '%s' doesn't exist! Did they leave?"):format(Player.Name))
	end
end

function ToolLib:Trash(Player: Player, Tool, Amount)
	local pData = PlayerData:WaitForChild(Player.UserId, 5)
	-- If you're making a trading system I'd be wary of waits like these, due to the possibility of this simply yielding for 5 seconds and
	-- Causing serious delays. Keep an eye out
	
	if pData then
		RemoveValue(pData, Tool, Amount, Library)
		
		local CompletelyRemoved = not pData.Items[Library]:FindFirstChild(Tool.Name)
		if CompletelyRemoved then
			if Player.StarterGear:FindFirstChild(Tool.Name) then
				Player.StarterGear[Tool.Name]:Destroy()
			end
			if Player.Backpack:FindFirstChild(Tool.Name) then
				Player.Backpack[Tool.Name]:Destroy()
			end
			if Player.Character and Player.Character:FindFirstChild(Tool.Name) then
				Player.Character[Tool.Name]:Destroy()
			end
		end
	else
		warn(("pData for Player '%s' doesn't exist! Did they leave?"):format(Player.Name))
	end
end

return ToolLib