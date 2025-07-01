--[[
	Evercyan @ March 2023
	DataManager
	
	DataManager handles all user data, like Levels, Tools, Armor, and even misc values that save, such as active armor.
	I would avoid messing around with the code here unless if you know what you're doing. Always make sure a change works properly
	before shipping the update out to players to avoid data loss (scary!!).
	
	"PlayerData" is a reference to the Configuration under ReplicatedStorage that loads during runtime. Make sure to yield for this to exist.
	This Configuration houses all "pData" Configurations. These are individual player's data that houses many ValueBase objects,
	such as NumberValues, to easily access on the client & server.
	Like any instance, trying to change the data on the client will not replicate to the server.
	
	While a solution like ProfileService & ReplicaService is recommended to avoid instances and lots of FindFirstChild calls, I still believe
	that this is the best solution for beginners due to the ease of use, and you're relying on Roblox as the source of truth.
	This makes it easier to edit values in run mode, especially if you aren't an experienced programmer.
	
	IMPORTANT NOTE: ----
	'leaderstats' is a folder games use to make stats appear on the player list in-game. Please note that this does exist on the client-side,
	but attempting to change stats here will do nothing. All player data is actually stored under ReplicatedStorage.PlayerData.
	
	If you're using third-party scripts that rely on leaderstats to be set to, you may need to alter the code to work with pData configs.
]]

--> Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)
local QuestLibrary = require(ReplicatedStorage.Modules.Shared.QuestLibrary)
local ContentLibrary = require(ReplicatedStorage.Modules.Shared.ContentLibrary)
local AttributeFunctions = require(ServerStorage.Modules.Server.AttributeFunctions)

--> Variables
local UserData = DataStoreService:GetDataStore("UserData")
local SameKeyCooldown = {}

--------------------------------------------------------------------------------

local PlayerData = Instance.new("Folder")
PlayerData.Name = "PlayerData"
PlayerData.Parent = ReplicatedStorage

local function ClampStat(ValueObject: IntValue, Min: number?, Max: number?)
	ValueObject.Changed:Connect(function()
		ValueObject.Value = math.clamp(ValueObject.Value, Min or -math.huge, Max or math.huge)
	end)
end

local function CreateStat(ClassName: string, Name: string, DefaultValue, ClampInfo)
	local Stat = Instance.new(ClassName)
	Stat.Name = Name
	Stat.Value = (DefaultValue or 0)
	if ClampInfo and (Stat:IsA("NumberValue") or Stat:IsA("IntValue")) then
		ClampStat(Stat, unpack(ClampInfo))
	end
	return Stat
end

local function CreateDataFolder(Player): Instance
	local oldData = PlayerData:FindFirstChild(Player.UserId)
	if oldData then
		oldData:Destroy()
	end

	local pData = Instance.new("Folder")
	pData.Name = Player.UserId

	---- Stats

	local Stats = Instance.new("Folder")
	Stats.Name = "Stats"
	Stats.Parent = pData

	for StatName, Data in GameConfig.Leaderstats do
		local Constraint = Data.Constraint or {0}

		local Max = Constraint[2]
		if Max and Max == true then
			Constraint[2] = GameConfig["Max" .. StatName]
		end

		local Stat = CreateStat("NumberValue", StatName, Constraint[1], Constraint)
		Stat.Parent = Stats
	end

	---- Items

	local Items = Instance.new("Folder")
	Items.Name = "Items"
	Items.Parent = pData

	for ItemType in GameConfig.Categories do
		local Folder = Instance.new("Folder")
		Folder.Name = ItemType
		Folder.Parent = Items
	end

	---- Attributes

	local Attributes = Instance.new("Folder")
	Attributes.Name = "Attributes"
	Attributes.Parent = pData
	for Attribute in GameConfig.Attributes do
		local Value = Instance.new("NumberValue")
		Value.Name = Attribute
		Value.Parent = Attributes

		if AttributeFunctions[Attribute] then
			local function UpdateAttribute()
				AttributeFunctions[Attribute](nil, Player, Attributes)
			end

			Player.CharacterAdded:Connect(function()
				task.defer(UpdateAttribute)
			end)
			task.defer(UpdateAttribute)

			Value.Changed:Connect(UpdateAttribute)
		end
	end

	local Points = Instance.new("NumberValue")
	Points.Name = "Points"
	Points.Parent = pData

	---- Chest cooldowns

	local ChestCooldowns = Instance.new("Folder")
	ChestCooldowns.Name = "Chests"
	ChestCooldowns.Parent = pData

	for _, Chest in CollectionService:GetTagged("Chest") do
		local Config = Chest:FindFirstChild("Config") and require(Chest.Config)
		if Config and Config.Name then
			if ChestCooldowns:FindFirstChild(Config.Name) then
				warn(`DataManager: Chest {Config.Name} already exists.`)
				continue
			end

			local Value = Instance.new("NumberValue")
			Value.Name = Config.Name
			Value.Parent = ChestCooldowns
		else
			warn(`DataManager: Chest {Chest.Name} doesn't have proper configuration.`)
		end
	end

	---- Quest handling

	local Quests = Instance.new("Folder")
	Quests.Name = "Quests"
	Quests.Parent = pData

	local CompletedQuests = Instance.new("Folder")
	CompletedQuests.Name = "Completed"
	CompletedQuests.Parent = Quests

	local ActiveQuests = Instance.new("Folder")
	ActiveQuests.Name = "Active"
	ActiveQuests.Parent = Quests

	---- NPC interactions

	local Interactions = Instance.new("Folder")
	Interactions.Name = "Interactions"
	Interactions.Parent = pData

	---- Accessory Slots

	local EquippedSlots = Instance.new("Folder")
	EquippedSlots.Name = "EquippedSlots"

	for Iteration = 1, GameConfig.EquippedAccessoryMax do
		local Slot = CreateStat("StringValue", Iteration, "")
		Slot.Parent = EquippedSlots
	end

	EquippedSlots.Parent = pData

	---- Preferences & misc

	local ActiveArmor = CreateStat("StringValue", "ActiveArmor", "")
	ActiveArmor.Parent = pData

	local Hotbar = Instance.new("Folder")
	Hotbar.Name = "Hotbar"
	Hotbar.Parent = pData

	for n = 1, 9 do
		local ValueObject = CreateStat("StringValue", tostring(n), "")
		ValueObject.Parent = Hotbar
	end

	if GameConfig.SaveCurrentLocation then
		task.spawn(function()
			while true do
				local SavedCFrame = nil :: CFrame

				local Character = Player.Character

				local Humanoid = Character and Character:FindFirstChildWhichIsA("Humanoid") :: Humanoid
				if Humanoid and Humanoid.Health > 0 then
					SavedCFrame = Character:GetPivot()
				end

				AttributeModule:SetAttribute(Player, "SavedCFrame", SavedCFrame)

				task.wait(GameConfig.SavedPositionRefresh)
			end
		end)
	end

	return pData
end

-- Saves per item registry
local function UnloadTools(ConvertedToolTable, Folder, Player, AssetType)
	local StarterGear = Player:WaitForChild("StarterGear")
	local Backpack = Player:WaitForChild("Backpack")

	for ItemName, Value in ConvertedToolTable do
		if Value <= 0 then
			continue
		end

		local Library = ContentLibrary[AssetType] or {}

		local Tool = Library[ItemName]
		if Tool then
			if not StarterGear:FindFirstChild(Tool.Name) then
				Tool.Instance:Clone().Parent = StarterGear
			end

			if not Backpack:FindFirstChild(Tool.Name) then
				Tool.Instance:Clone().Parent = Backpack
			end

			local Stat = CreateStat("NumberValue", ItemName)
			Stat.Parent = Folder
			Stat.Value = Value
		end
	end
end

-- Unloads loaded user data table into their game session
local function UnloadData(Player: Player, Data: any, pData: Instance)
	local RejoinTime = tick() - (Data.LastJoin or tick())

	-- Stats
	local Stats = pData:FindFirstChild("Stats")
	for StatName, StatValue in Data.Stats do
		local Stat = Stats:FindFirstChild(StatName)
		if Stat then
			Stat.Value = StatValue
		end
	end

	-- Items
	local Items = pData:FindFirstChild("Items")
	for ItemType, NewData in GameConfig.Categories do
		local ConvertedToolTable = (Data.Converted and Data.Items[ItemType]) or {}
		if not Data.Converted then -- Adjust for old data that hasen't been ported to NumberValues yet
			for Index, Value in Data.Items[ItemType] or {} do
				if typeof(Index) == "number" then
					ConvertedToolTable[Value] = (ConvertedToolTable[Value] and ConvertedToolTable[Value] + 1) or 1
				else
					ConvertedToolTable[Index] = Value
				end
			end
		end

		local isATool = NewData.IsATool
		if isATool then
			UnloadTools(ConvertedToolTable, Items[ItemType], Player, ItemType)
		elseif not isATool then
			local Folder = Items:FindFirstChild(ItemType)
			for ItemName, Value in ConvertedToolTable do
				if Value <= 0 then
					continue
				end

				local Item = ContentLibrary[ItemType][ItemName]
				if Item then
					local Stat = CreateStat("NumberValue", ItemName)
					Stat.Parent = Folder
					Stat.Value = Value
				end
			end
		end
	end

	-- Attributes
	local Attributes = pData:FindFirstChild("Attributes")
	if Attributes and Data.Attributes then
		for _, Atribute in Attributes:GetChildren() do
			local Value = Data.Attributes[Atribute.Name] or 0
			Atribute.Value = Value
		end
	end

	local Points = pData:FindFirstChild("Points")
	if Points and Data.Points then
		Points.Value = Data.Points
	end

	-- Chest cooldowns
	local ChestCooldowns = pData:FindFirstChild("Chests")
	if ChestCooldowns and Data.ChestCooldowns then
		for Name, Cooldown in Data.ChestCooldowns do
			local MaxCooldown = math.huge

			for _, Chest in CollectionService:GetTagged("Chest") do
				local Config = Chest:FindFirstChild("Config") and require(Chest.Config)

				if Config and Config.Name == Name then
					MaxCooldown = (Config.Cooldown.Days * 86400) 
						+ (Config.Cooldown.Hours * 3600) 
						+ (Config.Cooldown.Minutes * 60)
						+ Config.Cooldown.Seconds
				end
			end

			local Value = ChestCooldowns:FindFirstChild(Name)
			if Value and Value.Value < 1e9 then
				Value.Value = math.clamp(Cooldown - RejoinTime, 0, MaxCooldown)
			end
		end
	end

	-- Quests
	local Quests = pData:FindFirstChild("Quests")
	if Quests and Data.Quests then
		for _, Name in Data.Quests.Completed do
			local Value = Instance.new("BoolValue")
			Value.Parent = Quests.Completed
			Value.Name = Name
			Value.Value = true
		end

		for Name, Data in Data.Quests.Active do
			local Folder = Instance.new("Folder")
			Folder.Name = Name

			for NewName, NewData in Data.Data or Data do
				local NewFolder = Instance.new("Folder")
				NewFolder.Name = NewName
				Folder:SetAttribute("Start", Data.Start or os.time())

				for ValueName, Value in NewData do
					if typeof(Value) == "boolean" then
						local Boolean = Instance.new("BoolValue")
						Boolean.Parent = NewFolder
						Boolean.Name = ValueName
						Boolean.Value = Value
					elseif typeof(Value) == "number" then
						local Number = Instance.new("NumberValue")
						Number.Parent = NewFolder
						Number.Name = ValueName
						Number.Value = Value
					end
				end

				NewFolder.Parent = Folder
			end

			Folder.Parent = Quests.Active
		end
	end

	-- Potion / status effects
	task.spawn(function()
		local Statuses = Player:WaitForChild("Statuses")

		for Name, Data in (Data.Statuses or {}) do
			local Status = Statuses:WaitForChild(Name)

			for NewName, Value in Data do
				Status:SetAttribute(NewName, Value)
			end
		end
	end)

	-- Equipped accessories
	local EquippedSlots = pData:FindFirstChild("EquippedSlots")
	if EquippedSlots and Data.EquippedSlots then
		for Index, Name in Data.EquippedSlots do
			local Value = EquippedSlots:FindFirstChild(tostring(Index))
			if Value then
				Value.Value = Name
			end
		end
	end

	-- NPC interactions
	local Interactions = pData:FindFirstChild("Interactions")
	if Interactions and Data.Interactions then
		for Name, _Value in Data.Interactions do
			local Value = Instance.new("NumberValue")
			Value.Parent = Interactions
			Value.Name = Name
			Value.Value = _Value
		end
	end

	-- Preferences / Misc
	pData:FindFirstChild("ActiveArmor").Value = Data.ActiveArmor

	local HotbarFolder = pData:FindFirstChild("Hotbar")
	for SlotNumber, ItemName in Data.Hotbar do
		HotbarFolder:FindFirstChild(SlotNumber).Value = ItemName
	end

	if Data.SavedCFrame then
		task.spawn(function()
			local Character = Player.Character or Player.CharacterAdded:Wait()
			if not Player:HasAppearanceLoaded() then
				Player.CharacterAppearanceLoaded:Wait()
			end

			task.wait(0.5)
			Character:PivotTo(CFrame.new(Data.SavedCFrame.X, Data.SavedCFrame.Y, Data.SavedCFrame.Z))
		end)
	end
end

-- Yields until the game considers the game as being able to call a save/load to datastores
local function WaitForRequestBudget(RequestType)
	local CurrentBudget = DataStoreService:GetRequestBudgetForRequestType(RequestType)
	while CurrentBudget < 1 do
		CurrentBudget = DataStoreService:GetRequestBudgetForRequestType(RequestType)
		task.wait(5)
	end
end

-- Attempt to save user data. Returns whether or not the request was successful.
local function SaveData(Player: Player): boolean
	if not Player:GetAttribute("DataLoaded") then
		return false
	end

	local pData = PlayerData:FindFirstChild(Player.UserId)
	local StarterGear = Player:FindFirstChild("StarterGear")
	if not pData or not StarterGear then
		return false
	end

	-- Same Key Cooldown (can't write to the same key within 6 seconds)
	if SameKeyCooldown[Player.UserId] then
		repeat task.wait() until not SameKeyCooldown[Player.UserId]
	end
	SameKeyCooldown[Player.UserId] = true
	task.delay(GameConfig.PreLoadTime, function()
		SameKeyCooldown[Player.UserId] = nil
	end)

	-- Compile "DataToSave" table, which we pass to GlobalDataStore:SetAsync
	local DataToSave = {}
	DataToSave.Stats = {}
	DataToSave.Items = {}

	DataToSave.Attributes = {}
	DataToSave.ChestCooldowns = {}

	DataToSave.Statuses = {}

	DataToSave.Quests = {
		Completed = {},
		Active = {},
	}

	DataToSave.Interactions = {}

	DataToSave.EquippedSlots = {}
	for Iteration = 1, GameConfig.EquippedAccessoryMax do
		DataToSave.EquippedSlots[Iteration] = ""
	end

	-- Stats
	local Stats = pData:FindFirstChild("Stats")
	for _, ValueObject in Stats:GetChildren() do
		DataToSave.Stats[ValueObject.Name] = ValueObject.Value
	end

	-- Items
	local Items = pData:FindFirstChild("Items")
	local function CollectiveSave(AssetType)
		local Folder = Items:FindFirstChild(AssetType)
		if not Folder then
			warn(`DataManager: folder for {AssetType} doesn't exist!`)
			return
		end

		for _, ValueObject in Folder:GetChildren() do
			local DontSave = ValueObject:GetAttribute("DontSave")
			if not ValueObject:IsA("NumberValue") and DontSave then
				continue
			end

			local Library = ContentLibrary[AssetType] or {}
			if Library[ValueObject.Name] then
				if ValueObject:IsA("NumberValue") then
					DataToSave.Items[AssetType][ValueObject.Name] = ValueObject.Value - (DontSave or 0)
				else
					table.insert(DataToSave.Items[AssetType], ValueObject.Name)
				end
			end
		end
	end

	for ItemType, Data in GameConfig.Categories do
		DataToSave.Items[ItemType] = {}
		CollectiveSave(ItemType)
	end

	-- Attributes
	for _, Attribute in pData.Attributes:GetChildren() do
		DataToSave.Attributes[Attribute.Name] = Attribute.Value
	end

	DataToSave.Points = pData.Points.Value

	-- Chest cooldowns
	for _, Cooldown in pData.Chests:GetChildren() do
		DataToSave.ChestCooldowns[Cooldown.Name] = Cooldown.Value
	end

	-- Quests
	for _, Value in pData.Quests.Completed:GetChildren() do
		table.insert(DataToSave.Quests.Completed, Value.Name)
	end

	for _, Folder in pData.Quests.Active:GetChildren() do
		local SaveTable = {}

		local QuestData = QuestLibrary[Folder.Name]
		if not QuestData then
			warn(`[KIT: Quest {Folder.Name} no longer exists but is in players' datastore. Was this a mistake? (2)]`)
			continue
		end

		for Name, Data in QuestData.Requirements do
			SaveTable[Name] = {}

			for NewName, Value in Data do
				if typeof(Value) == "function" then
					SaveTable[Name][NewName] = false
				else
					SaveTable[Name][Value[1]] = 0
				end
			end
		end 

		for _, NewFolder in Folder:GetChildren() do
			for _, Value in NewFolder:GetChildren() do
				SaveTable[NewFolder.Name][Value.Name] = Value.Value
			end
		end

		DataToSave.Quests.Active[Folder.Name] = {
			Data = SaveTable,
			Start = Folder:GetAttribute("Start") or os.time()
		}
	end

	-- Potion effects
	local Statuses = Player:FindFirstChild("Statuses")
	if Statuses then
		for _, Status in Statuses:GetChildren() do
			DataToSave.Statuses[Status.Name] = {
				Duration = Status:GetAttribute("Duration"),
				Boost = Status:GetAttribute("Boost"),
				Addition = Status:GetAttribute("Addition"),
			}
		end
	end

	-- NPC interactions
	local Interactions = pData:FindFirstChild("Interactions")
	if Interactions then
		for _, Value in Interactions:GetChildren() do
			DataToSave.Interactions[Value.Name] = Value.Value
		end
	end

	-- Equipped accessories
	for Index in DataToSave.EquippedSlots do
		local Value = pData.EquippedSlots:FindFirstChild(tostring(Index))
		if Value then
			DataToSave.EquippedSlots[Index] = Value.Value
		end
	end

	-- Preferences / Misc
	local SavedCFrame = AttributeModule:GetAttribute(Player, "SavedCFrame")

	if GameConfig.SaveCurrentLocation and SavedCFrame and not AttributeModule:GetAttribute(Player, "DontSaveCFrame") then
		DataToSave.SavedCFrame = {
			X = SavedCFrame.Position.X,
			Y = SavedCFrame.Position.Y,
			Z = SavedCFrame.Position.Z
		}
	end

	DataToSave.ActiveArmor = pData.ActiveArmor.Value

	DataToSave.Hotbar = {}
	for _, ValueObject in pData.Hotbar:GetChildren() do
		DataToSave.Hotbar[ValueObject.Name] = ValueObject.Value
	end

	DataToSave.LastJoin = tick()
	DataToSave.Converted = true

	-- Save to DataStore
	local Success = nil :: boolean
	local Response = nil :: any

	repeat
		WaitForRequestBudget(Enum.DataStoreRequestType.SetIncrementAsync)

		Success, Response = pcall(function()
			return UserData:UpdateAsync("user/".. Player.UserId, function()
				return DataToSave
			end)
		end)
	until Success

	print(`DataManager: User {Player.Name}'s data saved successfully.`)

	return Success
end

-- Attempt to load user data. Returns whether or not the request was successful, as well as the data if it was.
local function LoadData(Player: Player): (boolean, any)
	local Success = nil :: boolean
	local Response = nil :: any

	repeat
		Success, Response = pcall(function()
			local RequestedData = nil

			UserData:UpdateAsync("user/".. Player.UserId, function(Data)
				RequestedData = Data
			end)

			return RequestedData
		end)

		if (not Success) or (Response == "wait") then
			task.wait(4)
		end
	until Success

	if Response then
		print(`DataManager: User {Player.Name}'s data loaded into the game with Level {Response.Stats.Level}.`)
	else
		print(`DataManager: User {Player.Name} has loaded into the game for the first time.`)
	end

	return Success, Response
end

local function OnPlayerAdded(Player: Player)
	local Success, Data = LoadData(Player)

	if not Success then
		CollectionService:AddTag(Player, "DataFailed")
		Player:Kick("Data unable to load. DataStore Service may be down. Please rejoin later.")
		return
	end

	local pData = CreateDataFolder(Player)
	if Data then
		UnloadData(Player, Data, pData)
	end
	pData.Parent = PlayerData

	Player:SetAttribute("DataLoaded", true)
end

Players.PlayerAdded:Connect(OnPlayerAdded)
for _, Player in Players:GetPlayers() do
	OnPlayerAdded(Player)
end

-- Save on leave
Players.PlayerRemoving:Connect(function(Player)
	SaveData(Player)

	local oldData = PlayerData:FindFirstChild(Player.UserId)
	if oldData then
		oldData:Destroy()
	end
end)

-- Server closing
game:BindToClose(function()
	if RunService:IsStudio() then
		print("DataManager: Can't save BindToClose in studio.")
		task.wait(1)
		return
	end

	for _, Player in Players:GetPlayers() do
		SaveData(Player)
	end
	task.wait(1)
end)

-- Auto-save
while task.wait(GameConfig.SaveTime) do
	for _, Player in Players:GetPlayers() do
		task.spawn(SaveData, Player)
	end
end

return {}