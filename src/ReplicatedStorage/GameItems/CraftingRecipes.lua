--[[ Requirements
SkillName = [Number]
> Will add more in the future

]]


local CraftingRecipes = {
	-- "Nil" or 5_1 (5 per level cap at 1)
	["Sword"] = {
		Requirements = {},
		Materials = {
			["Wood"] = {Conditions = "5_1",Amounts = 5},
			["Iron"] = {Conditions = "10_1",Amounts = 3},
			["Steel"] = {Conditions = "10_1",Amounts = 3},
		},
		ExpGains = 10,
	},
	["Steel Sword"] = {
		Requirements = {},
		Materials = {
			["Wood"] = {Conditions = "5_1",Amounts = 5},
		},
		Main = "Sword",-- will carry the stats also the main ingredient
		ExpGains = 10,
	},
	["Enchanted Wood"] = {
		Requirements = {Crafting = 5},
		Materials = {
			["Wood"] = {Conditions = "2_75",Amounts = 99},
		},
		ExpGains = 10,
	},
	["Dark Crystal"] = {
		Requirements = {Crafting = 10},
		Materials = {
			["Dark Essense"] = {Conditions = "Nil",Amounts = 5},
		},
		ExpGains = 10,
	},
	["Unstable Power Crystal"] = {
		Requirements = {Crafting = 12},
		Materials = {
			["Dark Essense"] = {Conditions = "Nil",Amounts = 10},
		},
		ExpGains = 10,
	},
}

return CraftingRecipes
