--[[
	ej0w @ October 2024
	PlayerDamagedEntity
	
	Handles mob damaging interpereted to the client, ran through the server to here.
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer

--> References
local _Assets = ReplicatedStorage.Assets
local PropEffects = _Assets.Effects.Props

--> Dependencies
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local RbxUtility = require(ReplicatedStorage.Modules.Shared.RbxUtility)
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)
local Maid = require(ReplicatedStorage.Modules.Shared.Maid)
local SFX = require(ReplicatedStorage.Modules.Shared.SFX)

local PropClientList = require(ReplicatedStorage.Context.Client.entityCode.PropClient.PropClientList)
local MobDisplay = require(ReplicatedStorage.Modules.Client.MobDisplay)
local TweenModel = require(ReplicatedStorage.Modules.Client.tweenModel)

local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local Remotes = {}

local Random = Random.new()

local LastHit = os.clock()
local LastNotification = os.clock()

local Counters = {}

--> Configuration
local CRITICAL_APPEND = "!!"

--------------------------------------------------------------------------------

local function CreateDamageCounter(Position, Damage, Entity, Config, Crit)
	local Enemy = Entity:FindFirstChild("Enemy") :: Humanoid
	local Alpha = if typeof(Damage) == "string" then 0 else (Enemy and Enemy.Health / Enemy.MaxHealth) 
		or AttributeModule:GetAttribute(Entity, "Health") / AttributeModule:GetAttribute(Entity, "MaxHealth")
	
	local MarkerID = if Enemy then "rbxassetid://79783334880507" else "rbxassetid://137418128965762"
	
	local Goal = typeof(Crit) == "Color3" and Crit 
		or Crit and GameConfig.CriticalColor
		or Config.HighlightColor
		or (not GameConfig.AdaptiveDamageIndicator and GameConfig.DamageIndicatorColor)
		or (Alpha > 0.66 and GameConfig.PercentageColors.High)
		or (Alpha > 0.33 and GameConfig.PercentageColors.Medium) 
		or GameConfig.PercentageColors.Low
	
	if Config then
		RbxUtility.CreateHighlight(Entity, 0.75, Goal)
	end
	
	local FoundCounter = nil :: Part
	
	for Index, Counter in Counters do
		if Counter[1] == Entity and not Counter[2]:GetAttribute("Removing") then
			FoundCounter = Counter[2]
		end
	end
	
	if FoundCounter and not GameConfig.DamageCounterIsAdditive then
		FoundCounter:Destroy()
		FoundCounter = nil
	end
	
	local Clock = os.clock()
	
	local DamageCounter = FoundCounter 
		or ReplicatedStorage.Assets.Scripts:WaitForChild("DamageCounter"):Clone()
	
	local Gui = DamageCounter.DMGBillboard
	Gui:SetAttribute("Clock", Clock)
	Gui:SetAttribute("CurrentDamage", (Gui:GetAttribute("CurrentDamage") or 0) + (typeof(Damage) == "string" and 0 or Damage))

	Gui.Enabled = true
	Gui.Canvas.GroupTransparency = 1
	Gui.Canvas.Marker.Image.Image = MarkerID
	
	local CriticalAppend = (Crit == true and CRITICAL_APPEND) or ""
	Gui.Canvas.Damage.Text = if typeof(Damage) == "string" then Damage
		else FormatNumber(math.round(Gui:GetAttribute("CurrentDamage") * 10) / 10, "Suffix") .. CriticalAppend
	
	Gui.Canvas.GroupColor3 = Goal
	Gui.Canvas.Marker.Image.Rotation = if Enemy then math.random(-90, 90) else math.random(-15, 15)

	DamageCounter.Parent = workspace:WaitForChild("Temporary")
	DamageCounter.Position = Position

	Tween:Play(Gui.Canvas, {0.5, "Exponential"}, {GroupTransparency = 0, Rotation = Random:NextNumber(-15, 15)})
	Tween:Play(DamageCounter, {0.5, "Back", "Out"}, {Position = Position + Vector3.new(Random:NextNumber(-2.5, 2.5), Random:NextNumber(-1, 1), Random:NextNumber(-2.5, 2.5))})

	local Constructor = {Entity, DamageCounter}
	table.insert(Counters, Constructor)

	task.delay(2, function()
		if DamageCounter.Parent == nil or Gui:GetAttribute("Clock") ~= Clock then
			return
		end

		table.remove(Counters, table.find(Counters, Constructor))
		DamageCounter:SetAttribute("Removing", true)

		Tween:Play(Gui.Canvas, {0.5, "Circular"}, {GroupTransparency = 1})
		Debris:AddItem(DamageCounter, 1)
	end)
end

-- Modify this function in order to change remote callback
-- * For general notifs: (Instance (set to nil for Character), Text, Color3, SFX, DoHighlight)
function Remotes:OnEvent(EntityInstance, Damage, Crit, ItemConfig, NoHitSound)
	local Character = Player.Character
	local Right = Character and (Character:FindFirstChild("Right Arm") or Character:FindFirstChild("RightHand"))
	
	local Attachment = Right and Right:FindFirstChild("RightGripAttachment")
	if not Attachment then return end
	
	local isNotification = typeof(Damage) == "string"
	if not EntityInstance and not isNotification then return end
	
	local IsMob = not isNotification and EntityInstance:FindFirstChildWhichIsA("Humanoid") 
	local isProp = not isNotification and CollectionService:HasTag(EntityInstance, "Prop")
	local PropObject = not isNotification and isProp and PropClientList[EntityInstance]
	local Config = not isNotification and ((IsMob and require(EntityInstance.MobConfig)) or (isProp and require(EntityInstance.PropConfig)))
	
	-- Damage counter
	local RootPart = (EntityInstance or Character):FindFirstChild("HumanoidRootPart") or (EntityInstance or Character):GetPivot()
	local Position = (GameConfig.DamageCounterPositionIsMob and RootPart.Position + Vector3.new(0, 2, 0)) 
		or Attachment.WorldPosition + (Attachment.WorldCFrame.LookVector * 3) + (Random:NextUnitVector() * .8)
	
	CreateDamageCounter(Position, Damage, EntityInstance or Character, isNotification and NoHitSound or Config, Crit)
	
	if isNotification then
		local isOffCooldown = os.clock() - LastNotification > 0.15
		if ItemConfig and isOffCooldown then
			SFX:Play2D(ItemConfig[1], {Volume = ItemConfig[2]})
			
			LastNotification = os.clock()
		end
		return
	end
	
	-- Hit SFX
	local HitSound = if IsMob then ((ItemConfig and ItemConfig.HitSFX and ItemConfig.HitSFX[math.random(#ItemConfig.HitSFX)]) or GameConfig.HitSound.Mobs)
		else ((Config.StrikeSounds and Config.StrikeSounds[math.random(#Config.StrikeSounds)]) or GameConfig.HitSound.Props[Config.PropType])
	
	if typeof(HitSound) ~= "table" then
		HitSound = {HitSound, 1}
	end

	local isOffCooldown = os.clock() - LastHit > 0.15
	if not NoHitSound and isOffCooldown then
		local CritSound = Crit and ((ItemConfig and ItemConfig.CriticalSFX) or GameConfig.CriticalSFX)
		if CritSound then
			SFX:Play2D(CritSound[1], {Volume = CritSound[2]})
		end
		
		SFX:Play2D(HitSound[1], {Volume = HitSound[2]})
		LastHit = os.clock()
	end

	-- Callbacks
	if IsMob and Config.BossData and Config.BossData.Type == "DamageDealt" then
		EventModule:Fire("RequestBossHUD", true, EntityInstance)
	end
	
	if GameConfig.MobHUDStyle ~= "None" and not UserInputService.TouchEnabled then
		MobDisplay:CreateShare(EntityInstance) 
	end
end

return Remotes