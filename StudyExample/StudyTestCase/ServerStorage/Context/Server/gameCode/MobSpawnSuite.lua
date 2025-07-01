--[[
	ej0w @ August 2024
	MobSpawnSuite
	
	Handles the spawning of custom characters/mobs
]]

--> Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> References
local MobFolder = ServerStorage.Assets.Entities.Spawns

-- Stops mobs from being initialized by the kit (keep in note the order scripts run, best to remove the tag from a mob altogether)
for _, Mob in MobFolder:GetChildren() do
	CollectionService:RemoveTag(Mob, "Mob")
end

--> Dependencies
local Modules = ServerStorage.Modules
local Heartbeat = RunService.Heartbeat

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

local MobLib = require(Modules.Libraries.Mob)
local MobList = require(Modules.Libraries.Mob.MobList)

local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)

--> Variables
local CurrentTimeStamps = {}
local CurrentlySpawned = {}
local ActiveMobSpawn = {}
local RespawnTimers = {}
local LastDied = {}

local Spawners = GameConfig.Spawners

--> Configuration
local SPAWNED_BOSS_MESSAGE	= "%s has spawned!"
local DESPAWNED_BOSS_MESSAGE = "%s has despawned."
local DIED_BOSS_MESSAGE = "%s has died."

--------------------------------------------------------------------------------

local function AlertChat(Color, Text)
	EventModule:FireAllClients("ChatAlert", Color or Color3.fromRGB(238, 238, 238), Text)
end

local function FormatNumberToTime(Number)
	local TotalHours = math.floor(Number / 3600)
	local TotalMinutes = math.floor((Number - (TotalHours * 3600)) / 60)
	local TotalSeconds = Number - (TotalHours * 3600) - (TotalMinutes * 60)
	if TotalHours > 0 then
		return `{TotalHours}h {TotalMinutes}m {TotalSeconds}s`
	elseif TotalMinutes > 0 then
		return `{TotalMinutes}m {TotalSeconds}s`
	else
		return `{TotalSeconds}s`
	end
end

local function UpdateRespawnUI(Name, Duration, Color, Position)
	local Start = os.clock()
	
	local RespawnPart = (RespawnTimers[Name] and RespawnTimers[Name]) 
		or ServerStorage.Assets.Scripts.RespawnGui:Clone()
	
	RespawnPart.Parent = workspace:FindFirstChild("Map") 
		or workspace
	
	RespawnPart.Name = Name
	RespawnPart:PivotTo(CFrame.new(Position))
	
	local BillboardGui = RespawnPart:WaitForChild("BossBillboard")
	BillboardGui.Canvas.Marker.Fill.ImageColor3 = Color
	BillboardGui.Canvas.Timer.TextColor3 = Color
	
	task.spawn(function()
		while os.clock() - Start <= Duration do
			local TimeLeft = Duration - (os.clock() - Start)
			
			
			BillboardGui.Canvas.Timer.Text = FormatNumberToTime(math.floor(TimeLeft))
			
			task.wait(1)
		end
	end)
	
	task.delay(Duration, function()
		BillboardGui.Enabled = false
	end)
	BillboardGui.Enabled = true
	
	RespawnTimers[Name] = RespawnPart
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local function RequestDespawnMob(Object, NewMob, Name, Color)
	if not CurrentlySpawned[Name] or not Object then
		return
	end
	
	local Data = Spawners[Name]

	LastDied[Name] = os.clock()
	CurrentlySpawned[Name] = nil
	CurrentTimeStamps[Name] = os.clock()

	MobList[NewMob] = nil

	if NewMob and Data.Type == "Clock" then
		task.defer(UpdateRespawnUI, Name, Data.Time, Color, (Data.Position or NewMob:GetPivot().Position))
	end

	AlertChat(Color:Lerp(Color3.fromRGB(0, 0, 0), 0.1), string.format(DESPAWNED_BOSS_MESSAGE, Name))

	Object:Destroy()
end

local function SetForDespawn(Despawn, Object, NewMob, Name, Color)
	task.spawn(function()
		while true do
			task.wait(Despawn)
			
			if not AttributeModule:GetAttribute(NewMob, "Target") then
				RequestDespawnMob(Object, NewMob, Name, Color)
				break
			end
		end
	end)
end

local function AlertSpawnedMobDied(Name, Object, Color)
	local MobInstance = MobFolder:FindFirstChild(Name)
	local Data = Spawners[Name]
	
	LastDied[Name] = os.clock()
	CurrentlySpawned[Name] = nil
	CurrentTimeStamps[Name] = os.clock()
	
	task.delay(5, function()
		Object:Destroy()
	end)
	
	if MobInstance and Data.Type == "Clock" then
		UpdateRespawnUI(Name, Data.Time, Color, (Data.Position or MobInstance:GetPivot().Position))
	end

	AlertChat(Color:Lerp(Color3.fromRGB(255, 255, 255), 0.1), string.format(DIED_BOSS_MESSAGE, Name))
end

local function RequestSpawnMob(Position, Name, Color, Despawn)
	local isActiveSpawn = ActiveMobSpawn[Name]
	if isActiveSpawn and isActiveSpawn.Parent ~= nil then
		return
	end
	
	if not CurrentlySpawned[Name] then
		local MobInstance = MobFolder:FindFirstChild(Name)
		assert(MobInstance, `Requested mob ({Name}) doesn't exist in Assets --> Mobs`)

		local NewMob = MobInstance:Clone()
		NewMob.Parent = workspace:WaitForChild("Mobs")
		ActiveMobSpawn[Name] = NewMob
		
		if Position then
			NewMob:WaitForChild("HumanoidRootPart"):PivotTo(CFrame.new(Position) * NewMob:GetPivot().Rotation)
		end

		local Object = MobLib.new(NewMob)
		if Despawn then
			SetForDespawn(Despawn, Object, NewMob, Name, Color)
		end

		local Enemy = NewMob:FindFirstChildWhichIsA("Humanoid")
		if Enemy then
			Enemy.Died:Connect(function()
				AlertSpawnedMobDied(Name, Object, Color)
			end)
		end
		
		CurrentlySpawned[Name] = true
		
		CollectionService:AddTag(NewMob, "Mob")
		AttributeModule:SetAttribute(NewMob, "NoRespawn", true)
		
		if GameConfig.EnabledFeatures.SpawnedBossUI then
			EventModule:FireAllClients("InformSpawnedBoss", Color, string.format(SPAWNED_BOSS_MESSAGE, Name))
		end
		AlertChat(Color, string.format(SPAWNED_BOSS_MESSAGE, Name))
	end
end

---- Initialize Types ---------------------------------------------------

local DataTypeCallbacks = {} do
	function DataTypeCallbacks:Clock(Name, Data)
		local TimeStamp = CurrentTimeStamps[Name]
		if not TimeStamp then
			CurrentTimeStamps[Name] = os.clock()
		end
		
		local RequestLastDied = LastDied[Name]
		if TimeStamp and (os.clock() - TimeStamp >= Data.Time) and (not RequestLastDied or os.clock() - RequestLastDied >= Data.Time) then
			CurrentTimeStamps[Name] = os.clock()
			RequestSpawnMob(Data.Position, Name, Data.Color, Data.Despawn)
		end
	end

	function DataTypeCallbacks:Check(Name, Data)
		local Verdict = Data.Request()
		if Verdict then
			RequestSpawnMob(Data.Position, Name, Data.Color, Data.Despawn)
		end
	end

	function DataTypeCallbacks:Event(Name, Data)
		Data.Connection:Connect(function()
			RequestSpawnMob(Data.Position, Name, Data.Color, Data.Despawn)
		end)
	end
end

local function CheckExistingCheckTypes()
	for Name, Data in Spawners do
		local Callback = DataTypeCallbacks[Data.Type]
		if Callback and (Data.Type ~= "Event") then -- Previous problem with memory leaks. sorry
			task.spawn(Callback, nil, Name, Data)
		end
	end
end

-- Event utils
for Name, Data in Spawners do
	if Data.Type == "Event" then
		local Callback = DataTypeCallbacks[Data.Type]
		task.spawn(Callback, nil, Name, Data)
	end
end

-- Heartbeat game clock, more reliable than a while loop & lightweight
local CheckedSinceLastClock = os.clock()
Heartbeat:Connect(function()
	if os.clock() - CheckedSinceLastClock >= 1 then
		CheckedSinceLastClock = os.clock()
		CheckExistingCheckTypes()
	end
end)

-- Intialize UIs
for Name, Data in Spawners do
	if Data.Type == "Clock" then
		local MobInstance = MobFolder:FindFirstChild(Name)
		if MobInstance then
			task.spawn(UpdateRespawnUI, Name, Data.Time, (Data.Color or Color3.fromRGB(255, 255, 255)), (Data.Position or MobInstance:GetPivot().Position))
		end
	end
end

return {}
