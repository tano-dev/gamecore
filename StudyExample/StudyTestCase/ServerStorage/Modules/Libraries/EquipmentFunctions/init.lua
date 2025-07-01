-- [SERVER]

--[[
	ej0w @ November 2024
	EquipmentFunctions
	
	Ran through both client and server, includes callbacks for both armor & accessories.
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

local Cache = {}

local function GetCachedEquipmentFunctionName(Model, Name)
	local Config = Model:FindFirstChild("ItemConfig") and require(Model.ItemConfig)
	return Config and Config.EquipmentFunctionName or Name
end

local function RequestCallback(Model, Name, Type, Params)
	if not Model then return end
	
	Name = GetCachedEquipmentFunctionName(Model, Name)
	if not Name then return end
	
	local Callback = Callbacks[Name] and Callbacks[Name][Type]
	if Callback and not Callbacks[Name].Disabled then
		Callback(nil, table.unpack(Params or {}))
	end
end

-- Set-up handler for events
EventModule:GetOnEvent("ServerToServerEquipmentCallback"):Connect(RequestCallback)
return {}