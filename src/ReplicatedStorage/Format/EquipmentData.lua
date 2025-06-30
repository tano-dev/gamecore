local ItemFormat = {
	0,              -- [1] ID
	"",             -- [2] CustomName
	"",             -- [3] CustomLore
	5,              -- [4] UpgradeAttempts
	3,              -- [5] EnchantSlots
	3,              -- [6] GemSlots
	0,              -- [7] Purity
	0,              -- [8] Corruption
	0,              -- [9] UpgradeAttemptUsed
	0,              -- [10] UpgradeAttemptSuccessed
	0,              -- [11] EnchantSlotUsed
	0,              -- [12] GemSlotUsed
	0,              -- [13] Reforge
	0,              -- [14] Owner
	1,              -- [15] Locked
	0,              -- [16] CurrentSlot
	{
		[1] = {0, 0}, -- [17] Enchants
		[2] = {0, 0},
		[3] = {0, 0}
	},
	{
		[1] = 0,      -- [18] Gems
		[2] = 0,
		[3] = 0
	},
	"",             -- [19] Upgrades
	{},             -- [20] State
	0,              -- [21] Enlightment
	0,              -- [22] Aura
	0,              -- [23] NBT
}
return ItemFormat