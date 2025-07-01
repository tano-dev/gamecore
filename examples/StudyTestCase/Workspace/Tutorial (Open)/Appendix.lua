--[[

	APPENDIX
	
	---- Preface ------------------------------------------------------------------------

	❗🔔 **INFO**
	- It should be noted that any attempts to port parts of this kit to the original MAY not work due to how the kit has been structured.
	- All programming in this mod has been made to replicate the original kit's programming style! Meaning, no headaches trying to figure this system out.
	
	---- Changes ------------------------------------------------------------------------
	
	📜 v1.09.3 (12/29/2024)
	
	- Fixed issue where lots of items in shop would cause lag
	- Added minute shorthand for boss mob spawn
	- Fixed damage multipliers being bugged
	- Changed block keybind to "F" and made it easier to customize
	- Added configuration for Crafting/Pawn/Shop SFX
	
	📜 v1.09.2 (12/19/2024)
	
	- Fixed CanStackItems messing with shop/crafting/pawn
	- Fixed issue where game would try saving nonexistant category (looping thru nil) data issues
	- Hopefully fixed item cost == nil shop bug
	
	📜 v1.09.1 (11/30/2024)
	
	- Configuration to disable parrying & keep blocking
	- Custom UI for teleport to spawn and tp on mob kill
	- Rework to SpawnLocation in GameConfig
	- Configuration to add multiple sounds in an SFX zone
	- Fixed minor issues with removed configuration that caused bugs
	- Added system for global keybinds
	- Added keybind text to backpack button & slightly reworked
	- Added config to change # of hotbar slots
	- Redid accessory equip system; it now uses a Callback system & armors can also use it
	- Reworked prop effects system to be continuous w/ other callback systems
	- Armors can now be configured to use keybinds
	- Revamped keybind & CAS systems entirely to be merged into CustomCAS
	- Reworked mob respawn system (wasn't happy with how random positions were handled)
	
	📜 v1.09 (11/24/2024)

	- Config for drop & level sfx
	- KeepPosition variable for mobs & ores (randomized position will be the same every time)
	- Can randomize mob respawn position
	- Fixed mobs freaking out when hit from far away
	- Entity name, damage highlight, health bar, area title, and bossbar title colors can all be changed in configuration.
	- Option to cancel quests & position marker for active quests
	- Mobs don't jump with WS of 0, and SpawnDelay/FollowDelay for more mob customization has been added
	- Mob projectile properties can be configured now
	- Cleanup to MobConfig & renamed BossStyle and Regenerate (to BossData and InstantRefreshData)
	- Fixed 'no quest' display for Quests UI
	- Revamped mob AI again & added configuration for AI
	- Redid mob target system to allow w/ moving mobs
	- Callbacks & mob functions can now be called by a separate name in config than the tool/mob name
	- Fixed constitution upgrade bugging when the player resets
	- Configurable Motor6D c0/c1 and offset
	- Prop hit & death effects can now be customized
	- Configurable option to keep health at max when maxhp changed (and mana)
	- New attributes system to declutter instances & keep shared network attributes
	- Fixed character orbit bugging on low FPS
	- Ability to require multiple of an item for level/portal doors (and generally revamped)
	- "AwardableOnce" config for tools, revamp of stat & item award
		*Items: {Type, Name, Amount (range/number)\*, Chance (xx/yy)\*, OnlyOnce\*}
		*Statistics: {Name, Amount (range/number)\*, Chance (xx/yy)\*, OnlyOnce\*}
	- Fixed armors being weird with clothing (deleting after respawning, etc)
	- Fixed visual display for attribute tallying being bugged
	- Added config to buy/sell with item cost instead of stat cost {Type, Name, Cost, OnlyOnce\*}
	- Added config for categories & tools to be hidden from inventory (ShowInInventory/DontShowInInventory)
	- Mob/ore healtbar now uses hp change system similar to bossbar
	- Added better config for sounds & added hit/miss SFX
	- Added ability to customize mob miss chance in MobConfig
	- Tools now have a volume control for attack/equip SFX
	- Visual changes for crits/misses, and configuration to change critical effect per tool or globally via OnCritical
	- Rename a callback to 'Default' for it to be activatable by any callback without a set module name
	- Quest/crafting pin UI now allow for custom leaderstats to be used
	- Mob Defense UI shortened to be less intrusive
	- Configurable erverwide drop notifications for items over xx rarity
	- Quest revamps (notification that quest has been completed, continuous quests, and talk to NPC objective is now possible)
	- Added togglable player HUD w/ health bar and level display
	- Added ability to set custom XP bar color
	- Fixed healing spell not being used sometimes
	- Fixed issues w/ StreamingEnabled
	- Touched up pawn UI slightly, revamped crafting & shop
	- Remade remote system entirely to be less intrusive & declutter
	
	📜 v1.08 (11/2/2024)
	
	---- [CONFIGURATION] --------------------
	- Autoclaim quest config in GameConfig (hides checkmark button too)
	- Props (ores) can be configured to do custom damage & params
	- Added better config for product & admin item config        
	- Added configuration for clothing armor
	- Added config for ^level xp, and *level xp
	- If manaperlevel <= 0 in config, mana bar will be disabled now
	- Added chance param to gifted drops (ie. chests & quests)

	---- [QOL] --------------------
	- Mouse cooldown system changes pos when in shift lock
	- Recoded datastore system so all items were numbervalues (reduces lag)    
	- Added popup info to spells & consumables
	- Rewrote error handling for libraries slightly
	- Motor6d can use ALL limbs, as long as it has an attachment
	- Added defense to armor tooltips & revamped tooltips in general
	- Additionally, item prompts now persist icon bg for tooltip when no icon
	- Config for walking & running animations and walkspeed changes
	- Revamped mob AI entirely
	- Ui colors & images for leaderstats autoupdate and shop/pawn cost display shows correct color depending on stat
	- Quests can now be configured to be repeatable

	---- [FEATURES] --------------------    
	- Overhauled prop/ores system in order to be configurable to any material type!
	- Added physical armor objects w/ slight armorlib recode    
	- Added multipliers to special mob types
	- Cooldown system has been reworked for weapons (can configure swing end/start for damage marking)
	- Toolsystem object (to cut lines in tool scripts)

	---- [FIXES & CHANGES] --------------------
	- (Hopefully) fixed issue where regeneration on mob wouldn't work right
	- Recalculated area requirement tooltip
	- Fixed issue where people could levelup past max level
	- Fixed teleport location on mobs
	- Level drops on mobs works correctly now
	- Fixed cost price being inaccurate for pawn (if set on cost only)
	- Fixed startercharacter not saving cframe occasionally (& can add DontSaveCFrame attribute to player)
	
	📜 v1.07 (10/20/2024)
	
	---- [CONFIGURATION] --------------------
	- Custom weapon hitsounds for weapons (HitSFX: table)
	- Only show accessory of a certain type (armor & accessories)
	- Made sfx also easily portable like anims
	- Added wander radius config to mobs
	- Configurable save spawn
	- Config for enemy sounds on death
	- Potion capped timers
	- Potion cooldown
	- Adaptive damage indicator fix & new damage indicator color config
	- Damage cap config to bosses
	- Config whether pressing with nothing active in box = buy 1
	- All item types can be used for level doors & portals now
	
	---- [QOL] --------------------
	- Previously owned non-stackable item wont show in notif (previously was bugged)
	- Weapon cooldown UI shown next to mouse
	- Weapon types (boss/event/etc) & declutter the weapon color ui
	- Mobile/console replacement for ^ button use ~ too for open ui, and lower max slots on mobile to prevent clutter
	- Fixed mobile notification layout & clearing after time up
	- Reworked tool scripts to be more uniform and easier to work with!!
	- Highlight is fainter when blocking
	- Preload animations
	- Despawn messages for spawned bosses
	- Stunned animation when the mob gets stunned, loops (& rework to weapon stun mobanimation --> can input table)
	- Progress to next area
	
	---- [FEATURES] --------------------	
	- Previous additions like new keybind for ceurelean crown
	- Consumables can now be made reusable
	- Gave all shop (pawn/crafting too) & quest NPCs the ability to be animated & recoded slightly
	- Revamped mob health display & damage display (with more config)
	- Xp/gold change display, configurable
	- Notification for new area & boss spawn
	
	---- [FIXES & CHANGES] --------------------
	- Starteritems have been reworked, won't bug when u add a new one
	- Updated shop/crafting owned & level requirement uis to be the same
	- Redid damage meter for hp bar a tiny bit
	- Fixed ranged toolnone being buggy for mobs
	- Mob spawn ui was a tiny bit delayed
	- Sometimes dmg notif said more than was done dmg after a while & didnt clear after respawn
	- Mp bar bugging after death
	- Made tp system not use objects (work w streaming) (tp to spawn is located in GameConfig)
	- Made datastore use updateasync
	- Recoded mob ai slightly
	- Fixed regenerate on mobs
	- Fixed absorption on blocking
	- Fixed pickaxe blocking & weapon switching cooldown
	- Fixed multiple leaderboards being usable at once
	- Fixed product system (badges & gamepasses were bugged)
	- Redid color grading to work with more than like 5 colors total
	- Fixed bug where pawn shop couldn't sell items w/ only cost vlaue
	- Fixed bug where attribute cost display was delayed
	- Fixed issue where inv tabs didn't show up when <2 owned

	📜 v1.06 (9/17/2024)
	
	---- [CONFIGURATION] --------------------
	- Revamped magic library to be more configurable
	- Added ability to add paid products
	- Added ability to buy multiple shop items (configurable)
	- Added ability to customize projectile hit effect
	- Added default stat modification in GameConfig
	- Ability to modify the values of any attribute/stat via armor
		
	- Added configurable seasonal icons to the tools
	- Added defense configuration in both mobs and weapons
	- Added defense/protection customization for all weapons, armors, and mobs
	- Added idle/equip animation configuration
	
	- Entirely rehauled & recoded the framework of the kit
	- Added boss spawns to the kit (previously only an add-on feature)
	
	---- [Mobs] --------------------
	- Added ability to customize mob huds - use your own hud and it overrides the default one :p
	- Configure mobs to regenerate if the engaged player has died (useful for superbosses)
	- Added ability for mobs to be able to equip armor
	- Fixed ranged mobs duplicating projectiles
	- Revamped mob AI and additionally added configuration for wandering
	
	---- [Mana / potions] --------------------
	- Entirely recoded the Mana system to be based off of the character, and properly scalable
	- Recoded potions system to not go off cooldown when you die
	- Added mana potions & additional configuration for potion boosts
	- Additionally, added health potions
	
	---- [UI] --------------------
	- Revamped portal UI & ability to use tool requirements for both portals and level doors
	- Redone damage notifications and some other minor UI tweaks
	- Revamped shop/pawn UIs, introduced dialogue
	- Revamped main UI to look more like kitteh6660's kit
	- Revamped pawn shop significantly, added item icons and category colors
	- UI now scales based off of the current viewport size
	- + more (stopped counting)
		
	---- [Spells] --------------------
	- Spells! Can now use spells to attack or protect yourself
	- Spells are considered Magic, meaning boosts that apply to magic apply to spells
	- Configurable in SpellLib --> Spells
	
	---- [Attributes] --------------------
	- Added attributes, customizable in GameConfig
	- Amplifiers customize how powerful attributes are
	- Point gain is fully customizable
	- Both proportionate & base damage attributes allowed
		
	---- [Bugfixes] --------------------
	- Fixed messed up mob ragdoll, added player ragdoll on death
	- Fixed issue where projectiles wouldn't get cleaned upsd
	- Improved the leveling system - xp remainder was off beforehand
	- Revamped the pawn shop UI: before it was bugged
	- Fixed piercing inaccuracy
	- Optimized casting ranged projectiles
	- and a LOT more (i stopped counting after the first day)
	
	- New notifications UI, dialogue/quests, mining/crafting, chests, etc
		*Doesn't include all changes, too many to count
	
	---- [10/11/2024] --------------------
	- Lost count again, added proximityprompts, framework recode, more gameconfig, more features, combat revamp, probably more
	
	📜 v1.05 (5/19/2024)
	
	---- [Consumables] --------------------
	- Added food items to the kit - heal from them!
	- Added potions, they could boost stats like maxhealth, walkspeed, damage, etc.
	- *Planning to make a display for potion effects soon
	- *Potion durations are stackable
	
	---- [Changes] --------------------
	- Forcefield now makes players invulnerable to damage
	- Some minor things reworked to ignore functionality if destroyed
	- Backpack is disablable in GameConfig
	- Tons of bugfixes and general optimization
	
	📜 v1.04 (5/17/2024)
	
	---- [Leaderboards] --------------------
	- Leaderboards have finally been introduced
	- Check BoardLib for customization - can also change stat path in model config
	
	---- [Changes] --------------------
	- Damage cooldown on the server is now compliant with item cooldowns
	- Ranged weapons now have the ability to shoot more than one projectile
	- Ability to remove MeleeMobAlign through GameConfig
	- Kit colors can now be changed through GameConfig
	- Cooldown now displays on an item's ActiveSlot in backpack
	- Mobs have the ability to award badges on death
	- Mob AI reworked to use PathfindingService
	- Ranged mobs have been introduced to the kit
	- Reorganization to workspace elements
	- Fixed bug where MP only updated when you rejoined
	
	📜 v1.03 (5/16/2024)
	
	---- [Changes] --------------------
	- Classes can now be customized in GameConfig
	- Armors no longer disappear spontaneously (clientside)
	- Fixed items duping when resetting (clientside)
	
	📜 v1.02 (5/xx/2024)
	
	(lost to time)
	
	📜 v1.01 (5/15/2024)
	
	---- [Introduction] --------------------
	- One of the biggest additions was the introduction of classes. There are currently three classes (and can be added on-to). Melee, Ranged, and Magic
	- Classes can be specialized via configuration in the Armor models. ManaPoints can also be added as benefits to armors
	- In configuration, class boosts can be set: They boost the damage of a class-specific item & shown on an armor's tooltip
	- I have gone out of my way to polish the damaging system, give way for customization referencing ranged weapon piercing, SFX, and among other changes
	- Datastores have been greatly improved - the original system was lacking a few crucial elements which made dataloss present
	
	---- [Magic] --------------------
	- New class type, comes with a default Druid's Staff and some other goodies
	- Customizable VFX inside of ItemConfig, acts as the first AOE items
	- ManaPoints system which is used to leverage magic class items
	- ManaPoints are given through (level*10) and armor boosts
	
	---- [Changes] --------------------
	- Fireworks now appear whenever the player has leveled BELOW 1,000
	- Configuration in GameConfig for whether the player can obtain more than one item (stacking)
	- DamageCounter now displays whenever the player has gotten a critical hit & highlights are used to show a mob as damaged
	- Multi-hit has been finally re-introduced to the kit
	- PlayerListStats has been slightly modified to show more than Levels (introduced in the main kit)
	- Pawn Shop has the ability to SellAll when item stacking is enabled
	- Boss bars have been added to increase the visibility of larger mobs' health. A maximum of four can be seen at once
	- Mobs now render with MeshParts, meaning each limb is material customizable
	- Mob health bars now display progress in color, and additionally display health
	- Mob HUD text is now illustrated with the mob's primary color
	- Main UI has been polished up, including more Humanoid stats, and easier customization (autoscale)
	- Trails and other miscellaneous goodies are included as optional features in tool configuration
	- DataStores can now be configured in GameConfig
	- Teleport To Spawn now shows a cooldown - along with the teleportation UI being slightly retouched
	- RbxUtility offers new useful functions for modification to the kit (SafeAssert among more)
	- Global drops have been introduced to GameConfig
	- Critical chance and luck modifiers have been introduced to GameConfig
	- MaxGold has been introduced to GameConfig
	- MobCollisions with the character can be toggled in GameConfig
	- Ranged weapons can now pierce (togglable) and can be given a dropoff value
	- Damaging has been reworked to allow multiple references with a specified limit in GameConfig
	- ^ Additionally has less delay when attacking
	
	----------------------------------------------------------------------------
	
	Message me on Roblox with any concerns or suggestions! https://www.roblox.com/users/978117804/profile
	Alternatively, DM on @ej0w 
	
]]