--[[
	ej0w @ October 2024
	Chest
	
	Handles the serverside for chests
]]

--> Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local GiftDrops = require(ServerStorage.Modules.Server.giftDrops)

--------------------------------------------------------------------------------

local function CollectionAdded(Tag: string, Callback:(...any) -> ())
	for _, Tagged: any in CollectionService:GetTagged(Tag) do
		Callback(Tagged)
	end
	CollectionService:GetInstanceAddedSignal(Tag):Connect(Callback)
end

return function()
	CollectionAdded("Chest", function(Chest: Model)
		local Config = Chest:FindFirstChild("Config") and require(Chest.Config)
		if not Config or not Config.Name then return end
		
		local ProximityPrompt = Chest:FindFirstChildWhichIsA("ProximityPrompt", true)
		ProximityPrompt.ObjectText = Config.Name
		if Config.Level > 1 then
			ProximityPrompt.ObjectText ..= ` [{FormatNumber(Config.Level, "Suffix")}]`
		end
		
		local Cooldown = Config.Cooldown
		
		local CooldownInSeconds = (Cooldown.Days * 86400) 
			+ (Cooldown.Hours * 3600) 
			+ (Cooldown.Minutes * 60)
			+ Cooldown.Seconds
		
		ProximityPrompt.Triggered:Connect(function(Player)
			local pData = PlayerData:WaitForChild(Player.UserId)
			
			local Level = pData.Stats.Level
			local ChestCooldowns = pData.Chests
			
			local ChestValue = ChestCooldowns:FindFirstChild(Config.Name)
			if ChestValue.Value > 0 or Level.Value < Config.Level then
				return EventModule:FireClient("SendNotification", Player, "Open failure!", "Not high enough level or already opened.", 12900311562)
			end
			
			local IsPermanent = Config.OpenableOnce	
			local Drops = Config.Drops
			
			if IsPermanent then
				ChestValue.Value = 1e9
			elseif not IsPermanent then
				ChestValue.Value = CooldownInSeconds
			end
			
			GiftDrops(Player, Drops)
		end)
		
		-- Setup
		for _, Part in Chest:GetDescendants() do
			if Part:IsA("BasePart") then
				Part.CollisionGroup = "Mobs"
			end
		end
		
		Chest.Name = Config.Name
	end)
end