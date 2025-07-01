--[[
	Evercyan @ March 2023
	PlayerListStats
	
	PlayerListStats creates a leaderstats folder under every Player on the client side (each client has their own instances)
	which shows their levels. They are placeholders, meaning the real data is under ReplicatedStorage.PlayerData.
	If you change stats under leaderstats instead of a pData config, it will not save, and will likely be overwritten.
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local StatsToShow = {}
for StatName, Data in GameConfig.Leaderstats do
	if not Data.ShowInPlayerList then 
		continue 
	end
	StatsToShow[Data.PlayerListOrder] = StatName
end

--------------------------------------------------------------------------------

local function FormatValue(Value: any): string
	return typeof(Value) == "number" and FormatNumber(Value, "Suffix") or tostring(Value)
end

local function OnPlayerAdded(Player: Player)
	local pData = PlayerData:WaitForChild(Player.UserId, 5)
	local Stats = pData and pData:WaitForChild("Stats", 5)
	if not Stats then return end
	
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	
	for _, StatName in StatsToShow do
		local Stat = Stats:WaitForChild(StatName, 5)
		if Stat then
			local ValueObject = Instance.new("StringValue")
			ValueObject.Name = StatName
			ValueObject.Value = FormatValue(Stat.Value)
			ValueObject.Parent = leaderstats
			
			Stat.Changed:Connect(function()
				ValueObject.Value = FormatValue(Stat.Value)
			end)
		end
	end
	
	leaderstats.Parent = Player
end

Players.PlayerAdded:Connect(OnPlayerAdded)
for _, Player in Players:GetPlayers() do
	task.defer(OnPlayerAdded, Player)
end

return {}