local Reforge = {
	Weapon ={
		["Slimy"] = {
			ID = 1,
			Common = {
				Damage = 1,
				CritDamage = -3,
			},
			Uncommon = {
				Damage = 2,
				CritDamage = -4,
			},
			Rare = {
				Damage = 4,
				CritDamage = -5,
			},
			Epic = {
				Damage = 7,
				CritDamage = -6,
			},
			Legendary = {
				Damage = 10,
				CritDamage = -7,
			},
			Mythic = {
				Damage = 15,
				CritDamage = -9,
			},
		},
		["Shiny"] = {
			ID = 2,
			Common = {
				Damage = 1,
				CritDamage = 3,
			},
			Uncommon = {
				Damage = 2,
				CritDamage = 4,
			},
			Rare = {
				Damage = 4,
				CritDamage = 5,
			},
			Epic = {
				Damage = 7,
				CritDamage = 6,
			},
			Legendary = {
				Damage = 10,
				CritDamage = 7,
			},
			Mythic = {
				Damage = 15,
				CritDamage = 9,
			},
		},
	},
	Armor = {
		["Rough"] = {
			ID = 1,
			Common = {
				Defense = 2,
			},
			Uncommon = {
				Defense = 5,
			},
			Rare = {
				Defense = 8,
			},
			Epic = {
				Defense = 12,
			},
			Legendary = {
				Defense = 18,
			},
			Mythic = {
				Defense = 25,
			},
		}
	},
	Accessory = {
		["Woody"] = {
			ID = 1,
			Common = {
				CuttingPower = 3,
				CuttingSpeed = 3,
			},
			Uncommon = {
				CuttingPower = 5,
				CuttingSpeed = 5,
			},
			Rare = {
				CuttingPower = 8,
				CuttingSpeed = 8,
			},
			Epic = {
				CuttingPower = 12,
				CuttingSpeed = 12,
			},
			Legendary = {
				CuttingPower = 18,
				CuttingSpeed = 18,
			},
			Mythic = {
				CuttingPower = 25,
				CuttingSpeed = 25,
			},
		},
		["Flowery"] = {
			ID = 2,
			Common = {
				FarmingSpeed = 5,
				FarmingFortune = 3,
				FarmingPristine = 1,
			},
			Uncommon = {
				FarmingSpeed = 10,
				FarmingFortune = 7,
				FarmingPristine = 1,
			},
			Rare = {
				FarmingSpeed = 20,
				FarmingFortune = 10,
				FarmingPristine = 2,
			},
			Epic = {
				FarmingSpeed = 30,
				FarmingFortune = 18,
				FarmingPristine = 4,
			},
			Legendary = {
				FarmingSpeed = 40,
				FarmingFortune = 25,
				FarmingPristine = 5,
			},
			Mythic = {
				FarmingSpeed = 50,
				FarmingFortune = 40,
				FarmingPristine = 8,
			},
		},
	},
}
return Reforge
