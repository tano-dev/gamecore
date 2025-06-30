-- This script is responsible for loading player data from the DataStore
-- and initializing the player's profile with default values.
local Players = game:GetService("Players")
local RunService = game:GetService('RunService')
local ProfileStore = require(game.ServerScriptService.Library.ProfileStore)
local LevelingCalculator = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("LevelingCalculator"))
local ItemDictionaryHandler = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("ItemDictionaryHandler"))

local function DataStoreKey()
	return RunService:IsStudio() and "Studio" or  "Live"
end
-- The PROFILE_TEMPLATE table is what new profile "Profile.Data" will default to:
local PROFILE_TEMPLATE = {
	MainLevel = 1,
	MainExp = 0,
	Place = 0,
	Zone = 0,
	Playtime = 0,
	Coin = 0,
	Awakened = 0,
	CombatStatPoints = 0,
	CombatAssignedStatPoints = 0,
	Strength = 0,
	Intelligence = 0,
	Dexterity = 0,
	Vitality = 0,
	Looting  = 0,
	Proficiency = 0,
	Combat = 0,
	Farming = 0,
	Foraging = 0,
	Fishing = 0,
	Mining = 0,
	Gemcrafting = 0,
	Crafting = 0,
	Alchemy = 0,
	Enchanting = 0,
	SelectedClass = 0,
	Advanturer = 0,
	Warrior = 0,
	Hunter = 0,
	Mage = 0,
	Hair = 0,
	HairColor = 0,
	Face = 0,
	TorsoSkin = 0,
	ArmSkin = 0,
	LegSkin = 0,
	Item = {
		[1] = {},
		[2] = {},
		[3] = {},
		[4] = {},
		[5] = {},
		[6] = {},
		[7] = {},
		[8] = {},
		[9] = {},
		[10] = {},
		[11] = {},
		[12] = {},
		[13] = {},
		[14] = {},
		[15] = {},
		[16] = {},
		[17] = {},
		[18] = {},
		[19] = {},
		[20] = {},
		[21] = {},
		[22] = {},
		[23] = {},
		[24] = {},
		[25] = {}
	},
	Consumable = {
		[1] = {},
		[2] = {},
		[3] = {},
		[4] = {},
		[5] = {},
		[6] = {},
		[7] = {},
		[8] = {},
		[9] = {},
		[10] = {},
		[11] = {},
		[12] = {},
		[13] = {},
		[14] = {},
		[15] = {},
		[16] = {},
		[17] = {},
		[18] = {},
		[19] = {},
		[20] = {},
		[21] = {},
		[22] = {},
		[23] = {},
		[24] = {},
		[25] = {},
		[26] = {},
		[27] = {},
		[28] = {},
		[29] = {},
		[30] = {},
		[31] = {},
		[32] = {},
		[33] = {},
		[34] = {},
		[35] = {},
		[36] = {},
	},
	Material = {
		[1] = {},
		[2] = {},
		[3] = {},
		[4] = {},
		[5] = {},
		[6] = {},
		[7] = {},
		[8] = {},
		[9] = {},
		[10] = {},
		[11] = {},
		[12] = {},
		[13] = {},
		[14] = {},
		[15] = {},
		[16] = {},
		[17] = {},
		[18] = {},
		[19] = {},
		[20] = {},
		[21] = {},
		[22] = {},
		[23] = {},
		[24] = {},
		[25] = {},
		[26] = {},
		[27] = {},
		[28] = {},
		[29] = {},
		[30] = {},
		[31] = {},
		[32] = {},
		[33] = {},
		[34] = {},
		[35] = {},
		[36] = {},
	},
	Equipped = {
		[1] = {Weapon={},Offhand={},Tool={},Helmet={},Chestplate={},Boots={},Pet={},Aura={}}, 
		--ItemFormat = {Weapon = 1,Offhand = 2,Tool = 3,Helmet = 4,Chestplate = 5,Boots = 6,Pet = 7,Aura = 8}
		[2] = {Slot1={},Slot2={},Slot3={},Slot4={},Slot5={},Slot6={},Slot7={},Slot8={},Slot9={}},
		--Accessory = {Slot1 = {},Slot2 = {},Slot3 = {},Slot4 = {},Slot5 = {},Slot6 = {},Slot7 = {},Slot8 = {},Slot9 = {}}
		[3] = {Reel = {},Float = {},Bait={}},
		[4]={Arrow = {},BowString = {}},
		[5]={A={},B={},C={}},
		[6]={A={},B={},C={}},

	},
	Bank = {},
	Land = {},
	Quest = {},
	
}


local PlayerStore = ProfileStore.New(DataStoreKey(), PROFILE_TEMPLATE)
local Profiles: {[Player]: typeof(PlayerStore:StartSessionAsync())} = {}

local function Init(player: Player, profile: typeof(PlayerStore:StartSessionAsync()))
	local PlayerStat = script:FindFirstChild("PlayerData"):Clone()
	PlayerStat.Parent = player
	local PlayerInventory = script:WaitForChild("Inventory"):Clone()
	PlayerInventory.Parent = player
	local PlayerBank = script:WaitForChild("Bank"):Clone()
	PlayerBank.Parent = player
	local NewNotifyData = Instance.new("NumberValue")
	NewNotifyData.Parent = game:GetService("ReplicatedStorage"):WaitForChild("PlayerDataHolder"):WaitForChild("Notify")
	NewNotifyData.Name = player.Name

	PlayerStat:SetAttribute("MainLevel",profile.Data.MainLevel)
	PlayerStat:SetAttribute("MainExp",profile.Data.MainExp)
	PlayerStat:SetAttribute("Place",profile.Data.Place)
	PlayerStat:SetAttribute("Zone",profile.Data.Zone)
	PlayerStat:SetAttribute("Playtime",profile.Data.Playtime)
	PlayerStat:SetAttribute("Coin",profile.Data.Coin)
	PlayerStat:SetAttribute("Superiority",profile.Data.Awakened)
	PlayerStat:SetAttribute("CombatStatPoints",profile.Data.CombatStatPoints)
	PlayerStat:SetAttribute("CombatAssignedStatPoints",profile.Data.CombatAssignedStatPoints)
	PlayerStat:SetAttribute("Strength",profile.Data.Strength)
	PlayerStat:SetAttribute("Intelligence",profile.Data.Intelligence)
	PlayerStat:SetAttribute("Dexterity",profile.Data.Dexterity)
	PlayerStat:SetAttribute("Vitality",profile.Data.Vitality)
	PlayerStat:SetAttribute("Looting",profile.Data.Looting)
	PlayerStat:SetAttribute("Proficiency",profile.Data.Proficiency)
	PlayerStat:SetAttribute("Combat",profile.Data.Combat)
	PlayerStat:SetAttribute("Farming",profile.Data.Farming)
	PlayerStat:SetAttribute("Foraging",profile.Data.Foraging)
	PlayerStat:SetAttribute("Fishing",profile.Data.Fishing)
	PlayerStat:SetAttribute("Mining",profile.Data.Mining)
	PlayerStat:SetAttribute("Gemcrafting",profile.Data.Gemcrafting)
	PlayerStat:SetAttribute("Crafting",profile.Data.Crafting)
	PlayerStat:SetAttribute("Alchemy",profile.Data.Alchemy)
	PlayerStat:SetAttribute("Enchanting",profile.Data.Enchanting)

	PlayerStat:SetAttribute("Hair",profile.Data.Hair)
	PlayerStat:SetAttribute("HairColor",profile.Data.HairColor)
	PlayerStat:SetAttribute("Face",profile.Data.Face)
	PlayerStat:SetAttribute("TorsoSkin",profile.Data.TorsoSkin)
	PlayerStat:SetAttribute("ArmSkin",profile.Data.ArmSkin)
	PlayerStat:SetAttribute("LegSkin",profile.Data.LegSkin)

	--PlayerStat:SetAttribute("Backup1",profile.Data.
	--PlayerStat:SetAttribute("Backup2",profile.Data.
	--PlayerStat:SetAttribute("Backup3",profile.Data.
	--PlayerStat:SetAttribute("Backup4",profile.Data.
	--PlayerStat:SetAttribute("Backup5",profile.Data.
	--PlayerStat:SetAttribute("Backup6",profile.Data.
	--PlayerStat:SetAttribute("Backup7",profile.Data.

	PlayerStat:SetAttribute("SelectedClass",profile.Data.SelectedClass)
	PlayerStat:SetAttribute("Advanturer",profile.Data.Advanturer)
	PlayerStat:SetAttribute("Warrior",profile.Data.Warrior)
	PlayerStat:SetAttribute("Hunter",profile.Data.Hunter)
	PlayerStat:SetAttribute("Mage",profile.Data.Mage)

	PlayerStat:SetAttribute("Health",100)
	PlayerStat:SetAttribute("Defense",0)
	PlayerStat:SetAttribute("Damage",0)
	PlayerStat:SetAttribute("CritChance",0)
	PlayerStat:SetAttribute("CritDamage",100)
	PlayerStat:SetAttribute("Mana",100)
	PlayerStat:SetAttribute("AttackSpeed",0)
	PlayerStat:SetAttribute("Ferocity",0)
	PlayerStat:SetAttribute("HealthRegenRate",100)
	PlayerStat:SetAttribute("ManaRegenRate",100)
	PlayerStat:SetAttribute("ActionBonusRate",100)
	PlayerStat:SetAttribute("ActionTurn",100)
	PlayerStat:SetAttribute("Speed",21)
	PlayerStat:SetAttribute("Jump",0)
	PlayerStat:SetAttribute("Luck",0)
	PlayerStat:SetAttribute("BonusCoins",0)
	PlayerStat:SetAttribute("RangedDamage",0)
	PlayerStat:SetAttribute("RangedDefense",0)
	PlayerStat:SetAttribute("MagicDamage",0)
	PlayerStat:SetAttribute("MagicDefense",0)
	PlayerStat:SetAttribute("TrueDamage",0)
	PlayerStat:SetAttribute("TrueDefense",0)
	PlayerStat:SetAttribute("DefenseFierce",0)
	PlayerStat:SetAttribute("DodgeChance",0)
	PlayerStat:SetAttribute("MissChance",0)
	PlayerStat:SetAttribute("ProfessionExp",0)
	PlayerStat:SetAttribute("ClassExp",0)
	PlayerStat:SetAttribute("SpellExp",0)
	PlayerStat:SetAttribute("HarvestSpeed",0)
	PlayerStat:SetAttribute("GrowingSpeed",0)
	PlayerStat:SetAttribute("FarmingFortune",0)
	PlayerStat:SetAttribute("FarmingPristine",0)
	PlayerStat:SetAttribute("CuttingPower",0)
	PlayerStat:SetAttribute("CuttingSpeed",0)
	PlayerStat:SetAttribute("ForagingFortune",0)
	PlayerStat:SetAttribute("ForagingPristine",0)
	PlayerStat:SetAttribute("MiningPower",0)
	PlayerStat:SetAttribute("MiningSpeed",0)
	PlayerStat:SetAttribute("MiningFortune",0)
	PlayerStat:SetAttribute("MiningPristine",0)
	PlayerStat:SetAttribute("ReelingPower",0)
	PlayerStat:SetAttribute("Lure",0)
	PlayerStat:SetAttribute("RareFishChance",0)
	PlayerStat:SetAttribute("TreasureChance",0)
	PlayerStat:SetAttribute("GemPower",0)
	PlayerStat:SetAttribute("GemChance",0)
	PlayerStat:SetAttribute("Refinery",0)
	PlayerStat:SetAttribute("CraftingCost",0)
	PlayerStat:SetAttribute("DismantlingDrop",0)
	PlayerStat:SetAttribute("Duration",0)
	PlayerStat:SetAttribute("Effectiveness",0)
	PlayerStat:SetAttribute("CookingSpeed",0)
	PlayerStat:SetAttribute("EnchantCost",0)
	PlayerStat:SetAttribute("RareEnchantChance",0)
	local function LoadProfession()
		local CombatLvl, CombatExpLeft, CombatNextExp = LevelingCalculator.CalculateLevel(profile.Data.Combat)
		local FarmingLvl, FarmingExpLeft, FarmingNextExp = LevelingCalculator.CalculateLevel(profile.Data.Farming)
		local ForagingLvl, ForagingExpLeft, ForagingNextExp = LevelingCalculator.CalculateLevel(profile.Data.Foraging)
		local FishingLvl, FishingExpLeft, FishingNextExp = LevelingCalculator.CalculateLevel(profile.Data.Fishing)
		local MiningLvl, MiningExpLeft, MiningNextExp = LevelingCalculator.CalculateLevel(profile.Data.Mining)
		local GemcraftingLvl, GemcraftingExpLeft, GemcraftingNextExp = LevelingCalculator.CalculateLevel(profile.Data.Gemcrafting)
		local CraftingLvl, CraftingExpLeft, CraftingNextExp = LevelingCalculator.CalculateLevel(profile.Data.Crafting)
		local AlchemyLvl, AlchemyExpLeft, AlchemyNextExp = LevelingCalculator.CalculateLevel(profile.Data.Alchemy)
		local EnchantingLvl, EnchantingExpLeft, EnchantingNextExp = LevelingCalculator.CalculateLevel(profile.Data.Enchanting)

		--PlayerStat:SetAttribute("Combat",GetStatsDS[16])
		--PlayerStat:SetAttribute("Farming",GetStatsDS[17])
		--PlayerStat:SetAttribute("Foraging",GetStatsDS[18])
		--PlayerStat:SetAttribute("Fishing",GetStatsDS[19])
		--PlayerStat:SetAttribute("Mining",GetStatsDS[20])
		--PlayerStat:SetAttribute("Gemcrafting",GetStatsDS[21])
		--PlayerStat:SetAttribute("Crafting",GetStatsDS[22])
		--PlayerStat:SetAttribute("Alchemy",GetStatsDS[23])
		--PlayerStat:SetAttribute("Enchanting",GetStatsDS[24])

		PlayerStat:SetAttribute("CombatLevel",CombatLvl)
		PlayerStat:SetAttribute("FarmingLevel",FarmingLvl)
		PlayerStat:SetAttribute("ForagingLevel",ForagingLvl)
		PlayerStat:SetAttribute("FishingLevel",FishingLvl)
		PlayerStat:SetAttribute("MiningLevel",MiningLvl)
		PlayerStat:SetAttribute("GemcraftingLevel",GemcraftingLvl)
		PlayerStat:SetAttribute("CraftingLevel",CraftingLvl)
		PlayerStat:SetAttribute("AlchemyLevel",AlchemyLvl)
		PlayerStat:SetAttribute("EnchantingLevel",EnchantingLvl)

		PlayerStat:SetAttribute("CombatExpLeft",CombatExpLeft)
		PlayerStat:SetAttribute("FarmingExpLeft",FarmingExpLeft)
		PlayerStat:SetAttribute("ForagingExpLeft",ForagingExpLeft)
		PlayerStat:SetAttribute("FishingExpLeft",FishingExpLeft)
		PlayerStat:SetAttribute("MiningExpLeft",MiningExpLeft)
		PlayerStat:SetAttribute("GemcraftingExpLeft",GemcraftingExpLeft)
		PlayerStat:SetAttribute("CraftingExpLeft",CraftingExpLeft)
		PlayerStat:SetAttribute("AlchemyExpLeft",AlchemyExpLeft)
		PlayerStat:SetAttribute("EnchantingExpLeft",EnchantingExpLeft)

		PlayerStat:SetAttribute("CombatNextLevelExp",CombatNextExp)
		PlayerStat:SetAttribute("FarmingNextLevelExp",FarmingNextExp)
		PlayerStat:SetAttribute("ForagingNextLevelExp",ForagingNextExp)
		PlayerStat:SetAttribute("FishingNextLevelExp",FishingNextExp)
		PlayerStat:SetAttribute("MiningNextLevelExp",MiningNextExp)
		PlayerStat:SetAttribute("GemcraftingNextLevelExp",GemcraftingNextExp)
		PlayerStat:SetAttribute("CraftingNextLevelExp",CraftingNextExp)
		PlayerStat:SetAttribute("AlchemyNextLevelExp",AlchemyNextExp)
		PlayerStat:SetAttribute("EnchantingNextLevelExp",EnchantingNextExp)
	end
	coroutine.wrap(LoadProfession)()

	local function OnStatsAttributeChanged(attributeName)
		print(attributeName.."stats changed")
		if PROFILE_TEMPLATE[attributeName] ~= nil then
			print(attributeName, true)
			profile.Data[attributeName] = PlayerStat:GetAttribute(attributeName)
		end 
	end
	PlayerStat.AttributeChanged:Connect(OnStatsAttributeChanged)

	local LoadEquipment = coroutine.wrap(function()
		for _,v in pairs(profile.Data.Item) do
			if next(v) ~= nil then
				ItemDictionaryHandler.DataToItem(player,v)
			end
		end
		return true
	end)()
	local LoadConsumable = coroutine.wrap(function()
		for _,v in pairs(profile.Data.Consumable) do
			if next(v) ~= nil then
				ItemDictionaryHandler.DataToItem(player,v)
			end
		end
		return true
	end)()
	local LoadMaterial = coroutine.wrap(function()
		for _,v in pairs(profile.Data.Material) do
			if next(v) ~= nil then
				ItemDictionaryHandler.DataToItem(player,v)
			end
		end
		return true
	end)()
	local LoadBank = coroutine.wrap(function()
		for _,v in pairs(profile.Data.Bank) do
			if next(v) ~= nil then
				ItemDictionaryHandler.DataToItem(player,v)
			end
		end
		return true
	end)()
	print("Loading Equipment")
	print(LoadEquipment,LoadConsumable,LoadMaterial,LoadBank)
	local function LinkItem(Object,indexSlot)
		print("linked item")
		--isAdded = isAdded or false
		-- local indexSlot = tonumber(Object.Parent.Name:split("_")[2])
		-- print(indexSlot)
		local function FireEvent()
			print(indexSlot)
			print(Object)
			profile.Data.Item[indexSlot] = ItemDictionaryHandler.ItemToData(Object)
		end
		local Itemconnection
		local Upgradeconnection
		local Gemconnection
		local Enchantconnection
		local Upgradeconnection_V
		local Gemconnection_V
		local Enchantconnection_V
		local Parentconnection
		Itemconnection =  Object.AttributeChanged:Connect(FireEvent)
		Upgradeconnection = Object:FindFirstChild("Upgrades").AttributeChanged:Connect(FireEvent)
		Upgradeconnection_V = Object:FindFirstChild("Upgrades"):GetPropertyChangedSignal("Value"):Connect(FireEvent)
		Gemconnection = Object:FindFirstChild("Gems").AttributeChanged:Connect(FireEvent)
		Gemconnection_V = Object:FindFirstChild("Gems"):GetPropertyChangedSignal("Value"):Connect(FireEvent)
		Enchantconnection = Object:FindFirstChild("Enchants").AttributeChanged:Connect(FireEvent)
		Enchantconnection_V = Object:FindFirstChild("Enchants"):GetPropertyChangedSignal("Value"):Connect(FireEvent)
		Parentconnection = PlayerInventory:FindFirstChild("Equipments"):FindFirstChild("Slot_"..indexSlot).ChildRemoved:Connect(function()
			print("disconnecting")
			Itemconnection:Disconnect()
			Upgradeconnection:Disconnect()
			Upgradeconnection_V:Disconnect()
			Gemconnection:Disconnect()
			Gemconnection_V:Disconnect()
			Enchantconnection:Disconnect()
			Enchantconnection_V:Disconnect()
			Parentconnection:Disconnect()
		end)
	end
	
	local function LinkConsumable(Object,indexSlot)
		print("linked consumable")
		--isAdded = isAdded or false
		-- local indexSlot = tonumber(Object.Parent.Name:split("_")[2])
		-- print(indexSlot)
		local function FireEvent()
			print(indexSlot)
			print(Object)
			profile.Data.Consumable[indexSlot] = ItemDictionaryHandler.ItemToData(Object)
		end
		local Itemconnection
		local Parentconnection
		Itemconnection =  Object.AttributeChanged:Connect(FireEvent)
		Parentconnection = PlayerInventory:FindFirstChild("Consumables"):FindFirstChild("Slot_"..indexSlot).ChildRemoved:Connect(function()
			print("disconnecting consumable")
			Itemconnection:Disconnect()
			Parentconnection:Disconnect()
		end)
	end
	
	local function LinkMaterial(Object,indexSlot)
		print("linked material")
		--isAdded = isAdded or false
		-- local indexSlot = tonumber(Object.Parent.Name:split("_")[2])
		print(indexSlot)
		local function FireEvent()
			print(indexSlot)
			print(Object)
			profile.Data.Material[indexSlot] = ItemDictionaryHandler.ItemToData(Object)
		end
		local Itemconnection
		local Parentconnection
		Itemconnection =  Object.AttributeChanged:Connect(FireEvent)
		Parentconnection = PlayerInventory:FindFirstChild("Materials"):FindFirstChild("Slot_"..indexSlot).ChildRemoved:Connect(function()
			print("disconnecting material")
			Itemconnection:Disconnect()
			Parentconnection:Disconnect()
		end)
	end
	
	for i = 1,36 do
		--wait()
		if i < 26 then
			if PlayerInventory:FindFirstChild("Equipments"):FindFirstChild("Slot_"..i):FindFirstChildOfClass("NumberValue") then
				LinkItem(PlayerInventory:FindFirstChild("Equipments"):FindFirstChild("Slot_"..i):FindFirstChildOfClass("NumberValue"),i)
			end
			PlayerInventory:FindFirstChild("Equipments"):FindFirstChild("Slot_"..i).ChildAdded:Connect(function(objectAdded) 
				local indexSlot = i
				print(objectAdded)
				objectAdded:SetAttribute("CurrentSlot",indexSlot)
				print(indexSlot)
				profile.Data.Item[indexSlot] = ItemDictionaryHandler.ItemToData(objectAdded)
				print(ItemDictionaryHandler.ItemToData(objectAdded))
				LinkItem(objectAdded,i)
			end)
			PlayerInventory:FindFirstChild("Equipments"):FindFirstChild("Slot_"..i).ChildRemoved:Connect(function()
				local indexSlot = i
				print(indexSlot)
				profile.Data.Item[indexSlot] = {}
			end)
		end

		if PlayerInventory:FindFirstChild("Consumables"):FindFirstChild("Slot_"..i):FindFirstChildOfClass("NumberValue") then
			LinkConsumable(PlayerInventory:FindFirstChild("Consumables"):FindFirstChild("Slot_"..i):FindFirstChildOfClass("NumberValue"),i)
		end
		PlayerInventory:FindFirstChild("Consumables"):FindFirstChild("Slot_"..i).ChildAdded:Connect(function(objectAdded) 
			local indexSlot = i
			print(objectAdded)
			objectAdded:SetAttribute("CurrentSlot",indexSlot)
			print(indexSlot)
			profile.Data.Consumable[indexSlot] = ItemDictionaryHandler.ItemToData(objectAdded)
			print(ItemDictionaryHandler.ItemToData(objectAdded))
			LinkConsumable(objectAdded,i)
		end)
		PlayerInventory:FindFirstChild("Consumables"):FindFirstChild("Slot_"..i).ChildRemoved:Connect(function()
			local indexSlot = i
			print(indexSlot)
			profile.Data.Consumable[indexSlot] = {}
		end)
		
		if PlayerInventory:FindFirstChild("Materials"):FindFirstChild("Slot_"..i):FindFirstChildOfClass("NumberValue") then
			LinkMaterial(PlayerInventory:FindFirstChild("Materials"):FindFirstChild("Slot_"..i):FindFirstChildOfClass("NumberValue"),i)
		end

		PlayerInventory:FindFirstChild("Materials"):FindFirstChild("Slot_"..i).ChildAdded:Connect(function(objectAdded) 
			local indexSlot = i
			print(objectAdded)
			objectAdded:SetAttribute("CurrentSlot",indexSlot)
			print(indexSlot)
			profile.Data.Material[indexSlot] = ItemDictionaryHandler.ItemToData(objectAdded)
			print(ItemDictionaryHandler.ItemToData(objectAdded))
			LinkMaterial(objectAdded,i)
		end)
		PlayerInventory:FindFirstChild("Materials"):FindFirstChild("Slot_"..i).ChildRemoved:Connect(function()
			local indexSlot = i
			print(indexSlot)
			profile.Data.Material[indexSlot] = {}
		end)
	end
	
	


	-- local NewNotifyData = Instance.new("NumberValue")
	-- NewNotifyData.Parent = game:GetService("ReplicatedStorage"):WaitForChild("PlayerDataHolder"):WaitForChild("Notify")
	-- NewNotifyData.Name = player.Name
end

local function PlayerAdded(player)

	-- Start a profile session for this player's data:

	local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})

	-- Handling new profile session or failure to start it:

	if profile ~= nil then

		profile:AddUserId(player.UserId) -- GDPR compliance
		profile:Reconcile() -- Fill in missing variables from PROFILE_TEMPLATE (optional)

		profile.OnSessionEnd:Connect(function()
			Profiles[player] = nil
			player:Kick(`Profile session end - Please rejoin`)
		end)

		if player.Parent == Players then
			Profiles[player] = profile
			print(`Profile loaded for {player.DisplayName}!`)
			-- EXAMPLE: Grant the player 100 coins for joining:
			Init(player, profile)
			-- You should set "Cash" in PROFILE_TEMPLATE and use "Profile:Reconcile()",
			-- otherwise you'll have to check whether "Data.Cash" is not nil
		else
			-- The player has left before the profile session started
			profile:EndSession()
		end

	else
		-- This condition should only happen when the Roblox server is shutting down
		player:Kick(`Profile load fail - Please rejoin`)
	end

end

-- In case Players have joined the server earlier than this script ran:
for _, player in Players:GetPlayers() do
	task.spawn(PlayerAdded, player)
end

Players.PlayerAdded:Connect(PlayerAdded)

Players.PlayerRemoving:Connect(function(player)
	local profile = Profiles[player]
	if profile ~= nil then
		profile:EndSession()
	end
end)

