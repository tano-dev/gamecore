--[[
	ej0w @ October 2024
	Preload
]]

--> Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local SavedAnimationIDs = {}
local RequestedPreloadCache = {}

--------------------------------------------------------------------------------

if not GameConfig.PreloadAnimations then
	return
end

--> Variables & Dependencies
local AllMobs = CollectionService:GetTagged("Mob")

local DefaultAnimations = ReplicatedStorage.Context.Client.entityCode.MobClient.DefaultAnimations

local AttackFunctions = require(ReplicatedStorage.Modules.Entity.attackFunctions)
local HitCycleFunctions = require(ReplicatedStorage.Modules.Entity.hitCycleFunctions)

-- Callbacks
local function CreatePreloadAnimation(ID)
	task.spawn(function()
		if typeof(ID) == "number" then
			ID = `rbxassetid://{ID}`
		elseif typeof(ID) == "table" then
			for _, NewID in ID do
				CreatePreloadAnimation(NewID)
			end
			return
		end

		if ID ~= nil and not SavedAnimationIDs[ID] then 
			local Animation = Instance.new("Animation")
			Animation.AnimationId = ID
			
			SavedAnimationIDs[ID] = Animation
			table.insert(RequestedPreloadCache, Animation)
		end
	end)
end

---- Create tool preloads

local AllTools = {}
for _, Tool: Tool in ReplicatedStorage.Items:GetDescendants() do
	if Tool:IsA("Tool") then
		table.insert(AllTools, Tool)
	end
end

for _, Tool in AllTools do
	local ItemConfig = Tool:FindFirstChild("ItemConfig") and require(Tool.ItemConfig)
	if ItemConfig then
		for _, ID in (ItemConfig.Animations or {}) do
			CreatePreloadAnimation(ID)
		end
		
		CreatePreloadAnimation(ItemConfig.ActivateAnimations)
		
		if ItemConfig.BlockAndParry then
			for _, ID in (ItemConfig.BlockAndParry.Animation or {}) do
				if typeof(ID) == "string" then
					CreatePreloadAnimation(ID)
				end
			end
			
			CreatePreloadAnimation(ItemConfig.BlockAndParry.ParryToMob)
		end
	end
end

---- Create mob preloads

for _, Attack in AttackFunctions:GetLibrary() do
	for _, Cycle in Attack do
		CreatePreloadAnimation(Cycle.TelegraphAnimation and Cycle.TelegraphAnimation[1])
	end
end

for _, Hit in HitCycleFunctions:GetLibrary() do
	for _, Cycle in Hit do
		CreatePreloadAnimation(Cycle.TelegraphAnimation and Cycle.TelegraphAnimation[1])
	end
end

for _, Animation in DefaultAnimations:GetChildren() do
	CreatePreloadAnimation(Animation.AnimationId)
end

for _, Mob in AllMobs do
	local MobConfig = Mob:FindFirstChild("MobConfig") and require(Mob.MobConfig)
	if MobConfig then
		for _, ID in MobConfig.CustomAnimations do
			CreatePreloadAnimation(ID)
		end
		
		if MobConfig.ChaseDelay and MobConfig.ChaseDelay[2] then
			CreatePreloadAnimation(MobConfig.ChaseDelay[2])
		end
		
		if MobConfig.RespawnDelay and MobConfig.RespawnDelay[2] then
			CreatePreloadAnimation(MobConfig.RespawnDelay[2])
		end
	end
end

---- Preload all animations

local Success, Return = pcall(function()
	ContentProvider:PreloadAsync(RequestedPreloadCache)
end)

if not Success then
	print("Preload failed:", Return)
end

return {}