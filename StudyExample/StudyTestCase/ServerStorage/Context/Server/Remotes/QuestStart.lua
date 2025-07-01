--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local QuestLibrary = require(ReplicatedStorage.Modules.Shared.QuestLibrary)
local GetQuestProgress = require(ReplicatedStorage.Modules.Shared.getQuestProgress)

local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local Remotes = {}

--------------------------------------------------------------------------------

if not GameConfig.EnabledFeatures.Quests then
	return {}
end

local function RequestStartQuest(Player, QuestName, Ignore)
	if typeof(QuestName) ~= "string" then return end

	local pData = PlayerData:FindFirstChild(Player.UserId)
	if not pData then return end

	local Statistics = pData.Stats
	local Level = Statistics.Level

	-- Check simple logic
	local Quests = pData:FindFirstChild("Quests")
	if not Quests or Quests.Completed:FindFirstChild(QuestName) or Quests.Active:FindFirstChild(QuestName) then
		return false, "You've already took/completed this quest."
	end

	local QuestData = QuestLibrary[QuestName]
	if not Ignore and (QuestData.Level and Level.Value < QuestData.Level) then
		return false, "Your level isn't high enough."
	end

	-- Check magnitude
	local NPCInstance = QuestData.NPCInstance
	local NPCPivot = NPCInstance:GetPivot().Position

	local CharacterPivot = Player.Character and Player.Character:GetPivot().Position
	if not Ignore and (not CharacterPivot or (CharacterPivot - NPCPivot).Magnitude > 25) then
		return false, "You're too far away from this NPC."
	end

	-- Check previous quests
	local Config = require(NPCInstance.Config)
	for _, QuestOffer in Config.QuestOffers do
		if QuestOffer.Name == QuestName then
			break
		end
		if not Quests.Completed:FindFirstChild(QuestOffer.Name) then
			return false, "You need to complete this NPC's other quests first."
		end
	end

	-- Create the quest folder
	local Folder = Instance.new("Folder")
	Folder.Name = QuestName
	Folder:SetAttribute("Start", os.time())

	for NewName, NewData in QuestData.Requirements do
		local NewFolder = Instance.new("Folder")
		NewFolder.Name = NewName

		for Name, Stat in NewData do
			if typeof(Stat) == "function" then
				local Boolean = Instance.new("BoolValue")
				Boolean.Parent = NewFolder
				Boolean.Name = Name
				Boolean.Value = false
			else
				local Number = Instance.new("NumberValue")
				Number.Parent = NewFolder
				Number.Name = Stat[1]
				Number.Value = 0
			end
		end
		
		NewFolder.Parent = Folder
	end
	
	Folder.Parent = Quests.Active
	
	return true
end

function Remotes:ForceStartQuest(Player, QuestName)
	warn("hello")
	local Success, Return = RequestStartQuest(Player, QuestName, true)
	if Success then
		EventModule:FireClient("SendNotification", Player, "Quest success!", `You have been given the quest '{QuestName}'.`, 12900311398)
	end
	warn(Success, Return)
end

-- Modify this function in order to change remote callback
function Remotes:OnEvent(Player, QuestName)
	local Success, Return = RequestStartQuest(Player, QuestName)
	if not Success then
		EventModule:FireClient("SendNotification", Player, "Quest failure!", Return or "n/a", 12900311562)
	else
		EventModule:FireClient("SendNotification", Player, "Quest success!", `You have been given the quest '{QuestName}'.`, 12900311398)
	end
	
	return Success
end

return Remotes
