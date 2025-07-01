-- [CLIENT]

--[[
	ej0w @ November 2024
	MobFunctions
	
	Returned whenever a mob fires one of the given callbacks, ran through both client and server.
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

local function GetCachedMobFunctionName(MobInstance, Name)
	local MobConfig = Cache[MobInstance] or MobInstance:FindFirstChild("MobConfig") and require(MobInstance.MobConfig)
	Cache[MobInstance] = MobConfig

	return MobConfig and MobConfig.MobFunctionName or Name
end

local function RequestCallback(MobInstance, Name, Type, Params)
	if not MobInstance then return end
	
	Name = GetCachedMobFunctionName(MobInstance, Name)
	if not Name then return end
	
	local Callback = Callbacks[Name] and Callbacks[Name][Type]
	if Callback and not Callbacks[Name].Disabled then
		Callback(nil, MobInstance, table.unpack(Params or {}))
	end
end

-- Set-up handler for events
EventModule:GetOnClientEvent("ServerToClientMobCallback"):Connect(RequestCallback)
return {}