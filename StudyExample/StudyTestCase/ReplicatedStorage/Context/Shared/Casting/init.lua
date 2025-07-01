--[[
	Evercyan @ March 2022
	Casting
	
	Inspired by FastCast, this is a module created as a lighter implementation compared to the original module for Infinity, and simplified further for the kit release.
	Only thing used from FastCast is the formula for exponential acceleration (Acceleration x Delta ^ 2).
	
	Code may look complex here, but effectively, you create a 'Caster' object to represent something that fires projectiles - this can be an enemy, a sentry, or for your use case, a bow or gun.
	After creating a Caster object, you can 'Cast' a projectile into 3D space to have it start being simulated from the origin, direction, velocity, and acceleration you give it.
	
	Origin is where the projectile starts, Direction is the direction that the projectile faces and takes, Velocity is the rate of speed that it will go, and finally, Acceleration is the change of velocity over time (e.g. gravity drops an arrow stronger over time)
	
	Each frame, projectiles are incremented forward for the difference in time since the last frame, and a Ray is fired from the last position to the current position. If the ray hits something (e.g. wall, mob), then it'll fire RayHit.
	Each Caster has 'Signal' classes that fire whenever key changes happen, and your Caster object (remember, it can be a bow, anything that can shoot a projectile!) will need to respond to these events.
	
	---- CASTER EVENTS ----
	
	LengthChanged - The Position value of the Projectile has been updated. Use this event to update the position of the physical object (ie. arrow mesh) associated with the projectile.
	RayHit - The ray for the Projectile has hit something - this can be anything, like a wall, terrain, or another player or character. Use this event to do something with the instance it hit (passes RaycastResult), like requesting the server to damage this mob.
	RayTerminating - The projectile has either passed the max length it can travel, it hit something, or it has been in the air for too long. The position will no longer be updated, and the projectile will be dropped from the pool. Cleanup here.
	
	Each function should be explained, if not self-explainable. If you ever need help, always reference the default Bow that comes with the kit.
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Debris = game:GetService("Debris")

--> References
local ProjectileCache = workspace:WaitForChild("Temporary"):WaitForChild("ProjectileCache")
local CastingMesh = ReplicatedStorage.Assets.Projectiles

--> Dependencies
local Signal = require(ReplicatedStorage.Modules.Shared.Signal)
local PartCache = require(ReplicatedStorage.Context.Shared.Casting.PartCache)
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)

local GameConfig = require(ReplicatedStorage.GameConfig)

local Visualizations = require(script.Visualizations)

--> Variables
local Pool = {}
local defaultCastingParams

----

-- Pool is a dynamic array that houses all active projectiles that get updated
-- each Heartbeat frame. It's removed from the pool once it gets terminated.
-- Projectiles get terminated if they hit something or reach their max distance.
local function AddToPool(Projectile)
	if not Projectile.Id then
		local Id = #Pool + 1
		
		Projectile.Id = HttpService:GenerateGUID()
		Pool[Projectile.Id] = Projectile
		Projectile.Caster.NumAlive += 1
	end
end

local function RemoveFromPool(Projectile)
	Pool[Projectile.Id] = nil
	Projectile.Caster.NumAlive -= 1
end

local function CastRay(Origin, Direction, RaycastParams: RaycastParams): RaycastResult?
	return workspace:Raycast(Origin, Direction, RaycastParams)
end

-- Calculate the estimated position for the projectile, based off of how long
-- the projectile has been alive for.
local function GetPosition(Projectile): Vector3
	local Delta = tick() - Projectile.initTime
	local Force = (Projectile.Acceleration * Delta^2) / 2
	return Projectile.Origin + (Projectile.Velocity * Delta) + Force
end

-- "Terminates" a projectile. When a projectile is terminated, it will be removed
-- from the Pool and cannot be resurrected. Make sure to lose the reference
-- to it, and it'll be garbage collected. Any physical objects should be removed
-- when RayTerminating is fired.
local function TerminateProjectile(Projectile)
	if Projectile.Alive then
		Projectile.Alive = false
		Projectile.Caster.RayTerminating:Fire(Projectile)
		task.delay(0.03, RemoveFromPool, Projectile)
	end
end

-- Updates a projectile's physical properties. If a projectile is alive (in the
-- pool), then it'll update every Heartbeat. Respective events are fired for
-- changes to be done by the script that casted a projectile, such as bullet
-- object CFraming.
local function UpdateProjectile(Projectile)
	if not Projectile.Alive then
		return
	end
	
	-- Grab new position & direction
	local oldPosition = Projectile.Position
	local Position = GetPosition(Projectile)
	local Direction = (Position - oldPosition)
	
	-- Cast a ray. If something is found, adjust position & direction magnitude.
	-- Prevents piercing from bugging and messing out as it contacts w/ the part
	local RaycastParams = RaycastParams.new()
	RaycastParams.RespectCanCollide = true
	RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local Parameters = {
		workspace:WaitForChild("Temporary"),
		workspace.Zones, workspace.Teleports
	}
	
	table.insert(Parameters, workspace:WaitForChild("Mobs"))
	if not Projectile.SentByMob then
		table.insert(Parameters, workspace:WaitForChild("Characters"))
	end
	
	RaycastParams.FilterDescendantsInstances = Parameters
	
	local MovementRaycast = CastRay(oldPosition, Direction, RaycastParams)
	if MovementRaycast then
		Position = MovementRaycast.Position
		Direction = (Position - oldPosition)
	end
	
	-- Cast ray for actual part detection
	local RaycastResult = CastRay(oldPosition, Direction, Projectile.castingParams.RaycastParams) or MovementRaycast
	local Part = RaycastResult and RaycastResult.Instance
	
	local Model = Part and Part:FindFirstAncestorOfClass("Model")
	local isMob = Model and CollectionService:HasTag(Model, "Mob")

	-- Check if item already passed thru & add pierces
	local PierceMax = Projectile.Pierce
	local Ended, TotalPierces, CanHit, DidPierce = false, 0, true, false
	
	local hasPiercedAlready = Part and table.find(Projectile.PierceBank, (isMob and Model) or Part)
	if RaycastResult and not hasPiercedAlready and PierceMax then
		Projectile.Pierces = Projectile.Pierces or 1
		CanHit = Projectile.Pierces < PierceMax

		-- Add pierces
		if isMob then
			DidPierce = true
			Projectile.Pierces += 1
			table.insert(Projectile.PierceBank, isMob and Model or Part)
		elseif not isMob then
			Projectile.Pierces = PierceMax
		end
		
		Ended = Projectile.Pierces >= PierceMax
		TotalPierces = Projectile.Pierces
	end
	
	-- Update projectile properties & fire LengthChanged
	Projectile.distanceTravelled += Direction.Magnitude
	Projectile.Direction = Direction
	Projectile.Position = Position
	if not DidPierce then
		Projectile.Caster.LengthChanged:Fire(Projectile)
	end
	
	-- Handle hit, piericing, and termination.
	local TimedOut = tick() - Projectile.initTime > 10
	local TooFar = Projectile.distanceTravelled >= .5e3
	
	if RaycastResult and not TimedOut then
		Projectile.Caster.RayHit:Fire(Projectile, RaycastResult, Ended, TotalPierces, CanHit)
		Visualizations:CreateHit(Position, Direction)
		if Ended then
			TerminateProjectile(Projectile)
		elseif not Ended then
			Visualizations:CreateSegment(Position, Direction)
			Visualizations:CreateOrigin(Position)
		end
	elseif TooFar or TimedOut then
		TerminateProjectile(Projectile)
		Visualizations:CreateTerminate(Position, Direction)
	else
		Visualizations:CreateSegment(Position, Direction)
		Visualizations:CreateOrigin(Position)
	end
end

-- Update all projectiles every Heartbeat.
local lastStep = 0
RunService.Heartbeat:Connect(function(Step)
	local delayed = Step > 0.3 and lastStep > 0.3
	
	if delayed and next(Pool) ~= nil then
		print("[Casting]: Heartbeat frame took too long! Terminating all projectiles.")
	end
	
	for _, Projectile in Pool do
		if delayed == true then
			TerminateProjectile(Projectile)
		else
			UpdateProjectile(Projectile)
		end
	end
	
	lastStep = Step
end)

local Casting = {}
local Caster = {}
Caster.__index = Caster

function Casting.new(): Caster
	return setmetatable({
		LengthChanged = Signal.new(),
		RayHit = Signal.new(),
		RayTerminating = Signal.new(),
		AliveLimit = 300,
		NumAlive = 0
	}, Caster)
end

-- NEW: Used to run a function instead of having a connection in the Caster script.
-- This is so if the script that made the Caster gets removed, it won't cause leaking/run forever.
local coro = coroutine.create(function()
	while true do
		local func = coroutine.yield()
		func()
	end
end)
coroutine.resume(coro)

function Caster:HookFunction(signalName, func)
	local Connection
	coroutine.resume(coro, function()
		Connection = self[signalName]:Connect(func)
	end)
	
	return Connection
end

function Casting.newCastingParams(Filter)
	local RaycastParams = RaycastParams.new()
	RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	RaycastParams.FilterDescendantsInstances = {
		workspace:WaitForChild("Temporary"),
		workspace.Zones, workspace.Teleports,
		Filter and table.unpack(Filter)
	}
	RaycastParams.IgnoreWater = true
	
	return {
		RaycastParams = RaycastParams
	}
end

function Caster:Cast(Owner: Player?, Tool: Tool?, Origin: Vector3, Direction: Vector3, Velocity, Acceleration, castingParams, Pierce, Damage, SentByMob)
	if self.NumAlive >= self.AliveLimit then
		print(`[Casting]: TOO_MANY_ALIVE: Cannot cast new bullet. Pool Limit for Caster: {self.AliveLimit}. Total pool size: {#Pool}`)
		return
	end
	
	local Projectile = {}
	
	if not castingParams then
		castingParams = Casting.newCastingParams({(SentByMob and workspace:WaitForChild("Mobs")) or workspace:WaitForChild("Characters")})
	end
	
	-- Constants
	Projectile.Caster = self
	Projectile.Origin = Origin
	Projectile.Velocity = Velocity
	Projectile.Acceleration = Acceleration
	Projectile.castingParams = castingParams
	Projectile.initTime = tick()
	Projectile.Pierce = Pierce
	Projectile.Damage = Damage
	
	Projectile.Tool = Tool
	Projectile.Owner = Owner
	
	-- Variables
	Projectile.Alive = true
	Projectile.SentByMob = SentByMob
	Projectile.Position = Origin
	Projectile.Direction = Direction
	Projectile.distanceTravelled = 0
	Projectile.UserData = {}
	Projectile.Pierces = 0
	Projectile.PierceBank = {}
	
	AddToPool(Projectile)
	-- Forcefully call Update. Should be used initially immediately after you
	-- Cast & assign a projectile object to the UserData table.
	function Projectile:Update()
		Projectile.UserData.CastingMesh:PivotTo(CFrame.lookAt(Origin, Origin + Direction))
		task.delay(0.03, UpdateProjectile, Projectile)
	end
	
	Visualizations:CreateOrigin(Origin)
	return Projectile
end

-- Sets the limit of how many alive/simulated projectiles can exist at one time, created by this Caster. There is no global limit.
function Caster:SetLimit(AliveLimit: number?)
	self.AliveLimit = AliveLimit or 300
end

---- Caster utilities - used for cross-sharing between scripts ---------------

-- Creates a thread independent from the script - helps in-case the script gets destroyed (or its parent) while being cleaned up
local BindableEvent = Instance.new("BindableEvent")
local function NewThread(Callback)
	local Connection; Connection = BindableEvent.Event:Connect(function()
		task.spawn(Callback)
		Connection:Disconnect()
		Connection = nil
	end)
	task.spawn(function()
		BindableEvent:Fire()
	end)
end

local function RoundVector3(Vector)
	return Vector3.new(math.round(Vector.X * 100) / 100, math.round(Vector.Y * 100) / 100, math.round(Vector.Z * 100) / 100)
end

function Casting:DefaultHookLengthChanged(NewCaster)
	NewCaster:HookFunction("LengthChanged", function(Projectile)
		local Size = Projectile.UserData.CastingMesh.Size
		local ProjectilePosition = Projectile.Position + -Projectile.Direction.Unit*(Size.Z/2)
		
		local NewCFrame = CFrame.lookAt(ProjectilePosition, ProjectilePosition + Projectile.Direction)
		Projectile.UserData.CastingMesh.CFrame = NewCFrame
		Projectile.UserData.CastingMesh:SetAttribute("Modified", os.clock())
	end)
end

function Casting:DefaultHookRayHit(NewCaster, Callback)
	NewCaster:HookFunction("RayHit", function(Projectile, RaycastResult, Ended, Pierces, CanHit)
		local Model = RaycastResult.Instance:FindFirstAncestorOfClass("Model")
		if Model and not Model:FindFirstChildWhichIsA("Humanoid") then
			Model = Model:FindFirstAncestorOfClass("Model")
		end
		
		-- Trail / stick
		if Ended then
			local CastingMesh = Projectile.UserData.CastingMesh
			if CastingMesh:GetAttribute("CanStick") then
				CastingMesh.Anchored = false
				local Weld = Instance.new("Weld")
				Weld.Name = "Sticky"
				Weld.Part0 = RaycastResult.Instance
				Weld.Part1 = CastingMesh
				Weld.C0 = RaycastResult.Instance.CFrame:Inverse() * CastingMesh.CFrame
				Weld.Parent = CastingMesh
			end
			for _, Instance in CastingMesh:GetChildren() do
				if Instance:IsA("Trail") or Instance:IsA("ParticleEmitter") then
					task.delay(nil, function() -- Wait until the next resumption to disable, so it will render the final trail section
						Instance.Enabled = false
					end)
				end
			end
		end
		
		-- Fire impacted callback
		if Projectile.Owner == Players.LocalPlayer then
			EventModule:FireServer("ClientToServerCallback", Projectile.Tool.Name, "OnImpacted", {Projectile.Tool, RaycastResult.Position, RaycastResult.Normal, RaycastResult.Instance})
		end
		
		-- Callback function
		if Callback then
			Callback(Projectile, RaycastResult, Ended, Pierces, Model, CanHit)
		end
	end)
end

function Casting:DefaultHookRayTerminating(NewCaster)
	NewCaster:HookFunction("RayTerminating", function(Projectile)
		local Cache = PartCache.new(ReplicatedStorage.Assets.Projectiles[Projectile.UserData.CastingMesh.Name], nil, ProjectileCache)
		local CastingMesh = Projectile.UserData.CastingMesh

		-- Stick clean-up, and return part to cache
		local Weld = CastingMesh:FindFirstChild("Sticky")
		if Weld then
			NewThread(function()
				task.wait(3)
				if Weld and Weld.Parent then
					Weld:Destroy()
				end
				Cache:ReturnPart(CastingMesh)
			end)
		elseif not Weld then
			task.defer(function()
				Cache:ReturnPart(CastingMesh)
			end)
		end
	end)
end

---- Caster network sharing - let other players see a projectile ---------------

--- Caster listeners for client-sided caster to handle shared projectiles
local SharedCaster = Casting.new()
SharedCaster:SetLimit(80)

Casting:DefaultHookLengthChanged(SharedCaster)
Casting:DefaultHookRayHit(SharedCaster)
Casting:DefaultHookRayTerminating(SharedCaster)

-- Share this clients projectile with other clients.
function Caster:Share(Origin: Vector3, Direction: Vector3, Velocity: Vector3, Acceleration: Vector3, MeshName: string)
	if RunService:IsServer() then warn("[Caster]: Caster.Share can only be used by the client.") end
	EventModule:FireServer("ShareProjectile", Origin, Direction, Velocity, Acceleration, MeshName)
end

-- Handle remote requests from the client to server and server to client(s)
if RunService:IsClient() then
	-- Requests from the server are completed here to show shared projectiles from the other player on this local player's side
	EventModule:GetOnClientEvent("ReceiveProjectile"):Connect(function(playerWhichSent: Player, Origin, Direction, Velocity, Acceleration, MeshName: string)
		if not Origin or not Direction or not Velocity or not Acceleration or not MeshName then return end
		if typeof(Origin) ~= "Vector3" or typeof(Direction) ~= "Vector3" or typeof(Velocity) ~= "Vector3" or typeof(Acceleration) ~= "Vector3" or typeof(MeshName) ~= "string" then return end
		
		local Template = ReplicatedStorage.Assets.Projectiles:FindFirstChild(MeshName)
		if not Template then
			return
		end
		
		local Projectile = SharedCaster:Cast(nil, nil, Origin, Direction, Velocity, Acceleration)
		if Projectile then
			local Cache = PartCache.new(Template, nil, ProjectileCache)
			local CastingMesh = Cache:GetPart()
			
			Projectile.UserData.CastingMesh = CastingMesh
			Projectile:Update() -- Initially update the projectile after the trail is cleared, so it will appear for the first frame, and the trail will reset so it won't trail from far away to here
		end
	end)
elseif RunService:IsServer() then
	-- Requests from the client are completed here to share them to every other client
	EventModule:GetOnServerEvent("ShareProjectile"):Connect(function(Client, ...)
		for _, Player in Players:GetPlayers() do
			if Player ~= Client then
				EventModule:FireClient("ReceiveProjectile", Player, Client, ...)
			end
		end
	end)
end

--------------------------------------------------------------------------------

defaultCastingParams = Casting.newCastingParams()
export type Caster = typeof(Casting.new())
return Casting