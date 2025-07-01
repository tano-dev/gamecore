--[[
	Evercyan @ March 2023
	HumanoidAttributes
	
	One important thing about this kit, is that you should never set a player's MaxHealth,
	WalkSpeed, and JumpPower manually through Humanoid properties.
	
	The kit uses a feature known as Humanoid "Attributes", which is a Configuration under the Humanoid
	(Humanoid.Attributes). Under here is another Configuration for each value.
	
	These Configurations have Attributes (shown at the bottom of the Properties window) which can be added
	to increase the total health.
	
	The reason this is done is so that we can add other sources of health (Game passes, Armor, etc), and the game
	won't lose track, or be forced to set the health to (100 + n).
	
	----------------------------------------------------------------------------
	
	It may sound confusing, but essentially, you can add 250 health to the character by doing this:
	> Character.Humanoid.Attributes.Health:SetAttribute("Premium VIP", 250)
	
	There are now two sources of Health
	• "Default": 100
	• "Premium VIP": 250
	
	The total is automatically calculated (250+100 = 350), and set as the player's new MaxHealth for the character.
	
	You can remove health by setting an attribute to nil
	> Character.Humanoid.Attributes.Health:SetAttribute("Premium VIP", nil)
	
	• "Default": 100
	
	The total is automatically calculated (100 = 100), and set as the player's new MaxHealth for the character.
	
	This can be done with other values as well. There are currently only three supported values:
	• Health (MaxHealth),
	• WalkSpeed,
	• JumpPower
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

local RegenerationModifiers = {}
for _, Module in script.HealthRegen:GetChildren() do
	RegenerationModifiers[Module.Name] = require(Module)
end

--> Variables
local HumanoidAttributes = {}
HumanoidAttributes.__index = HumanoidAttributes

local DefaultValues = GameConfig.DefaultHumanoid
local RegenerateRate = GameConfig.Regenerate.Rate
local RegenerateStep = GameConfig.Regenerate.Step

export type HumanoidAttributes = {
	Instance: Configuration,
	Humanoid: Humanoid,
	Update: (self: HumanoidAttributes) -> ()
}

----------------------------------------------------------------------------

function HumanoidAttributes.new(Humanoid: Humanoid): HumanoidAttributes
	local self = setmetatable({}, HumanoidAttributes) -- Looks complex, but all this does here is redirect an index to under HumanoidAttributes table if it doesn't exist in self.
	
	local Character = Humanoid.Parent
	self.Character = Character
	
	local Player = Players:GetPlayerFromCharacter(Character)
	self.Player = Player
	
	local Configuration = Instance.new("Configuration")
	Configuration.Name = "Attributes"
	
	for Name, DefaultValue in DefaultValues do
		local SubConfig = Instance.new("Configuration")
		SubConfig.Name = Name
		SubConfig.Parent = Configuration
		SubConfig:SetAttribute("Default", DefaultValue)
		
		SubConfig.AttributeChanged:Connect(function(AttributeName)
			self:Update()
		end)
	end
	
	Configuration.Parent = Humanoid
	
	self.Instance = Configuration
	self.Humanoid = Humanoid
	
	Humanoid.UseJumpPower = true
	
	self:Update()
	self:StepRegenerate()
	return self
end

function HumanoidAttributes:Update()
	for _, SubConfig in self.Instance:GetChildren() do
		if SubConfig:IsA("Configuration") then
			local n = 0
			for Name, Value in SubConfig:GetAttributes() do
				if typeof(Value) == "number" then
					n += Value
				end
			end
			
			local PropertyName = (SubConfig.Name == "Health" and "MaxHealth") or SubConfig.Name
			local Percent = SubConfig.Name == "Health" and (self.Humanoid.Health/self.Humanoid.MaxHealth)
			
			self.Humanoid[PropertyName] = n
			if Percent == 1 and GameConfig.HumanoidStatsRefreshWhenAdded then
				self.Humanoid.Health = self.Humanoid.MaxHealth
			end
		end
	end
end

function HumanoidAttributes:StepRegenerate()
	task.spawn(function()
		while self and self.Humanoid.Parent ~= nil do
			while self.Humanoid.Health < self.Humanoid.MaxHealth do
				local DeltaTime = task.wait(RegenerateStep)
				
				local DeltaHealth = DeltaTime * RegenerateRate * self.Humanoid.MaxHealth
				for _, Callback in RegenerationModifiers do
					DeltaHealth = Callback(self, DeltaHealth)
				end
				
				if self.Humanoid.Health > 0 then
					self.Humanoid.Health = math.min(self.Humanoid.Health + DeltaHealth, self.Humanoid.MaxHealth)
				end
			end
			
			self.Humanoid.HealthChanged:Wait()
		end
	end)
end

return HumanoidAttributes