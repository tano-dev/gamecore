--[[
	ej0w @ September 2024
	PlayerUtils
	
	Handles instancing of folders which humanoid uses, along with MP regeneration
	Shortens the main PlayerHandlerV2 script
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")
local Server = ServerStorage.Modules.Server

--> Dependencies
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)

local PlayerLeveling = require(Server.PlayerLeveling)
local BoostFunctions = require(Server.BoostFunctions)

local GameConfig = require(ReplicatedStorage.GameConfig)

local MPModifiers = {}
for _, Module in script.ManaRegen:GetChildren() do
	MPModifiers[Module.Name] = require(Module)
end

--> Variables
local PlayerUtils = {}

--------------------------------------------------------------------------------

local function CreateConfigurations(Name, Parent, Configurations, Per)
	local Configuration = Instance.new("Configuration")
	Configuration.Name = Name

	for _, Name in Configurations do
		local SubConfig = Instance.new("Configuration")
		SubConfig.Name = Name
		SubConfig.Parent = Configuration
		Per(SubConfig)
	end

	Configuration.Parent = Parent
	return Configuration
end

function PlayerUtils:CheckIfLogged(Player: Player)
	local CountOwned = 0

	local pData = PlayerData:WaitForChild(Player.UserId)
	local Items = pData.Items

	for _, Asset in GameConfig.StarterItems do
		local AssetType = Asset[1]
		local AssetName = Asset[2]

		local Directory = Items:WaitForChild(AssetType)
		if Directory:FindFirstChild(AssetName) then
			CountOwned += 1
		end
	end

	return CountOwned == 0
end

function PlayerUtils:CreateHumanoidStats(Humanoid)
	if not Humanoid or Humanoid.Parent == nil then 
		return   
	end

	-- Class attributes
	local ClassBoosts = Instance.new("Configuration")
	ClassBoosts.Name = "Boosts"
	for _, Name in GameConfig.ClassBoosts do
		local SubConfig = Instance.new("Configuration")
		SubConfig.Name = Name
		SubConfig.Parent = ClassBoosts

		-- Mana is additive
		SubConfig:SetAttribute("Default", (Name == "Mana" and 0) or 1)
	end

	-- Statistic based attributes
	local Statistics = Instance.new("Configuration")
	Statistics.Name = "Statistics"
	for _, Name in GameConfig.Statistics do
		local SubConfig = Instance.new("Configuration")
		SubConfig.Name = Name
		SubConfig.Parent = Statistics
	end

	-- Mana attributes
	local ManaAttributes = Instance.new("Configuration")
	ManaAttributes.Name = "Mana"
	
	for _, Name in {"Mana", "MaxMana"} do
		local SubConfig = Instance.new("Configuration")
		SubConfig.Name = Name
		SubConfig.Parent = ManaAttributes
		
		SubConfig:SetAttribute("Default", 0)
	end
	
	-- MaxMana attribute changed
	local PreviousMaxMana = 0

	ManaAttributes.MaxMana.AttributeChanged:Connect(function()
		local MaxMana = 100
		for Name, Value in ManaAttributes.MaxMana:GetAttributes() do
			MaxMana += Value
		end

		-- Update mana to sort w/ new max
		local ManaAttribute = ManaAttributes:WaitForChild("Mana")
		local Default = ManaAttribute:GetAttribute("Default")

		local MPBoost = (GameConfig.HumanoidStatsRefreshWhenAdded and MaxMana > PreviousMaxMana and Default + (MaxMana - PreviousMaxMana)) or Default
		local Addition = math.clamp(MPBoost, 0, MaxMana)
		ManaAttribute:SetAttribute("Default", Addition)

		PreviousMaxMana = MaxMana
	end)

	ClassBoosts.Parent = Humanoid
	Statistics.Parent = Humanoid
	ManaAttributes.Parent = Humanoid
	return ClassBoosts, Statistics, ManaAttributes
end

function PlayerUtils:SetUpManaLoop(Player, Level)
	local DeltaTime = os.clock()
	task.delay(1, function()
		while Player.Parent ~= nil do
			local Difference = os.clock() - DeltaTime
			DeltaTime = os.clock()
			
			local Character = Player.Character
			local Humanoid = Character and Character:FindFirstChild("Humanoid")

			-- Potion duration, cancel potion boost if on zero
			local Statuses = Player:FindFirstChild("Statuses")
			for _, Effect in Statuses:GetChildren() do
				local Addition = math.clamp(Effect:GetAttribute("Duration") - 1, 0, math.huge)

				if Addition == 0 then
					Effect:SetAttribute("Boost", 1)
					Effect:SetAttribute("Addition", 0)
				end

				Effect:SetAttribute("Duration", Addition)
			end
			
			local IsDead = not Humanoid or Humanoid.Health <= 0
			
			local Boosts = Humanoid and Humanoid:FindFirstChild("Boosts")
			local ManaAttributes = Humanoid and Humanoid:FindFirstChild("Mana")

			-- Mana increase & attribute/other gain
			if Boosts and ManaAttributes and not IsDead then
				local ManaIncrease = math.max(math.floor((Level.Value * GameConfig.ManaPerLevel) / 25), 1)
				for Name, Value in Boosts.Mana:GetAttributes() do
					ManaIncrease += Value
				end

				for _, Callback in MPModifiers do
					ManaIncrease = Callback(Player, ManaIncrease)
				end

				local MaxMana = 0
				for Name, Value in ManaAttributes.MaxMana:GetAttributes() do
					if Value ~= Value then continue end
					MaxMana += Value
				end
				
				local NewValue = math.round((ManaAttributes.Mana:GetAttribute("Default") + ManaIncrease) * Difference)
				
				local Addition = math.clamp(NewValue, 0, MaxMana)
				if Addition ~= Addition then return end
				
				ManaAttributes.Mana:SetAttribute("Default", Addition)
			end
			
			task.wait(1)
		end
	end)
end

function PlayerUtils:SetUpChestsLoop(Player, Chests)
	local DeltaTime = os.clock()
	task.defer(function()
		while Player.Parent ~= nil do
			local Difference = os.clock() - DeltaTime
			DeltaTime = os.clock()
			
			for _, Chest in Chests:GetChildren() do
				if Chest.Value >= 1e9 then
					continue
				end
				Chest.Value = math.clamp(Chest.Value - Difference, 0, math.huge)
			end
			
			task.wait(1)
		end
	end)
end

function PlayerUtils:SetUpPlayerStats(Player)
	local Statuses = Instance.new("Configuration")
	Statuses.Name = "Statuses"
	
	for Name, Data in GameConfig.Boosts do
		local SubConfig = Instance.new("Configuration")
		SubConfig.Name = Name
		SubConfig.Parent = Statuses
		
		SubConfig:SetAttribute("Boost", 1)
		SubConfig:SetAttribute("Addition", 0)
		
		SubConfig:SetAttribute("Duration", 0)
		
		-- Clamp
		SubConfig:GetAttributeChangedSignal("Duration"):Connect(function()
			local Duration = SubConfig:GetAttribute("Duration")
			
			local NewDuration = math.clamp(Duration, 0, Data.MaxTimer)
			if NewDuration ~= Duration then
				SubConfig:SetAttribute("Duration", NewDuration)
			end
		end)
		
		-- Boost functions
		if BoostFunctions[Name] then
			SubConfig:GetAttributeChangedSignal("Addition"):Connect(function()
				BoostFunctions[Name](nil, Player, "Addition", SubConfig:GetAttribute("Addition", 0))
			end)
			SubConfig:GetAttributeChangedSignal("Boost"):Connect(function()
				BoostFunctions[Name](nil, Player, "Boost", SubConfig:GetAttribute("Boost", 0))
			end)
		end
	end

	Statuses.Parent = Player
end
	
return PlayerUtils