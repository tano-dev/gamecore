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
local Modules = ReplicatedStorage.Modules

local MobFolder = workspace:WaitForChild("Mobs")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

local RbxUtility = require(Modules.Shared.RbxUtility)
local _Animation = require(Modules.Client.Animation)
local SFX = require(Modules.Shared.SFX)

local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)

local ToolSystem = require(ReplicatedStorage.Modules.Client.ToolSystem)
local CustomCAS = require(ReplicatedStorage.Modules.Client.CustomCAS)

local Tween = require(ReplicatedStorage.Modules.Shared.Tween)

--> Variables
local LastEquippedTool = 0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return function(Tool)
	local Handle = Tool:WaitForChild("Handle")
	local ItemConfig = require(Tool:WaitForChild("ItemConfig"))
	
	local toolSystem = ToolSystem.new(Tool, true)
	
	-- Variables
	local ActiveSlashTrack

	local CachedDebounce = {}
	local Callbacks = {}
	local Debounce = {}
	
	local Blocking = false
	local Equipped = false
	local OnDelay = false
	local CanHit = false
	
	local isDelayedSwing = ItemConfig.Cooldown >= 1 or ItemConfig.DelayedSwing
	
	local swingStart = (ItemConfig.DelayedSwing and math.clamp(ItemConfig.DelayedSwing[1], 0, ItemConfig.Cooldown))
		or 0
	
	local swingEnd = (ItemConfig.DelayedSwing and math.clamp(ItemConfig.DelayedSwing[2], swingStart, ItemConfig.Cooldown))
		or ItemConfig.Cooldown
		or 1
	
	local BlockLetGo = 0
	local BlockActivations = ItemConfig.BlockAndParry and {ItemConfig.BlockAndParry.Keybind}
	
	-- Character
	local Character = Player.Character or Player.CharacterAdded:Wait()
	
	local Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
	local Animator = Humanoid:WaitForChild("Animator") :: Animator

	---- DAMAGE ON TOUCH -----------------------------------------------------------
	-- Code here damages any mob which touches the handle, as long as it's within the cooldown period.

	local function AddDebounce(Mob: Model)
		table.insert(Debounce, Mob)
	end

	local function FindDebounce(Mob: Model)
		return table.find(Debounce, Mob)
	end

	local function OnTouched(HitPart: BasePart?, Delta: number?)
		local Model = HitPart.Parent
		
		local isLingeredHitbox = isDelayedSwing and (os.clock() - toolSystem.LastSwing > swingEnd) 
			or isDelayedSwing and (os.clock() - toolSystem.LastSwing < swingStart)
		
		if isLingeredHitbox
			or Blocking 
			or (os.clock() - BlockLetGo < 0.2) 
			or not Model
		then
			return
		end
		
		local isMob = CollectionService:HasTag(Model, "Mob")
		local isProp = CollectionService:HasTag(Model, "Prop")

		local Enemy = (isMob and Model:FindFirstChildOfClass("Humanoid")) 
			or isProp and Model

		if (not Tool.Enabled and not FindDebounce(Enemy)) and Enemy then
			local HasHitRecently = CachedDebounce[Enemy] and os.clock() - CachedDebounce[Enemy] < 0.1
			
			local IsDisabled = os.clock() - toolSystem.LastDisable < 0
			if IsDisabled or HasHitRecently then
				return
			end

			if (isMob and Enemy.Health > 0) or (isProp and not AttributeModule:GetAttribute(Model, "isDead")) then
				EventModule:FireServer("DamageEntity", Model, nil, ItemConfig.ToolType or ItemConfig.WeaponType)
			end

			if not isDelayedSwing then
				task.delay(ItemConfig.Cooldown, function()
					local Index = FindDebounce(Enemy)
					if Index then
						table.remove(Debounce, Index)
					end
				end)
			end

			CachedDebounce[Enemy] = os.clock()
			AddDebounce(Enemy)
		end
	end

	--------------------------------------------------------------------------------
	
	local UserInputTypes = {}
	for Name in Enum.UserInputType:GetEnumItems() do
		UserInputTypes[Name] = true
	end
	
	local function CheckIfCanBlock(Ignore)
		if not Tool:IsDescendantOf(workspace) or not ItemConfig.BlockAndParry then
			return
		end
		
		local IsBlocking = false
		for _, Input in BlockActivations do
			if UserInputTypes[Input.Name] and UserInputService:IsMouseButtonPressed(Input) or UserInputService:IsKeyDown(Input) then
				IsBlocking = true
			end
		end
		
		if IsBlocking then
			Callbacks.RequestStartBlock(Ignore)
		end
	end
	
	local function RequestActivate()
		if not ItemConfig.Autofire or not Tool:IsDescendantOf(workspace) then
			return
		end
				
		local IsAutofiring = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
		if IsAutofiring then
			Tool:Activate()
		else
			CheckIfCanBlock()
		end
	end
	
	local RequestSwing = os.clock()
	
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
		
		if Blocking or (os.clock() - BlockLetGo < 0.2) then
			return
		end
		
		---- Hit miscellaneous & activated
		
		toolSystem:Activated()
		
		local Clock = os.clock()
		toolSystem.LastSwing = Clock
		
		-- Hit delay
		if swingStart > 0 then
			task.delay(swingStart, function()
				if toolSystem.LastSwing == Clock then
					CanHit = true
				end
			end)
		else
			CanHit = true
		end
		
		task.delay(swingEnd, function()
			if toolSystem.LastSwing == Clock then
				CanHit = false
			end
		end)
		
		task.delay(swingStart, function()
			if toolSystem.LastSwing == Clock then
				toolSystem:RequestUpdateTrail(true)
			end
		end)
		
		-- Other
		table.clear(Debounce)
		
		EventModule:Fire("PlayerUsedWeapon", ItemConfig.Cooldown, Tool.Name)
		
		Tool.Enabled = false
		
		---- Callback
		
		task.delay(ItemConfig.Cooldown, function()
			CanHit = false
			Tool.Enabled = true
			
			RequestActivate()
		end)
		
		task.delay(swingEnd, toolSystem.RequestUpdateTrail, toolSystem, false)
	end)
	
	Tool.Equipped:Connect(function()
		toolSystem:Equipped()
		
		Equipped = true

		while Equipped do
			for _, Part in Handle:GetTouchingParts() do
				task.spawn(OnTouched, Part)
			end
			
			RunService.Heartbeat:Wait()
		end
	end)

	Tool.Unequipped:Connect(function()
		toolSystem:Unequipped()
		
		Equipped = false
		CanHit = false
	end)
	
	Handle.Touched:Connect(function()
		-- keep
	end)
	
	---- Parry connection
	-- btw i apologize if the code's messy, annoying having to account for the default kit animations & all exceptions
	
	if ItemConfig.BlockAndParry and not ItemConfig.ToolType then
		local BlockConnections = {}
		local CheckingParry = false
		
		local LastStoppedBlock = os.clock()
		local RequestHold = os.clock()
		local LastBlock = os.clock()
		
		local ParryAnimationTrack = nil :: AnimationTrack
		local ParryAnimations = nil :: {any}
		
		---- Animation handler
		
		-- Preferred w/ custom animations is an animation to go into both parrying & blocking, however, I can't use custom animations in a kit
		-- I recommend you to use those instead, I've supplied how to in this code
		local UsesKitSystem = not ItemConfig.BlockAndParry.Animation.Hold
		if UsesKitSystem then
			local Animation = Instance.new("Animation")
			Animation.AnimationId = _Animation:GetAnimationID(ItemConfig.BlockAndParry.Animation[1])

			ParryAnimationTrack = Animator:LoadAnimation(Animation)
		else
			ParryAnimations = {}
			for Name, Animation in ItemConfig.BlockAndParry.Animation do
				ParryAnimations[Name] = _Animation:LoadAnimations(Animation)
			end
		end
		
		-- Animation callbacks
		local function StopBlockAnimation(NoAdjust)
			if ParryAnimationTrack.IsPlaying then
				ParryAnimationTrack:Stop(0.15)
			end
			
			if not NoAdjust then
				ParryAnimationTrack:AdjustSpeed(1)
			end
		end
		
		local function PlayCustomAnimation(Name)
			toolSystem:StopAnimations({"Hold", "Block", "Parry", "LetGo"}, 0.35)
			if ParryAnimations[Name] then
				return toolSystem:PlayAnimation(Name, toolSystem:PickAnimation(Name, nil, ParryAnimations), 0.35)
			end
		end
		
		-- Main callbacks
		local function PlayBlockHold(Clock)
			if UsesKitSystem then
				StopBlockAnimation()

				local Clock = os.clock()
				LastBlock = Clock

				task.delay(ItemConfig.BlockAndParry.Animation[2], function()
					if Blocking and LastBlock == Clock then
						ParryAnimationTrack:AdjustSpeed(0)
					end
				end)

				ParryAnimationTrack.TimePosition = 0
				ParryAnimationTrack:Play()
			else
				PlayCustomAnimation("Hold")
			end
		end
		
		local function PlayMainParry()
			if UsesKitSystem then
				ParryAnimationTrack:AdjustSpeed(1)
				return ParryAnimationTrack
			else
				return PlayCustomAnimation("Parry")
			end
		end
		
		local function PlayMainBlock()
			if UsesKitSystem then
				StopBlockAnimation(true)
			else
				PlayCustomAnimation("Block")
			end
		end
		
		local function PlayBlockLetGo()
			if UsesKitSystem then
				StopBlockAnimation(true)
			else
				PlayCustomAnimation("LetGo")
			end
		end
		
		-- Connect w/ end block
		local function ConnectParried()
			local Track = PlayMainParry()
			CheckingParry = true

			Track.Ended:Once(function()
				CheckingParry = false
				LastStoppedBlock = os.clock()

				CheckIfCanBlock(true)
			end)

			toolSystem:RequestUpdateTrail(true)
			SFX:Play3D(GameConfig.ParrySFX[1], Tool.Handle, {Volume = GameConfig.ParrySFX[2]})
			
			task.delay(0.25, toolSystem.RequestUpdateTrail, toolSystem, false)
		end
		
		local function ConnectBlockedOrLetGo(Result)
			if Result == "Blocked" then
				PlayMainBlock()

				toolSystem.LastDisable = os.clock() + ItemConfig.BlockAndParry.DisableTime
				EventModule:Fire("PlayerUsedWeapon", ItemConfig.BlockAndParry.DisableTime, Tool.Name)

				SFX:Play3D(GameConfig.BlockSFX[1], Tool.Handle, {Volume = GameConfig.BlockSFX[2]})
				task.delay(ItemConfig.BlockAndParry.DisableTime, CheckIfCanBlock, true)
			else
				PlayBlockLetGo()
			end

			task.delay(0.25 - 0.01, CheckIfCanBlock, true)
			LastStoppedBlock = os.clock() + 0.25
		end
		
		---- Blocking logic itself - non-animation for the most part
		
		local function ConnectEndBlock(Result)
			BlockConnections = toolSystem:RequestDisconnectAll(BlockConnections)

			local IsDisabled = os.clock() - toolSystem.LastDisable < 0
			if IsDisabled or Humanoid.Health <= 0 then
				return
			end
			
			-- Check parried & blocked
			if Result == "Parried" then
				ConnectParried()
			else
				ConnectBlockedOrLetGo(Result)
			end
			
			AttributeModule:SetAttribute(Character, "Blocking", nil)
			Blocking = false
		end
		
		function Callbacks.RequestStartBlock(Ignore)
			if CheckingParry 
				or (not Ignore and os.clock() - LastStoppedBlock < 0) 
				or Humanoid.Health <= 0 
			then
				return
			end
			
			local TimeLeftDisabled = os.clock() - toolSystem.LastDisable 
			
			local Clock = os.clock()
			RequestHold = Clock

			local IsDisabled = TimeLeftDisabled < 0
			if IsDisabled then
				task.delay(TimeLeftDisabled + 0.03, function()
					if Clock == RequestHold then
						RequestActivate()
					end
				end)

				return
			end
			
			AttributeModule:SetAttribute(Character, "Blocking", true)
			Blocking = true

			PlayBlockHold()
			EventModule:FireServer("RequestBlock", Tool, true)
		end
		
		local function RequestBlockWithWeapon(Verdict, GPE)
			if Blocking and not Verdict then
				EventModule:FireServer("RequestBlock", Tool, false, true)
			elseif not Blocking and Verdict and not GPE then
				Callbacks.RequestStartBlock()
			end
		end
		
		local function Validation(Verdict, GPE)
			if Verdict and GPE then
				return false
			end
			
			return true
		end
		
		---- Connections
		-- These garbagecollect when the tool gets destroyed
		
		UserInputService.InputBegan:Connect(function(Input: InputObject, GameProcessedEvent: boolean)
			if GameProcessedEvent or Blocking then
				return
			end
			
			if os.clock() - toolSystem.LastSwing < ItemConfig.Cooldown then
				return
			end

			local IsInTable = table.find(BlockActivations, Input.UserInputType) 
				or table.find(BlockActivations, Input.KeyCode)

			local IsPressed = Tool:IsDescendantOf(workspace) and IsInTable
			if IsPressed then
				Callbacks.RequestStartBlock()
			end
		end)

		UserInputService.InputEnded:Connect(function(Input: InputObject, GameProcessedEvent: boolean)
			if not Blocking then
				return
			end

			local IsInTable = table.find(BlockActivations, Input.UserInputType) 
				or table.find(BlockActivations, Input.KeyCode)

			local IsPressed = Tool:IsDescendantOf(workspace) and IsInTable
			if IsPressed then
				local NearMobInstance = false
				
				for _, Mob in CollectionService:GetTagged("Mob") do
					if (Mob:GetPivot().Position - Character:GetPivot().Position).Magnitude <= 12 then
						NearMobInstance = true
						break
					end
				end
				
				EventModule:FireServer("RequestBlock", Tool, false, NearMobInstance)
			end
		end)
		
		AttributeModule:GetAttributeChanged(Tool, "BlockResult"):Connect(function()
			local Result = AttributeModule:GetAttribute(Tool, "BlockResult")
			if Result == nil then
				return
			end

			ConnectEndBlock(Result)
		end)

		Tool.Equipped:Connect(function()
			local isDesktop = (not UserInputService.TouchEnabled and not UserInputService.GamepadEnabled)
			CustomCAS:StartContextInput("WeaponBlock" .. Tool.Name, "Block", nil, true, BlockActivations[1], nil, nil, nil, 999, RequestBlockWithWeapon, Validation, nil, true, isDesktop)
		end)

		Tool.Unequipped:Connect(function()
			CustomCAS:StopContextInput("WeaponBlock" .. Tool.Name)
			
			EventModule:FireServer("RequestBlock", Tool, false, false)
			ConnectEndBlock()
		end)
	end
end

