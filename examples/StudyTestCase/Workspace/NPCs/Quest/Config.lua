return {
	Name = "Wandering Peasant",
	CloseDistance = 20,
	
	AlreadyTakenDialogue = "It seems that you're already taking one of my quests. Come back later.",
	TooLowLevelDialogue = "It appears that you're too low level to talk to me. Come back when you're at level <b>%s</b>",
	NoMoreQuestsDialogue = "You've already completed all my quests.",
	
	Animations = {
		Idle = nil, -- Same system as mobs; uses mob default idle if nil specified
	},
	
	QuestOffers = { -- In order, won't offer the next unless the first is already done.
		{
			Rewards = {
				Statistics = { -- {Name, Amount (range/number)*, Chance (xx/yy)*, OnlyOnce*}
					{"Gold", 50},
					{"XP", 20},
				},
				
				Items = { -- {Type, Name, Amount (range/number)*, Chance (xx/yy)*, OnlyOnce*}
					{"Tool", "Cannon", 1},
				},
			},
			
			Requirements = {
				Mobs = { -- Required mob (NAMES) and xx amount to kill
					{"Goblin", 25},
					{"Pirate", 1},
				},
				
				Statistics = { -- Required level/gold/kills in order to succeed; unfortunately, not change of stats.
					{"Kills", 35},
					{"Level", 10},
				},
				
				Objectives = { -- These are checked every xx seconds. If returned true, then successful.
					["Obtain an <b>Iron Sword</b>"] = function(Player)
						local Backpack = Player.Backpack
						return Backpack:FindFirstChild("Iron Sword")
					end,
				},
			},
			
			-- General
			Name = "Adventurer I",

			Dialogues = {
				"Heya there! I was looking if you could sort out those mobs over there, they've been terrorizing us for a while.",
				"In return, I'll give you a <b>Cannon</b>. Deal?",
			},
			
			Repeatable = false, -- Whether the player can take this quest multiple times
			Succession = false, -- If enabled, the next quest will automatically be given when this one is completed
			
			Position = Vector3.zero, -- Vector3, set to use a quest marker on this specific spot when quest is active (set to nil to disable).
			
			Level = 5,
		},
		
		--[[
		
		{
			Next quest ...
		},
		
		]]
	}
}