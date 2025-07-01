--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local QuestLibrary = require(ReplicatedStorage.Modules.Shared.QuestLibrary)
local ContentLibrary = require(ReplicatedStorage.Modules.Shared.ContentLibrary)

local GetQuestProgress = require(ReplicatedStorage.Modules.Shared.getQuestProgress)
local QuestLibrary = require(ReplicatedStorage.Modules.Shared.QuestLibrary)
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)

local GiftDrops = require(ServerStorage.Modules.Server.giftDrops)
local QuestStart = require(ServerStorage.Context.Server.Remotes.QuestStart)

local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local Remotes = {}

local Libraries = {}
for _, Module in ServerStorage.Modules.Libraries["items [Subcategories]"]:GetChildren() do
	Libraries[Module.Name] = require(Module)
end

--------------------------------------------------------------------------------

if not GameConfig.EnabledFeatures.Quests then
	return {}
end

local function RequestCompleteQuest(Player, QuestName)
	if typeof(QuestName) ~= "string" then return end
	
	local pData = PlayerData:FindFirstChild(Player.UserId)
	if not pData then return end
	
	local Quests = pData:FindFirstChild("Quests")
	if not Quests then return end
	
	local QuestData = QuestLibrary[QuestName]
	if not QuestData then return end
	
	if not Quests.Active:FindFirstChild(QuestName) or Quests.Completed:FindFirstChild(QuestName) then
		return false, "You've already taken/aren't taking this quest."
	end
	
	local Progress = GetQuestProgress(QuestName, Player)
	if Progress >= 1 or Progress == true then
		local QuestFolder = Quests.Active:WaitForChild(QuestName)
		QuestFolder:Destroy()
		
		if not QuestData.Repeatable then
			local Value = Instance.new("BoolValue")
			Value.Parent = Quests.Completed
			Value.Name = QuestName
			Value.Value = true
		end
		
		EventModule:FireClient("SendNotification", Player, "Quest completed!", `You have successfully completed '{QuestName}'`, 12900311398)
		
		if QuestData.Rewards then
			GiftDrops(Player, QuestData.Rewards)
		end
		
		if QuestData.Succession then
			local NewQuestName = nil
			
			local Config = require(QuestData.NPCInstance.Config)
			for Index, QuestOffer in Config.QuestOffers do
				if QuestOffer.Name == QuestName then
					NewQuestName = Config.QuestOffers[Index + 1] and Config.QuestOffers[Index + 1].Name
					break
				end
			end
			
			if NewQuestName then
				task.defer(function()
					QuestStart:ForceStartQuest(Player, NewQuestName)
				end)
			end
		end
		
		return true
	else
		return false, "You haven't finished this quest yet."
	end
end

-- Modify this function in order to change remote callback
function Remotes:OnEvent(Player, QuestName)
	local Success, Return = RequestCompleteQuest(Player, QuestName)
	if not Success then
		EventModule:FireClient("SendNotification", Player, "Quest failure!", Return or "n/a", 12900311562)
	end

	return Success
end

return Remotes
