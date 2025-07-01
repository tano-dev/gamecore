--[[
	ej0w @ October 2024
	QuestLibrary
	
	Works similarly to ContentLibrary, simply sorts quests into an easily usable format.
]]

--> Services
local CollectionService = game:GetService("CollectionService")

--> Variables
local QuestLibrary = {}

--------------------------------------------------------------------------------

local function CheckForQuest(Tagged)
	local Config = Tagged:FindFirstChild("Config")
	Config = Config and require(Config)
	
	if not Config then
		warn(`QuestLibrary: Quest NPC '{Tagged.Name}' doesn't have configuration.`)
		return
	end
	
	local QuestOffers = Config.QuestOffers
	for _, Data in QuestOffers do
		if QuestLibrary[Data.Name] then
			warn(`QuestLibrary: Quest '{Data.Name}' already exists, please change its name.`)
			continue
		end
		
		local NewData = table.clone(Data)
		NewData.NPCInstance = Tagged
		
		QuestLibrary[Data.Name] = NewData
	end
end

for _, Tagged in CollectionService:GetTagged("Quest") do
	CheckForQuest(Tagged)
end
CollectionService:GetInstanceAddedSignal("Quest"):Connect(CheckForQuest)
return QuestLibrary
