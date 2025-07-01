return {
	-- Days/hours/mins/seconds before next open (saves when rejoins), per person
	Cooldown = {["Days"] = 0, ["Hours"] = 0, ["Minutes"] = 1, ["Seconds"] = 30},
	
	Drops = {
		Statistics = { -- {Name, Amount (range/number)*, Chance (xx/yy)*, OnlyOnce*}
			{"Gold", 50},
			{"XP", 20},
		},
		
		Items = {  -- {Type, Name, Amount (range/number)*, Chance (xx/yy)*, OnlyOnce*}
			{"Tool", "Iron Sword", 1},
		},
	},

	Name = "King's Chest", -- Must be unique from every chest in order to work w/ datastores
	Level = 7, -- Required level to open (used for level locked chests)
	
	OpenableOnce = false, -- Can only open this chest once per save
}