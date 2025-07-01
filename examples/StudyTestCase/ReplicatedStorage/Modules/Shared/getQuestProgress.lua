--[[
	ej0w @ October 2024
	GetQuestProgress
	
	Also used to progress check how far a player is into a quest.
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--> Player
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local QuestLibrary = require(ReplicatedStorage.Modules.Shared.QuestLibrary)

--------------------------------------------------------------------------------

return function(QuestName, Player)
	local Player = Player or Players.LocalPlayer
	
	local pData = PlayerData:FindFirstChild(Player.UserId)
	
	local Statistics = pData and pData:FindFirstChild("Stats")
	local Quests = pData and pData:FindFirstChild("Quests")
	if not Statistics or not Quests then return 0 end
	
	local QuestData = QuestLibrary[QuestName]
	if not QuestData then return 0 end
	
	local QuestRequirements = QuestData.Requirements
	if not QuestRequirements then return 0 end
	
	local CurrentQuestProgress = Quests.Active:FindFirstChild(QuestName)
	if not CurrentQuestProgress then return 0 end
	
	---- Compare quest requirements w/ progress
	
	local TotalRequested = 0
	local CurrentCompleted = 0
	
	local AllItems = {}
	AllItems.Mobs = {}
	AllItems.Objectives = {}
	AllItems.Statistics = {}
	
	local IndexableRequirements = {}
	IndexableRequirements.Mobs = {}
	IndexableRequirements.Statistics = {}
	
	-- Mob kills
	local Mobs = CurrentQuestProgress:FindFirstChild("Mobs")
	for _, Data in (QuestRequirements.Mobs or {}) do
		local Value = Mobs and Mobs:FindFirstChild(Data[1])
		
		local IsSuccessful = Value and Value.Value >= Data[2]
		if IsSuccessful then
			CurrentCompleted += 1
		end
		
		IndexableRequirements.Mobs[Data[1]] = Data[2]
		AllItems.Mobs[Data[1]] = IsSuccessful or (IsSuccessful == nil and false)
		
		TotalRequested += 1
	end
	
	-- Objectives
	local Objectives = CurrentQuestProgress:FindFirstChild("Objectives")
	for Name in (QuestRequirements.Objectives or {}) do
		local Value = Objectives and Objectives:FindFirstChild(Name)
		
		local IsSuccessful = Value and Value.Value == true
		if IsSuccessful then
			CurrentCompleted += 1
		end
		
		AllItems.Objectives[Name] = IsSuccessful or (IsSuccessful == nil and false)
		
		TotalRequested += 1
	end
	
	-- Statistics
	for _, Data in (QuestRequirements.Statistics or {}) do
		local Statistic = Statistics:FindFirstChild(Data[1])
		
		local IsSuccessful = Statistic and Statistic.Value >= Data[2]
		if IsSuccessful then
			CurrentCompleted += 1
		end
		
		IndexableRequirements.Statistics[Data[1]] = Data[2]
		AllItems.Statistics[Data[1]] = IsSuccessful or (IsSuccessful == nil and false)
		
		TotalRequested += 1
	end
	
	return math.clamp(CurrentCompleted / TotalRequested, 0, 1), AllItems, IndexableRequirements
end
