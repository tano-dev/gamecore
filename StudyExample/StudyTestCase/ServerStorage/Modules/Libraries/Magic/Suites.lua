--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")

--> References
local Effects = ReplicatedStorage.Assets.Effects

local Modules = ServerStorage.Modules

--> Dependencies
local DamageLib = require(Modules.Libraries.Damage)
local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local Magic = {}

--------------------------------------------------------------------------------
-- Utilities

local function HeartbeatWait(Magnitude)
	local Speed = 4
	for Iteration = 5, Magnitude, Speed do
		RunService.Heartbeat:Wait()
	end
end

local function ReturnMobsInRadius(EndPosition, Radius)
	local Mobs = workspace:WaitForChild("Mobs"):GetChildren()
	local Hits = {}
	for _, Mob in Mobs do
		local HumanoidRootPart = Mob:FindFirstChild("HumanoidRootPart")
		if (not HumanoidRootPart) or (not Mob:FindFirstChild("MobConfig")) then 
			continue 
		end

		if (EndPosition - HumanoidRootPart.Position).Magnitude < Radius then
			table.insert(Hits, Mob)
		end
	end
	return Hits
end

--------------------------------------------------------------------------------
-- Effect functions, add new functions here and specify them inside of ItemConfig
-- Preferred to use the configuration base for ranged items as default but all applicable

function Magic:Arbiter(Player, Tool, StartPosition, EndPosition, EventCallback)
	local Arbiter = Effects.Arbiter

	local RaycastParams = RaycastParams.new()
	RaycastParams.RespectCanCollide = true
	RaycastParams.FilterDescendantsInstances = {
		workspace:WaitForChild("Temporary"), workspace:WaitForChild("Characters"),
		workspace.Zones, workspace:WaitForChild("Mobs"), workspace.Teleports, workspace.Map.Doors
	}
	RaycastParams.FilterType = Enum.RaycastFilterType.Exclude

	local Raycast = workspace:Raycast(StartPosition, (EndPosition - StartPosition).Unit * 5000, RaycastParams)
	EndPosition = (Raycast and Raycast.Position) or EndPosition

	local CanExplode = (EndPosition - StartPosition).Magnitude < 150 

	local ItemConfig = require(Tool.ItemConfig)
	local ItemSuite = ItemConfig.Suite[2]

	local BezierModule = require(Arbiter.BezierModule)
	local Circle = require(Arbiter.Circle)
	local Boom = require(Arbiter.CreateBoom)

	-- Commence
	local Projectile = Arbiter.Projectiles:FindFirstChild(ItemSuite.Projectile)
	EventCallback(StartPosition, EndPosition, {CanExplode = CanExplode})

	if not CanExplode then
		return true, {}
	end
	HeartbeatWait((StartPosition - EndPosition).Magnitude)

	-- Damaging
	local Hits = ReturnMobsInRadius(EndPosition, ItemSuite.BlastRadius + 4)
	for _, Mob in Hits do
		task.spawn(DamageLib.CallDamage, Player, Mob, nil, "Magic")
	end

	return true, Hits
end

return Magic