local DS2 = require(game:GetService("ServerScriptService"):WaitForChild("DataStore2"))
local HttpServ = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ItemStorage = game:GetService("ReplicatedStorage"):WaitForChild("GameItems")

-- Combine data stores
DS2.Combine("DATA", "StatsDS", "EquipmentInventoryDS", "ConsumableInventoryDS", "MaterialInventoryDS", "BankDS", "EquippedDS")

-- Require modules
local modules = {
	EquipmentFormat = require(game:GetService("ReplicatedStorage").Format.EquipmentFormat),
	EquippedData = require(game:GetService("ReplicatedStorage").Format.EquippedData),
	ItemDictionaryHandler = require(game:GetService("ServerStorage").Modules.ItemDictionaryHandler),
	ItemSlotHandler = require(game:GetService("ServerStorage").Modules.ItemSlotHandler),
	CopyTable = require(game:GetService("ReplicatedStorage").Modules.CopyTable),
	ItemHandler = require(game:GetService("ServerStorage").Modules.ItemHandler),
	LevelingCalculator = require(game:GetService("ReplicatedStorage").Modules.LevelingCalculator)
}

local NonSaveStats = {
	"AddictionStr", "AddictionDex", "AddictionInt", "AddictionVit", "AddictionHealth",
	"AddictionDefense", "AddictionMana", "AddictionSpeed", "AddictionJumpPower",
	"AddictionDamage", "AddictionCritChance", "AddictionCritDamage", "AddictionFerocity",
	"AddictionAttackSpeed", "AddictionHealthRegenRate", "AddictionManaRegenRate",
	"AddictionRangedDefense", "AddictionMagicDefense", "AddictionRangedAttack",
	"AddictionMagicAttack"
}

local Priority = {
	GameLevel = 1, GameExp = 2, Place = 3, Zone = 4, Playtime = 5,
	Coin = 6, Superiority = 7, CombatStatPoints = 8, CombatAssignedStatPoints = 9,
	Strength = 10, Intelligence = 11, Dexterity = 12, Vitality = 13,
	Looting = 14, Proficiency = 15, Combat = 16, Farming = 17,
	Foraging = 18, Fishing = 19, Mining = 20, Gemcrafting = 21,
	Crafting = 22, Alchemy = 23, Enchanting = 24, SelectedClass = 25,
	Advanturer = 26, Warrior = 27, Hunter = 28, Mage = 29,
	LostFairy = 100, CraftingExp = 0
}

local function LoadData(plr, PlayerStat, PlayerInventory, PlayerBank)
	local dataStores = {
		PlrStats = DS2("StatsDS", plr),
		EquipmentInventory = DS2("EquipmentInventoryDS", plr),
		ConsumableInventory = DS2("ConsumableInventoryDS", plr),
		MaterialInventory = DS2("MaterialInventoryDS", plr),
		Bank = DS2("BankDS", plr),
		Equipped = DS2("EquippedDS", plr)
	}

	-- Set backups for all data stores
	for _, store in pairs(dataStores) do
		store:SetBackup(5)
		if store:IsBackup() then
			warn(store.Name .. " DS is experiencing problems")
		end
	end

	-- Load default data
	local GetStatsDS = dataStores.PlrStats:GetTable({1,0,0,0,0,100,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0})
	local GetEquipmentInventoryDS = dataStores.EquipmentInventory:Get({})
	local GetConsumableInventoryDS = dataStores.ConsumableInventory:Get({})
	local GetMaterialInventoryDS = dataStores.MaterialInventory:Get({})
	local GetBankDS = dataStores.Bank:Get({})
	local GetEquippedDS = dataStores.Equipped:GetTable({[1] = {[1]={},[2]={},[3]={},[4]={},[5]={},[6]={},[7]={},[8]={}},[2] = {[1]={},[2]={},[3]={},[4]={},[5]={},[6]={},[7]={},[8]={},[9]={}},[3] = {[1]={},[2]={},[3]={}},[4]={[1]={},[2]={}},[5]={[1]={},[2]={},[3]={}}})

	-- Set player attributes
	for i, value in ipairs(GetStatsDS) do
		print(i,value)
		local attributeName = Priority[i]
		print(attributeName)
		if attributeName then
			PlayerStat:SetAttribute(attributeName, value)
		end
	end

	-- Set default attributes
	local defaultAttributes = {
		Health = 100, Defense = 0, Damage = 0, CritChance = 0, CritDamage = 100,
		Mana = 100, AttackSpeed = 0, Ferocity = 0, HealthRegenRate = 100,
		ManaRegenRate = 100, ActionBonusRate = 100, ActionTurn = 100,
		Speed = 21, Jump = 0, Luck = 0, BonusCoins = 0, RangedDamage = 0,
		RangedDefense = 0, MagicDamage = 0, MagicDefense = 0, TrueDamage = 0,
		TrueDefense = 0, DefenseFierce = 0, DodgeChance = 0, MissChance = 0,
		ProfessionExp = 0, ClassExp = 0, SpellExp = 0, HarvestSpeed = 0,
		GrowingSpeed = 0, FarmingFortune = 0, FarmingPristine = 0,
		CuttingPower = 0, CuttingSpeed = 0, ForagingFortune = 0,
		ForagingPristine = 0, MiningPower = 0, MiningSpeed = 0,
		MiningFortune = 0, MiningPristine = 0, ReelingPower = 0, Lure = 0,
		RareFishChance = 0, TreasureChance = 0, GemPower = 0, GemChance = 0,
		Refinery = 0, CraftingCost = 0, DismantlingDrop = 0, Duration = 0,
		Effectiveness = 0, CookingSpeed = 0, EnchantCost = 0, RareEnchantChance = 0
	}

	for name, value in pairs(defaultAttributes) do
		PlayerStat:SetAttribute(name, value)
	end

	-- Load profession data
	local function LoadProfession()
		local professions = {"Combat", "Farming", "Foraging", "Fishing", "Mining", "Gemcrafting", "Crafting", "Alchemy", "Enchanting"}
		for _, profession in ipairs(professions) do
			local level, expLeft, nextExp = modules.LevelingCalculator.CalculateLevel(GetStatsDS[Priority[profession]])
			PlayerStat:SetAttribute(profession.."Level", level)
			PlayerStat:SetAttribute(profession.."ExpLeft", expLeft)
			PlayerStat:SetAttribute(profession.."NextLevelExp", nextExp)
		end
	end
	coroutine.wrap(LoadProfession)()

	-- Load inventory items
	local function LoadInventory(inventoryType, dataStore)
		return coroutine.wrap(function()
			for _, itemData in pairs(dataStore) do
				local itemDictionary = modules.ItemDictionaryHandler.DataToDictionary(itemData)
				modules.ItemSlotHandler.MoveToSlot(plr, itemDictionary)
			end
			return true
		end)()
	end

	local LoadEquipment = LoadInventory("Equipment", GetEquipmentInventoryDS)
	local LoadConsumable = LoadInventory("Consumable", GetConsumableInventoryDS)
	local LoadMaterial = LoadInventory("Material", GetMaterialInventoryDS)
	local LoadBank = LoadInventory("Bank", GetBankDS)

	-- Load equipped items
	local LoadEquipped = coroutine.wrap(function()
		local equipSlots = {
			[1] = {"Weapon", "Offhand", "Tool", "Helmet", "Chestplate", "Boots", "Pet", "Aura"},
			[2] = {"Accessory"},
			[3] = {"Fishing"},
			[4] = {"Bow"}
		}

		for category, slots in pairs(equipSlots) do
			for i, slotName in ipairs(slots) do
				local itemData = GetEquippedDS[category][i]
				if itemData and next(itemData) then
					local parent = PlayerInventory.Equipped[category == 2 and "Accessory" or "Main"][slotName]
					local itemDictionary = modules.ItemDictionaryHandler.DataToDictionary(itemData)
					modules.ItemDictionaryHandler.DictionaryToItem(itemDictionary, parent)
				end
			end
		end
		return true
	end)()

	-- Wait for all loading to complete
	assert(LoadEquipment and LoadConsumable and LoadMaterial and LoadBank and LoadEquipped, "Failed to load all inventory data")

	local IsLoaded = true
	local DataLoaded = Instance.new("BoolValue", plr)
	DataLoaded.Name = "DataLoaded"
	DataLoaded.Value = true
	print(plr.Name .. " has loaded.")
	-- Stats Saving
	local function OnStatsAttributeChanged(attributeName)
		print(attributeName .. "stats changed")
		if Priority[attributeName] ~= nil then
			for name, value in pairs(PlayerStat:GetAttributes()) do
				if Priority[name] then
					GetStatsDS[Priority[name]] = value
				end
			end
			dataStores.PlrStats:Set(GetStatsDS)
		end 
	end

	PlayerStat.AttributeChanged:Connect(OnStatsAttributeChanged)
	-- Set up data saving
	local function SaveData()
		local EquipmentsTable, ConsumablesTable, MaterialsTable, BankTable, EquippedTable = modules.ItemSlotHandler.GetSlots(plr)

		local function SaveInventory(inventoryType, dataStore, inventoryTable)
			modules.ItemSlotHandler.CorrectSlotNumber(plr, inventoryType)
			local newData = {}
			for i, v in pairs(inventoryTable) do
				newData[i] = modules.ItemDictionaryHandler.DictionaryToData(v)
			end
			if IsLoaded then
				dataStore:Set(newData)
			end
		end

		SaveInventory(2, dataStores.EquipmentInventory, EquipmentsTable)
		SaveInventory(3, dataStores.ConsumableInventory, ConsumablesTable)
		SaveInventory(4, dataStores.MaterialInventory, MaterialsTable)
		SaveInventory(6, dataStores.Bank, BankTable)

		-- Save equipped items
		modules.ItemSlotHandler.CorrectSlotNumber(plr, 5)
		local equippedData = {
			[1] = {[1]={},[2]={},[3]={},[4]={},[5]={},[6]={},[7]={},[8]={}},
			[2] = {},
			[3] = {[1]={},[2]={},[3]={}},
			[4]={[1]={},[2]={}},
			[5]={[1]={},[2]={},[3]={}}
		}

		for category, items in pairs(EquippedTable) do
			if category == "Accessory" then
				for slot, item in pairs(items) do
					local slotNumber = tonumber(slot:match("%d+"))
					equippedData[2][slotNumber] = next(item) and modules.ItemDictionaryHandler.DictionaryToData(item) or {}
				end
			elseif category ~= "Fishing" and category ~= "Bow" then
				local slotIndex = modules.EquippedData[category]
				equippedData[1][slotIndex] = items.ID and modules.ItemDictionaryHandler.DictionaryToData(items) or {}
			end
		end

		if IsLoaded then
			dataStores.Equipped:Set(equippedData)
		end
		print("saved")
	end

	-- Set up autosave
	--local autosaveConnection
	--autosaveConnection = RunService.Heartbeat:Connect(function()
	--	SaveData()
	--end)

	-- Clean up on player leaving
	plr.AncestryChanged:Connect(function(_, parent)
		if not parent then
			SaveData()
			--autosaveConnection:Disconnect()
		end
	end)
end

game.Players.PlayerAdded:Connect(function(plr)
	local PlayerStat = script.PlayerData:Clone()
	PlayerStat.Parent = plr

	local PlayerInventory = script.Inventory:Clone()
	PlayerInventory.Parent = plr

	local PlayerBank = script.Bank:Clone()
	PlayerBank.Parent = plr

	local NewNotifyData = Instance.new("NumberValue")
	NewNotifyData.Name = plr.Name
	NewNotifyData.Parent = game:GetService("ReplicatedStorage").PlayerDataHolder.Notify

	wait()

	LoadData(plr, PlayerStat, PlayerInventory, PlayerBank)
	modules.ItemSlotHandler.CorrectSlotNumber(plr)
end)