-- [CLIENT]

--[[
	ej0w @ October 2024
	Keybinds
	
	These are returned when a keybind is used (enabled) through accessories or tools.
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

local CustomCAS = require(ReplicatedStorage.Modules.Client.CustomCAS)

local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)
local SFX = require(ReplicatedStorage.Modules.Shared.SFX)

local Callbacks = {}
for _, Module in script:GetChildren() do
	Callbacks[Module.Name] = require(Module)
end

--> Variables
local Keybinds = {}

--------------------------------------------------------------------------------

local function RequestCallKeybind(Player, Name, Verdict, ItemData)
	local Callback = Callbacks[Name] 
	if Callback then
		task.spawn(function()
			if Verdict then
				Callback:OnActivated(Player)
			else
				Callback:OnLetGo(Player)
			end
		end)
		
		if Player == Player and Verdict ~= nil and ItemData then
			EventModule:FireServer("ClientToServerKeybind", ItemData.Type, ItemData.Name, Name, Verdict)
		end
	else
		warn(`No clientside callback for keybind "{Name}", have you checked the serverside?(+)`)
	end
end

-- Set-up handler for events
EventModule:GetOnClientEvent("ServerToClientKeybind"):Connect(RequestCallKeybind)

---- Keybind setup

function Keybinds:UpdateKeybind(Key, Name, Verdict, Cooldown, Icon, HoldTime, ItemData)
	if Verdict then
		local function Validation(Verdict, GPE)
			local Character = Players.LocalPlayer.Character
			if not Character or AttributeModule:GetAttribute(Character, "Blocking") then
				return false
			end
			
			if GPE then
				return false
			end
			
			return true
		end
		
		local function Callback(Verdict, GPE)
			RequestCallKeybind(Player, Name, Verdict, ItemData)
		end
		
		CustomCAS:StartContextInput(Name, Name, nil, true, Key, Cooldown, true, HoldTime or 2, 999, Callback, Validation)
	elseif not Verdict then
		CustomCAS:StopContextInput(Name)
	end
end

return Keybinds