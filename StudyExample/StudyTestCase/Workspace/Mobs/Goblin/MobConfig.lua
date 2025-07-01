return {
	-- General
	Name = "Goblin", -- Name of the mob shown in its interface
	Rank = nil, -- Mob Rank - 'nil' for no rank, or a string for a rank ("Boss")
	
	Level = {3, 1}, -- Mob Level, followed by Min Level (req to kill/access the mob - this is typically the realm level / boss portal level)
	MobTypes = {"Regular"}, -- Weapons can use these values to change damage modifier versus mobs, they'll do more damage to these!
	
	-- Visuals
	Color = nil, -- Color for mob text & display on player hud, set to nil to use default

	HealthBarColor = nil, -- Set to use custom healthbar color
	HighlightColor = nil, -- Set to use custom damage highlight color
	
	RandomizeAppearance = {"Goblin 2"}, -- Set to nil to not use, else, choses a random mob from Entities --> Alternatives from the given names to replace with (and current model)
	AddCurrentModelToRandom = true, -- ^^ adds current mob to random table, {Mob, "xxx", "xxx"} if set to true
	
	Armor = nil, -- Set to nil if not wearing; else, wears the armor name from Items --> Armor
	
	-- Humanoid
	RegenerateData = {
		Amount = nil, -- Set to a number to regenerate xx amount per time in step, set to nil to use percentage
		Percentage = 1 / 100, -- Amount of MaxHealth regenerated per step time (set to nil to disable regen)
		Step = 1, -- Time (in seconds) between each regeneration step (set to nil to disable regen)
		Duration = 30, -- Time (in seconds) of the mob not being in combat to regenerate (set to nil to disable regen)
	},
	
	InstantRefreshData = {
		CanRefresh = false, -- The player who engaged the mob (which no other players can engage) will regenerate when player is dead or far enough away
		Cooldown = 60, -- Time without interaction that the mob regenerates on its own
		Distance = 125, -- Distance until the mob can be regenerated (in studs)
	},

	BossData = {
		Type = "None", -- 'AtDistance', 'DamageDealt', or 'None', Based on how the HUD will be shown. DamageDealt = if hit, AtDistance = distance required [2]
		Distance = 125, -- Distance until both shown (if AtDistance) & left
		Color = nil, -- HUD color, set to nil to use default red/yellow/green colors.
	},
	
	AIData = {
		Range = nil, -- How far away the mob can be from its origin and still follow the player (set to nil to use infinite distance)
		LookAtTarget = true, -- Looks at the player the mob is targeting (similar to melee mob align)
		FollowDistance = 32, -- Minimum distance (in studs) required for the mob to follow any nearby player

		Percentage = 0.25, -- At what hp percentage the mob will run away, when on 'Medium' tendency
		KeepDistance = {13, 16}, -- Min/max distance for the mob to keep distance with player, used for ranged/running away

		CanWander = true, -- Whether the mob can wander or not (WanderRadius also prevents if set to nil)
		WanderRadius = 10, -- The mob will wander when there's no players nearby (set to nil to disable)

		Type = nil, -- Set to nil to use the default (based on whether mob has projectile config), can choose 'Melee', 'Ranged'
		Tendency = "Brave", -- Whether the mob will target the player constantly (keep distance as ranged) 'Brave', run away when low 'Medium', or only run away 'Coward'
		Intelligence = "Smart", -- Whether the mob can pathfind to the player (or uses MoveTo), can choose 'Smart', 'Dumb'
	},
	
	Health = 15, -- Amount of max health the mob spawns with
	Defense = {0.25, false}, -- The amount of damage the mob resists from hits
	-- * Value 2: If set to false, defense is x, else, it's regular damage reduction (e.g. if player does 10 damage and mob has 5 defense, mob takes 5 damage)
	
	WanderSpeed = 12, -- Speed the mob is when wandering/walking (not targeting a player)
	WalkSpeed = 13, -- How fast the mob is (studs per second), wandering is -2 walkspeed!
	JumpPower = 50, -- Jump power of the mob (50 is default), used for jumping if an obstruction is in the way that the mob can jump over
	
	-- Behavior
	Damage = 5, -- Damage dealt to any player that touches the mob
	RespawnTime = 5, -- Time (in seconds) until the mob respawns after death
	
	KeepPosition = false, -- Whether the entity will always spawn at the same position
	RespawnRadius = 5, -- Random stud radius that the mob can spawn in, calculated off of floor position (set to nil to disable)
	
	MobFunctionName = nil, -- Set to a string name to override the module's name being used in MobFunctions (for example, making it 'Default' uses the moduled named so) 
	AttackCycle = false, -- Set AttackCycles in ReplicatedStorage --> Modules --> Entity --> attackFunctions --> (Name or "Default")
	HitCycle = true, -- Set HitCycles in ReplicatedStorage --> Modules --> Entity --> hitCycleFunctions --> (Name or "Default")
	-- * For all of these, set it to a string, (ie. 'Default') to use the module w/ that name. Setting to true uses the mob's name.

	MaxDamageCap = nil, -- Max percent (decimal) of Mob's MaxHealth can be dealt by the player, set to nil to not use. ie. 0.33 --> 33k DMG out of 100k HP can be max dealt
	NoKnockback = false, -- Doesn't get knocked back even when the player has a knockback tool
	NoStun = false, -- Can't get stunned
	
	WeightToMissChance = 5, -- The higher the number, the harder for the mob to miss, max is 85.
	
	ChaseDelay = {0, nil}, -- (Optional) duration & (optional) animation delay, plays when the mob finds a player it can chase after idling (can set to nil to disable) 
	RespawnDelay = {0, nil}, -- (Optional) duration & (optional) animation delay, plays when the mob respawns - won't chase or move until time is up (can set to nil to disable) 
	-- * Animation prioirity for respawn & chase delay should be higher than idle

	-- On Death
	Drops = {
		Statistics = { -- {Name, Amount (range/number)*, Chance (xx/yy)*, OnlyOnce*}
			{"XP", 20}, 
			{"Gold", 10},
		},
		
		Items = { -- {Type, Name, Amount (range/number)*, Chance (xx/yy)*, OnlyOnce*}
			{"Tool", "Iron Sword", 1, {1, 10}},
		},
	},
	-- * Mob drops that can be gizven to the player on death, like stats (Level / XP / Gold) & items (Armor / Tool)
	
	TeleportLocation = nil, -- Teleport player to a location on death - nil for no tp, or a Vector3 to teleport
	AwardBadge = nil, -- Badge ID
	
	DeathSound = nil, -- rbxassetid:// string or number, plays when the Mob dies
	
	-- Rig
	CustomAnimations = { -- If any values below are nil, they use the animation defaults, based off the default Thief rig.
		Running = nil, -- (Used for chasing players) Animation id for Running animation (ie. custom rigs) - keep to nil for default anims
		Walking = nil, -- (Used for wandering) Animation id for Running animation (ie. custom rigs) - keep to nil for default anims
		Jumping = nil, -- Animation id for Jumping animation (ie. custom rigs) - keep to nil for default anims
		Idle = nil, -- Animation id for Idle animation (ie. custom rigs) - keep to nil for default anims
		Stun = nil, -- Stun animation (can be a table), make sure the animation is looped!
	},
	
	HitboxObjects = nil, -- (set to nil to default to Tool or arms) Works w/ models & limbs (Tool is classified as a model)
}