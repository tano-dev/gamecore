--> Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local QuestLibrary = require(ReplicatedStorage.Modules.Shared.QuestLibrary)
local ContentLibrary = require(ReplicatedStorage.Modules.Shared.ContentLibrary)

local GetQuestProgress = require(ReplicatedStorage.Modules.Shared.getQuestProgress)
local QuestLibrary = require(ReplicatedStorage.Modules.Shared.QuestLibrary)

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

-- Modify this function in order to change remote callback
function Remotes:OnEvent(Player, NPCInstance)
	local pData = PlayerData:WaitForChild(Player.UserId)
	
	if typeof(NPCInstance) == "Instance" and (CollectionService:HasTag(NPCInstance, "Quest") or CollectionService:HasTag(NPCInstance, "Dialogue")) then
		local Character = Player.Character
		
		local CharOrigin = Character and Character:GetPivot().Position
		if not CharOrigin then return end
		
		local Config = NPCInstance:FindFirstChild("Config") and require(NPCInstance.Config)
		if not Config then return end
		
		local Origin = NPCInstance:GetPivot().Position
		if (Origin - CharOrigin).Magnitude > 25 then return end
		
		local Value = pData.Interactions:FindFirstChild(Config.Name)
		if not Value then
			Value = Instance.new("NumberValue")
			Value.Name = Config.Name
			Value.Parent = pData.Interactions
		end
		
		Value.Value = os.time()
	end
end

return Remotes
