--[[
	ej0w @ October 2024
	ToolSystem
	
	Handles animation & more for tools, general cleanliness.
]]

--> Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")

--> Player
local Player = Players.LocalPlayer

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)
local _Animation = require(ReplicatedStorage.Modules.Client.Animation)
local SFX = require(ReplicatedStorage.Modules.Shared.SFX)

--> Variables
local ToolSystem = {}
ToolSystem.__index = ToolSystem

local LastEquippedTool = 0

--> Configuration
local DEFAULT_VOLUME = 0.3

--------------------------------------------------------------------------------

function ToolSystem.new(Tool, canDisableWeaponSwitching, noToolNone)
	local Handle = Tool:WaitForChild("Handle")
	local ItemConfig = require(Tool:WaitForChild("ItemConfig"))
	
	-- Character
	local Character = Player.Character or Player.CharacterAdded:Wait()

	local Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
	local Head = Character:WaitForChild("Head")
	
	local Animator = Humanoid:WaitForChild("Animator") :: Animator
	
	-- Variables
	local WeaponSwitchingConnections = {}
	
	local Sequence = 0
	
	---- ToolSystem object ------------------------------------------------------------------------
	
	local self = setmetatable({}, ToolSystem)
	self.Tool = Tool
	self.Config = ItemConfig
	
	self.LastDisable = 0
	self.LastSwing = 0
	
	self.noToolNone = noToolNone
	self.canDisableWeaponSwitching = canDisableWeaponSwitching
	
	self.equipClock = os.clock()
	
	-- Trails
	local Trails = {}

	function self:RequestUpdateTrail(Verdict)
		if ItemConfig.IgnoreTrailScript then
			return
		end
		
		for _, Trail in Trails do
			local Value = if Verdict ~= nil 
				then Verdict 
				else not Trail.Enabled

			Trail.Enabled = Value
		end
	end
	
	if not ItemConfig.IgnoreTrailScript then
		for _, Trail in Tool:GetDescendants() do
			if Trail:IsA("Trail") then
				if Trail.Name == "Default" then
					Trail.Color = ColorSequence.new(Handle.Color)
				end

				table.insert(Trails, Trail)
			end
		end
	end

	-- Weapon switching
	if canDisableWeaponSwitching and GameConfig.DisableWeaponSwitching then
		WeaponSwitchingConnections[#WeaponSwitchingConnections + 1] = ContextActionService.LocalToolEquipped:Connect(function(_Tool)
			if _Tool == Tool then
				local LastEquippedTime = os.clock() - LastEquippedTool
				local LastDisabledTime = os.clock() - self.LastDisable

				if os.clock() - self.LastSwing < ItemConfig.Cooldown then
					return
				end

				if LastEquippedTime < 1 and LastDisabledTime > 0 then
					local FreezeTime = math.clamp(ItemConfig.Cooldown, 0.25, 1)
					self.LastDisable = os.clock() + FreezeTime
					
					EventModule:Fire("PlayerUsedWeapon", FreezeTime, Tool.Name)
				end
			end
		end)

		WeaponSwitchingConnections[#WeaponSwitchingConnections + 1] = ContextActionService.LocalToolUnequipped:Connect(function()
			LastEquippedTool = os.clock()
		end)
	end
	
	-- Equip/unequip connections (movement code mainly)
	local Connections = {}

	function self:RequestDisconnectAll(Connections)
		for _, Connection in Connections do
			Connection:Disconnect()
			Connection = nil
		end

		return {}
	end

	-- SFX
	local isUsingDefaultSFX = not ItemConfig.EquipSound and true
	
	local AttackSFX = ItemConfig.ActivateSound and (typeof(ItemConfig.ActivateSound) == "table" and ItemConfig.ActivateSound or {ItemConfig.ActivateSound, DEFAULT_VOLUME})
	local EquipSFX = ItemConfig.EquipSound and (typeof(ItemConfig.EquipSound) == "table" and ItemConfig.EquipSound or {ItemConfig.EquipSound, DEFAULT_VOLUME}) 
		or GameConfig.DefaultEquipSound
	
	local ActivateSound = ItemConfig.ActivateSound and SFX:CreateBaseSound(
		AttackSFX[1], 
		{Parent = Handle, RollOffMaxDistance = 100, Volume = AttackSFX[2]}
	)
	
	local EquipSound = SFX:CreateBaseSound(
		EquipSFX[1], 
		{Parent = Handle, RollOffMaxDistance = 100, Volume = EquipSFX[2]}
	) 
	
	-- Create animations
	local Animations = {}
	for Name, Table in (ItemConfig.Animations or {}) do
		Animations[Name] = _Animation:LoadAnimations(Table)
	end

	local PlayingAnimationTracks = {}
	
	function self:PlayAnimation(AnimationName, AnimationTrack, Fade)
		if not AnimationTrack then
			return
		end

		if PlayingAnimationTracks[AnimationName] then
			PlayingAnimationTracks[AnimationName]:Stop()
			PlayingAnimationTracks[AnimationName] = nil
		end

		PlayingAnimationTracks[AnimationName] = AnimationTrack
		AnimationTrack:Play(Fade)

		return AnimationTrack
	end

	function self:PickAnimation(AnimationName, Cycle, Table)
		local AnimationTable = (Table or Animations)[AnimationName]
		if not AnimationTable then return end

		local Character = Player.Character
		if not Character then return end

		local Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
		local Animator = Humanoid:WaitForChild("Animator") :: Animator

		local AnimationInstance = (Cycle and AnimationTable[Cycle]) 
			or AnimationTable[math.random(#AnimationTable)]
		
		local AnimationTrack = Animator:LoadAnimation(AnimationInstance)
		return AnimationTrack
	end

	function self:StopAnimations(Animations, Fade)
		for Name, Track in PlayingAnimationTracks do
			if table.find(Animations, Name) then
				Track:Stop(Fade)
				PlayingAnimationTracks[Name] = nil
			end
		end
	end
	
	-- Connections
	function self:Activated()
		self:StopAnimations{"Activate", "Equip", "Unequip"}

		-- Sequential attacks (& fire to server)
		if Animations and Animations.Activate then
			Sequence = (ItemConfig.Sequential and Sequence + 1) 
				or math.random(#Animations.Activate)

			if Sequence > #Animations.Activate then 
				Sequence = 1 
			end
			
			EventModule:Fire("ClientToClientCallback", Player, Tool.Name, "OnActivated", {Tool, Sequence})
			EventModule:FireServer("ClientToServerCallback", Tool.Name, "OnActivated", {Tool, Sequence})
		end

		local Animation = self:PickAnimation("Activate", Sequence)
		if Animation then
			self:PlayAnimation("Activate", Animation)
		end

		if ActivateSound then
			ActivateSound:Play() 
		end
	end
	
	local PlayingToolNoneAnimation = nil
	
	function self:Equipped()
		self.equipClock = os.clock()
		
		if noToolNone then
			task.defer(function()
				PlayingToolNoneAnimation = nil
				repeat
					for _, Animation in Animator:GetPlayingAnimationTracks() do
						if Animation.Name == "ToolNoneAnim" then
							PlayingToolNoneAnimation = Animation
						end
					end
					if not PlayingToolNoneAnimation then
						task.wait()
					end
				until PlayingToolNoneAnimation or not Tool:IsDescendantOf(workspace)

				if not Tool:IsDescendantOf(workspace) then
					return
				end

				PlayingToolNoneAnimation:AdjustSpeed(0)
				PlayingToolNoneAnimation:Stop()
			end)
		end
		
		self:StopAnimations{"Unequip"}

		local EquipAnimation = self:PickAnimation("Equip")
		self:PlayAnimation("Equip", EquipAnimation)

		local CurrentMovement = nil
		local JumpAnimation = nil :: AnimationTrack

		local function OnMoveDirectionChanged(Fade)
			local MoveDirection = Humanoid.MoveDirection
			local OldMovement = CurrentMovement

			local IsIdle = MoveDirection.Magnitude < 0.1
			CurrentMovement = IsIdle and "Idle" or "Walk"

			if CurrentMovement ~= OldMovement and not (JumpAnimation and JumpAnimation.IsPlaying) then
				self:StopAnimations({OldMovement}, Fade or 0.25)
				self:PlayAnimation(CurrentMovement, self:PickAnimation(CurrentMovement), Fade or 0.25)
			end
		end

		local function OnStateChanged(OldState, NewState)
			if NewState == Enum.HumanoidStateType.Freefall then
				local Clock = self.equipClock 
				
				task.delay(0.25, function()
					if Tool:IsDescendantOf(workspace) and Clock == self.equipClock then
						self:PlayAnimation("Fall", self:PickAnimation("Fall"), 0.25)
						self:StopAnimations({"Walk", "Idle"}, 0.0)
					end
				end)
			elseif NewState == Enum.HumanoidStateType.Jumping then
				self:StopAnimations({"Walk", "Idle"}, 0.25)
				JumpAnimation = self:PlayAnimation("Jump", self:PickAnimation("Jump"), 0.25)
			elseif NewState == Enum.HumanoidStateType.Landed then
				CurrentMovement = nil
				JumpAnimation = nil
				self:StopAnimations({"Fall", "Jump"}, 0.3)
				OnMoveDirectionChanged(0.25)
			end
		end

		Connections[#Connections + 1] = Humanoid.StateChanged:Connect(OnStateChanged)
		Connections[#Connections + 1] = Humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(OnMoveDirectionChanged)
		OnMoveDirectionChanged()

		if EquipSound then
			EquipSound:Play()
		end
	end
	
	function self:Unequipped()
		self:RequestUpdateTrail(false)
		
		if noToolNone then
			task.defer(function()
				if Character:FindFirstChildWhichIsA("Tool") and PlayingToolNoneAnimation then
					PlayingToolNoneAnimation:AdjustSpeed(1)
					PlayingToolNoneAnimation:Play()
				end
			end)
		end

		local UnequipAnimation = self:PickAnimation("Unequip")
		self:PlayAnimation("Unequip", UnequipAnimation)

		self:StopAnimations{"Activate", "Walk", "Idle", "Equip", "Jump", "Fall"}
		Connections = self:RequestDisconnectAll(Connections)

		if EquipSound and EquipSound.IsPlaying then
			EquipSound:Stop()
		end
	end
	
	Tool.AncestryChanged:Connect(function(Child, Parent)
		if Parent == nil then
			for _, Connection in WeaponSwitchingConnections do
				Connection:Disconnect()
			end
			self:RequestDisconnectAll(Connections)
		end
	end)
	
	return self
end

return ToolSystem