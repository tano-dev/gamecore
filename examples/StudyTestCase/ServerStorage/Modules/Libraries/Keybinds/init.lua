-- [SERVER]

--[[
	ej0w @ October 2024
	Keybinds
	
	These are returned when a keybind is used (enabled) through accessories or tools.
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local ContentLibrary = require(ReplicatedStorage.Modules.Shared.ContentLibrary)

local Callbacks = {}
for _, Module in script:GetChildren() do
	Callbacks[Module.Name] = require(Module)
end

--> Variables
local Debounce = {}
local PerPlayerCooldown = {}

local Requests = {}
task.spawn(function()
	while true do
		Requests = {}
		
		task.wait(GameConfig.MaxInputInteractions[2])
	end
end)

--------------------------------------------------------------------------------
-- Serverside parameters --> {Player, Tool, Hit (only on .Hit)}

local function RequestCallback(Player, Name, Verdict)
	local Callback = Callbacks[Name]
	if not Callback then
		return
	end
	
	task.spawn(function()
		if Verdict then
			Callback:OnActivated(Player)
		else
			Callback:OnLetGo(Player)
		end
	end)
end

-- Set-up handler for events
EventModule:GetOnServerEvent("ClientToServerKeybind"):Connect(function(Player, ItemType, ItemName, KeybindName, Verdict)
	if typeof(ItemType) ~= "string" then return end
	if typeof(ItemName) ~= "string" then return end
	if typeof(KeybindName) ~= "string" then return end
	if typeof(Verdict) ~= "boolean" then return end
	
	local pData = PlayerData:WaitForChild(Player.UserId)
	local Items = pData:WaitForChild("Items")
	
	if not Requests[Player.UserId] then
		Requests[Player.UserId] = 0
	end
	
	Requests[Player.UserId] += 1
	if Requests[Player.UserId] > GameConfig.MaxInputInteractions[1] then
		return
	end
	
	local Accessory = ContentLibrary[ItemType][ItemName]
	
	local ConfigKeybinds = Accessory 
		and Accessory.Config 
		and Accessory.Config.Keybinds
	
	if not ConfigKeybinds then 
		return
	end
	
	local RequestedCooldown = nil
	
	for Key, Data in ConfigKeybinds do
		if Data[1] == KeybindName then
			RequestedCooldown = Data[2]
			break
		end
	end
	
	local Item = Items[ItemType]:FindFirstChild(ItemName)
	if not Item or Item:IsA("NumberValue") and Item.Value < 1 then 
		return
	end
	
	PerPlayerCooldown[Player] = (PerPlayerCooldown[Player] or {})
	PerPlayerCooldown[Player][KeybindName] = (PerPlayerCooldown[Player][KeybindName] or {})
	
	if RequestedCooldown and not PerPlayerCooldown[Player][KeybindName][Verdict] then
		task.delay(RequestedCooldown * 0.75, function()
			PerPlayerCooldown[Player][KeybindName][Verdict] = nil
		end)
		PerPlayerCooldown[Player][KeybindName][Verdict] = true
		
		-- Fire remote to clients & callback on server
		for _, _Player in Players:GetPlayers() do
			if _Player ~= Player then
				EventModule:FireClient("ServerToClientKeybind", _Player, Player, KeybindName, Verdict)
			end
		end
		RequestCallback(Player, KeybindName, Verdict)
	end
end)

return {}