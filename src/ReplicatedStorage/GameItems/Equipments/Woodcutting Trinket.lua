local ItemData = require(game:GetService("ReplicatedStorage"):WaitForChild("GameItems"):WaitForChild("ItemDataStogare"))
local Item = {
	--Main Stuffs
	ID = ItemData[script.Name].ID,
	Name = script.Name,
	AvailableClasses = {"Adventurer"}, --Adventurer = All
	--AvailableClasses = {"Hunter","Gamer","Alone4D"} Specfic classes
	Rarity = "Epic",
	ItemType = 1, --1 = equipment,2 = consumable,3 = material
	SubType = "Accessory", -- if ItemType == "Equipment"
	EquipmentType = "Sword",
	ItemLevel = 1,
	BaseStats = {
		CuttingSpeed = 5,
		CuttingPower = 5,
	},
	Description = "",
	Upgradable = true,--
	UpgradeAttempts = 5,-- will ignore this if Upgradable is false
	--Random Stuffs
	Dismantlable = true,
	DismantleExp = 10,
	DismantleDrops = {
		["Sword"] = {
			IsRandom = true,--Crafting won't effect IsRandom is false
			Chance = 0.8,-- Crafting won't effect, if number then yes.
			--"Guaranteed" or number
			Min = 1,-- will ignore this if IsRandom is false
			Max = 3,-- will ignore this if Chance = "Guaranteed"
			KeepStats = "All" -- on apply for equipments 
			--> All, Nil, Upgrades, Gems, Enchants
		},
	},
	BuyPrice = 250,
	SellPrice = 100,
	Locked= false,-- like soulbound
	Important = true, --will send notify when you are about to yoink it whatsoever...
	ConsumeOnUse = true, -- true/false not matter if it equipment or material
	
}
return Item