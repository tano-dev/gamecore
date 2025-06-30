local ItemFormat = {
	ID = 0,
	CustomName = "",
	CustomLore = "",
	UpgradeAttempts = 5,
	EnchantSlots = 3,
	GemSlots = 3,
	Purity = 0,
	Corruption = 0,
	UpgradeAttemptUsed = 0,
	UpgradeAttemptSuccessed = 0,
	EnchantSlotUsed = 0,
	GemSlotUsed = 0,
	Reforge = 0,
	Owner = 0,
	Locked = 0,--1 == no, 2 == yes, 3 == only owner of that item
	CurrentSlot = 0, -- if > 16 then it will go to Stogare or somewhere else..
	--ID = 0 means nil
	Enchants = {
		Slot1 = {ID = 0,Level = 0},
		Slot2 = {ID = 0,Level = 0},
		Slot3 = {ID = 0,Level = 0},
	},
	Gems = {
		Slot1 = {ID = 0},
		Slot2 = {ID = 0},
		Slot3 = {ID = 0},
	},
	Upgrades = {
		--Damage = 3,
		--CritChance = 1,
		--RangedDamage = 2,
	},
	State = "",
	Enlightment = 0,
	Aura = 0,
	NBT = 0,
}
return ItemFormat
