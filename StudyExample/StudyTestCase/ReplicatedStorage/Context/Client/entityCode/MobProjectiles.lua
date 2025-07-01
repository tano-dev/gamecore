--[[
	ej0w @ May 2024
	MobProjectiles
	
	Handles clientside rendering for mob projectiles,
	Being completely transparent, player damage from ranged mobs is also held here (i suggest a better alternative if you're planning to use ranged mobs a lot).
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer

--> References
local ProjectileCache = workspace:WaitForChild("Temporary"):WaitForChild("ProjectileCache")
local Modules = ReplicatedStorage.Modules

--> Dependencies
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local PartCache = require(ReplicatedStorage.Context.Shared.Casting.PartCache)
local Casting = require(ReplicatedStorage.Context.Shared.Casting)

local GameConfig = require(ReplicatedStorage.GameConfig)
local SFX = require(Modules.Shared.SFX)
local RbxUtility = require(Modules.Shared.RbxUtility)

--> Variables
local Projectiles = {}
local Caster = Casting.new()

local RaycastParams = RaycastParams.new()
RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
RaycastParams.FilterDescendantsInstances = {
	workspace:WaitForChild("Temporary"),
	workspace:WaitForChild("Mobs"), workspace.Map.Doors, workspace.Zones, workspace.Teleports, workspace:WaitForChild("Props")
}
RaycastParams.IgnoreWater = true

--------------------------------------------------------------------------------

Casting:DefaultHookRayHit(Caster, function(Projectile, RaycastResult, Ended, Pierces, Model, CanHit)
	local isPlayer = Model and Players:GetPlayerFromCharacter(Model)
	if isPlayer and (Player == isPlayer) and CanHit then
		local Humanoid = Model:FindFirstChildOfClass("Humanoid")
		if Humanoid and Humanoid.Health > 0 then
			EventModule:FireServer("PlayerDamaged", Projectile.Damage, Projectile.MobInstance)
		end
	end
end)

Casting:DefaultHookLengthChanged(Caster)
Casting:DefaultHookRayTerminating(Caster)

function Projectiles:CastProjectile(MobInstance, _, Direction, CastingMesh, Damage)
	local Origin = MobInstance:FindFirstChild("CastPoint", true).WorldPosition
	
	local MobConfig = require(MobInstance:WaitForChild("MobConfig", 60))
	if not MobConfig or not MobConfig.ProjectileData then 
		return 
	end
	
	local Projectile = Caster:Cast(MobInstance, nil, Origin, Direction, Direction.Unit * MobConfig.ProjectileData.Velocity, MobConfig.ProjectileData.Acceleration, {RaycastParams = RaycastParams}, MobConfig.ProjectileData.Pierce, Damage, true)
	if Projectile then
		local Cache = PartCache.new(ReplicatedStorage.Assets.Projectiles[CastingMesh], nil, ProjectileCache)
		local CastingMesh = Cache:GetPart()
		Projectile.UserData.CastingMesh = CastingMesh
		Projectile.MobInstance = MobInstance
		Projectile:Update()
	end
end

EventModule:GetOnClientEvent("MobProcessedFire"):Connect(function(MobInstance, _, Direction, CastingMesh, Damage, ActivateSound)
	local Origin = MobInstance:FindFirstChild("CastPoint", true)
	Origin = Origin and Origin.WorldPosition
	if not Origin then
		return 
	end
	
	local Character = Player.Character
	if not Character or (Character:GetPivot().Position - Origin).Magnitude > GameConfig.MobRenderDistance then
		return
	end
	
	task.spawn(function()
		SFX:Play3D(ActivateSound, Origin)
	end)
	
	Projectiles:CastProjectile(MobInstance, Origin, Direction, CastingMesh, Damage)
end)

return Projectiles