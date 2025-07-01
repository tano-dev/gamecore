--[[
	ej0w @ November 2024
	GlobalKeybindsSetup
	
	This module is to handle custom keybinds for the client: add keybinds under RS --> Modules --> Client--> GlobalKeybinds
]]

--> Services
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer

local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")
local pData = PlayerData:WaitForChild(Player.UserId)

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local CustomCAS = require(ReplicatedStorage.Modules.Client.CustomCAS)

local Callbacks = {}
for _, Module in ReplicatedStorage.Modules.Libraries.GlobalKeybinds:GetChildren() do
	Callbacks[Module.Name] = require(Module)
end

--------------------------------------------------------------------------------

for Name, Keybind in Callbacks do
	if Keybind.Disabled then 
		continue 
	end
	
	local function Validation(Verdict, GPE)
		if GPE then
			return false
		end
		
		local Success = Keybind:RequestValidation(Player)
		if not Success then
			return false
		end

		return true
	end
	
	local function Callback(Verdict, GPE)
		if Verdict == false and not Keybind.ActivateCooldownWhenLetGo then
			return
		end
		
		EventModule:Fire("ClientToClientGlobalKeybind", Player, Name, Verdict)
	end
	
	CustomCAS:StartContextInput(Name, Name, Keybind.Icon, Keybind.MakeInputButton, Keybind.Key, Keybind.Cooldown, Keybind.ActivateCooldownWhenLetGo, nil, Keybind.Priority or 999, Callback, Validation, Keybind.CustomText, not Keybind.MakeClickSound, not Keybind.CanPress)
end

return {}