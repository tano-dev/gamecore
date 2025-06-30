local ItemData = require(game:GetService("ReplicatedStorage"):WaitForChild("GameItems"):WaitForChild("ItemDataStogare"))
local Item = {
	--Main Stuffs
	ID = ItemData[script.Name].ID,
	Name = script.Name,
	Rarity = "Common",
	ItemType = 2, --1 = equipment,2 = consumable,3 = material
	SubType = "Bait",
	Description = "Better Bait lol.",
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
	Stackable = true,
	StackSize = 999,
	Locked = false,-- like soulbound
	Important = true, --will send notify when you are about to yoink it whatsoever...
	ConsumeOnUse = true, -- true/false not matter if it equipment or material
	
}
return Item