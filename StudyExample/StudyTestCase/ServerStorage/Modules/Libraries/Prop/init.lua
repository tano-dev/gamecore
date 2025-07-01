--[[
	ej0w @ October 2024
	Prop
	
	Serversided logic handling for props, pretty barebones version of MobLib, adapted for props & all other subtypes instead
]]

--> Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)
local ContentLibrary = require(ReplicatedStorage.Modules.Shared.ContentLibrary)
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local SFX = require(ReplicatedStorage.Modules.Shared.SFX)
local Signal = require(ReplicatedStorage.Modules.Shared.Signal)
local ProductLib = require(ReplicatedStorage.Modules.Shared.Product)
local GiftDrops = require(ServerStorage.Modules.Server.giftDrops)

local _PropEffects = require(ServerStorage.Modules.Libraries.PropEffects)

local GetStatMultiplier = require(ReplicatedStorage.Modules.Shared.getStatMultiplier)

local AttackUtils = require(ServerStorage.Modules.Server.AttackUtils)
local MaterialLib = require(ServerStorage.Modules.Libraries["items [Subcategories]"].Material)

local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local DamageCooldown = {}
local Random = Random.new()

local Props = require(script.PropList)

--------------------------------------------------------------------------------

if not GameConfig.EnabledFeatures.Props then
	return {}
end

local PropLib = {}

local Prop = {}
Prop.__index = Prop

local PropsFolder = workspace:FindFirstChild("Props")
if not PropsFolder then
	PropsFolder = Instance.new("Folder")
	PropsFolder.Name = "Props"
	PropsFolder.Parent = workspace
end

function PropLib.new(PropInstance: Model): Props.Prop
	local Config = PropInstance:FindFirstChild("PropConfig") and require(PropInstance.PropConfig)
	if not Config then
		error(("OreLib.new: Passed ore '%s' is missing vital components."):format(PropInstance.Name))
	end
	
	local AttributeFolder = PropInstance:FindFirstChild("HeldAttributes") 
		or AttributeModule:CreateAttributeFolder(PropInstance)
	
	if AttributeModule:GetAttribute(PropInstance, "Loaded") then
		return 
	end
	
	local Prop = setmetatable({}, Prop)
	Prop.Instance = PropInstance
	Prop.Config = Config
	Prop.Hitbox = PropInstance:FindFirstChild("Hitbox")
	
	Prop.Base = {}
	Prop.Material = {}
	
	Prop.Attributes = AttributeFolder
	
	---- Load in pre-clone stuff
	
	local function SetRandomPivot(Pivot)
		Pivot = Pivot or PropInstance:GetPivot()
		
		local Position = Pivot.Position + Vector3.new(Random:NextNumber(-Config.RespawnRadius, Config.RespawnRadius), 0, Random:NextNumber(-Config.RespawnRadius, Config.RespawnRadius))
		local NewPivot = nil

		local NewPosition, Raycast = AttackUtils.Floor(Position)
		if NewPosition and math.abs(Position.Y - NewPosition.Y) < 5 then
			local LowerPosition = Prop.Hitbox.Position - (Vector3.yAxis * (Prop.Hitbox.Size.Y / 2))
			local Offset = Vector3.yAxis * (Pivot.Position.Y - LowerPosition.Y)

			NewPivot = CFrame.new(NewPosition + Offset) * Pivot.Rotation
			PropInstance:PivotTo(NewPivot)
		end
		
		return NewPivot
	end
	
	local InitiallyLoaded = AttributeModule:GetAttribute(PropInstance, "InitiallyLoaded")
	if not InitiallyLoaded then
		for _, Part in PropInstance:GetDescendants() do
			if Part:IsA("BasePart") then
				Part.CollisionGroup = "Mobs"
			end
		end
		
		-- Set random pivot
		if Config.RespawnRadius and Config.RespawnRadius > 0 then
			local NewPivot = SetRandomPivot()
			if NewPivot then
				AttributeModule:SetAttribute(PropInstance, "OriginPivot", NewPivot)
			end
		end
		
		AttributeModule:SetAttribute(PropInstance, "InitiallyLoaded", true)
	end
	
	Prop._Copy = PropInstance:Clone()
	
	---- Initialize
	
	AttributeModule:SetAttribute(PropInstance, "Loaded", true)
	
	-- Set pivot of ore if respawned
	if InitiallyLoaded then
		local OriginPivot = AttributeModule:GetAttribute(PropInstance, "OriginPivot")
		if not Config.KeepPosition and Config.RespawnRadius and Config.RespawnRadius > 0 then
			SetRandomPivot(OriginPivot)
		elseif OriginPivot then
			PropInstance:PivotTo(OriginPivot)
		end
	end
	
	-- Set random material orientations
	for _, Part in PropInstance:GetDescendants() do
		if Part.Name == "Material" then
			Part.Orientation = Vector3.new(0, Random:NextNumber(-360, 360), 0)
			table.insert(Prop.Material, Part)
		elseif Part:IsA("BasePart") and Part.Transparency ~= 1 then
			table.insert(Prop.Base, Part)
		end
	end
	
	Prop.Scale = PropInstance:GetScale()
	Prop.Origin = PropInstance:GetPivot()
	
	Prop.Health = Config.Health
	Prop.MaxHealth = Config.Health
	Prop.PlayerTags = {}
	
	AttributeModule:SetAttribute(PropInstance, "Health", Prop.Health)
	AttributeModule:SetAttribute(PropInstance, "MaxHealth", Prop.MaxHealth)
	
	-- Hit effect
	local PreviousHealth = Prop.Health
	
	AttributeModule:GetAttributeChanged(PropInstance, "Health"):Connect(function()
		local CurrentHealth = AttributeModule:GetAttribute(PropInstance, "Health")
		if CurrentHealth < PreviousHealth then
			Prop:RequestEffect("OnHit")
		end
		
		PreviousHealth = CurrentHealth
	end)
	
	PropInstance.Parent = PropsFolder
	Props[PropInstance] = Prop
	return Prop
end

function Prop:OnDied()
	if not self.isDead then
		self.isDead = true
		
		self:RequestEffect("OnDeath")
		self:AwardDrops()
		
		task.wait(self.Config.RespawnTime or 5)
		
		self:Respawn()
	end
end

function Prop:Destroy()
	if not self.Destroyed then
		self.Destroyed = true
		
		Props[self.Instance] = nil
		
		self.Instance:Destroy()
		
		setmetatable(self, nil)
	end
end

function Prop:TakeDamage(Damage: number)
	if not self.isDead then
		local NewRequestedHealth = math.clamp(rawget(self, "Health") - Damage, 0, rawget(self, "MaxHealth"))
		if NewRequestedHealth == 0 then
			task.spawn(self.OnDied, self)
		end
		
		self.Health = NewRequestedHealth
		AttributeModule:SetAttribute(self.Instance, "Health", NewRequestedHealth)
	end
end

function Prop:Respawn()
	if not self.Destroyed then
		local NewProp = self._Copy
		self:Destroy()
		NewProp.Parent = PropsFolder
	end
end

function Prop:AwardDrops()
	local AlreadyGiven = {}
	
	for UserId, Damage: number in self.PlayerTags do
		UserId = tonumber(UserId)
		
		if AlreadyGiven[UserId] then continue end
		AlreadyGiven[UserId] = true
		
		local Player = Players:GetPlayerByUserId(UserId)
		local Percent = Damage / self.MaxHealth
		if not Player or Percent < 0.25 then continue end
		
		local pData = PlayerData:FindFirstChild(Player.UserId)

		local Statistics = pData:FindFirstChild("Stats")
		if not Statistics then continue end
		
		---- Handle items & stats
		
		GiftDrops(Player, self.Config.Drops, true, true, true)
	end
end

function Prop:RequestEffect(Name)
	return _PropEffects:RequestEffect(self, Name)
end

task.defer(function()
	CollectionService:GetInstanceAddedSignal("Prop"):Connect(function(PropInstance)
		if PropInstance:IsDescendantOf(workspace) then 
			PropLib.new(PropInstance)
		end
	end)
	for _, PropInstance in CollectionService:GetTagged("Prop") do
		if PropInstance:IsDescendantOf(workspace) then 
			task.defer(PropLib.new, PropInstance)
		end
	end
end)

return PropLib