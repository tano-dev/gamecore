--[[
	ej0w @ November 2024
	AIMob
	
	Handles the internal system for Mob pathfinding & general AI, all movement handled under here 
]]

--> Services
local PathfindingService = game:GetService("PathfindingService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--> Dependencies
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)

local MobList = require(script.Parent.MobList)

local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local AIMob = {}
AIMob.__index = AIMob

--> Configuration
local CHECK_ALL_MOVEMENT = 1 / 2
local MOVEMENT_DURATION = 1 / 4
local WANDER_CHECK_TIME = 1 / 5

---- UTILITY FUNCTIONS ---------------------------------------------------------

local RaycastParamsHitCharacters = RaycastParams.new()
RaycastParamsHitCharacters.FilterDescendantsInstances = {
	workspace:WaitForChild("Temporary"), 
	workspace:WaitForChild("Mobs"), workspace.Teleports, workspace.Map.Doors, workspace.Zones
}
RaycastParamsHitCharacters.FilterType = Enum.RaycastFilterType.Exclude
RaycastParamsHitCharacters.RespectCanCollide = true
RaycastParamsHitCharacters.IgnoreWater = true

local RaycastParams = RaycastParams.new()
RaycastParams.FilterDescendantsInstances = {
	workspace:WaitForChild("Temporary"), workspace:WaitForChild("Characters"),
	workspace.Zones, workspace:WaitForChild("Mobs"), workspace.Teleports, workspace.Map.Doors
}
RaycastParams.RespectCanCollide = true
RaycastParams.IgnoreWater = true

--------------------------------------------------------------------------------

function AIMob.new(Mob)
	local self = setmetatable({}, AIMob)
	self.Instance = Mob.Instance
	self.Mob = Mob
	
	local Agent = self:ConstructPathfindingAgent(Mob)
	Mob.Path = Agent and PathfindingService:CreatePath(Agent)
	Mob.Agent = Agent
	
	self.Threads = {}
	
	self.Threads[#self.Threads + 1] = task.spawn(AIMob.ConnectActiveCycle, self)
	self.Threads[#self.Threads + 1] = task.spawn(function()
		while self:IsMobAlive() do
			if not Mob.isActive and not Mob.isWandering and not Mob.isGoingBack then
				self:StartWandering()
			end
			
			self:RequestJump()
			task.wait(CHECK_ALL_MOVEMENT)
		end
	end)
	
	if Mob.Ranged and not Mob.Shooting then
		self.Threads[#self.Threads + 1] = task.spawn(function()
			Mob.Shooting = true
			
			while self:IsMobAlive() do
				self:RequestShootAt()
				
				task.wait(Mob.Config.Cooldown or 1)
			end
		end)
	end
	
	return self
end

function AIMob:Destroy()
	for _, Thread in self.Threads do
		task.cancel(Thread)
		Thread = nil
	end
	
	setmetatable(self, nil)
end

function AIMob:IsMobAlive()
	return self.Mob and self.Mob.Instance and not self.Mob.isDead
end

function AIMob:SetNetworkOwner(Owner)
	if not self:IsMobAlive() then return end
	
	task.spawn(function()
		pcall(function()
			self.Mob.Root:SetNetworkOwner(Owner)
		end)
	end)
end

function AIMob:ConstructPathfindingAgent()
	if not self:IsMobAlive() then return end
	
	return {
		AgentRadius =  self.Mob.Instance.Hitbox.Size.X,
		AgentHeight =  self.Mob.Instance.Hitbox.Size.Y,
		AgentCanJump = true,
		WaypointSpacing = (self.Mob.Config.WalkSpeed and  self.Mob.Config.WalkSpeed > 8 and self.Mob.Config.WalkSpeed) or 32,
	}
end

function AIMob:RequestDisconnect()
	self.Mob.PathfindId = nil
	self.Mob.Locating = false
end

-- Gets the closest player within range to the given mob. If the closest player is the player the mob is already following, distance is 2x.
-- Note: If streaming is enabled, MoveTo may produce undesired results if the max distance is ever higher than streaming minimum, such as the enemy
-- appearing to 'idle' if the current distance/magnitude is between the streaming minimum and the max follow distance (including 2x possibility)
function AIMob:GetClosestPlayer(MaxDistance)
	if not self:IsMobAlive() then return end
	
	local Mob = self.Mob
	local RegenerateTag = Mob.Instance:FindFirstChild("RegenerateTag")
	
	if RegenerateTag then
		local PlayerID = RegenerateTag:GetAttribute("PlayerID") 
		local Player = PlayerID and (Players:GetPlayerByUserId(PlayerID) or Players:GetPlayerByUserId("-" .. PlayerID))

		-- Fixes when the player dies
		local Character = Player and Player.Character
		if not Character or not Character:FindFirstChild("Humanoid") or Character.Humanoid.Health <= 0 then
			return nil
		end

		local Magnitude = Character and (Character:GetPivot().Position - Mob.Instance:GetPivot().Position).Magnitude
		return Player, Magnitude
	elseif not RegenerateTag then
		local Closest = {Player = nil, Magnitude = math.huge}

		local ActivePlayer -- We retain a reference to this, so they have to get further away from the mob to stop following, instead of the usual distance.
		if Mob.Enemy.WalkToPart then
			local Player = Players:GetPlayerFromCharacter(Mob.Enemy.WalkToPart.Parent)
			if Player then
				ActivePlayer = Player
			end
		end

		for _, Player in Players:GetPlayers() do
			local Character = Player.Character
			if not Character then continue end

			local Magnitude = (Character:GetPivot().Position - Mob.Instance:GetPivot().Position).Magnitude

			MaxDistance = MaxDistance 
				or (ActivePlayer == Player and (Mob.FollowDistance or 32) * 2) 
				or Mob.FollowDistance 

			if Magnitude <= MaxDistance and Magnitude < Closest.Magnitude then
				Closest.Player = Player
				Closest.Magnitude = Magnitude
			end
		end

		-- Fixes when the player dies
		if Closest.Player then
			local Character = Closest.Player.Character
			if not Character or not Character:FindFirstChild("Humanoid") or Character.Humanoid.Health <= 0 then
				return nil
			end
		end

		return Closest.Player, Closest.Player and Closest.Magnitude
	end
end

-- Adds the mob to the ActiveMobs table. This table runs a few times per second and updates follow & jump code for active mobs.
-- Active mobs are unanchored, and anchored back when they're not active (not within follow range of any player)
function AIMob:StartTracking(Range)
	if not self:IsMobAlive() then return end
	
	local Mob = self.Mob
	local Success = false
	
	local FollowDistance = Range or Mob.FollowDistance
	
	local Player, Magnitude = self:GetClosestPlayer(FollowDistance)
	if Player and Magnitude and Magnitude < FollowDistance then
		local Character = Player.Character

		local CharacterPivot = Character and Character:GetPivot().Position
		local Torso = Character and Character:FindFirstChild("Torso")

		if not Mob.isActive then
			local ChaseDelay = (Mob.Config.ChaseDelay and Mob.Config.ChaseDelay[1]) or 0
			if ChaseDelay > 0 and not Mob.isActive then
				task.delay(ChaseDelay, function()
					Mob:SetWalkSpeed("Chasing", nil)
				end)

				Mob:SetWalkSpeed("Chasing", -9999)
			end

			Mob:RequestCallback("OnTargetPlayer", {Player})
		end

		task.spawn(function()
			self:RequestFollowPath(Mob.Path, CharacterPivot, Torso, nil, true)
		end)

		Success = true
	end

	if Success then
		Mob.isActive = true
		Mob.isGoingBack = false
		Mob.isWandering = false
		Mob.PathfindId = nil
		Mob.Range = Range
	end

	return Success
end

-- Requests the mob to perform a jump if there's an obstacle in the way of it.
function AIMob:RequestJump()
	if not self:IsMobAlive() then return end

	local Mob = self.Mob
	local Root: BasePart = Mob.Root
	local JumpHeight: number = (Mob.Enemy.JumpPower ^ 2) / (2 * workspace.Gravity) * .8
	local HipPoint: CFrame = Root.CFrame + (Root.CFrame.LookVector*(Root.Size.Z/2-0.2)) + (Root.CFrame.UpVector/-Root.Size.Y/2)

	local RaycastResult = workspace:Raycast(
		HipPoint.Position,
		HipPoint.LookVector * Mob.Enemy.WalkSpeed/4,
		RaycastParams
	)

	if RaycastResult then
		if RaycastResult.Instance ~= workspace.Terrain then
			local PartHeight: number = (RaycastResult.Instance.Position + Vector3.new(0, RaycastResult.Instance.Size.Y/2, 0)).Y
			if (HipPoint.Position.Y + JumpHeight) > PartHeight then
				Mob:RequestJump()
			end
		else
			Mob:RequestJump()
		end
	end
end

function AIMob:RequestFollowPath(Path, Destination, Target, Ignore, NotMaxDist)
	if not self:IsMobAlive() then return end

	local Mob = self.Mob
	local Origin = Mob.Root.Position
	local Enemy = Mob.Enemy :: Humanoid

	local MobTorso = Mob.Instance:FindFirstChild("Torso")
	if not MobTorso then
		return
	end

	local RealDestination = (Target and Target.Position or Destination)
	local Raycast = workspace:Raycast(Origin, (RealDestination - Origin).Unit * 1000, RaycastParamsHitCharacters)

	local CanLazyWalk = not Ignore and Raycast and (RealDestination - Raycast.Position).Magnitude < 10

	local isDistance = Target and math.abs(MobTorso.Position.Y - Target.Position.Y) <= 1
	local isClose = Target and CanLazyWalk and isDistance

	local canWalkDumb = Mob.isDumb or isClose
	if canWalkDumb or isClose then
		self:RequestDisconnect()
		Enemy:MoveTo(RealDestination, Target)
	else
		local Success, Return = pcall(function()
			Path:ComputeAsync(Mob.Root.Position, Destination)
		end)

		local CanPathfind = Success and Path.Status == Enum.PathStatus.Success
		if CanPathfind and self:IsMobAlive() then
			local Waypoints = Path:GetWaypoints()
			local Iteration = nil

			self:RequestDisconnect()

			local Clock = os.clock()
			Mob.PathfindId = Clock

			local function RequestPathfind(Index, Waypoint)
				if Mob.isDead or not Mob.Instance then
					return
				end

				Mob.Root.Anchored = false
				AttributeModule:SetAttribute(Mob.Instance, "DontAnchor", true)

				local nextWaypoint = Waypoints[Index + 1]
				local enumJump = Enum.PathWaypointAction.Jump

				if (GameConfig.JumpyMobs and Waypoint.Action == enumJump) or (nextWaypoint and nextWaypoint.Action == enumJump) then
					Mob:RequestJump()
				else
					self:RequestJump()
				end

				Enemy:MoveTo(nextWaypoint and nextWaypoint.Position or Waypoint.Position)
				Enemy.MoveToFinished:Wait()
			end

			task.spawn(function()
				for Index, Waypoint in Waypoints do
					if Index == 1 then
						continue
					end

					local isTooClose = (Mob.Ranged and Target and (Target.Position - Waypoint.Position).Magnitude < 14)
					local isTooFar = (Target and (Target.Position - Waypoint.Position).Magnitude > Mob.FollowDistance * 2)

					if Mob.PathfindId ~= Clock or isTooClose or (isTooFar and not NotMaxDist) or not self:IsMobAlive() then 
						if isTooClose then
							local Magnitude = (Destination - Origin).Magnitude
							local Distance = (Mob.keepDistance[2] - 1) - Magnitude

							local RetreatVector = (Origin - Destination).Unit * Distance

							Enemy:MoveTo(Origin + RetreatVector, nil)
						end
						
						self:RequestDisconnect()
						break 
					end

					RequestPathfind(Index, Waypoint)
				end
			end)
		elseif not CanPathfind then
			self:RequestDisconnect()
			Enemy:MoveTo(RealDestination, Target)
		end
	end
end

function AIMob:StartWandering()
	if not self:IsMobAlive() then return end

	local Mob = self.Mob
	if not Mob.isWandering then
		Mob:RequestCallback("OnWandering")
		Mob:SetWalkSpeed("Wandering", (Mob.Config.WanderSpeed and Mob.Config.WanderSpeed - Mob.Config.WalkSpeed) or -2)

		Mob.isWandering = true

		if not AttributeModule:GetAttribute(Mob.Instance, "Origin") then
			AttributeModule:SetAttribute(Mob.Instance, "Origin", Mob.Instance:GetPivot().Position)
		end

		local currentlyWandering = false

		while self:IsMobAlive() and Mob.isWandering and not Mob.isActive do
			if self:StartTracking() then
				break
			end

			if math.random(10) == 1 and not currentlyWandering then
				local Player, Magnitude = self:GetClosestPlayer(GameConfig.DefaultDistanceRadius)
				if Magnitude and Magnitude < GameConfig.DefaultDistanceRadius then
					local Origin = AttributeModule:GetAttribute(Mob.Instance, "Origin")

					local Chosen = nil :: Vector3
					local Success = nil :: boolean

					while not Chosen and not Success and Origin do
						local Position = Origin + Vector3.new(math.random(-Mob.WanderRadius, Mob.WanderRadius), 25, math.random(-Mob.WanderRadius, Mob.WanderRadius))

						local Raycast = workspace:Raycast(Position, Vector3.new(0, -50, 0), RaycastParams)
						if Raycast and Raycast.Instance.CanCollide then
							Chosen = Raycast.Position
							Success = true
						end

						if not Success then
							task.wait()
						end
					end

					if Chosen then
						currentlyWandering = true
						
						self:RequestFollowPath(Mob.Path, Chosen, nil, true)
						
						currentlyWandering = false
					end
				end
			end

			task.wait(WANDER_CHECK_TIME)
		end

		Mob:SetWalkSpeed("Wandering", nil)
		Mob.isWandering = false
	end
end

function AIMob:GoBack(CantChase)
	if not self:IsMobAlive() then return end

	local Mob = self.Mob
	if not Mob.isGoingBack then
		Mob.isActive = false
		Mob.isWandering = false
		Mob.isGoingBack = true
		
		local MobInstance = Mob.Instance
		AttributeModule:SetAttribute(MobInstance, "Target", nil)
		
		self:SetNetworkOwner()
		
		Mob:RequestCallback("OnGoingBack")
		Mob:SetWalkSpeed("GoingBack", (Mob.Config.WanderSpeed and Mob.Config.WanderSpeed - Mob.Config.WalkSpeed) or -2)

		while Mob and Mob.Instance and not Mob.isDead and Mob.isGoingBack and not Mob.isActive and (Mob.Origin.Position - Mob.Instance:GetPivot().Position).Magnitude > 5 do
			if not CantChase and self:StartTracking() then 
				break 
			end

			self:RequestJump()
			self:RequestFollowPath(Mob.Path, Mob.Origin.Position) 

			task.wait(MOVEMENT_DURATION)
		end

		Mob:SetWalkSpeed("GoingBack", nil)
		Mob.isGoingBack = false
	end
end

function AIMob:RequestShootAt(Player)
	if not self:IsMobAlive() then return end

	local Mob = self.Mob
	local MobInstance = Mob.Instance
	
	local isStunned = AttributeModule:GetAttribute(MobInstance, "Stunned")
	if isStunned then return end
	
	local Player = Player or self:GetClosestPlayer(Mob.FollowDistance)
	if not Player then return end
	
	local Origin = MobInstance:GetPivot().Position
	local Destination = Player.Character:GetPivot().Position

	local Magnitude = (Destination - Origin).Magnitude
	local Distance = 15 - Magnitude
	
	local Tool = MobInstance:FindFirstChildWhichIsA("Tool")

	-- Shoot projectile
	local CastPoint: Attachment = Tool and Tool.Handle:FindFirstChild("CastPoint")
	if CastPoint then
		local Origin = CastPoint.WorldPosition + Vector3.new(0, 3, 0)
		Origin = Origin + (CastPoint.WorldCFrame.UpVector * 5)

		local Destination = Destination + Vector3.new(0, -2, 0)

		local Magnitude = (Destination - Origin).Magnitude
		local Direction = (Destination - Origin).Unit

		Mob:RequestCallback("OnShoot", {Player})
		
		EventModule:FireAllClients("MobProcessedFire",
			MobInstance, Origin, Direction, 
			Mob.Config.Projectile, Mob.Config.Damage, Mob.Config.ActivateSound
		)
		
		EventModule:FireAllClients("RequestAnimateMob", MobInstance, "Fire")
	end
end

function AIMob:ConnectActiveCycle()
	if not self:IsMobAlive() then return end

	local Mob = self.Mob
	local Enemy = Mob.Enemy
	local MobInstance = Mob.Instance
	
	local previouslyActive = false
	
	while self:IsMobAlive() do
		if Mob.isActive and Mob.Root then
			Mob:SetWalkSpeed("GoingBack", nil)
			Mob:SetWalkSpeed("Wandering", nil)

			if Mob.Root.Anchored then
				Mob.Root.Anchored = false
			end
			
			local Player = self:GetClosestPlayer(Mob.Range)
			local Origin = Mob.Instance:GetPivot().Position
			
			local isTracking = Player and Player.Character
			local Destination = isTracking and Player.Character:GetPivot().Position
			local Torso = isTracking and Player.Character:FindFirstChild("Torso")
			
			local isTooFarFromSpawn = (Origin - Mob.Origin.Position).Magnitude > Mob.rangeRadius
			if isTracking and not isTooFarFromSpawn then
				self:SetNetworkOwner(Player)
				
				task.wait(1 / 10)
				
				Mob.isGoingBack = false
				Mob.isWandering = false

				Mob.PathfindId = nil

				local Magnitude = (Destination - Origin).Magnitude
				local Distance = Mob.keepDistance[2] - Magnitude
				
				AttributeModule:SetAttribute(MobInstance, "Target", Player.UserId)
				
				local HealthPercentage = Enemy.Health / Enemy.MaxHealth
				local RetreatVector = (Origin - Destination).Unit * Distance
				
				-- Determine where mob is going
				local isMelee = Mob.aiType == "Melee" or not Mob.Ranged
				local isRanged = Mob.aiType == "Ranged" or Mob.Ranged
				
				local isAwayFromPlayer = Magnitude > Mob.keepDistance[2]
				
				local canFocus = isRanged
					or Mob.tendencyType == "Medium" and HealthPercentage <= Mob.runPercentage
					or Mob.tendencyType == "Coward"
				
				local canGoNearPlayer = (isRanged and isAwayFromPlayer) 
					or Mob.tendencyType == "Brave" and not isRanged
					or Mob.tendencyType == "Medium" and HealthPercentage > Mob.runPercentage and not isRanged
				
				if Mob.lookTarget then
					AttributeModule:SetAttribute(MobInstance, "Focus", true)
				else
					AttributeModule:SetAttribute(MobInstance, "Still", canFocus and Magnitude > Mob.keepDistance[1] and Magnitude < Mob.keepDistance[2] or nil)
				end

				if canGoNearPlayer then
					self:RequestFollowPath(Mob.Path, (Mob.Ranged and Origin + RetreatVector) or Destination, Torso) 
				else
					self:RequestDisconnect()
					Enemy:MoveTo(Origin + RetreatVector, nil)
				end

				self:RequestJump()
			else
				Mob.Range = nil
				AttributeModule:SetAttribute(MobInstance, "Focus", false)
				
				self:GoBack(isTooFarFromSpawn)
			end
		end
		
		task.wait(MOVEMENT_DURATION)
	end
end

return AIMob