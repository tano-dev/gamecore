--[[
	ej0w @ October 2024
	RequestStunMob
	
	Stuns a mob, simple!
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

--> References
local StunAsset = ReplicatedStorage.Assets.Effects.Stun.Attachment

--> Dependencies
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)
local Mobs = require(ServerStorage.Modules.Libraries.Mob.MobList)

--------------------------------------------------------------------------------

return function(Mob, StunTime)
	if typeof(Mob) == "Instance" or (typeof(Mob) == "table" and not Mob.Instance) then
		Mob = Mobs[Mob]
	end
	
	if AttributeModule:GetAttribute(Mob.Instance, "NoStun") or AttributeModule:GetAttribute(Mob.Instance, "Stunned") then
		return
	end
	
	local StunEffect = StunAsset:Clone()
	StunEffect.Parent = Mob.Instance:FindFirstChild("Head")

	for _, Particle in StunEffect:GetChildren() do
		task.delay(math.clamp(StunTime - 0.5, 0.5, math.huge), function()
			Particle.Enabled = false
		end)
	end
	Debris:AddItem(StunEffect, StunTime + 3)

	task.delay(StunTime, function()
		if Mob and not Mob.isDead then
			AttributeModule:SetAttribute(Mob.Instance, "Stunned", nil)
			Mob:SetWalkSpeed("ParryStun", nil)
		end
	end)
	
	AttributeModule:SetAttribute(Mob.Instance, "Stunned", true)
	Mob:RequestCallback("OnStunned")
	Mob:SetWalkSpeed("ParryStun", -9999)
end