local DS2 = require(game:GetService("ServerScriptService"):WaitForChild("DataStore2"))
local HttpServ = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ItemStorage = game:GetService("ReplicatedStorage"):WaitForChild("GameItems")

-- Combine all data stores
DS2.Combine("DATA", "StatsDS", "EquipmentInventoryDS", "ConsumableInventoryDS", "MaterialInventoryDS", "BankDS", "EquippedDS")

-- Module requires
local EquipmentFormat = require(game:GetService("ReplicatedStorage"):WaitForChild("Format"):WaitForChild("EquipmentFormat"))
local EquippedData = require(game:GetService("ReplicatedStorage"):WaitForChild("Format"):WaitForChild("EquippedData"))
local ItemDictionaryHandler = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("ItemDictionaryHandler"))
local ItemSlotHandler = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("ItemSlotHandler"))
local CopyTable = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("CopyTable"))
local ItemHandler = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("ItemHandler"))
local LevelingCalculator = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("LevelingCalculator"))

-- Constants
local SAVE_INTERVAL = 30 -- Save every 30 seconds
local MAX_QUEUE_SIZE = 5

-- Priority mapping for stats
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
		Stats = DS2("StatsDS", plr),
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
			warn(store.name .. " DS is experiencing problems")
		end
	end

	-- Load data from data stores
	local data = {
		Stats = dataStores.Stats:GetTable({1,0,0,0,0,100,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}),
		EquipmentInventory = dataStores.EquipmentInventory:Get({}),
		ConsumableInventory = dataStores.ConsumableInventory:Get({}),
		MaterialInventory = dataStores.MaterialInventory:Get({}),
		Bank = dataStores.Bank:Get({}),
		Equipped = dataStores.Equipped:GetTable({[1] = {[1]={},[2]={},[3]={},[4]={},[5]={},[6]={},[7]={},[8]={}},[2] = {[1]={},[2]={},[3]={},[4]={},[5]={},[6]={},[7]={},[8]={},[9]={}},[3] = {[1]={},[2]={},[3]={}},[4]={[1]={},[2]={}},[5]={[1]={},[2]={},[3]={}}})
	}

	-- Set player stats
	for name, value in pairs(Priority) do
		PlayerStat:SetAttribute(name, data.Stats[value])
	end

	-- Set additional stats
	local additionalStats = {"Health", "Defense", "Damage", "CritChance", "CritDamage", "Mana", "AttackSpeed", "Ferocity", "HealthRegenRate", "ManaRegenRate", "ActionBonusRate", "ActionTurn", "Speed", "Jump", "Luck", "BonusCoins", "RangedDamage", "RangedDefense", "MagicDamage", "MagicDefense", "TrueDamage", "TrueDefense", "DefenseFierce", "DodgeChance", "MissChance", "ProfessionExp", "ClassExp", "SpellExp", "HarvestSpeed", "GrowingSpeed", "FarmingFortune", "FarmingPristine", "CuttingPower", "CuttingSpeed", "ForagingFortune", "ForagingPristine", "MiningPower", "MiningSpeed", "MiningFortune", "MiningPristine", "ReelingPower", "Lure", "RareFishChance", "TreasureChance", "GemPower", "GemChance", "Refinery", "CraftingCost", "DismantlingDrop", "Duration", "Effectiveness", "CookingSpeed", "EnchantCost", "RareEnchantChance"}

	for _, stat in ipairs(additionalStats) do
		PlayerStat:SetAttribute(stat, stat == "Health" and 100 or (stat == "CritDamage" and 100 or (stat == "Mana" and 100 or (stat == "HealthRegenRate" and 100 or (stat == "ManaRegenRate" and 100 or (stat == "ActionBonusRate" and 100 or (stat == "ActionTurn" and 100 or (stat == "Speed" and 21 or 0))))))))
	end

	-- Load profession data
	local function LoadProfession()
		local professions = {"Combat", "Farming", "Foraging", "Fishing", "Mining", "Gemcrafting", "Crafting", "Alchemy", "Enchanting"}
		for _, prof in ipairs(professions) do
			local level, expLeft, nextExp = LevelingCalculator.CalculateLevel(data.Stats[Priority[prof]])
			PlayerStat:SetAttribute(prof.."Level", level)
			PlayerStat:SetAttribute(prof.."ExpLeft", expLeft)
			PlayerStat:SetAttribute(prof.."NextLevelExp", nextExp)
		end
	end
	coroutine.wrap(LoadProfession)()

	-- Load inventory items
	local function LoadInventoryItems(inventoryType)
		for _, item in pairs(data[inventoryType.."Inventory"]) do
			local itemDictionarized = ItemDictionaryHandler.DataToDictionary(item)
			ItemSlotHandler.MoveToSlot(plr, itemDictionarized)
		end
	end

	coroutine.wrap(function() LoadInventoryItems("Equipment") end)()
	coroutine.wrap(function() LoadInventoryItems("Consumable") end)()
	coroutine.wrap(function() LoadInventoryItems("Material") end)()

	-- Load bank items
	coroutine.wrap(function()
		for _, item in pairs(data.Bank) do
			local itemDictionarized = ItemDictionaryHandler.DataToDictionary(item)
			ItemSlotHandler.MoveToSlot(plr, itemDictionarized, true)
		end
	end)()

	-- Load equipped items
	coroutine.wrap(function()
		for category, items in pairs(data.Equipped) do
			if category == 1 then -- Main equipment
				for slot, item in pairs(items) do
					if next(item) ~= nil then
						local parent = PlayerInventory:WaitForChild("Equipped"):WaitForChild("Main"):WaitForChild(EquippedData[slot])
						local itemDictionarized = ItemDictionaryHandler.DataToDictionary(item)
						ItemDictionaryHandler.DictionaryToItem(itemDictionarized, parent)
					end
				end
			elseif category == 2 then -- Accessories
				for slot, item in pairs(items) do
					if next(item) ~= nil then
						local parent = PlayerInventory:WaitForChild("Equipped"):WaitForChild("Accessory"):WaitForChild("AccessorySlot_"..slot)
						local itemDictionarized = ItemDictionaryHandler.DataToDictionary(item)
						ItemDictionaryHandler.DictionaryToItem(itemDictionarized, parent)
					end
				end
			end
			-- Add similar logic for other equipment categories if needed
		end
	end)()

	-- Set up save queues
	local saveQueues = {
		Equipment = 0,
		Consumable = 0,
		Material = 0,
		Bank = 0,
		Equipped = 0
	}

	-- Function to handle item changes
	local function OnItemChanged(object, inventoryType)
		local queue = saveQueues[inventoryType]
		if queue < MAX_QUEUE_SIZE then
			saveQueues[inventoryType] = queue + 1
		end
	end

	-- Set up change listeners for inventory slots
	local function SetupInventoryListeners()
		for _, invType in ipairs({"Equipments", "Consumables", "Materials"}) do
			for i = 1, 36 do
				local slot = PlayerInventory:FindFirstChild(invType):FindFirstChild("Slot_"..i)
				slot.ChildAdded:Connect(function(child) OnItemChanged(child, invType) end)
				slot.ChildRemoved:Connect(function(child) OnItemChanged(child, invType) end)
			end
		end
	end

	SetupInventoryListeners()

	-- Set up change listeners for equipped items
	local function SetupEquippedListeners()
		for _, category in ipairs({"Main", "Accessory"}) do
			for _, slot in pairs(PlayerInventory:WaitForChild("Equipped"):WaitForChild(category):GetChildren()) do
				slot.ChildAdded:Connect(function(child) OnItemChanged(child, "Equipped") end)
				slot.ChildRemoved:Connect(function(child) OnItemChanged(child, "Equipped") end)
			end
		end
	end

	SetupEquippedListeners()

	-- Set up change listener for bank
	PlayerBank.ChildAdded:Connect(function(child) OnItemChanged(child, "Bank") end)
	PlayerBank.ChildRemoved:Connect(function(child) OnItemChanged(child, "Bank") end)

	-- Function to save data
	local function SaveData()
		for inventoryType, queue in pairs(saveQueues) do
			if queue > 0 then
				local newData = ItemSlotHandler.GetSlots(plr)[inventoryType.."Table"]
				local dataToSave = {}
				for i, v in pairs(newData) do
					dataToSave[i] = ItemDictionaryHandler.DictionaryToData(v)
				end
				dataStores[inventoryType]:Set(dataToSave)
				saveQueues[inventoryType] = 0
			end
		end

		-- Save player stats
		local newStats = {}
		for name, value in pairs(PlayerStat:GetAttributes()) do
			if Priority[name] then
				newStats[Priority[name]] = value
			end
		end
		dataStores.Stats:Set(newStats)
	end

	-- Set up periodic saving
	spawn(function()
		while true do
			wait(SAVE_INTERVAL)
			SaveData()
		end
	end)

	-- Set up saving on player leaving
	plr.PlayerRemoving:Connect(SaveData)

	-- Signal that data is loaded
	local DataLoaded = Instance.new("BoolValue", plr)
	DataLoaded.Name = "DataLoaded"
	DataLoaded.Value = true
	print(plr.Name.." has loaded.")
end

game.Players.PlayerAdded:Connect(function(plr)
	local PlayerStat = script:WaitForChild("PlayerData"):Clone()
	PlayerStat.Parent = plr

	local PlayerInventory = script:WaitForChild("Inventory"):Clone()
	PlayerInventory.Parent = plr

	local PlayerBank = script:WaitForChild("Bank"):Clone()
	PlayerBank.Parent = plr

	local NewNotifyData = Instance.new("NumberValue", game:GetService("ReplicatedStorage"):WaitForChild("PlayerDataHolder"):WaitForChild("Notify"))
	NewNotifyData.Name = plr.Name

	wait()

	LoadData(plr, PlayerStat, PlayerInventory, PlayerBank)
	ItemSlotHandler.CorrectSlotNumber(plr)
end)