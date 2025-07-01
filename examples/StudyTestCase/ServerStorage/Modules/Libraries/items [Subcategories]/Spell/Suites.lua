--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

--> Dependencies
local SFX = require(ReplicatedStorage.Modules.Shared.SFX)
local DamageLib = require(ServerStorage.Modules.Libraries.Damage)
local Mobs = require(ServerStorage.Modules.Libraries.Mob.MobList)

--> Variables
local Spells = {}
local CurrentlyAffected = {}

--------------------------------------------------------------------------------
-- Utilities

local function AddParticlesToCharacter(Character, TotalTime, Folder)
	local Limbs = {"Left Leg", "Left Arm", "Right Arm", "Right Leg", "Torso", "Head"}
	for _, Limb in Limbs do
		local LimbPart = Character:FindFirstChild(Limb)
		if not LimbPart then
			continue
		end

		for _, Particle in Folder:GetChildren() do
			local Clone = Particle:Clone()
			Clone.Parent = LimbPart
			Clone.Enabled = true
			task.delay(TotalTime, function()
				Clone.Enabled = false
			end)

			Debris:AddItem(Clone, TotalTime + 2)
		end
	end
end

local function ChangeCharacter(Character, Callback)
	local Tool = Character:FindFirstChildWhichIsA("Tool")
	for _, Object: Part in Character:GetDescendants() do
		if Tool and Object:IsDescendantOf(Tool) then
			continue
		end
		
		if Object:IsA("SpecialMesh") then
			Object.TextureId = ""
		elseif Object:IsA("BasePart") then
			if Object:IsA("MeshPart") then
				Object.TextureID = ""
			end
			task.spawn(Callback, Object)
		elseif Object:IsA("Decal") then
			Object.Transparency = 1
		end
	end
end

--------------------------------------------------------------------------------
-- Callbacks

function Spells:Fire(Player, Spell, MobInstance, Properties)
	local Enemy = MobInstance:FindFirstChild("Enemy") :: Humanoid
	if Enemy.Health <= 0 then return end
	
	if CurrentlyAffected[MobInstance] then return end
	CurrentlyAffected[MobInstance] = os.clock()
	
	local TotalTime = Properties.Delay * Properties.Ticks
	task.delay(TotalTime, function()
		CurrentlyAffected[MobInstance] = nil
	end)
	
	AddParticlesToCharacter(MobInstance, TotalTime, ReplicatedStorage.Assets.Effects.Burn)
	
	for Iteration = 1, Properties.Ticks do
		DamageLib:DamageMob(Player, Mobs[MobInstance], {ClassType = "Spell", Ignore = true, Tool = Spell})
		RunService.Heartbeat:Wait()
		if Enemy.Health <= 0 then
			ChangeCharacter(MobInstance, function(Object)
				if Object.Transparency ~= 1 then
					Object.Transparency = 0
				end
				Object.Color = Color3.fromRGB(0, 0, 0)
				Object.Reflectance = 0
				Object.Material = Enum.Material.SmoothPlastic
			end)
			
			break
		end
		
		task.wait(Properties.Delay)
	end
end

function Spells:Freeze(Player, Spell, MobInstance, Properties)
	if not MobInstance then return end
	
	local Enemy = MobInstance:FindFirstChild("Enemy") :: Humanoid
	if Enemy.Health <= 0 then return end

	if CurrentlyAffected[MobInstance] then return end
	CurrentlyAffected[MobInstance] = os.clock()
	
	local OriginalWalkspeed = Enemy.WalkSpeed
	local TotalTime = Properties.Delay * Properties.Ticks
	
	local WalkSpeed = Enemy:WaitForChild("WalkSpeed")
	WalkSpeed:SetAttribute("FreezingSpell", -10)
	
	AddParticlesToCharacter(MobInstance, TotalTime, ReplicatedStorage.Assets.Effects.Freeze)
	
	task.delay(TotalTime, function()
		WalkSpeed:SetAttribute("FreezingSpell", nil)
		CurrentlyAffected[MobInstance] = nil
	end)
	
	for Iteration = 1, Properties.Ticks do
		DamageLib:DamageMob(Player, Mobs[MobInstance], {ClassType = "Spell", Ignore = true, Tool = Spell})
		RunService.Heartbeat:Wait()
		
		if Enemy.Health <= 0 then
			ChangeCharacter(MobInstance, function(Object)
				if Object.Transparency ~= 1 then
					Object.Transparency = 0.25
				end
				Object.CastShadow = false
				Object.Color = Color3.fromRGB(153, 194, 255)
				Object.Material = Enum.Material.Ice
			end)

			break
		end

		task.wait(Properties.Delay)
	end
end

function Spells:Health(Player, Spell, _, Properties)
	local Character = Player.Character
	
	local Humanoid = Character and Character:FindFirstChild("Humanoid")
	local Attributes = Humanoid and Humanoid:WaitForChild("Attributes", 1)
	if not Attributes then return end
	
	-- Set effect
	local Additive = Properties.Additive
	local Duration = Properties.Duration
	
	local MaxHealth = 0
	for Name, Value in Attributes.Health:GetAttributes() do
		if Name == "Spell" then
			continue
		end
		MaxHealth += Value
	end

	local Statuses = Player:WaitForChild("Statuses", 1)
	local Effect = Statuses and Statuses:WaitForChild("Health")
	if Effect and Additive then
		local AddedHealth = math.round(Additive * MaxHealth)
		Effect:SetAttribute("Duration", Duration)
		
		if Effect:GetAttribute("Addition") < AddedHealth then
			Effect:SetAttribute("Addition", AddedHealth)
		end
	end

	-- Heal percentage of health
	local Percentage = Properties.Percentage
	if Percentage then
		local Health = Humanoid.MaxHealth * Percentage
		Humanoid.Health = math.clamp(Humanoid.Health + Health, 0, Humanoid.MaxHealth)
	end
end

return Spells