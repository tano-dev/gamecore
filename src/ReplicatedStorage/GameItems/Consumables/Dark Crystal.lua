local ItemData = require(game:GetService("ReplicatedStorage"):WaitForChild("GameItems"):WaitForChild("ItemDataStogare"))
local Item = {
	--Main Stuffs
	ID = ItemData[script.Name].ID,
	Name = script.Name,
	Rarity = "Rare",
	ItemType = 2, --1 = equipment,2 = consumable,3 = material
	SubType = "Upgrader",
	Description = "Harnessed the unstable power, it's power sometimes bring power or destruction.",
	--If Upgrader
	Modification = {
		Conditions = nil,
		AcceptType = {"All"},
		UpgradeRng = true,
		SuccessRate = 6/10,
		UpgradeRange = 10,
		OnFailRange = 3,
		UpgradeCount = 1,
		Weight = 2,
		Upgrade = {
			OnWeapon = {
				["1:4:1"] = {
					Damage = {
						["1:4"] = {Weight = 1,Value = "1:5"},
						["5:9"] = {Weight = 1,Value = "-2:7"},
						["10:10"] = {Weight = 2,Value = "5:7"},
					},
				},
				["5:6:1"] = {
					Damage = {
						["1:10"] = {Weight = 2,Value = "5:5"},
					},
					CritChance = {
						["1:9"] = {Weight = 1,Value = "2:5"},
						["10:10"] = {Weight = 2,Value = "5:5"},
					},
					CritDamage = {
						["1:9"] = {Weight = 1,Value = "5:15"},
						["10:10"] = {Weight = 2,Value = "12:12"},
					},
					Strength = {
						["1:10"] = {Weight = 1,Value = "1:2"},
					},
					Dexterity = {
						["1:10"] = {Weight = 1,Value = "1:2"},
					},
					Intelligence = {
						["1:10"] = {Weight = 1,Value = "1:2"},
					},
					Vitality = {
						["1:10"] = {Weight = 1,Value = "1:2"},
					},
				},
				["7:7:2"] = {
					Damage = {
						["1:10"] = {Weight = 2,Value = "6:6"},
					},
					CritChance = {
						["1:9"] = {Weight = 2,Value = "1:3"},
						["10:10"] = {Weight = 2,Value = "3:5"},
					},
					CritDamage = {
						["1:9"] = {Weight = 2,Value = "2:7"},
						["10:10"] = {Weight = 2,Value = "7:12"},
					},
					Strength = {
						["1:10"] = {Weight = 2,Value = "2:2"},
					},
					Dexterity = {
						["1:10"] = {Weight = 2,Value = "2:2"},
					},
					Intelligence = {
						["1:10"] = {Weight = 2,Value = "2:2"},
					},
					Vitality = {
						["1:10"] = {Weight = 2,Value = "2:2"},
					},
					RangedDamage = {
						["1:10"] = {Weight = 2,Value = "5:5"},
					},
					MagicDamage = {
						["1:10"] = {Weight = 2,Value = "5:5"},
					},
				},
				["8:8:0"] = {
					Strength = {
						["1:10"] = {Weight = 1,Value = "1:1"},
					},
					Dexterity = {
						["1:10"] = {Weight = 1,Value = "1:1"},
					},
					Intelligence = {
						["1:10"] = {Weight = 1,Value = "1:1"},
					},
					Vitality = {
						["1:10"] = {Weight = 1,Value = "1:1"},
					},
				},
				["9:10:1"] = {
					Strength = {
						["1:10"] = {Weight = 2,Value = "2:3"},
					},
					Dexterity = {
						["1:10"] = {Weight = 2,Value = "2:3"},
					},
					Intelligence = {
						["1:10"] = {Weight = 2,Value = "2:3"},
					},
					Vitality = {
						["1:10"] = {Weight = 2,Value = "2:3"},
					},
					RangedDamage = {
						["1:10"] = {Weight = 2,Value = "5:5"},
					},
					MagicDamage = {
						["1:10"] = {Weight = 2,Value = "5:5"},
					},
				},
			},
			OnChestplate = {
				["1:4:1"] = {
					Defense = {
						["1:4"] = {Weight = 1,Value = "2:5"},
						["5:10"] = {Weight = 1,Value = "-2:7"},
					},
				},
				["5:6:1"] = {
					Defense = {
						["1:10"] = {Weight = 2,Value = "6:6"},
					},
					ManaRegenRate = {
						["1:8"] = {Weight = 1,Value = "5:5"},
						["9:10"] = {Weight = 2,Value = "10:10"},
					},
					HealthRegenRate = {
						["1:8"] = {Weight = 1,Value = "5:5"},
						["9:10"] = {Weight = 2,Value = "10:10"},
					},
					Str = {
						["1:10"] = {Weight = 1,Value = "1:2"},
					},
					Dexterity = {
						["1:10"] = {Weight = 1,Value = "1:2"},
					},
					Intelligence = {
						["1:10"] = {Weight = 1,Value = "1:2"},
					},
					Vitality = {
						["1:10"] = {Weight = 1,Value = "1:2"},
					},
				},
				["7:8:0"] = {
					Str = {
						["1:10"] = {Weight = 1,Value = "1:1"},
					},
					Dexterity = {
						["1:10"] = {Weight = 1,Value = "1:1"},
					},
					Intelligence = {
						["1:10"] = {Weight = 1,Value = "1:1"},
					},
					Vitality = {
						["1:10"] = {Weight = 1,Value = "1:1"},
					},
				},
				["9:10:1"] = {
					Str = {
						["1:10"] = {Weight = 2,Value = "1:5"},
					},
					Dexterity = {
						["1:10"] = {Weight = 2,Value = "1:5"},
					},
					Intelligence = {
						["1:10"] = {Weight = 2,Value = "1:5"},
					},
					Vitality = {
						["1:10"] = {Weight = 2,Value = "1:5"},
					},
					RangedDefense = {
						["1:10"] = {Weight = 2,Value = "5:5"},
					},
					MagicDefense = {
						["1:10"] = {Weight = 2,Value = "5:5"},
					},
				},
			},
			OnArmor = {
				["1:4:1"] = {
					BaseStats = {
						["1:4"] = {Weight = 1,Value = "2:2"},
						["5:10"] = {Weight = 1,Value = "1:3"},
					},
				},
				["5:6:1"] = {
					Defense = {
						["1:10"] = {Weight = 2,Value = "6:6"},
					},
					Speed = {
						["1:8"] = {Weight = 1,Value = "1:2"},
						["9:10"] = {Weight = 2,Value = "1:3"},
					},
					Jump = {
						["1:8"] = {Weight = 1,Value = "1:2"},
						["9:10"] = {Weight = 2,Value = "1:3"},
					},
					Strength = {
						["1:10"] = {Weight = 1,Value = "1:2"},
					},
					Dexterity = {
						["1:10"] = {Weight = 1,Value = "1:2"},
					},
					Intelligence = {
						["1:10"] = {Weight = 1,Value = "1:2"},
					},
					Vitality = {
						["1:10"] = {Weight = 1,Value = "1:2"},
					},
				},
				["7:10:1"] = {
					Strength = {
						["1:10"] = {Weight = 2,Value = "1:5"},
					},
					Dexterity = {
						["1:10"] = {Weight = 2,Value = "1:5"},
					},
					Intelligence = {
						["1:10"] = {Weight = 2,Value = "1:5"},
					},
					Vitality = {
						["1:10"] = {Weight = 2,Value = "1:5"},
					},
					RangedDefense = {
						["1:10"] = {Weight = 2,Value = "5:5"},
					},
					MagicDefense = {
						["1:10"] = {Weight = 2,Value = "5:5"},
					},
				},
			},
			Successed = {
				["1:10"] = {
					SetCorruption = 1,
					Message = "The power of the crystal reached to your equipment.",
					MessageColor = Color3.fromRGB(85, 0, 255),
				},
			},
		},

		OnFail = {
			OnAll = {
				["1:1"] = {
					UpgradeSlots = 1,
				},
				["2:3"] = {
					UpgradeAttempts = 1,
				},
			},
			Failed = {
				["1:1"] = {
					Message = "The power of the crystal had destroy this upgrade slot permanently.",
					MessageColor = Color3.fromRGB(255, 0, 0),
				},
				["2:3"] = {
					Message = "The power of the crystal failed to reach your equipment.",
					MessageColor = Color3.fromRGB(255, 0, 0),
				},
				
			},
		},
	},
	--Random Stuffs
	Dismantlable = false,
	DismantleDrops = {
		["Dark Essense"] = {
			IsRandom = true,
			Chance = 1/1,-- 100%
			Min = 3,-- will ignore this if IsRandom is false
			Max = 5,
		},
	},
	BuyPrice = 0,
	SellPrice = 100,
	Stackable = false,
	StackSize = 64,
	Locked = false,-- like soulbound
	Important = true, --will send notify when you are about to yoink it whatsoever...
	ConsumeOnUse = true, -- true/false not matter if it equipment or material

}
return Item