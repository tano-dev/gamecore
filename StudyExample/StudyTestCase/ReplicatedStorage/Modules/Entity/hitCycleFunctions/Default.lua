--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--[[ Cycles inbetween, duration = Cooldown ]]

--------------------------------------------------------------------------------

return {
	{
		TelegraphAnimation = {186934658, 0.2, 0.5},
		-- [TelegraphAnimation]: {AnimationID, FreezeTime?, TimeFrozen?}

		Attack = {4, "InFront"},
		-- [Attack]: {Stud distance, "InFront", "Circular"}
		-- * HitboxObjects also used, set Radius to nil if not using ^^ this (only uses HitboxObjects)!

		ShowTrail = true, -- Shows the mob's tools' trail on activation - note that you'll need to disable the trail beforehand.
		StopWhileAttacking = false, -- Stops whilst doing an attack for x swconds

		Callback = function(MobInstance, NearestTorso)
			--print(MobInstance, NearestTorso)
		end, -- Run a script here w the given parameters above, calls per cycle (can set to nil)

		Range = 8, -- Studs distance away from a player until mob swings at them
		Cooldown = 2,
	},
	{
		TelegraphAnimation = {186934753, 0.2, 0.5},
		-- [TelegraphAnimation]: {AnimationID, FreezeTime?, TimeFrozen?}

		Attack = {5, "InFront"},
		-- [Attack]: {Stud distance, "InFront", "Circular"}
		-- * HitboxObjects also used, set Radius to nil if not using ^^ this (only uses HitboxObjects)!

		ShowTrail = true, -- Shows the mob's tools' trail on activation - note that you'll need to disable the trail beforehand.
		StopWhileAttacking = false, -- Stops whilst doing an attack for x swconds

		Callback = function(MobInstance, NearestTorso)
			--print(MobInstance, NearestTorso)
		end, -- Run a script here w the given parameters above, calls per cycle (can set to nil)

		Range = 8, -- Studs distance away from a player until mob swings at them
		Cooldown = 2,
	},
}