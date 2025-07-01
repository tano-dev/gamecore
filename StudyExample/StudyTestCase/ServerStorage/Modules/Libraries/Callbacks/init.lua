-- [SERVER]

--[[
	ej0w @ October 2024
	Callbacks
	
	These are returned when an item is used.
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--> Dependencies
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)

local GameConfig = require(ReplicatedStorage.GameConfig)

local Callbacks = {}
for _, Module in script:GetChildren() do
	Callbacks[Module.Name] = require(Module)
end

--> References
local Debounce = {}

local Requests = {}
task.spawn(function()
	while true do
		Requests = {}
		
		task.wait(GameConfig.MaxInputInteractions[2])
	end
end)

local ValidClientToServer = {"OnActivated", "OnEquipped", "OnUnequipped", "OnImpacted"}

--------------------------------------------------------------------------------
-- Serverside parameters --> {Player, Tool, Hit (only on .Hit)}

local Cache = {}

local function GetCachedToolCallbackName(Player, Name)
	local Character = Player.Character
	local Tool = Character and Character:FindFirstChild(Name) or Player.Backpack:FindFirstChild(Name)

	local ItemConfig = Cache[Name] or Tool:FindFirstChild("ItemConfig") and require(Tool.ItemConfig)
	Cache[Name] = ItemConfig

	return ItemConfig.CallbackName or Name
end

local function RequestCallback(Player, Name, Type, Params)
	Name = GetCachedToolCallbackName(Player, Name)
	if not Name then return end
	
	local ChosenModule = Callbacks[Name] or Callbacks.Default
	local Callback = ChosenModule and ChosenModule[Type]
	if Callback and not Callbacks[Name].Disabled then
		Callback(nil, Player, table.unpack(Params or {}))
	end
end

-- Set-up handler for events
EventModule:GetOnServerEvent("ClientToServerCallback"):Connect(function(Player, Name, Type, Params)
	if typeof(Type) ~= "string" or not table.find(ValidClientToServer, Type) then return end
	if typeof(Name) ~= "string" then return end
	
	if not Requests[Player.UserId] then
		Requests[Player.UserId] = 0
	end
	
	Requests[Player.UserId] += 1
	if Requests[Player.UserId] > GameConfig.MaxInputInteractions[1] then
		return
	end
	
	local Character = Player.Character
	
	local Tool = (Character and Character:FindFirstChild(Name)) or Player.Backpack:FindFirstChild(Name)
	if not Tool or not Tool:IsA("Tool") then return end
	
	local ItemConfig = Tool:FindFirstChild("ItemConfig") and require(Tool.ItemConfig)
	if ItemConfig then
		if Type == "OnActivated" then
			if ItemConfig.Type ~= "Tool" or not ItemConfig.Cooldown then
				return
			end
			
			if not Debounce[Player.UserId] then 
				Debounce[Player.UserId] = {} 
			end

			if not Debounce[Player.UserId][Name] then 
				Debounce[Player.UserId][Name] = os.clock() - (ItemConfig.Cooldown * 2) 
			end

			local Cooldown = Debounce[Player.UserId][Name] 
			if (os.clock() - Cooldown) < (ItemConfig.Cooldown / 1.25) then
				return
			end
			Debounce[Player.UserId][Name]  = os.clock()
		end
		
		-- Fire remote to clients & callback on server
		for _, _Player in Players:GetPlayers() do
			if _Player ~= Player then
				EventModule:FireClient("ServerToClientCallback", _Player, Player, Name, Type, Params)
			end
		end
		RequestCallback(Player, Name, Type, Params)
	end
end)

-- Set-up handler for events
EventModule:GetOnEvent("ServerToServerCallback"):Connect(RequestCallback)
return {}