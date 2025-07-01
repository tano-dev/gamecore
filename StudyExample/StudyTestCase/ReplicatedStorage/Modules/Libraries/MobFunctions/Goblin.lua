-- [CLIENT] --> Shared to all clients

--> Variables
local Callback = {}

-- VV Remove this line or set to false to make this run, left this here for a reference for scripters!
Callback.Disabled = true 

--------------------------------------------------------------------------------

function Callback:OnSpawned(MobInstance)
	print("Mob spawned:", MobInstance)
end

function Callback:OnDied(MobInstance)
	print("Mob died:", MobInstance)
end

function Callback:OnTargetPlayer(MobInstance, Player)
	print("Mob target player:", MobInstance, Player)
end

function Callback:OnWandering(MobInstance)
	print("Mob wandering:", MobInstance)
end

function Callback:OnGoingBack(MobInstance)
	print("Mob going back:", MobInstance)
end

function Callback:OnStunned(MobInstance)
	print("Mob stunned:", MobInstance)
end

function Callback:OnHit(MobInstance, Player)
	print("Mob got hit:", MobInstance, Player)
end

function Callback:OnShoot(MobInstance, Player)
	print("Mob shot:", MobInstance, Player)
end

function Callback:OnHitPlayer(MobInstance, Player)
	print("Mob hit player:", MobInstance, Player)
end

return Callback
