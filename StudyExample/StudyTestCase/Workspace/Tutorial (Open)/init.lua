--[[

	---------------------------------------------------------------------------------------------------------

	𝐏𝐫𝐞𝐟𝐚𝐜𝐞
	
	
	Hi!
	
	For simplicity sake, I have stripped much of the old tutorial from this kit in favor for a more efficient method (& because it would be too long)
	I'll go over how to adjust to this new kit (ie. the big changes & framework changes), then how to work with each feature.
	- ej0w
	
	---------------------------------------------------------------------------------------------------------
	
	𝐒𝐞𝐭𝐭𝐢𝐧𝐠 𝐮𝐩 𝐭𝐡𝐞 𝐤𝐢𝐭
	
	
	Setting up the kit is fairly simple. I'm writing this with the notion that you're experienced with the old (Evercyan's V2) kit, but in case you're not:
	
	Each folder has a name & that's the directory where it goes. Drag and drop every folder in this model to the given folder name, then ungroup, and it should work correctly.
	ie. ReplicatedStorage --> game.ReplicatedStorage
	ie. StarterPlayer.StarterPlayerScripts --> game.StarterPlayer.StarterPlayerScripts
	
		*In order for datastores to work properly, you'll need to enable studio access to API Services.
		*If mobs duplicate, look into removing the HD Admin module and seeing if that fixes the problem.
	
	
	I've focused on removing the trouble of trying to port a half-working system into your game,
	So you can focus on what you want to do most: make the game.
		
	---------------------------------------------------------------------------------------------------------
		
	𝐌𝐨𝐝𝐢𝐟𝐲𝐢𝐧𝐠 & 𝐜𝐨𝐧𝐟𝐢𝐠𝐮𝐫𝐚𝐭𝐢𝐨𝐧
	
	
	Now that you've had some experience with the kit, it's time to personalize it to yourself!
	
	In ReplicatedStorage, you'll notice a few areas which desire to be modified, I'll be going over each one independently.
		*Item config: ReplicatedStorage.Items ... Item
		*Game configuration: ReplicatedStorage.GameConfig
		*Additional GameConfig: ReplicatedStorage.Config
		
	*Also, the government is lying to you: all the animation config in this kit can either be {123123123}, 123123123, "rbxassetid://123123123", or {"rbxassetid://123123123"}
	
	I mention item configuration here because it's held in ReplicatedStorage (along w/ the other configuration). 
	
	𝐖𝐞𝐚𝐩𝐨𝐧𝐬
	
	To add a new weapon, simply duplicate the old model & change its properties, etc.
		*To add new tooltips (and modify old ones) for custom types, refer to RS --> Modules,Client --> returnTooltipInfo
	
	To configure a weapon, tool, material, or other, look directly into the ModuleScript called 'ItemConfig' and call judgements based off of what it tells you.
		Most of the configuration is straight-forward; however, it's important to note that,
		
		*Keybinds & callbacks are both required independently from the script in [RS / SS] --> Modules --> Libraries --> [PathName]*
			Keybinds and callbacks are your best friend in this kit, they give you the ability to code custom functions into a weapon with ease
		
		Additionally, some specific types of tools behave differently. 
		The utility for Magic weapons is held under SS --> Modules,Libraries,Magic --> Suites, and RS --> Context,Remotes,ReplicaMagicCalled --> Suites
		
		To configure the usage of consumables & spells, refer to SS --> Modules,Libraries,Items --> [Item Type] --> Suites
		
		Weapons have the ability to connect w/ blocking & parrying to the developer's request.
		Check sword code to see how it's done, there's also useful config for custom animations.
		
		All tools have the ability to configure Motor6D (if it doesn't exist in the tool config, add it)
		This allows you to make dual welding & animate the tool separately from the character's arm
	
	𝐆𝐚𝐦𝐞𝐂𝐨𝐧𝐟𝐢𝐠
	
	Now that we're over weapons, I'll direct you to GameConfig. This is where a majority of the game's configuration is held (hence, the name)
		Most settings in this module explain themselves,
		If they don't currently make sense to you, then I wouldn't reccomend modifying them (out of possible errors)
		
		With that being said, I'll go over some of the bigger settings.
			'EnabledFeatures' allows you to disable/enable features of the kit that you don't like
			'ColorPreset' allows you to change the entire theme of the UI
		
			'Leaderstats' is a table that holds configuration for the shown & used leaderstats,
			'Attributes' shows you all attributes which the player can take advantage of,
			'Categories' are all the item types that the game sees as valid.
			
			*Further explanation is in the module itself
			
		After this, I reccommend checking out GameConfig's parent folder 'Config'
			Presets: Simply all the default color presets the dev can use
			Products: Gamepass/badge/premium/group benefits
			Spawners: Spawnable mobs, further configuration is in the script itself
			Remotes: Replacement for a massive Remotes folder in RS - A table w/ all remotes and its instance type.
			
	---------------------------------------------------------------------------------------------------------
			
	𝐆𝐚𝐦𝐞 𝐞𝐧𝐯𝐢𝐫𝐨𝐧𝐦𝐞𝐧𝐭
	
	
	Now that you've seen how to configure the kit's main system, I'll segway over to how to configure assets in the game (ie. mobs, chests, level doors).
	
	To add a new asset, simply duplicate the old one & change its properties to your desire
	It's important to note that assets like quests and chests require the config name to be unique.
	
	𝐌𝐨𝐛𝐬
	
	Configuring mobs is fairly straight-forward, I won't go over much, but I want to talk about a few really important pieces!
	
	'InstantRefreshData' Allows you to determine whether the mob regenerates when the player that targeted/attacked it died (useful for bosses)
	'BossData' Allows you to add/remote boss HUDs
	'AttackCycle' & 'HitCycle' are the bread and butter of mob combat. Configure these directly in RS --> Modules,Entity --> attackFunctions & hitCycleFunctions
	'RandomizeAppearance' Makes it possible for mobs to use unique models at random, check out the config for more.
	
	Clientside is located in RS --> entityCode --> MobClient
	Serverside is located in SS --> Libraries --> Mob
	
	𝐎𝐫𝐞𝐬 (now Props)
	
	Allows you to mine resources in return for materials, the configuration is very simple.
	Nothing to really talk about - but take into account level & tier when creating an effective mining area
	
	Clientside is located in RS --> entityCode --> PropClient
	Serverside is located in SS --> Libraries --> Prop
	
	To add a new type of prop:
	- Change the impact effect in RS --> Effects --> Impacts --> Props --> propName (optional)
	- Configure PropClient w/ the given prop type of your choice (if wanted)
	- Change PropType config in the Prop
	- Make a tool that can gather/mine this prop (using ToolType)!
	
	𝐍𝐏𝐂𝐬 (crafting, shop, pawn, dialogue, quest)
	
	Contrasting older kits, the NPC systems in this kit are extremely simple.
	
	For shop, simply add which items should be sold.
	For pawn shops, request the sell value in the ItemConfig itself
	For crafting, duplicate the table, specify a recipe, and you're done
	For dialogue & quest, do the same thing as ^^ but for quest requirements and dialogues instead
	
	*Each one of these will only take you a few seconds to configure!
	
	Clientside is located in RS --> userInterface --> Quests
	
	𝐓𝐞𝐥𝐞𝐩𝐨𝐫𝐭𝐬 & 𝐝𝐨𝐨𝐫𝐬
	
	Only main difference in this kit versus the old one is the introduction of item requirements for doors & portals
	'Tool' Tool name, non discriminatory to itemtypes, just requires to be a "Tool" class(?) IIRC
	
	Clientside is located in RS --> environmentCode --> Transportation
	
	𝐙𝐨𝐧𝐞𝐬 (lighting & sound)
	
	Desipite what the configuration says, you can modify w/ both SFX and lighting at the same time.
	Creates a smooth gradient between two areas, configuration for lighting is held under RS --> Assets,Lighting --> [Lighting Name]
	
	Clientside is located in RS --> environmentCode --> Zones
	
	𝐂𝐡𝐞𝐬𝐭𝐬
	
	Specify a time date and rewards.
	
	Clientside is located in RS --> environmentCode --> Chests
	Serverside is located in SS --> Libraries --> Chest
	
	---------------------------------------------------------------------------------------------------------
	
	𝐅𝐫𝐚𝐦𝐞𝐰𝐨𝐫𝐤
	
	
	If you haven't noticed already, the way scripts are handled in this kit differ vastly from the original kit.
	Don't let this alienate you; they work practically the same, but the new kit allows for the addition of new features without becoming overcrowded.
	
	Server and client are mostly shared in framework (Context & modules)
	
	Context contains modules for the state of the network, and an optional shared folder.
		Modules inside of this folder are run when the game starts
	
		The clientside uses these modules for things like casting, UI, tool setup, etc.
		Tool setup is handled entirely within this framework, instead of there being a ton of tool scripts spammed in every tool.
		
		The server uses these modules to handle the main game setup, ie. datastores, remotes, etc.
	
	Modules contains (modules) which aren't inherently ran at runtime.
		However, 'Libraries' differ in that these modules behave similarly to the ones in Context.
		
		Callbacks & Keybinds for both server and client are handled in Libraries, alomg with all tool repositories.
		Mob & ore systems are ran through Libraries on the server.	
		
		On the other hand, the Serverside has another folder for Server modules. These are required by different scripts,
		The clientside has folders for Entity, Shared, and Client modules. Additonally required by different scripts.
		
			Sometimes, modules are present in the form of camelCase. When this is the case, they're either a folder module (more modules under it & they run indep.),
			or the required module can be used in the form of a callback. ie. RequiredModule(xxxx)
	
	Learning the workflow for the framework in this kit is really important to mastering it, it makes game development SO much easier.
	
	*Note that all modules can be configured using 'Priority' attributes and run at different times
	
	---------------------------------------------------------------------------------------------------------
	
	𝐀𝐝𝐯𝐚𝐧𝐜𝐞𝐝
	
	
	Q: How do I add a new attribute?
	
	A: The process for adding attributes will vary in difficulty depending on what you're adding>
	The GameConfig to show attributes itself is very simple, but after that, you'll have to figure out the method that
	You desire to obtain the attribute value, then use it to modify some type of event.
	
	Configuration for displaying attribute progress in the UI is under RS --> Modules,Client --> DynamicStatFunctions
	
	
	Q: How to I add a new feature / script to the framework?
	
	A: Depends from where, but understanding what modules do where is important. To make a new tool script, rename the script to the type.
	To make a new UI script, do the same.
	
	To program an object inside of the workspace, use [RS / SS] --> Context --> Client / Server --> Collection,
	And set the object tag to what you desire.
	
	Just making a script that runs on the client or server, create a ModuleScript in Context & the correct applied module folder.
	
	
	Q: How do i modify (thing here)?
	
	A: Either search in Filter workspace for the thing you're asking about, or press Ctrl + Shift + F to search all scripts.
	Then, modify the thing from there.
	
	To modify ProximityPrompts, refer to RS --> Context,Client,stats & Miscellaneous --> ProximityPrompts
	To modify Notifications, refer to RS --> Modules,Client --> createNotification
	
	
	Q: Can you add (thing here)?
	
	A: The easiest option is often to add it yourself, or outsource it from someone else in the community
	Don't rely on updates to this kit as your only source of features & gameplay!
	
	---------------------------------------------------------------------------------------------------------
	---------------------------------------------------------------------------------------------------------
	
	There's a high probability I forgot a couple things in this tutorial,
	But hopefully, the script documentation will help.
	
	Anyways, thanks for giving my kit a try, I hope to see great games come from you!
	For inquiries or bug reports, Message me on @ej0w, or join our server! /ZRAHPK8crd
	
	*Open the Appendix for a (mostly) complete changelog
	
]]