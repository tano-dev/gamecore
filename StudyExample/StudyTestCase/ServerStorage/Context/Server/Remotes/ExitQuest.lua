--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)

local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local Remotes = {}

--------------------------------------------------------------------------------

if not GameConfig.EnabledFeatures.Quests then
	return {}
end

local function RequestExitQuest(Player, QuestName)
	if typeof(QuestName) ~= "string" then return end

	local pData = PlayerData:FindFirstChild(Player.UserId)
	if not pData then return end
	
	local QuestFolder = pData.Quests.Active:FindFirstChild(QuestName)
	if QuestFolder then
		QuestFolder:Destroy()
	end
end

-- Modify this function in order to change remote callback
function Remotes:OnEvent(Player, QuestName)
	RequestExitQuest(Player, QuestName)
	
	EventModule:FireClient("SendNotification", Player, "Quest canceled!", `You have canceled the quest '{QuestName}'.`, 12900311398)
end

return Remotes
