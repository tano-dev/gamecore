return {
	Name = "Ralph's Smithery", -- Name of the interface label. Not to be confused with the billboard gui named "Shop".
	
	Color = Color3.fromRGB(239, 173, 80), -- Interface accent color
	CloseDistance = 20, -- Distance when the GUI automatically closes
	
	Level = 1, -- Level which items can't be crafted (good if it's a level locked area)
	
	Smithery = {
		{ 
			Item = {"Tool", "Iron Pickaxe"},
			
			Recipe = {
				Statistics = {
					{"Gold", 100}
				},
				
				Material = {
					{"Iron", 15}, 
					{"Stone", 30}
				},
			},
			
			Level = 5,
			CraftMultiple = true,
		},
		{
			Item = {"Accessory", "Dark Sword"},
			
			Recipe = {
				Statistics = {
					{"Gold", 5_000}
				},
				
				Material = {
					{"Iron", 200}
				},
				
				Tool = {
					{"Cannon", 1}, {"Druid Staff", 1}
				},
				
				Accessory = {
					{"Cerulean Crown", 1}
				},
			},

			Level = 25,
			CraftMultiple = false,
		},
	},
	
	Dialogues = {
		"Don't believe everything you see.",
		"I see a little sparkle in your eyes; don't entirely know what it means.",
		"Has anyone told you that you're appreciated? You are.",
		"I hate to see people divided. Things would be easier if we all blacksmithed.",
		"It's okay to trust someone sometimes. I know I wish I heard that sooner.",
		"If you need help with idenfitying ores, let me know!",
		"Don't feel ashamed if you need to reach out to anyone.",
		"I don't see as many travelers coming around these parts anymore",
		"I'm sure you've already heard the news, I won't brief you on it.",
		"Don't be afraid to be your true self.",
		"After all, only you know what's best for yourself",
		"Don't worry, I still care.",
	},
}