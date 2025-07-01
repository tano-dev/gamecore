--[[
	ej0w @ October 2024
	DamageLib
	
	Consists all Ore, Mob, and Player related damaging
	Highly advised to use Critical and Damage modules under this script to modify damage values
]]

--> Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

--> Dependencies
local Mobs = require(ServerStorage.Modules.Libraries.Mob.MobList)
local Props = require(ServerStorage.Modules.Libraries.Prop.PropList)

local Knockback = require(ServerStorage.Modules.Server.Knockback)
local RequestStunMob = require(ServerStorage.Modules.Server.requestStunMob)

local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)
local ProductLib = require(ReplicatedStorage.Modules.Shared.Product)
local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local DamageLib = {}

local DamageModifiers = {}
for _, Module in script.Damage:GetChildren() do
	DamageModifiers[Module.Name] = require(Module)
end

local CriticalModifiers = {}
for _, Module in script.Critical:GetChildren() do
	CriticalModifiers[Module.Name] = require(Module)
end

local Interactions = {}

task.spawn(function()
	while true do
		Interactions = {}

		task.wait(GameConfig.MaxDamageInteractions[2])
	end
end)

local Random = Random.new()

--> Configuration
local MOB_MISS_MAX_CHANCE = 85

--------------------------------------------------------------------------------
-- Utilities

local function GetUserID(Player)
	local UserId = Player.UserId; if string.find(UserId, "-") then UserId = string.gsub(UserId, "-", "") end
	return UserId
end

local function GetPlayerBestDPS(Player)
	local Character = Player.Character
	local Weapons = {Character:FindFirstChildWhichIsA("Tool")}
	for _, Weapon in Player.Backpack:GetChildren() do
		table.insert(Weapons, Weapon)
	end
	
	local Selected = {}
	local BestDPS = 0
	for _, Weapon in Weapons do
		if Selected[Weapon.Name] then continue end
		Selected[Weapon.Name] = true
		
		local ItemConfig = Weapon:FindFirstChild("ItemConfig") and require(Weapon.ItemConfig)
		if ItemConfig and ItemConfig.Damage then
			local DPS = if typeof(ItemConfig.Damage) == "table" 
				then ((ItemConfig.Damage[1] + ItemConfig.Damage[2]) / 2) / ItemConfig.Cooldown 
				else ItemConfig.Damage / ItemConfig.Cooldown
			
			if DPS > BestDPS then
				BestDPS = DPS
			end
		end
	end
	
	return BestDPS
end

local function ShareDamageCallback(_Player, Name, Type, Params)
	EventModule:FireAllClients("ServerToClientCallback", _Player, Name, Type, Params)
	EventModule:Fire("ServerToServerCallback", _Player, Name, Type, Params)
end

--------------------------------------------------------------------------------
-- Player damaging

local function InteractParry(Player, Mob, Damage)
	local Character = Player.Character
	local DidNotInteract = true

	-- Blocking & parrying (honestly this entire system is really messy and idk how to fix that)
	local Tool = Character:FindFirstChildWhichIsA("Tool")
	local ItemConfig = Tool and Tool:FindFirstChild("ItemConfig") and require(Tool.ItemConfig)

	if ItemConfig and ItemConfig.BlockAndParry then
		local IsReleased = AttributeModule:GetAttribute(Tool, "Released")

		local MobPivot = Mob and Mob.Instance:GetPivot().Position
		local CharacterPivot = Character:GetPivot().Position

		local IsBlocking = AttributeModule:GetAttribute(Tool, "Blocking") 
			or IsReleased and Mob and Mob.Ranged

		if not Mob or IsBlocking then
			Damage = math.clamp(Damage - (Damage * ItemConfig.BlockAndParry.Absorption), 0, Damage)
		elseif Mob and IsReleased then
			Damage = 0

			local KnockbackValue = ItemConfig.Knockback or ItemConfig.BlockAndParry.Knockback
			if KnockbackValue then
				Knockback:Activate(Mob.Instance:FindFirstChild("Torso"), KnockbackValue, CharacterPivot, MobPivot)
			end

			local ParryToMob = ItemConfig.BlockAndParry.ParryToMob
			if ParryToMob then
				EventModule:FireAllClients("ForceAnimateMob", Mob.Instance, ParryToMob[math.random(#ParryToMob)])
			end

			local StunTime = ItemConfig.BlockAndParry.StunTime
			if StunTime then
				RequestStunMob(Mob, StunTime)
			end

			DamageLib:DamageMob(Player, Mob, {ClassType = "Melee", Ignore = true, Tool = Tool, Multiplier = ItemConfig.BlockAndParry.Multiplier or true})
			ShareDamageCallback(Player, Tool.Name, "OnParried", {Tool, Mob.Instance})
		end

		if not Mob or not Mob.Ranged then
			AttributeModule:SetAttribute(Tool, "BlockResult", (IsBlocking and "Blocked") or (IsReleased and "Parried"))
			AttributeModule:SetAttribute(Tool, "Blocking", nil)
			AttributeModule:SetAttribute(Tool, "Released", nil)
		end

		DidNotInteract = not IsReleased and not IsBlocking
	end
	
	return Damage, DidNotInteract
end

function DamageLib.Hurt(Player: Player, Damage: number, Mob)
	if typeof(Mob) == "Instance" then
		Mob = Mobs[Mob]
	end
	
	if Mob and AttributeModule:GetAttribute(Mob.Instance, "Stunned") then
		return
	end
	
	local Character = Player.Character
	local Humanoid = Character and Character:FindFirstChildWhichIsA("Humanoid") :: Humanoid
	if not Character then return end
	
	local pData = ReplicatedStorage:WaitForChild("PlayerData"):WaitForChild(Player.UserId)
	
	-- Hardcoded constitution because I genuinely don't know another use case for mobs missing attacks
	local Attributes = pData.Attributes
	local Constitution = Attributes.Constitution
	if Constitution.Value > 0 then
		local HitOpportunity = math.clamp(Constitution.Value * GameConfig.Attributes.Constitution.Amplifier, 0, math.max(MOB_MISS_MAX_CHANCE - (Mob and Mob.Config.WeightToMissChance or 0), 0))
		if math.random(100) < HitOpportunity then 
			EventModule:FireClient("PlayerDamagedEntity", Player, nil, "Missed!", GameConfig.MissColor, GameConfig.MissSFX)
			return false
		end
	end
	
	-- Defense hardcoding / ported over from Mob
	local RawDefense = 0
	local Statistics = Humanoid:FindFirstChild("Statistics")
	for Name, Value in (Statistics and Statistics.Defense:GetAttributes() or {}) do
		local IsAdditive = string.find(Name, "Additive")
		if IsAdditive then
			RawDefense += Value
		elseif not IsAdditive then
			RawDefense += Value * Damage
		end
	end

	Damage = math.clamp(math.round(Damage - RawDefense), 1, math.huge)

	local Humanoid = Character:FindFirstChild("Humanoid")
	if not Humanoid 
		or Character:FindFirstChildWhichIsA("ForceField") 
		or not Character:FindFirstChild("Torso") 
		or Character.Torso:FindFirstChildWhichIsA("ForceField") 
	then
		return false
	end
	
	local NewDamage, DidNotInteract = InteractParry(Player, Mob, Damage)
	Damage = NewDamage
	
	-- Damage handling
	Damage = math.round(Damage)
	
	local CanDamage = Damage > 0
	if CanDamage then
		Humanoid.Health = math.clamp(Humanoid.Health - Damage, 0, Humanoid.MaxHealth)
	end
	
	if Mob then
		Mob:RequestCallback("OnHitPlayer", {Player})
	end
	
	EventModule:FireClient("MobDamagedPlayer", Player, CanDamage, DidNotInteract)
end

EventModule:GetOnServerEvent("PlayerDamaged"):Connect(function(Player, Damage, MobInstance)
	if typeof(Damage) ~= "number" or Damage ~= Damage or Damage < 0 then 
		return 
	end
	
	local CanHighlight = DamageLib.Hurt(Player, Damage, MobInstance)
	if CanHighlight then
		EventModule:FireClient("MobDamagedPlayer", Player, nil, Damage, nil, true, true)
	end
end)

--------------------------------------------------------------------------------

local RemoteUsages = {}
local ParryCooldown = {}
local ActivateCooldown = {}

task.spawn(function()
	while true do
		RemoteUsages = {}
		
		task.wait(GameConfig.MaxInputInteractions[2])
	end
end)

---- Parrying / blocking

EventModule:GetOnServerEvent("RequestBlock"):Connect(function(Player: Player, OldTool, Verdict: boolean, CanComplete: boolean)
	if not RemoteUsages[Player] then 
		RemoteUsages[Player] = 0 
	end
	
	RemoteUsages[Player] += 1
	
	-- Check if the player can block
	local Character = Player.Character
	
	local Humanoid = Character and Character:FindFirstChild("Humanoid") :: Humanoid
	local Tool = Character and Character:FindFirstChildWhichIsA("Tool")
	
	if not Tool or RemoteUsages[Player] > GameConfig.MaxInputInteractions[1] then 
		AttributeModule:SetAttribute(OldTool, "BlockResult", os.clock())
		AttributeModule:SetAttribute(OldTool, "Blocking", nil)
		AttributeModule:SetAttribute(OldTool, "Released", nil)
		return 
	end
	
	if (not Humanoid or Humanoid.Health <= 0) or not Tool:IsDescendantOf(Character) then
		return
	end

	local ItemConfig = Tool:FindFirstChild("ItemConfig") and require(Tool.ItemConfig)
	if not ItemConfig or not ItemConfig.BlockAndParry then
		return
	end
	
	-- On activated block:
	AttributeModule:SetAttribute(Tool, "BlockResult", nil)

	if Verdict then
		AttributeModule:SetAttribute(Tool, "Blocking", true)
	elseif not Verdict then
		if ItemConfig.BlockAndParry.CanParry and CanComplete and not ActivateCooldown[Player] then
			ActivateCooldown[Player] = true

			AttributeModule:SetAttribute(Tool, "Released", true)

			task.delay(ItemConfig.BlockAndParry.ParryWindow, function()
				if not AttributeModule:GetAttribute(Tool, "BlockResult") then
					AttributeModule:SetAttribute(Tool, "BlockResult", os.clock())
				end
				AttributeModule:SetAttribute(Tool, "Released", nil)

				ActivateCooldown[Player] = false
			end)
		elseif not ActivateCooldown[Player] then
			AttributeModule:SetAttribute(Tool, "BlockResult", os.clock())
		end
		
		AttributeModule:SetAttribute(Tool, "Blocking", nil)
	end
end)

--------------------------------------------------------------------------------
-- Ore / mob damaging

function DamageLib:TagMobForDamage(Player: Player, Mob, Damage: number)
	if Mob.isDead then
		return 
	end
	
	local UserId = GetUserID(Player)
	
	if Mob.Config.InstantRefreshData and Mob.Config.InstantRefreshData.CanRefresh then
		local RegenerateTag = Mob.Instance:FindFirstChild("RegenerateTag")
			or Instance.new("Configuration")
		
		RegenerateTag.Name = "RegenerateTag"
		RegenerateTag.Parent = Mob.Instance
		
		if RegenerateTag:GetAttribute("Player") == nil or RegenerateTag:GetAttribute("Player") == Player then
			RegenerateTag:SetAttribute("Clock", os.clock())
			RegenerateTag:SetAttribute("PlayerID", UserId)
		end
	end
	
	local PlayerTags = Mob.Instance:FindFirstChild("PlayerTags")
	if not PlayerTags then
		PlayerTags = Instance.new("Configuration")
		PlayerTags.Name = "PlayerTags"
		PlayerTags.Parent = Mob.Instance
	end
	
	local ExistingTag = PlayerTags:GetAttribute(tonumber(UserId))
	PlayerTags:SetAttribute(tonumber(UserId), (ExistingTag or 0) + Damage)
end

-- Sorry for how messy this is: Ignore should be called for serverside, Tool & Modifier same story, modifier is true/num to no knockback, number to * damage
function DamageLib:DamageMob(Player: Player, Mob, Parameters)
	Parameters = Parameters or {}
	
	local NoHitSound = Parameters.NoHitSound 
	local Multiplier = Parameters.Multiplier
	local ClassType = Parameters.ClassType
	local Damage = Parameters.Damage
	local Ignore = Parameters.Ignore 
	local Dampen = Parameters.Dampen
	local Tool = Parameters.Tool
	
	local UserId = GetUserID(Player)
	local RegenerateTag = Mob.Instance:FindFirstChild("RegenerateTag")
	
	if Mob.isDead or (Mob.Config.InstantRefreshData and Mob.Config.InstantRefreshData.CanRefresh and RegenerateTag and (RegenerateTag:GetAttribute("PlayerID") ~= UserId and RegenerateTag:GetAttribute("PlayerID") ~= nil)) then
		return
	end
	
	local pData = ReplicatedStorage.PlayerData:FindFirstChild(Player.UserId)
	local Level = pData and pData:FindFirstChild("Stats") and pData.Stats:FindFirstChild("Level")
	if not Level or (Level.Value < Mob.Config.Level[2]) then
		return
	end
	
	-- Make sure the equipped tool can be found, so we can safely grab the damage from it.
	-- Never pass damage as a number through a remote, as the client can manipulate this data.
	local Character = Player.Character
	
	local Humanoid = Character and Character:FindFirstChild("Humanoid") :: Humanoid
	if not Humanoid or Humanoid.Health <= 0 then
		return
	end
	
	local Tool = Tool or Character:FindFirstChildOfClass("Tool")
	local ItemConfig = Tool and Tool:FindFirstChild("ItemConfig") and require(Tool.ItemConfig)
	if (not ItemConfig or not ItemConfig.Damage or ItemConfig.WeaponType ~= ClassType) and not Ignore then 
		return 
	end
	
	-- Damage Cooldown
	local Count = Interactions[Player.UserId]
	local Default = GameConfig.MaxDamageInteractions[1]
	if not Ignore and (Count and (Count > Default / ItemConfig.Cooldown)) then
		return 
	end
	
	Interactions[Player.UserId] = (Count and Count + 1) or 1
	
	-- Calculate damage & criticals
	-- *These wouldn't be hardcoded if they were practical
	local ItemSuite = ItemConfig and ItemConfig.Suite and ItemConfig.Suite[2]
	local CriticalChance = ItemConfig and ItemConfig.CriticalChance or GameConfig.CriticalChance
	local CriticalDamage = GameConfig.CriticalMultiplier
	
	if CriticalChance[2] then
		local UnitCriticalChance = {1, CriticalChance[2] / CriticalChance[1]}
		for _, Callback in CriticalModifiers do
			UnitCriticalChance, CriticalDamage = Callback(Player, Tool, UnitCriticalChance, CriticalDamage)
		end
	end
	
	local Proportionate = ItemSuite and ItemSuite.Proportionate
	local SuiteDamage = ItemSuite and ItemSuite.Damage

	local Damage = Damage 
		or Proportionate and GetPlayerBestDPS(Player) * ItemSuite.Damage
		or SuiteDamage
		or typeof(ItemConfig.Damage) == "table" and Random:NextInteger(unpack(ItemConfig.Damage))
		or ItemConfig.Damage
	
	if Tool then
		for _, Callback in DamageModifiers do
			Damage = Callback(Player, Tool, Damage, Mob)
		end
	end
	
	-- Defense negation
	local ConfigDefensePenetration = ItemConfig and ItemConfig.DefensePenetration
	local ConfigDefense = Mob.Config.Defense
	
	-- The general idea is to convert both of these values to numbers, and subtract from eachother
	-- *It looks hacky due to implementation for % defenses
	local WeaponCanAdd = ConfigDefensePenetration and ConfigDefensePenetration[2]
	local WeaponDefense = ConfigDefensePenetration and ConfigDefensePenetration[1]
	if not WeaponCanAdd then
		WeaponDefense = WeaponDefense and math.clamp(WeaponDefense, 0, 1)
	end
	
	local MobCanAdd = ConfigDefense and ConfigDefense[2]
	local MobDefense = ConfigDefense and ConfigDefense[1]
	if not MobCanAdd then
		MobDefense = MobDefense and math.clamp(MobDefense, 0, 1)
	end
	
	local RawMobDefense = (MobCanAdd and MobDefense) or 0
	local RawWeaponDefense = (WeaponCanAdd and WeaponDefense) or 0
	if MobDefense and not MobCanAdd then
		local DividedMobDefense = (1 / MobDefense)
		if WeaponDefense and not WeaponCanAdd then
			DividedMobDefense *= (1 / WeaponDefense)
		end
		local NegatedWeaponDamage = Damage / DividedMobDefense
		RawMobDefense = NegatedWeaponDamage
	end
	
	RawMobDefense = math.clamp(RawMobDefense - RawWeaponDefense, 0, math.huge)
	Damage = math.clamp(Damage - RawMobDefense, 1, math.huge)
	
	-- Dampen damage (based on ranged piercing)
	if Dampen and Dampen == Dampen then
		local ClampedDampen = math.clamp(Dampen, 0.1, 1)
		Damage = Damage * ClampedDampen
	end
	
	-- Critical multiplier
	local Critical = CriticalChance[2] and Random:NextInteger(unpack(CriticalChance)) == CriticalChance[2]
	if Critical then
		Damage *= CriticalDamage
	end
	
	-- Damage modifier
	if typeof(Multiplier) == "number" then
		Damage *= Multiplier
	end
	
	-- Damage cap
	local MaxDamageCap = Mob.Config.MaxDamageCap 
	if MaxDamageCap then
		local MaxDamage = math.round(Mob.Config.Health * MaxDamageCap)
		Damage = math.clamp(Damage, 0, MaxDamage)
	end
	
	Damage = math.round(Damage)
	
	-- Knockback (honestly idk why you'd use this other than high cooldown items)
	local CharacterPivot = Character:GetPivot().Position
	local MobPivot = Mob.Instance:GetPivot().Position
	
	if not Multiplier and ItemConfig and ItemConfig.Knockback then -- Multiplier is a constant for all parried attacks. Is true if no multiplier in parry config
		Knockback:Activate(Mob.Instance:FindFirstChild("Torso"), ItemConfig.Knockback, CharacterPivot, MobPivot)
	end
	
	AttributeModule:SetAttribute(Mob.Instance, "HasBeenHit", true)
	
	-- Damage handling
	DamageLib:TagMobForDamage(Player, Mob, Damage)
	
	Mob:TakeDamage(Damage)
	Mob:RequestCallback("OnHit", {Player})
	
	EventModule:FireClient("PlayerDamagedEntity", Player, Mob.Instance, Damage, Critical, ItemConfig, NoHitSound)
	
	if Tool then
		if Critical then
			ShareDamageCallback(Player, Tool.Name, "OnCritical", {Tool, Mob.Instance})
		end
		
		ShareDamageCallback(Player, Tool.Name, "OnHit", {Tool, Mob.Instance})
	end
end

function DamageLib:DamageProp(Player: Player, Prop, Parameters)
	Parameters = Parameters or {}
	
	local Damage = Parameters.Damage
	local Ignore = Parameters.Ignore 
	local Tool = Parameters.Tool
	
	local Character = Player.Character
	Tool = Tool or Character and Character:FindFirstChildOfClass("Tool")
	
	if Prop.isDead then return end
	
	-- Check if ItemConfig exists & uses eight weapon type
	local ItemConfig = Tool and Tool:FindFirstChild("ItemConfig") and require(Tool.ItemConfig)
	if (not ItemConfig or not ItemConfig.Damage or not ItemConfig.ValidPropTypes or not table.find(ItemConfig.ValidPropTypes, Prop.Config.PropType)) and not Ignore then 
		return 
	end
	
	-- Check if player's level is enough to mine ore
	local pData = ReplicatedStorage.PlayerData:FindFirstChild(Player.UserId)
	local Level = pData and pData:FindFirstChild("Stats") and pData.Stats:FindFirstChild("Level")
	if Level and Level.Value < Prop.Config.Level[2] then
		EventModule:FireClient("PlayerDamagedEntity", Player, Prop.Instance, "Level too low!", GameConfig.WarningColor, ItemConfig.InvalidSFX or GameConfig.InvalidSFX)
		return
	end
	
	if ItemConfig.Tier < Prop.Config.Tier then
		EventModule:FireClient("PlayerDamagedEntity", Player, Prop.Instance, "Tier too low!", GameConfig.WarningColor, ItemConfig.InvalidSFX or GameConfig.InvalidSFX)
		return
	end
	
	-- Calculate damage
	local Damage = Damage 
		or typeof(ItemConfig.Damage) == "table" and Random:NextInteger(unpack(ItemConfig.Damage))
		or ItemConfig.Damage

	for _, Callback in DamageModifiers do
		Damage = Callback(Player, Tool, Damage)
	end
	
	Damage = math.round(Damage)

	-- Ore tagging
	local CurrentDamage = Prop.PlayerTags[Player.UserId] or 0
	Prop.PlayerTags[Player.UserId] = CurrentDamage + Damage
	
	-- Render damage & return
	Prop:TakeDamage(Damage)
	
	EventModule:FireClient("PlayerDamagedEntity", Player, Prop.Instance, Damage, false, ItemConfig, false, Prop.Scale)
	ShareDamageCallback(Player, Tool.Name, "OnHit", {Tool, Prop.Instance})
end

function DamageLib.CallDamage(Player, EntityInstance: Model, Dampen: number?, Class)
	if not EntityInstance or typeof(EntityInstance) ~= "Instance" then return end
	
	if CollectionService:HasTag(EntityInstance, "Mob") then
		local Mob = Mobs[EntityInstance]
		if Mob then
			DamageLib:DamageMob(Player, Mob, {Dampen = Dampen, ClassType = Class})
		end
	elseif CollectionService:HasTag(EntityInstance, "Prop") then
		local Prop = Props[EntityInstance]
		if Prop then
			DamageLib:DamageProp(Player, Prop)
		end
	end
end

EventModule:GetOnServerEvent("DamageEntity"):Connect(DamageLib.CallDamage)
return DamageLib