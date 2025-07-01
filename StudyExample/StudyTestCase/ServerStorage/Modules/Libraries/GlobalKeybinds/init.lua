-- [SERVER]

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

local function RequestCallKeybind(Player, Name, Verdict)
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
EventModule:GetOnServerEvent("ClientToServerGlobalKeybind"):Connect(function(Player, Name, Verdict)
	if typeof(Name) ~= "string" then return end
	if typeof(Verdict) ~= "boolean" then return end
	
	local KeybindData = ReplicatedStorage.Modules.Libraries.GlobalKeybinds:FindFirstChild(Name) -- TODO get cooldown & validate it exists
	KeybindData = KeybindData and require(KeybindData)
	if not KeybindData then return end
	
	local RequestedCooldown = KeybindData.Cooldown or 0

	PerPlayerCooldown[Player] = (PerPlayerCooldown[Player] or {})
	PerPlayerCooldown[Player][Name] = (PerPlayerCooldown[Player][Name] or {})

	if not PerPlayerCooldown[Player][Name][Verdict] then
		task.delay(RequestedCooldown * 0.75, function()
			PerPlayerCooldown[Player][Name][Verdict] = nil
		end)
		PerPlayerCooldown[Player][Name][Verdict] = true

		-- Fire remote to clients & callback on server
		for _, _Player in Players:GetPlayers() do
			if _Player ~= Player then
				EventModule:FireClient("ServerToClientGlobalKeybind", _Player, Player, Name, Verdict)
			end
		end
		RequestCallKeybind(Player, Name, Verdict)
	end
end)

return {}
