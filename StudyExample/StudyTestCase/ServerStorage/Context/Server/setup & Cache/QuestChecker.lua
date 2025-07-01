--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local QuestLibrary = require(ReplicatedStorage.Modules.Shared.QuestLibrary)
local GameConfig = require(ReplicatedStorage.GameConfig)

--------------------------------------------------------------------------------

if not GameConfig.EnabledFeatures.Quests then
	return {}
end

---- Quest objective checking

local function CheckPerFolder(Folder)
	local Player = Players:GetPlayerByUserId(tonumber(Folder.Name))
	if not Player then return end
	
	local Quests = Folder:FindFirstChild("Quests")
	if not Quests then return end
	
	local function CheckPerObjective(Callback, Objectives, Name)
		local Objective = Objectives and Objectives:FindFirstChild(Name)
		local Success = Callback(Player)
		
		if Objective and Success then
			Objective.Value = true
		end
	end
	
	for _, Folder in Quests.Active:GetChildren() do
		local Quest = QuestLibrary[Folder.Name]
		if not Quest then
			warn(`[KIT: Quest {Folder.Name} no longer exists but is in players' datastore. Was this a mistake? (1)]`)
			continue
		end
		
		local Objectives = Quest.Requirements.Objectives
		if Objectives then
			for Name, Callback in Objectives do
				task.spawn(CheckPerObjective, Callback, Folder:FindFirstChild("Objectives"), Name)
			end
		end
	end
end

task.spawn(function()
	while true do 
		for _, Folder in PlayerData:GetChildren() do
			CheckPerFolder(Folder)
		end

		task.wait(GameConfig.QuestRefresh)
	end
end)

return {}