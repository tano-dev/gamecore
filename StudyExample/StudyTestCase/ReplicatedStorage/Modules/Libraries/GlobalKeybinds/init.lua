-- [CLIENT]

--[[
	ej0w @ November 2024
	GlobalKeybinds
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

local EventModule = require(ReplicatedStorage.Modules.Shared.Event)

local Callbacks = {}
for _, Module in script:GetChildren() do
	Callbacks[Module.Name] = require(Module)
end

--------------------------------------------------------------------------------

local function RequestCallKeybind(Player, Name, Verdict)
	local Callback = Callbacks[Name] 
	if Callback then
		task.spawn(function()
			if Verdict then
				Callback:OnActivated(Player)
			else
				Callback:OnLetGo(Player)
			end
		end)

		if Player == Players.LocalPlayer and Verdict ~= nil then
			EventModule:FireServer("ClientToServerGlobalKeybind", Name, Verdict)
		end
	else
		warn(`No clientside callback for *global keybind* "{Name}", have you checked the serverside?(+)`)
	end
end

-- Set-up handler for events
EventModule:GetOnClientEvent("ServerToClientGlobalKeybind"):Connect(RequestCallKeybind)
EventModule:GetOnEvent("ClientToClientGlobalKeybind"):Connect(RequestCallKeybind)

return {}
