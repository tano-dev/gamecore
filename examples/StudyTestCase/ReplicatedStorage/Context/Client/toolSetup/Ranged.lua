--> Services
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer

--> References
local ProjectileCache = workspace:WaitForChild("Temporary"):WaitForChild("ProjectileCache")
local Modules = ReplicatedStorage.Modules

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

local ToolSystem = require(ReplicatedStorage.Modules.Client.ToolSystem)
local PartCache = require(ReplicatedStorage.Context.Shared.Casting.PartCache)
local Casting = require(ReplicatedStorage.Context.Shared.Casting)
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)

local RbxUtility = require(Modules.Shared.RbxUtility)
local _Animation = require(Modules.Client.Animation)
local SFX = require(Modules.Shared.SFX)

--> Variables
local LastEquippedTool = 0
local RequestSwing = 0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return function(Tool)
	local Handle = Tool:WaitForChild("Handle")
	local CastPoint = Handle:WaitForChild("CastPoint") -- The projectiles start from this point

	local ItemConfig = require(Tool:WaitForChild("ItemConfig"))

	local ActiveSlashTrack
	local Caster = Casting.new()
	local Random = Random.new()
	
	local toolSystem = ToolSystem.new(Tool, true)
	
	-- Character
	local Character = Player.Character or Player.CharacterAdded:Wait()

	local Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
	local Animator = Humanoid:WaitForChild("Animator") :: Animator
	
	---- CASTER LISTENERS ----------------------------------------------------------

	local LastHit = os.clock()
	local Interacted = {}
	Casting:DefaultHookRayHit(Caster, function(Projectile, RaycastResult, Ended, Pierces, Model, CanHit)
		local Dampen = 1 / (ItemConfig.Dropoff * Pierces)
		local isMob = Model and CollectionService:HasTag(Model, "Mob")

		if ItemConfig.CollisionFunction then
			task.spawn(ItemConfig.CollisionFunction, Projectile, Ended, RaycastResult.Position, RaycastResult.Instance, isMob)
		end

		if isMob and CanHit then
			local Enemy = isMob and Model:FindFirstChildOfClass("Humanoid")

			-- Multishot doesn't hit the same mob multiple times
			if table.find(Interacted, Model) then
				return
			end
			table.insert(Interacted, Model)
			task.delay(ItemConfig.Cooldown * 0.8, function()
				table.remove(Interacted, table.find(Interacted, Model))
			end)

			if Enemy and Enemy.Health > 0 then
				EventModule:FireServer("DamageEntity", Model, Dampen, ItemConfig.WeaponType)
			end
		end
	end)

	Casting:DefaultHookLengthChanged(Caster)
	Casting:DefaultHookRayTerminating(Caster)

	---- PROJECTILE CASTING --------------------------------------------------------
	-- Code here creates new projectiles, assigns them a 3d mesh part, and initially updates them.

	local function GetMouseHit(): Vector3
		local RaycastParams = RaycastParams.new()
		RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
		RaycastParams.FilterDescendantsInstances = {
			workspace:WaitForChild("Temporary"), workspace:WaitForChild("Characters"),
			workspace.Zones, workspace.Teleports
		}
		RaycastParams.RespectCanCollide = true

		local MouseLocation = UserInputService:GetMouseLocation()
		local ViewportRay = workspace.CurrentCamera:ViewportPointToRay(MouseLocation.X, MouseLocation.Y)
		local RaycastResult = workspace:Raycast(ViewportRay.Origin, ViewportRay.Direction * 1e3, RaycastParams)

		return RaycastResult and RaycastResult.Position or (ViewportRay.Origin + ViewportRay.Direction.Unit * 1e3)
	end

	local function CastProjectile()
		local Origin = CastPoint.WorldPosition
		local Direction = (GetMouseHit() - Origin).Unit -- Normalizes the vector length to 1 stud
		Direction = (CFrame.lookAt(Vector3.zero, Direction) * CFrame.fromOrientation(0, 0, Random:NextNumber(0, math.pi*2)):ToWorldSpace(CFrame.fromOrientation(math.rad(Random:NextNumber(ItemConfig.SpreadAngle.Min, ItemConfig.SpreadAngle.Max)), 0, 0))).LookVector -- Spread angle

		local Projectile = Caster:Cast(Player, Tool, Origin, Direction, Direction.Unit * ItemConfig.Velocity, ItemConfig.Acceleration, nil, ItemConfig.Pierce) -- This function creates the projectile on this client

		if Projectile then -- If the pool's quota for this Caster is maxed out, a Projectile object may not be returned. Just mentioning!
			Caster:Share(Origin, Direction, Direction.Unit * ItemConfig.Velocity, ItemConfig.Acceleration, ItemConfig.CastingMesh) -- This function shares this projectile with other clients to be created on their side

			local Cache = PartCache.new(ReplicatedStorage.Assets.Projectiles[ItemConfig.CastingMesh], nil, ProjectileCache)
			local CastingMesh = Cache:GetPart()

			Projectile.UserData.CastingMesh = CastingMesh
			Projectile:Update() -- Initially update the projectile after the trail is cleared, so it will appear for the first frame, and the trail will reset so it won't trail from far away to here
		end
	end

	--------------------------------------------------------------------------------
	
	local function RequestActivate()
		if ItemConfig.Autofire and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			if Tool:IsDescendantOf(workspace) then
				Tool:Activate()
			end
		end
	end
	
	Tool.Activated:Connect(function()
		if not Tool.Enabled or Humanoid.Health <= 0 then
			return
		end
		
		local TimeLeftDisabled = os.clock() - toolSystem.LastDisable 

		local Clock = os.clock()
		RequestSwing = Clock

		local IsDisabled = TimeLeftDisabled < 0
		if IsDisabled then
			task.delay(TimeLeftDisabled + 0.03, function()
				if Clock == RequestSwing then
					RequestActivate()
				end
			end)

			return
		end

		---- Activated
		
		toolSystem:Activated()
		
		EventModule:Fire("PlayerUsedWeapon", ItemConfig.Cooldown, Tool.Name)
		toolSystem.LastSwing = os.clock()

		for _ = 1, ItemConfig.Shoot do
			task.spawn(CastProjectile)
		end
		
		Tool.Enabled = false
		
		---- Callback
		
		task.delay(ItemConfig.Cooldown, function()
			Tool.Enabled = true
			RequestActivate()
		end)
	end)

	Tool.Equipped:Connect(function()
		toolSystem:Equipped()
	end)

	Tool.Unequipped:Connect(function()
		toolSystem:Unequipped()
	end)
end