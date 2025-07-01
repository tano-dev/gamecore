return {
	Name = "Sean's Forest Shop", -- Name of the interface label. Not to be confused with the billboard gui named "Shop".
	
	Color = Color3.fromRGB(85, 139, 255), -- Interface accent color
	CloseDistance = 20, -- Distance when the GUI automatically closes
	
	Items = { -- Each item is formatted like {"itemType", "itemName"}.
		{"Accessory", "The Prince's Crown"},
		{"Tool", "Iron Sword"},
		{"Armor", "Iron Armor"},
		{"Consumable", "Health Potion"},
		{"Spell", "Burn"},
		{"Spell", "Chill"},
		{"Spell", "Lesser Heal"},
	},
	
	Dialogues = {
		"Everything - all at cheap rates!",
		"Inflation's getting out of hand. Sorry.",
		"Theyre affordable. Check back later.",
		"Been hearing about that one guy. What about you?",
		"I don't know. It's quite a burden to have all that gold.",
		"I understand. But I'm not your therapist.",
		"Heard you should listen to Glass Beach.",
		"I'm simply trying to sell items. Please don't hit me.",
		"Have you looked into having more items?",
		"Lot going on right now. Want some items?"
	},
}