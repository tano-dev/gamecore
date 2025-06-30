local ItemData = require(game:GetService("ReplicatedStorage"):WaitForChild("GameItems"):WaitForChild("ItemDataStogare"))
local Item = {
	--Main Stuffs
	ID = ItemData[script.Name].ID,
	Name = script.Name,
	Rarity = "Epic",
	ItemType = 2, --1 = equipment,2 = consumable,3 = material
	SubType = "Upgrader",
	Description = "Contains huge power but unstable.Will bring huge power when success, but when it fails...",
	--If Upgrader
	Modification = {
		Conditions = nil,
		AcceptType = {"All"},
		UpgradeRng = true,
		UpgradeRange = 10,
		SuccessRate = 1/2,
		OnFailRange = 4,
		UpgradeCount = 5,
		Weight = 1,
		Upgrade = {
			OnWeapon = {
				["1:10:1"] = {
					Damage = {
						["1:3"] = {Weight = 1,Value = "10:15"},
						["4:8"] = {Weight = 1,Value = "10:10"},
						["9:10"] = {Weight = 1,Value = "-5:20"},
					},
					
				},
			},
			OnChestplate = {
				["1:10:1"] = {
					Defense = {
						["1:3"] = {Weight = 1,Value = "10:15"},
						["4:8"] = {Weight = 1,Value = "10:10"},
						["9:10"] = {Weight = 1,Value = "-5:20"},
					},

				},
			},
			OnArmor = {
				["1:10:1"] = {
					BaseStats = {
						["1:3"] = {Weight = 1,Value = "1:4"},
						["4:9"] = {Weight = 1,Value = "2:3"},
						["10:10"] = {Weight = 1,Value = "0:5"},
					},

				},
			},
			Successed = {
				["1:10"] = {
					SetCorruption = 2,
					Message = "The power of the crystal reached your equipment.",
					MessageColor = Color3.fromRGB(85, 0, 127),
				},
			},
		},

		OnFail = {
			OnAll = {
				["1:3"] = {
					UpgradeSlots = 1,
					SetCorruption = 1,
				},
				["4:4"] = {
					Destroy = true,
				},
			},
			Failed = {
				["1:3"] = {
					Message = "The power of the crystal had destroy this upgrade slot permanently.",
					MessageColor = Color3.fromRGB(255, 0, 0),
				},
				["4:4"] = {
					Message = "Your equipment was blown up by the power of the crystal.",
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
			Min = 5,-- will ignore this if IsRandom is false
			Max = 12,
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