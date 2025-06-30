local ItemData = require(game:GetService("ReplicatedStorage"):WaitForChild("GameItems"):WaitForChild("ItemDataStogare"))
local Item = {
	--Main Stuffs
	ID = ItemData[script.Name].ID,
	Name = script.Name,
	Rarity = "Uncommon",
	ItemType = 2, --1 = equipment,2 = consumable,3 = material
	SubType = "Upgrader",
	Description = "Clean all failed upgrades.",
	--If Upgrader
	Modification = {
		Conditions = {"Purity_-10_95"},
		AcceptType = {"All"},
		UpgradeRng = false,
		UpgradeRange = 10,
		SuccessRate = 1,
		OnFailRange = 1,
		UpgradeCount = 0,
		Weight = 1,
		Upgrade = {
			OnAll = {
				["1:1:1"] = {
					ResetFailedUpgrades = {
						["1:1"] = {Weight = 1,Value = true},
					},
					
				},
			},
			Successed = {
				["1:1"] = {
					SetPurity = 1,
					Message = "The power of the crystal reached your equipment and clean all of your upgrades.",
					MessageColor = Color3.fromRGB(255, 255, 255),
				},
			},
		},

		OnFail = {
			OnAll = {},
			Failed = {
				["1:1"] = {
					Message = "The power of the crystal failed to reach your equipment.",
					MessageColor = Color3.fromRGB(255, 0, 0),
				},
			},
		},
	},
	--Random Stuffs
	Dismantlable = false,
	DismantleDrops = {
		["Light Essense"] = {
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