--[[
	Evercyan @ March 2023
	MobClient
	
	Unlike MobLib which handles server-sided code, and most of it in general, we run
	some code on the client for things such as custom health overlays & overwriting humanoid state types.
	
	If you want to edit mob code to add new behavior or edit existing behavior, you likely want to refer
	to the server-sided code under ServerStorage.
]]

--> Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer

--> Dependencies
local SFX = require(ReplicatedStorage.Modules.Shared.SFX)
local Maid = require(ReplicatedStorage.Modules.Shared.Maid)
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)
local Format = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local RbxUtility = require(ReplicatedStorage.Modules.Shared.RbxUtility)
local Brightness = require(ReplicatedStorage.Modules.Shared.Brightness)
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)

local HitCycleFunctions = require(ReplicatedStorage.Modules.Entity.hitCycleFunctions)
local AttackFunctions = require(ReplicatedStorage.Modules.Entity.attackFunctions)

local SafeWait = require(ReplicatedStorage.Modules.Client.safeWait)

local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local Mobs = {}

local MobRankColors = GameConfig.MobRankColors

local LastHit = os.clock()

--> Configurations
local MOB_RENDER_DISTANCE = GameConfig.MobRenderDistance
local STOP_ANIMS_ON_STUN = false
local HEALTH_CHANGE_STOP = 2

--------------------------------------------------------------------------------

-- Turn an animation table / configurable animation (string & number) into a chosen "rbxassetid://xxx" string.
local function GetAnimationID(ConfigAnimation)
	if ConfigAnimation == nil then
		return
	end
	
	local isTable = typeof(ConfigAnimation) == "table"
	local ChosenID = isTable and ConfigAnimation[math.random(#ConfigAnimation)] 
		or ConfigAnimation
	
	if tonumber(ChosenID) then
		ChosenID = `rbxassetid://{ChosenID}`
	end
	
	return tostring(ChosenID)
end

-- Creates an "AnimationTrack" instance which is stored on the client for playing
local function LoadAnimationTrack(MobInstance: Model, Name: string, Priority: string) : AnimationTrack?
	local Enemy = MobInstance:FindFirstChild("Enemy") :: Humanoid
	local Animator = Enemy and Enemy:FindFirstChild("Animator") :: Animator
	local MobConfig = MobInstance:FindFirstChild("MobConfig") and require(MobInstance:FindFirstChild("MobConfig"))
	if not Animator or not MobConfig then return nil end
	
	local AnimationTableOrTrack = nil
	local AnimationTrack = nil
	
	local CustomAnimation = MobConfig.CustomAnimations[Name]
	
	local Animation
	if CustomAnimation then
		local isTable = typeof(CustomAnimation) == "table"
		if isTable then
			AnimationTableOrTrack = {}
			
			for _, ID in CustomAnimation do
				local NewAnimation = Instance.new("Animation")
				NewAnimation.AnimationId = GetAnimationID(ID)
				AnimationTableOrTrack[ID] = NewAnimation
			end
		elseif not isTable then
			AnimationTableOrTrack = Instance.new("Animation")
			AnimationTableOrTrack.AnimationId = GetAnimationID(CustomAnimation)
		end
	else
		AnimationTableOrTrack = script.DefaultAnimations:FindFirstChild(Name)
	end
	
	if not AnimationTableOrTrack then
		return
	end
	
	local isTable = typeof(AnimationTableOrTrack) == "table"
	if isTable then
		local AnimationTable = {}
		
		for ID, Track in AnimationTableOrTrack do
			local NewAnimationTrack = Animator:LoadAnimation(Track)
			NewAnimationTrack.Priority = Enum.AnimationPriority[Priority or "Core"]
			AnimationTable[ID] = NewAnimationTrack
		end
		
		AnimationTrack = AnimationTable
	elseif not isTable then
		AnimationTrack = Animator:LoadAnimation(AnimationTableOrTrack)
		AnimationTrack.Priority = Enum.AnimationPriority[Priority or "Core"]
	end
	
	return AnimationTrack
end

-- Creates and returns the overhead gui instance for mobs
local function SetupOverheadGui(MobInstance: Model, Root: BasePart, MobConfig): BillboardGui
	local OverrideGui = MobInstance:FindFirstChild("BillboardGui")
	if OverrideGui then
		return OverrideGui
	end
		
	local Gui = script:WaitForChild("BillboardGui"):Clone()
	
	local MobName = `<b>{MobConfig.Name}</b>`
	if MobConfig.Level and (GameConfig.MobShowsLevelIfOne or MobConfig.Level[1] > 1) then
		MobName ..= ` <font size='16' color="rgb(245,245,245)">[{Format(MobConfig.Level[1], "Suffix")}]</font>`
	end
	
	local HealthCanvas = Gui.Canvas.Center.HealthBar
	local SideCanvas = Gui.Canvas.Center.SideInfo
	
	HealthCanvas.MobName.Text = MobName

	if MobConfig.Rank then
		local RankPrefix = MobConfig.Rank and `<b>{MobConfig.Rank}</b>`
		HealthCanvas.MobRank.Text = RankPrefix
		HealthCanvas.MobRank.Visible = true
		
		if MobConfig.Rank then
			HealthCanvas.MobRank.TextColor3 = MobRankColors[MobConfig.Rank] or Color3.new(1, 1, 1)
			HealthCanvas.MobRank.TextTransparency = 0
		end
	else
		HealthCanvas.MobRank.Visible = false
	end
	
	if MobConfig.Defense and MobConfig.Defense[1] and MobConfig.Defense[1] > 0 then
		local DefenseAddon = MobConfig.Defense[2] and "+" or ""
		local DefensePercentage = math.round(math.clamp(MobConfig.Defense[1] * 100, 0, 100) * 10) / 10

		local DefensePrexix = `<font transparency="0.2" size="14">{DefenseAddon}{(MobConfig.Defense[2] and Format(MobConfig.Defense[1], "Suffix")) or DefensePercentage .. "%"}</font>`
		SideCanvas.Defense.Display.Text = DefensePrexix
		SideCanvas.Defense:SetAttribute("Visible", true)
		
		if not GameConfig.HideMobHUDIfHeal then
			SideCanvas.Defense.Visible = true
		end
	end
	
	local TotalVisibleItems = 0
	for _, Frame in SideCanvas:GetChildren() do
		if Frame:IsA("GuiObject") and (Frame.Visible or Frame:GetAttribute("Visible")) then
			TotalVisibleItems += 1
		end
	end
	
	local isSideCanvasVisible = TotalVisibleItems > 0
	if isSideCanvasVisible and GameConfig.ScaleMobBarUI then
		HealthCanvas.HealthBar.Size = UDim2.fromOffset(HealthCanvas.HealthBar.Size.X.Offset / 1.25, HealthCanvas.HealthBar.Size.Y.Offset)
	end
	
	SideCanvas.Visible = isSideCanvasVisible
	SideCanvas:SetAttribute("Visible", isSideCanvasVisible)
	
	Gui.Canvas.GroupTransparency = 1
	
	task.spawn(function()
		SafeWait(MobInstance, "Hitbox")
		
		local CoordinateFrame: CFrame, Size: Vector3 = MobInstance:GetBoundingBox()
		Gui.Adornee = Root
		Gui.Enabled = true
		
		Gui.StudsOffsetWorldSpace = Vector3.new(0, (CoordinateFrame.Position.Y+Size.Y/2) - Root.Position.Y, 0)
		Tween:Play(Gui.Canvas, {0.25, "Circular"}, {GroupTransparency = 0})
	end)
	
	if GameConfig.ScaleMobBarUI then
		task.defer(function()
			Gui.Canvas.Center.Size = UDim2.fromOffset(HealthCanvas.AbsoluteSize.X, 0)
		end)
	end
	
	return Gui
end

local function PerMob(MobInstance: Model)
	if Mobs[MobInstance] then return end
	
	local Enemy = SafeWait(MobInstance, "Enemy") :: Humanoid
	local Root = SafeWait(MobInstance, "HumanoidRootPart") :: BasePart
	local MobConfig = SafeWait(MobInstance, "MobConfig") and require(MobInstance:FindFirstChild("MobConfig"))
	if not Enemy or not Root or not MobConfig then return end
	
	local Maid = Maid.new()
	
	-- Set humanoid states (helps prevent falling down & useless calculations - you're unlikely to have an enemy climbing without pathfinding)
	for _, EnumName in {"FallingDown", "Seated", "Flying", "Swimming"} do
		local HumanoidStateType = Enum.HumanoidStateType[EnumName]
		Enemy:SetStateEnabled(HumanoidStateType, false)
		if Enemy:GetState() == HumanoidStateType then
			Enemy:ChangeState(Enum.HumanoidStateType.Running)
		end
	end
	
	local Mob = {}
	Mob.Name = MobConfig.Name
	Mob.Instance = MobInstance
	Mob.Root = Root
	Mob.Enemy = Enemy
	
	Mob.Config = MobConfig
	Mob.BossData = MobConfig.BossData
	
	-- Animations / Behavior ---------------------------------------------------
	
	local Animator = Enemy:WaitForChild("Animator")
	local WalkSpeed = Enemy:WaitForChild("WalkSpeed")
	
	local AnimationTracks = {
		Idle = LoadAnimationTrack(MobInstance, "Idle", "Idle"),
		
		Running = LoadAnimationTrack(MobInstance, "Running", "Core"),
		Walking = MobConfig.Walking and LoadAnimationTrack(MobInstance, "Walking", "Core"),
		
		Jumping = LoadAnimationTrack(MobInstance, "Jumping", "Movement"),
		Stun = LoadAnimationTrack(MobInstance, "Stun", "Action"),
	}
	
	---- Animation callbacks
	
	local function RequestPlayIdle()
		local Character = Player.Character
		local CharRoot = Character and Character:FindFirstChild("HumanoidRootPart")
		
		if AnimationTracks.Idle and not AnimationTracks.Idle.IsPlaying then
			local Magnitude = CharRoot and (Root.Position - CharRoot.Position).Magnitude
			if Magnitude and Magnitude < MOB_RENDER_DISTANCE then
				AnimationTracks.Idle:Play()
			end
			
			Mob.IdleShouldBePlaying = true
		end
	end
	
	local function RequestStopIdle()
		AnimationTracks.Idle:Stop()
		
		Mob.IdleShouldBePlaying = false
	end
	
	local PreviousSpeed = nil
	
	local function RequestPlayMoving(Speed)
		local Percent = Speed and (Speed / Enemy.WalkSpeed) or 1
		if Speed then
			PreviousSpeed = Speed
		end
		
		local RequestedAnimation = nil
		
		local isWalking = WalkSpeed:GetAttribute("Wandering") or WalkSpeed:GetAttribute("GoingBack")
		RequestedAnimation = isWalking and "Walking" or "Running"
		
		local OppositeAnimation = (RequestedAnimation == "Running" and "Walking")
			or "Running"
		
		local wasPlaying = false
		
		local OppositeTrack = AnimationTracks[OppositeAnimation]
		if OppositeTrack and OppositeTrack.IsPlaying then
			OppositeTrack:Stop(0.25)
			
			wasPlaying = true
		end
		
		local RequestedTrack = AnimationTracks[RequestedAnimation] or AnimationTracks.Running
		if not RequestedTrack.IsPlaying then
			RequestedTrack:Play(OppositeTrack and 0.25)
		end

		RequestedTrack:AdjustSpeed(Percent)
	end
	
	local function RequestStopMoving()
		if AnimationTracks.Walking then
			AnimationTracks.Walking:Stop()
		end
		
		AnimationTracks.Running:Stop()
	end
	
	---- Initialize animations
	
	if MobConfig.Projectile then
		AnimationTracks.ToolNone = LoadAnimationTrack(MobInstance, "ToolNone", "Action")
		AnimationTracks.ToolNone:Play()
		
		AnimationTracks.Fire = LoadAnimationTrack(MobInstance, "Fire", "Action2")
	end
	
	WalkSpeed.AttributeChanged:Connect(function()
		RequestPlayMoving(PreviousSpeed)
	end)
	
	Maid:Add(Enemy.Running:Connect(function(Speed)
		local isCurrentlyRunning = Speed > 0.01
		if isCurrentlyRunning then
			RequestPlayMoving(Speed)
			RequestStopIdle()
		elseif not isCurrentlyRunning then
			RequestStopMoving()
			RequestPlayIdle()
		end
	end))
	
	Maid:Add(Enemy.Jumping:Connect(function()
		AnimationTracks.Jumping.TimePosition = 0
		
		if not AnimationTracks.Jumping.IsPlaying then
			AnimationTracks.Jumping:Play()
			
			RequestStopIdle()
		end
	end))
	
	Maid:Add(Root:GetPropertyChangedSignal("Anchored"):Connect(function()
		if Root.Anchored then
			for Name, Animation in AnimationTracks do
				if Name == "Idle" or Name == "ToolNone" then
					continue
				end
				
				local isTable = typeof(Animation) == "table" 
				if isTable then
					for _, Track in Animation do
						Track:Stop()
					end
				elseif not isTable then
					Animation:Stop()
				end
			end
			
			RequestPlayIdle()
		end
	end))
	
	-- Stunned animation handling
	Maid:Add(AttributeModule:GetAttributeChanged(MobInstance, "Stunned"):Connect(function()
		local StunAnimation = (typeof(AnimationTracks.Stun) == "table" and AnimationTracks.Stun[math.random(#AnimationTracks.Stun)])
			or AnimationTracks.Stun
		
		local isStunned = AttributeModule:GetAttribute(MobInstance, "Stunned")
		if isStunned then
			for TrackName, AnimationTrack: AnimationTrack in AnimationTracks do
				if string.find(TrackName, "Telegraph") and (STOP_ANIMS_ON_STUN or AnimationTrack.Length > 1.5) then
					AnimationTrack:Stop()
				end
			end
			
			if StunAnimation then
				StunAnimation:Play()
			end
		elseif not isStunned then
			if typeof(AnimationTracks.Stun) == "table" then
				for _, Animation in AnimationTracks.Stun do
					Animation:Stop()
				end
			elseif StunAnimation then
				StunAnimation:Stop()
			end
		end
	end))
	
	-- Attack animation handling
	local function RequestLoadAttack(Attack)
		local AnimationID = Attack.TelegraphAnimation
		if not AnimationID or AnimationTracks["Telegraph" .. AnimationID[1]] then
			return
		end

		local Animation = Instance.new("Animation")
		Animation.AnimationId = GetAnimationID(AnimationID[1])

		AnimationTracks["Telegraph" .. AnimationID[1]] = Animator:LoadAnimation(Animation)
	end
	
	if MobConfig.AttackCycle then
		local AttackCycle = AttackFunctions:GetAttackCycle(Mob)

		for _, Sequence in AttackCycle do
			for _, Attack in Sequence do 
				RequestLoadAttack(Attack)
			end
		end
	end
	
	if MobConfig.HitCycle then
		local HitCycle = HitCycleFunctions:GetHitCycle(Mob)
		
		for _, Attack in HitCycle do 
			RequestLoadAttack(Attack)
		end
	end
	
	-- Chase delay animation handling
	if MobConfig.ChaseDelay and MobConfig.ChaseDelay[2] then
		local Animation = Instance.new("Animation")
		Animation.AnimationId = GetAnimationID(MobConfig.ChaseDelay[2])
		
		local ChaseTrack = Animator:LoadAnimation(Animation)
		AnimationTracks.ChaseDelay = ChaseTrack
		
		local PreviousTarget = nil
		local ChosenTargetID = os.clock()
		
		AttributeModule:GetAttributeChanged(MobInstance, "Target"):Connect(function()
			local NewTarget = AttributeModule:GetAttribute(MobInstance, "Target")
			if PreviousTarget == nil and NewTarget ~= nil then
				if AnimationTracks.Idle.IsPlaying then
					AnimationTracks.Idle:Stop()
				end
				
				local Clock = os.clock()
				ChosenTargetID = Clock
				
				if AnimationTracks.ChaseDelay.IsPlaying then
					AnimationTracks.ChaseDelay:Stop()
				end
				
				AnimationTracks.ChaseDelay:Play()
				AnimationTracks.ChaseDelay.Ended:Wait()
				
				if ChosenTargetID == Clock and Mob.IdleShouldBePlaying and not AnimationTracks.Idle.IsPlaying then
					RequestPlayIdle()
				end
			end

			PreviousTarget = NewTarget
		end)
	end
	
	-- Respawn animation handling
	local isRespawnDelay = MobConfig.RespawnDelay and MobConfig.RespawnDelay[2] 
	if isRespawnDelay then
		local Animation = Instance.new("Animation")
		Animation.AnimationId = GetAnimationID(MobConfig.RespawnDelay[2])
		
		local RespawnTrack = Animator:LoadAnimation(Animation)
		AnimationTracks.RespawnDelay = RespawnTrack
		
		RespawnTrack:Play()
		RespawnTrack.Ended:Once(RequestPlayIdle)
	elseif not isRespawnDelay then
		RequestPlayIdle()
	end
	
	-- Mob's Overhead GUI ------------------------------------------------------
	
	local Gui = SetupOverheadGui(MobInstance, Root, MobConfig)
	Gui.Parent = MobInstance
	
	local HealthCanvas = Gui.Canvas.Center.HealthBar
	local SideCanvas = Gui.Canvas.Center.SideInfo
	
	local Fill = HealthCanvas.HealthBar.Fill
	local Meter = HealthCanvas.HealthBar.Meter
	
	local PreviousHealth = MobConfig.Health
	local CurrentTime = os.clock()
	
	local function UpdateFill()
		local Percent = math.clamp(Enemy.Health/Enemy.MaxHealth, 0, 1)
		Tween:Play(Fill, {0.5, "Circular"}, {Size = UDim2.new(Percent, 0, 1, 0)})
		
		local Health = math.floor(Enemy.Health * 10) / 10
		local MaxHealth = math.floor(Enemy.MaxHealth * 10) / 10
		HealthCanvas.HealthBar.Display.Text = `{Format(Health, "Suffix")} / {Format(MaxHealth, "Suffix")}`
		
		-- Meter frame (damage residual)
		local Alpha = Enemy.Health / Enemy.MaxHealth
		if Enemy.Health > PreviousHealth then
			Meter.Size = UDim2.fromScale(Alpha, 1)
		else
			local Clock = os.clock()
			CurrentTime = Clock

			task.delay(HEALTH_CHANGE_STOP, function()
				if CurrentTime == Clock then
					local NewAlpha = Enemy.Health / Enemy.MaxHealth
					Tween:Play(Meter, {0.5, "Circular"}, {Size = UDim2.fromScale(Alpha, 1)})
				end
			end)
		end
		
		-- Hide/show mob UI
		if GameConfig.HideMobHUDIfHeal then
			local IsFullyHealed = Enemy.Health == Enemy.MaxHealth
			if IsFullyHealed then
				HealthCanvas.HealthBar.GroupTransparency = 1
			else
				Tween:Play(HealthCanvas.HealthBar, {0.5, "Circular"}, {GroupTransparency = 0})
			end
			
			if SideCanvas.Defense:GetAttribute("Visible") then
				SideCanvas.Defense.Visible = not IsFullyHealed
			end

			HealthCanvas.UIListLayout.Padding = (not IsFullyHealed and UDim.new(0, 5)) or UDim.new(0, 3)
			HealthCanvas.HealthBar.Visible = not IsFullyHealed
			
			if GameConfig.ScaleMobBarUI then
				task.defer(function()
					Gui.Canvas.Center.Size = UDim2.fromOffset(HealthCanvas.AbsoluteSize.X, 0)
				end)
			end
		end
		
		-- Health bar color
		local Alpha = Health / MaxHealth
		local Goal = MobConfig.HealthBarColor
			or (Alpha > 0.66 and GameConfig.PercentageColors.High)
			or (Alpha > 0.33 and GameConfig.PercentageColors.Medium) 
			or GameConfig.PercentageColors.Low
		
		Tween:Play(Fill, {0.5, "Circular"}, {BackgroundColor3 = Goal})
		Tween:Play(Meter, {0.5, "Circular"}, {BackgroundColor3 = Goal})
		
		PreviousHealth = Enemy.Health
	end
	
	HealthCanvas.HealthBar.Fill.Size = UDim2.new(0, 0, 1, 0)
	
	AttributeModule:GetAttributeChanged(MobInstance, "HasBeenHit"):Connect(UpdateFill)
	Enemy.HealthChanged:Connect(UpdateFill)
	
	UpdateFill()
	
	-- Textlabel color
	local Head = MobInstance:WaitForChild("Head")
	local Torso = MobInstance:WaitForChild("Torso")
	
	local Color = MobConfig.Color or Brightness:AdjustColor(Head.Color, Torso.Color)
	HealthCanvas.MobName.TextColor3 = Color
	
	-- Enemy died
	Maid:Add(Enemy.Died:Once(function()
		if MobConfig.RespawnTime > 0.35 then
			task.delay(MobConfig.RespawnTime - 0.35, function()
				for _, Part in MobInstance:GetDescendants() do
					if Part:IsA("BasePart") then
						Tween:Play(Part, {0.25}, {Transparency = 1})
						Part.CastShadow = false
					elseif Part:IsA("Decal") then
						Part:Destroy()
					end
				end
			end)
		end
		
		Tween:Play(Gui.Canvas, {0.5, "Circular"}, {GroupTransparency = 1})
	end))
	
	Mob.AnimationTracks = AnimationTracks
	Mobs[MobInstance] = Mob
	
	Maid:Add(MobInstance.Destroying:Connect(function()
		Mobs[MobInstance] = nil
		Maid:Destroy()
	end))
end

---- Setup connections

CollectionService:GetInstanceAddedSignal("Mob"):Connect(PerMob)
for _, MobInstance in CollectionService:GetTagged("Mob") do
	task.spawn(PerMob, MobInstance)
end

---- Animation & mob damage

local function LoadAnimation(Mob, AnimationID)
	if typeof(Mob) == "Instance" then
		Mob = Mobs[Mob]
	end

	local Character = Player.Character

	-- Magnitude checks
	local Torso = Character and Character:FindFirstChild("Torso")
	if not Torso then 
		return 
	end

	local Position = Mob.Instance.Torso.Position
	if (Position - Torso.Position).Magnitude > MOB_RENDER_DISTANCE then
		return
	end

	-- Load & play animation ------------------------------------------------------
	
	local Animator = Mob.Enemy:WaitForChild("Animator") :: Animator
	
	Mob.ForcedAnimations = (Mob.ForcedAnimations or {})
	
	local AnimationTrack = Mob.ForcedAnimations[AnimationID]
	if not AnimationTrack then
		local Animation = Instance.new("Animation")
		Animation.AnimationId = GetAnimationID(AnimationID)

		AnimationTrack = Animator:LoadAnimation(Animation)
		AnimationTrack.Priority = Enum.AnimationPriority.Action2
		
		Mob.ForcedAnimations[AnimationID] = AnimationTrack
	end
	
	AnimationTrack:Play()
end

local function PlayPrefabAnimation(Mob, Animation, AnimationID, FreezeFrame, TimeFrozen, ShowTrail)
	if typeof(Mob) == "Instance" then
		Mob = Mobs[Mob]
	end
	
	if not Mob then
		return
	end
	
	local Character = Player.Character
	
	-- Magnitude checks
	local Torso = Character and Character:FindFirstChild("Torso")
	if not Torso then 
		return 
	end
	
	local Position = Mob.Instance.Torso.Position
	if (Position - Torso.Position).Magnitude > MOB_RENDER_DISTANCE then
		return
	end
	
	-- Tool trails ------------------------------------------------------
	
	local Tool = Mob.Instance:FindFirstChildWhichIsA("Tool")
	local Trail = Tool and Tool.Handle:FindFirstChildWhichIsA("Trail")
	
	local function EnableTrail(Verdict)
		if ShowTrail and Trail then
			if Trail.Name == "Default" then
				Trail.Color = ColorSequence.new(Tool.Handle.Color)
			end
			
			Trail.Enabled = Verdict
		end
	end
	
	EnableTrail(false)

	local AnimationTrack = Mob.AnimationTracks[Animation]
	local isTable = typeof(AnimationTrack) == "table"
	
	local Chosen = nil :: AnimationTrack
	
	-- Animation handling ------------------------------------------------------
	
	if isTable then
		for _, Track in AnimationTrack do
			Track:Stop()
		end
		
		local IsGeneralAnimation = (not AnimationID or not AnimationTrack[AnimationID])
		if IsGeneralAnimation then
			local AssortedAnimations = {}
			for _, Animation in AnimationTrack do
				table.insert(AssortedAnimations, Animation)
			end

			Chosen = AssortedAnimations[math.random(#AssortedAnimations)]
		elseif not IsGeneralAnimation then
			Chosen = AnimationTrack[AnimationID]
		end
	elseif not isTable then
		Chosen = AnimationTrack
	end
	
	-- Freeze for specified time
	Chosen.TimePosition = 0
	if Chosen.IsPlaying then
		Chosen:Stop()
	end
	
	Chosen:AdjustSpeed(1)
	Chosen:Play()
	
	-- Freezeframe & frozen time ------------------------------------------------------

	if not FreezeFrame or not TimeFrozen then
		return
	end
	
	task.delay(FreezeFrame, function()
		Chosen:AdjustSpeed(0)
		
		task.wait(TimeFrozen)
		
		EnableTrail(true)
		Chosen:AdjustSpeed(1)
		
		Chosen.Ended:Once(function()
			EnableTrail(false)
		end)
	end)
end

local function ActivateMobDamage(CanHighlight: boolean, didNotInteract)
	local Character = Player.Character
	if CanHighlight and Character then
		local isOffCooldown = os.clock() - LastHit > 0.15
		if GameConfig.PlayerHurtSFX and isOffCooldown then
			SFX:Play2D(GameConfig.PlayerHurtSFX[1], {Volume = GameConfig.PlayerHurtSFX[2]})
			
			LastHit = os.clock()
		end
		RbxUtility.CreateHighlight(Character, 0.75, nil, (not didNotInteract) and 0.725)
	end
end

EventModule:GetOnClientEvent("ForceAnimateMob"):Connect(LoadAnimation)
EventModule:GetOnClientEvent("RequestAnimateMob"):Connect(PlayPrefabAnimation)
EventModule:GetOnClientEvent("MobDamagedPlayer"):Connect(ActivateMobDamage)
EventModule:GetOnEvent("PlayerRequestHit"):Connect(ActivateMobDamage)

---- Render mobs for idle play & boss HUDs

local function CycleThroughMob(CharRoot, Mob)
	local MobInstance = Mob.Instance
	local Enemy = MobInstance:FindFirstChildWhichIsA("Humanoid")
	
	local Magnitude = Mob.Root and (Mob.Root.Position - CharRoot.Position).Magnitude
	if Enemy.Health > 0 and Magnitude < MOB_RENDER_DISTANCE then
		if Mob.IdleShouldBePlaying then
			local IdleTrack = Mob.AnimationTracks.Idle
			if IdleTrack and not IdleTrack.IsPlaying then
				IdleTrack:Play()
			end
		end
	end
	
	local BossData = Mob.BossData 
	local BossDistance = BossData and BossData.Distance or GameConfig.DefaultDistanceRadius
	
	if BossData and (BossData.Type ~= nil and BossData.Type ~= "None") then
		if BossData.Type == "AtDistance" and Magnitude < BossDistance and Enemy.Health > 0 then
			EventModule:Fire("RequestBossHUD", true, Mob.Instance)
		elseif Magnitude > BossDistance + 10 or Enemy.Health <= 0 then
			EventModule:Fire("RequestBossHUD", false, Mob.Instance)
		end
	end
end

task.defer(function()
	while true do
		local Character = Player.Character
		
		local CharRoot = Character and Character:FindFirstChild("HumanoidRootPart") :: BasePart
		local Humanoid = Character and Character:FindFirstChild("Humanoid") :: Humanoid
		
		if CharRoot and Humanoid and Humanoid.Health > 0 then --and (CharRoot and CharRoot.Position ~= LastPosition) then
			for _, Mob in Mobs do
				CycleThroughMob(CharRoot, Mob)
			end
		end
		
		task.wait(GameConfig.DefaultClientRefresh)
	end
end)

return {}