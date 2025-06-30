local ItemData = require(game:GetService("ReplicatedStorage"):WaitForChild("GameItems"):WaitForChild("ItemDataStogare"))
local Item = {
	--Main Stuffs
	ID = ItemData[script.Name].ID,
	Name = script.Name,
	Rarity = "Common",
	ItemType = 2, --1 = equipment,2 = consumable,3 = material
	SubType = "Upgrader",
	Description = "Help your equipment less pathetic.",
	--If Upgrader
	Modification = {
		Conditions = {"NotUpgraded_20_100"},
		AcceptType = {"All"},
		UpgradeRng = false,
		UpgradeRange = 10,
		SuccessRate = 0,
		OnFailRange = 1,
		UpgradeCount =1,
		Weight = 1,
		Upgrade = {
			OnAll = {
				["1:1:0"] = {
					BaseStats = {
						["1:1"] = {Weight= 1,LevelScale="7:75"}},
				},
			},
			Successed = {
				["1:1"] = {
					UpgradeSlots = -999,
					Message = "Your equipment successfully absorped the power of the crystal.",
					MessageColor = Color3.fromRGB(0, 255, 255),
				},
			},
		},
		OnFail = {
			OnAll = {
				["1:1"] = {
					UpgradeSlots = 1,
				},
			},
				
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
		["Name Items"] = {
			IsRandom = false,
			Chance = 1/1,-- 100%
			Min = 0,-- will ignore this if IsRandom is false
			Max = 1,
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