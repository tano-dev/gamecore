-- [CLIENT]

--[[
	ej0w @ October 2024
	Callbacks
	
	These are returned when an item is used.
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Dependencies
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)

local Callbacks = {}
for _, Module in script:GetChildren() do
	Callbacks[Module.Name] = require(Module)
end

--------------------------------------------------------------------------------
-- Clientside parameters --> {Player, Tool, Hit (only on .Hit)}

local Cache = {}

local function GetCachedToolCallbackName(Player, Name)
	local Character = Player.Character
	local Tool = Character and Character:FindFirstChild(Name) or Player.Backpack:FindFirstChild(Name)

	local ItemConfig = Cache[Name] or Tool:FindFirstChild("ItemConfig") and require(Tool.ItemConfig)
	Cache[Name] = ItemConfig

	return ItemConfig and ItemConfig.CallbackName or Name
end

local function RequestCallback(Player, Name, Type, Params)
	if not Player then return end
	
	Name = GetCachedToolCallbackName(Player, Name)
	if not Name then return end
	
	local ChosenModule = Callbacks[Name] or Callbacks.Default
	local Callback = ChosenModule and ChosenModule[Type]
	if Callback and not Callbacks[Name].Disabled then
		Callback(nil, Player, table.unpack(Params or {}))
	end
end

-- Set-up handler for events
EventModule:GetOnEvent("ClientToClientCallback"):Connect(RequestCallback)
EventModule:GetOnClientEvent("ServerToClientCallback"):Connect(RequestCallback)
return {}