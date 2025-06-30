local DS2 = require(game:GetService("ServerScriptService"):WaitForChild("DataStore2"))
local HttpServ = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ItemStorage = game:GetService("ReplicatedStorage"):WaitForChild("GameItems")
DS2.Combine("DATA", "StatsDS","EquipmentInventoryDS","ConsumableInventoryDS","MaterialInventoryDS","BankDS","EquippedDS")
--Modules calling
local EquipmentFormat = require(game:GetService("ReplicatedStorage"):WaitForChild("Format"):WaitForChild("EquipmentFormat"))
local EquippedData = require(game:GetService("ReplicatedStorage"):WaitForChild("Format"):WaitForChild("EquippedData"))
local ItemDictionaryHandler = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("ItemDictionaryHandler"))
local ItemSlotHandler = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("ItemSlotHandler"))
local CopyTable = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("CopyTable"))
local ItemHandler = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("ItemHandler"))
--local ItemType = require(game:GetService("ReplicatedStorage"):WaitForChild("GameItems"):WaitForChild("ItemType"))
local LevelingCalculator = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("LevelingCalculator"))
local NonSaveStats = {"AddictionStr","AddictionDex","AddictionInt","AddictionVit","AddictionHealth","AddictionDefense","AddictionMana","AddictionSpeed","AddictionJumpPower","AddictionDamage","AddictionCritChance","AddictionCritDamage","AddictionFerocity","AddictionAttackSpeed","AddictionHealthRegenRate","AddictionManaRegenRate","AddictionRangedDefense","AddictionMagicDefense","AddictionRangedAttack","AddictionMagicAttack"}
--Thứ tự
--{1,0,0,0,0,100,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0}
local Priority = {
	GameLevel = 1,
	GameExp = 2,
	Place = 3,
	Zone = 4,
	Playtime = 5,
	Coin = 6,
	Superiority = 7,
	CombatStatPoints = 8,
	CombatAssignedStatPoints = 9,
	Strength = 10,
	Intelligence = 11,
	Dexterity = 12,
	Vitality = 13,
	Looting  = 14,
	Proficiency = 15,
	Combat = 16,
	Farming = 17,
	Foraging = 18,
	Fishing = 19,
	Mining = 20,
	Gemcrafting = 21,
	Crafting = 22,
	Alchemy = 23,
	Enchanting = 24,
	SelectedClass = 25,
	Advanturer = 26,
	Warrior = 27,
	Hunter = 28,
	Mage = 29,
	--Health = 0,
	--Defense = 0,
	--Damage = 0,
	--CritChance = 0,
	--CritDamage = 0,
	--Mana = 0,
	--AttackSpeed = 0,
	--Ferocity = 0,
	--HealthRegenRate = 0,
	--ManaRegenRate = 0,
	--Speed = 0,
	--JumpPower = 0,
	--RangedDefense = 0,
	--MagicDefense = 0,
	--RangedAttack = 0,
	--MagicAttack = 0,
	LostFairy = 100,
	CraftingExp = 0,
}
--local EquippedTableFormat = {[1] = {[1]={},[2]={},[3]={},[4]={},[5]={},[6]={},[7]={},[8]={}},[2] = {},[3] = {[1]={},[2]={},[3]={}},[4]={[1]={},[2]={}},[5]={[1]={},[2]={},[3]={}}}
--Dexterity


LoadData = function(plr,PlayerStat,PlayerInventory,PlayerBank)
	-- Data Calling
	local PlrStats = DS2("StatsDS",plr)
	local EquipmentInventory = DS2("EquipmentInventoryDS",plr)
	local ConsumableInventory = DS2("ConsumableInventoryDS",plr)
	local MaterialInventory = DS2("MaterialInventoryDS",plr)
	local Bank = DS2("BankDS",plr)
	local Equipped = DS2("EquippedDS",plr)
	local NewSword = ItemDictionaryHandler.ItemToDictionary(script:WaitForChild("Sword"))
	NewSword.Owner = plr.UserId
	local NewSwordButData = ItemDictionaryHandler.DictionaryToData(NewSword)
	local IsLoaded = false
	PlrStats:SetBackup(5)
	EquipmentInventory:SetBackup(5)
	ConsumableInventory:SetBackup(5)
	MaterialInventory:SetBackup(5)
	Bank:SetBackup(5)
	Equipped:SetBackup(5)
	--Data store backup checking
	if PlrStats:IsBackup() == true then
		warn("Stats DS is experiencing problems")
	end
	if EquipmentInventory:IsBackup() == true then
		warn("EquipmentInventory DS is experiencing problems")
	end
	if ConsumableInventory:IsBackup() == true then
		warn("ConsumableInventory DS is experiencing problems")
	end
	if MaterialInventory:IsBackup() == true then
		warn("MaterialInventory DS is experiencing problems")
	end
	if Bank:IsBackup() == true then
		warn("Bank DS is experiencing problems")
	end
	if Equipped:IsBackup() == true then
		warn("Equipped DS is experiencing problems")
	end
	--Default data
	local GetStatsDS = PlrStats:GetTable({1,0,0,0,0,100,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0})
	local GetEquipmentInventoryDS = EquipmentInventory:Get({})
	local GetConsumableInventoryDS = ConsumableInventory:Get({})
	local GetMaterialInventoryDS = MaterialInventory:Get({})
	local GetBankDS = Bank:Get({})
	local GetEquippedDS = Equipped:GetTable({[1] = {[1]={},[2]={},[3]={},[4]={},[5]={},[6]={},[7]={},[8]={}},[2] = {[1]={},[2]={},[3]={},[4]={},[5]={},[6]={},[7]={},[8]={},[9]={}},[3] = {[1]={},[2]={},[3]={}},[4]={[1]={},[2]={}},[5]={[1]={},[2]={},[3]={}}})
	local EquipmentsQueue = 0
	local ConsumablesQueue = 0
	local MaterialsQueue = 0
	local BankQueue = 0
	local EquippedQueue = 0
	--Stats
	--print(GetStatsDS)
	--GetEquippedDS[2] = {}
	print(DS2("DATA",plr)["value"])
	--print(HttpServ:JSONEncode(DS2("DATA",plr)["value"]))
	--print("GetStatsDS")
	PlayerStat:SetAttribute("MainLevel",GetStatsDS[1])
	PlayerStat:SetAttribute("MainExp",GetStatsDS[2])
	PlayerStat:SetAttribute("Place",GetStatsDS[3])
	PlayerStat:SetAttribute("Zone",GetStatsDS[4])
	PlayerStat:SetAttribute("Playtime",GetStatsDS[5])
	PlayerStat:SetAttribute("Coin",GetStatsDS[6])
	PlayerStat:SetAttribute("Superiority",GetStatsDS[7])
	PlayerStat:SetAttribute("CombatStatPoints",GetStatsDS[8])
	PlayerStat:SetAttribute("CombatAssignedStatPoints",GetStatsDS[9])
	PlayerStat:SetAttribute("Strength",GetStatsDS[10])
	PlayerStat:SetAttribute("Intelligence",GetStatsDS[11])
	PlayerStat:SetAttribute("Dexterity",GetStatsDS[12])
	PlayerStat:SetAttribute("Vitality",GetStatsDS[13])
	PlayerStat:SetAttribute("Looting",GetStatsDS[14])
	PlayerStat:SetAttribute("Proficiency",GetStatsDS[15])
	PlayerStat:SetAttribute("Combat",GetStatsDS[16])
	PlayerStat:SetAttribute("Farming",GetStatsDS[17])
	PlayerStat:SetAttribute("Foraging",GetStatsDS[18])
	PlayerStat:SetAttribute("Fishing",GetStatsDS[19])
	PlayerStat:SetAttribute("Mining",GetStatsDS[20])
	PlayerStat:SetAttribute("Gemcrafting",GetStatsDS[21])
	PlayerStat:SetAttribute("Crafting",GetStatsDS[22])
	PlayerStat:SetAttribute("Alchemy",GetStatsDS[23])
	PlayerStat:SetAttribute("Enchanting",GetStatsDS[24])
	
	PlayerStat:SetAttribute("Hair",GetStatsDS[25])
	PlayerStat:SetAttribute("HairColor",GetStatsDS[26])
	PlayerStat:SetAttribute("Face",GetStatsDS[27])
	PlayerStat:SetAttribute("TorsoSkin",GetStatsDS[28])
	PlayerStat:SetAttribute("ArmSkin",GetStatsDS[29])
	PlayerStat:SetAttribute("LegSkin",GetStatsDS[30])
	
	PlayerStat:SetAttribute("Backup1",GetStatsDS[31])
	PlayerStat:SetAttribute("Backup2",GetStatsDS[32])
	PlayerStat:SetAttribute("Backup3",GetStatsDS[33])
	PlayerStat:SetAttribute("Backup4",GetStatsDS[34])
	PlayerStat:SetAttribute("Backup5",GetStatsDS[35])
	PlayerStat:SetAttribute("Backup6",GetStatsDS[36])
	PlayerStat:SetAttribute("Backup7",GetStatsDS[37])
	
	PlayerStat:SetAttribute("SelectedClass",GetStatsDS[38])
	PlayerStat:SetAttribute("Advanturer",GetStatsDS[39])
	PlayerStat:SetAttribute("Warrior",GetStatsDS[40])
	PlayerStat:SetAttribute("Hunter",GetStatsDS[41])
	PlayerStat:SetAttribute("Mage",GetStatsDS[42])

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
	--LevelingStuff
	local function LoadProfession()
		local CombatLvl, CombatExpLeft, CombatNextExp = LevelingCalculator.CalculateLevel(GetStatsDS[16])
		local FarmingLvl, FarmingExpLeft, FarmingNextExp = LevelingCalculator.CalculateLevel(GetStatsDS[17])
		local ForagingLvl, ForagingExpLeft, ForagingNextExp = LevelingCalculator.CalculateLevel(GetStatsDS[18])
		local FishingLvl, FishingExpLeft, FishingNextExp = LevelingCalculator.CalculateLevel(GetStatsDS[19])
		local MiningLvl, MiningExpLeft, MiningNextExp = LevelingCalculator.CalculateLevel(GetStatsDS[20])
		local GemcraftingLvl, GemcraftingExpLeft, GemcraftingNextExp = LevelingCalculator.CalculateLevel(GetStatsDS[21])
		local CraftingLvl, CraftingExpLeft, CraftingNextExp = LevelingCalculator.CalculateLevel(GetStatsDS[22])
		local AlchemyLvl, AlchemyExpLeft, AlchemyNextExp = LevelingCalculator.CalculateLevel(GetStatsDS[23])
		local EnchantingLvl, EnchantingExpLeft, EnchantingNextExp = LevelingCalculator.CalculateLevel(GetStatsDS[24])

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
	
	local LoadEquipment = coroutine.wrap(function()
		for i,v in pairs(GetEquipmentInventoryDS) do
			--local ItemDictionarized = ItemDictionaryHandler.DataToDictionary(v)
			--print(ItemDictionarized)
			--ItemSlotHandler.MoveToSlot(plr,ItemDictionarized)
			ItemDictionaryHandler.DataToItem(plr,v)
		end
		return true
	end)()
	local LoadConsumable = coroutine.wrap(function()
		for i,v in pairs(GetConsumableInventoryDS) do
			--local ItemDictionarized = ItemDictionaryHandler.DataToDictionary(v)
			--print(ItemDictionarized)
			--ItemSlotHandler.MoveToSlot(plr,ItemDictionarized)
			ItemDictionaryHandler.DataToItem(plr,v)
		end
		return true
	end)()
	local LoadMaterial = coroutine.wrap(function()
		for i,v in pairs(GetMaterialInventoryDS) do
			--local ItemDictionarized = ItemDictionaryHandler.DataToDictionary(v)
			--print(ItemDictionarized)
			--ItemSlotHandler.MoveToSlot(plr,ItemDictionarized)
			ItemDictionaryHandler.DataToItem(plr,v)
		end
		return true
	end)()
	local LoadBank = coroutine.wrap(function()
		for i,v in pairs(GetBankDS) do
			ItemDictionaryHandler.DataToItem(plr,v)
		end
		return true
	end)()

	local LoadEquipped = coroutine.wrap(function()
		for i,v in pairs(GetEquippedDS[1]) do
			local parent 
			if i == 1 then
				parent = PlayerInventory:WaitForChild("Equipped"):WaitForChild("Main"):WaitForChild("Weapon")
			elseif i == 2 then
				parent = PlayerInventory:WaitForChild("Equipped"):WaitForChild("Main"):WaitForChild("Offhand")
			elseif i == 3 then
				parent = PlayerInventory:WaitForChild("Equipped"):WaitForChild("Main"):WaitForChild("Tool")
			elseif i == 4 then
				parent = PlayerInventory:WaitForChild("Equipped"):WaitForChild("Main"):WaitForChild("Helmet")
			elseif i == 5 then
				parent = PlayerInventory:WaitForChild("Equipped"):WaitForChild("Main"):WaitForChild("Chestplate")
			elseif i == 6 then
				parent = PlayerInventory:WaitForChild("Equipped"):WaitForChild("Main"):WaitForChild("Boots")
			elseif i == 7 then
				parent = PlayerInventory:WaitForChild("Equipped"):WaitForChild("Main"):WaitForChild("Pet")
			elseif i == 8 then
				parent = PlayerInventory:WaitForChild("Equipped"):WaitForChild("Main"):WaitForChild("Aura")
			end
			if #v ~= 0 then
				local ItemDictionarized = ItemDictionaryHandler.DataToDictionary(v)
				print(ItemDictionarized)
				ItemDictionaryHandler.DictionaryToItem(ItemDictionarized,parent)
			end
		end
		print(GetEquippedDS[2])
		for i,v in pairs(GetEquippedDS[2]) do
			print(i)
			print(v)
			local parent = PlayerInventory:WaitForChild("Equipped"):WaitForChild("Accessory"):WaitForChild("AccessorySlot_"..i)
			if v[1] ~= nil then
				local ItemDictionarized = ItemDictionaryHandler.DataToDictionary(v)
				ItemDictionaryHandler.DictionaryToItem(ItemDictionarized,parent)
			end
		end
		for i,v in pairs(GetEquippedDS[3]) do
			local parent = PlayerInventory:WaitForChild("Equipped"):WaitForChild("Fishing"):WaitForChild("Slot_"..i)
			if v[1] ~= nil then
				local ItemDictionarized = ItemDictionaryHandler.DataToDictionary(v)
				ItemDictionaryHandler.DictionaryToItem(ItemDictionarized,parent)
			end
		end
		for i,v in pairs(GetEquippedDS[4]) do
			local parent = PlayerInventory:WaitForChild("Equipped"):WaitForChild("Bow"):WaitForChild("Slot_"..i)
			if v[1] ~= nil then
				local ItemDictionarized = ItemDictionaryHandler.DataToDictionary(v)
				ItemDictionaryHandler.DictionaryToItem(ItemDictionarized,parent)
			end
		end
		return true
	end)()
	print(LoadEquipment,LoadConsumable,LoadMaterial,LoadBank,LoadEquipped)
	--Adding checking if dataloaded or not
	
	IsLoaded = true
	--If stats data changed --> save
	local function OnStatsAttributeChanged(attributeName)
		print(attributeName.."stats changed")
		if Priority[attributeName] ~= nil then
			print(attributeName, true)
			for name, value in pairs(PlayerStat:GetAttributes()) do
				if Priority[name] then
					GetStatsDS[Priority[name]] = value
				end
			end
			PlrStats:Set(GetStatsDS)
		end 
	end
	local function OnItemChanged(Object,Is`Bank`)
		--print(Object.Name)
		local counts = 10
		--repeat until Object.Name ~= "Value"
		repeat 
			task.wait()
			--print(Object.Name)
			if Object.Name ~= "Value" then
				if ItemStorage:FindFirstChild("Equipments"):FindFirstChild(Object.Name) then
					local backuplookup = require(ItemStorage:FindFirstChild("Equipments")[Object.Name])
					Object.Value = backuplookup.ID
					break
				elseif ItemStorage:FindFirstChild("Consumables"):FindFirstChild(Object.Name) then
					local backuplookup = require(ItemStorage:FindFirstChild("Consumables")[Object.Name])
					Object.Value = backuplookup.ID
					break
				elseif ItemStorage:FindFirstChild("Materials"):FindFirstChild(Object.Name) then
					local backuplookup = require(ItemStorage:FindFirstChild("Materials")[Object.Name])
					Object.Value = backuplookup.ID
					break
				else
					plr:Kick("Error: Failed to load item (L92,Datastore2), if it keeps happening please contact tanokhoi.")
					warn("error aaaa")
					break
				end
			end
			counts = counts - 1
		until counts == 0
		local itemname,itemtype  = ItemDictionaryHandler.IDToName(Object.Value)
		if IsBank == true then
			if BankQueue >= 5 then
				BankQueue = 5
			else
				BankQueue = BankQueue + 1
			end
		elseif IsBank == "Equipped" then
			local function FireEvent()
				if EquippedQueue >= 5 then
					EquippedQueue =5
				else
					EquippedQueue = EquippedQueue + 1
				end
			end
			local connection 
			local connection2
			local connection3
			connection =  Object.AttributeChanged:Connect(FireEvent)
			if Object:FindFirstChild("Upgrades") then
				connection2 = Object:FindFirstChild("Upgrades").Changed:Connect(FireEvent)
			end
			connection3 = Object.AncestryChanged:Connect(function(child,parent)
				if child.Name == Object.Name and parent then
					connection:Disconnect()
					if Object:FindFirstChild("Upgrades") then
						connection2:Disconnect()
					end
					connection3:Disconnect()
				end
			end)
			FireEvent()
		else
			local function FireEvent()
				print("Fired OnItemChanged")
				if itemtype == 1 then
					print("Fired condition 1")
					if EquipmentsQueue >= 5 then
						EquipmentsQueue = 5
					else
						EquipmentsQueue = EquipmentsQueue + 1
					end
				elseif itemtype == 2 then
					print("Fired condition 2")
					if ConsumablesQueue >= 5 then
						ConsumablesQueue = 5
					else
						ConsumablesQueue = ConsumablesQueue + 1
					end
				elseif itemtype == 3 then
					print("Fired condition 3")
					if MaterialsQueue >= 5 then
						MaterialsQueue = 5
					else
						MaterialsQueue = MaterialsQueue + 1
					end
				end
			end
			local connection 
			local connection2
			local connection3
			connection =  Object.AttributeChanged:Connect(FireEvent)
			if Object:FindFirstChild("Upgrades") then
				connection2 = Object:FindFirstChild("Upgrades").Changed:Connect(FireEvent)
			end
			connection3 = Object.AncestryChanged:Connect(function(child,parent)
				if child.Name == Object.Name and parent then
					connection:Disconnect()
					if Object:FindFirstChild("Upgrades") then
						connection2:Disconnect()
					end
					connection3:Disconnect()
				end
			end)
			FireEvent()
		end
	end
	local function OnRemoval(Object,IsBank)
		print("detected")
		local itemname,itemtype  = ItemDictionaryHandler.IDToName(Object.Value)
		if IsBank == true then
			if BankQueue >= 5 then
				BankQueue = 5
			else
				BankQueue = BankQueue + 1
			end
		elseif IsBank == "Equipped" then
			if EquippedQueue >= 5 then
				EquippedQueue =5
			else
				EquippedQueue = EquippedQueue + 1
			end
		else
			if itemtype == 1 then
				if EquipmentsQueue >= 5 then
					EquipmentsQueue = 5
				else
					EquipmentsQueue = EquipmentsQueue + 1
				end
			elseif itemtype == 2 then
				if ConsumablesQueue >= 5 then
					ConsumablesQueue = 5
				else
					ConsumablesQueue = ConsumablesQueue + 1
				end
			elseif itemtype == 3 then
				if MaterialsQueue >= 5 then
					MaterialsQueue = 5
				else
					MaterialsQueue = MaterialsQueue + 1
				end
			end
		end
	end
	local function LinkItem(Object)

		local function FireEvent()
			print("Fired LinkItem FireEvent")
			print(Object)
			print(Object.Parent.Name)
			if Object.Parent.Parent.Name == "Equipments" then
				print("Fired LinkItem FireEvent Equipments")
				if EquipmentsQueue >= 5 then
					EquipmentsQueue = 5
				else
					EquipmentsQueue = EquipmentsQueue + 1
				end
			elseif Object.Parent.Parent.Name == "Consumables" then
				print("Fired LinkItem FireEvent Consumables")
				if ConsumablesQueue >= 5 then
					ConsumablesQueue = 5
				else
					ConsumablesQueue = ConsumablesQueue + 1
				end
			elseif Object.Parent.Parent.Name == "Materials" then
				print("Fired LinkItem FireEvent Materials")
				if MaterialsQueue >= 5 then
					MaterialsQueue = 5
				else
					MaterialsQueue = MaterialsQueue + 1
				end
			elseif Object.Parent.Parent.Name == "Main" or Object.Parent.Parent.Name == "Accessory" then
				print("Fired LinkItem FireEvent Main")
				if EquippedQueue >= 5 then
					EquippedQueue =5
				else
					EquippedQueue = EquippedQueue + 1
				end
			end
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
		if Object:FindFirstChild("Upgrades") then
			Upgradeconnection = Object:FindFirstChild("Upgrades").AttributeChanged:Connect(FireEvent)
			Upgradeconnection_V = Object:FindFirstChild("Upgrades"):GetPropertyChangedSignal("Value"):Connect(FireEvent)
		end
		if Object:FindFirstChild("Gems") then
			Gemconnection = Object:FindFirstChild("Gems").AttributeChanged:Connect(FireEvent)
			Gemconnection_V = Object:FindFirstChild("Gems"):GetPropertyChangedSignal("Value"):Connect(FireEvent)
		end
		if Object:FindFirstChild("Enchants") then
			Enchantconnection = Object:FindFirstChild("Enchants").AttributeChanged:Connect(FireEvent)
			Enchantconnection_V = Object:FindFirstChild("Enchants"):GetPropertyChangedSignal("Value"):Connect(FireEvent)
		end
		Parentconnection = Object.AncestryChanged:Connect(function(child,parent)
			if child.Name == Object.Name and parent then
				Itemconnection:Disconnect()
				if Object:FindFirstChild("Upgrades") then
					Upgradeconnection:Disconnect()
					Enchantconnection_V:Disconnect()
				end
				if Object:FindFirstChild("Gems") then
					Gemconnection:Disconnect()
					Gemconnection_V:Disconnect()
				end
				if Object:FindFirstChild("Enchants") then
					Enchantconnection:Disconnect()
					Enchantconnection_V:Disconnect()
				end
				Parentconnection:Disconnect()
			end
		end)
	end
	PlayerStat.AttributeChanged:Connect(OnStatsAttributeChanged)
	--Will rework on this soon
	for i = 1,36 do
		--wait()
		if i < 26 then
			if PlayerInventory:FindFirstChild("Equipments"):FindFirstChild("Slot_"..i):FindFirstChildOfClass("NumberValue") then
				LinkItem(PlayerInventory:FindFirstChild("Equipments"):FindFirstChild("Slot_"..i):FindFirstChildOfClass("NumberValue"))
			end
			PlayerInventory:FindFirstChild("Equipments"):FindFirstChild("Slot_"..i).ChildAdded:Connect(OnItemChanged)
			PlayerInventory:FindFirstChild("Equipments"):FindFirstChild("Slot_"..i).ChildRemoved:Connect(OnRemoval)
		end
		
		if PlayerInventory:FindFirstChild("Consumables"):FindFirstChild("Slot_"..i):FindFirstChildOfClass("NumberValue") then
			LinkItem(PlayerInventory:FindFirstChild("Consumables"):FindFirstChild("Slot_"..i):FindFirstChildOfClass("NumberValue"))
		end
		if PlayerInventory:FindFirstChild("Materials"):FindFirstChild("Slot_"..i):FindFirstChildOfClass("NumberValue") then
			LinkItem(PlayerInventory:FindFirstChild("Materials"):FindFirstChild("Slot_"..i):FindFirstChildOfClass("NumberValue"))
		end
		PlayerInventory:FindFirstChild("Consumables"):FindFirstChild("Slot_"..i).ChildAdded:Connect(OnItemChanged)
		PlayerInventory:FindFirstChild("Consumables"):FindFirstChild("Slot_"..i).ChildRemoved:Connect(OnRemoval)
		PlayerInventory:FindFirstChild("Materials"):FindFirstChild("Slot_"..i).ChildAdded:Connect(OnItemChanged)
		PlayerInventory:FindFirstChild("Materials"):FindFirstChild("Slot_"..i).ChildRemoved:Connect(OnRemoval)
	end
	for i,v in pairs(PlayerInventory:WaitForChild("Equipped"):WaitForChild("Main"):GetChildren()) do
		if v:FindFirstChildOfClass("NumberValue") then
			LinkItem(v:FindFirstChildOfClass("NumberValue"))
		end
		v.ChildAdded:Connect(function(obj) OnItemChanged(obj,"Equipped") end)
		v.ChildRemoved:Connect(function(obj) OnRemoval(obj,"Equipped") end)
	end
	for i,v in pairs(PlayerInventory:WaitForChild("Equipped"):WaitForChild("Accessory"):GetChildren()) do
		if v:FindFirstChildOfClass("NumberValue") then
			LinkItem(v:FindFirstChildOfClass("NumberValue"))
		end
		v.ChildAdded:Connect(function(obj) OnItemChanged(obj,"Equipped") end)
		v.ChildRemoved:Connect(function(obj) OnRemoval(obj,"Equipped") end)
	end
	PlayerBank.ChildAdded:Connect(function(obj) OnItemChanged(obj,true) end)
	PlayerBank.ChildRemoved:Connect(function(obj) OnRemoval(obj,true) end)

	local IsLooping = false
	local Run = false
	local DataLoaded = Instance.new("BoolValue",plr)
	DataLoaded.Name = "DataLoaded"
	DataLoaded.Value = true
	print(plr.Name.." has loaded.")
	--Queuing if data changed
	--[[
	local interval = 0.1
	local start = tick()
	local nextStep = start+interval
	local iter = 1

	connectionTable.connectionLoop = RunService.Heartbeat:Connect(function(dt)
    if(tick() >= nextStep)then
        iter = iter+1
        nextStep = start + (iter * interval)

        --while loop code here
    end
	end)
	
	local RunService = game:GetService("RunService")
	local connectionTable = {}

	connectionTable.connectionLoop = RunService.Heartbeat:Connect(function(step)
  --while loop code here

	end)

	--When shutting down the loop
	connectionTable.connectionLoop:Disconnect()

	--Shutting down all loops in a table
	for _, connection in pairs(connectionTable) do
	  connection:Disconnect()
	end
	]]
	RunService.Heartbeat:Connect(function()
		if EquipmentsQueue > 0 then
			local EquipmentsTable = ItemSlotHandler.GetSlotsv2(plr,false,2) 
			print("EquipmentsQueue: "..EquipmentsQueue)
			EquipmentsQueue = EquipmentsQueue - 1
			--ItemSlotHandler.CorrectSlotNumber(plr,2)
			GetEquipmentInventoryDS = {}
			print(EquipmentsTable)
			for i,v in pairs(EquipmentsTable) do
				GetEquipmentInventoryDS[i] = ItemDictionaryHandler.DictionaryToData(v)
			end
			--print(GetEquipmentInventoryDS)
			if IsLoaded then
				EquipmentInventory:Set(GetEquipmentInventoryDS)
			end
		end
		if ConsumablesQueue > 0 then
			local ConsumablesTable = ItemSlotHandler.GetSlotsv2(plr,false,3) 
			print("ConsumablesQueue: "..ConsumablesQueue)
			ConsumablesQueue = ConsumablesQueue - 1
			--ItemSlotHandler.CorrectSlotNumber(plr,3)
			GetConsumableInventoryDS = {}
			for i,v in pairs(ConsumablesTable) do
				GetConsumableInventoryDS[i] = ItemDictionaryHandler.DictionaryToData(v)
			end
			--print(GetConsumableInventoryDS)
			if IsLoaded then
				ConsumableInventory:Set(GetConsumableInventoryDS)
			end
		end
		if MaterialsQueue > 0 then
			local MaterialsTable = ItemSlotHandler.GetSlotsv2(plr,false,4) 
			print("MaterialsQueue: "..MaterialsQueue)
			MaterialsQueue = MaterialsQueue - 1
			--ItemSlotHandler.CorrectSlotNumber(plr,4)
			GetMaterialInventoryDS = {}
			for i,v in pairs(MaterialsTable) do
				GetMaterialInventoryDS[i] = ItemDictionaryHandler.DictionaryToData(v)
			end
			--print(GetMaterialInventoryDS)
			if IsLoaded then
				MaterialInventory:Set(GetMaterialInventoryDS)
			end
		end
		if BankQueue > 0 then
			local BankTable = ItemSlotHandler.GetSlotsv2(plr,false,5) 
			print("BankQueue: "..BankQueue)
			BankQueue = BankQueue - 1
			--ItemSlotHandler.CorrectSlotNumber(plr,6)
			GetBankDS = {}
			for i,v in pairs(BankTable) do
				GetBankDS[i] = ItemDictionaryHandler.DictionaryToData(v)
			end
			--print(string.len(HttpServ:JSONEncode(GetBankDS)))
			print(GetBankDS)
			if IsLoaded then
				Bank:Set(GetBankDS)
			end
		end
		if EquippedQueue > 0 then
			local EquippedTable = ItemSlotHandler.GetSlotsv2(plr,false,6) 
			print("EquippedQueue: "..EquippedQueue)
			--print(EquippedTable)
			EquippedQueue = EquippedQueue - 1
			--ItemSlotHandler.CorrectSlotNumber(plr,5)
			local clonetable = {
				[1] = {[1]={},[2]={},[3]={},[4]={},[5]={},[6]={},[7]={},[8]={}},
				[2] = {},
				[3] = {[1]={},[2]={},[3]={}},
				[4]={[1]={},[2]={}},
				[5]={[1]={},[2]={},[3]={}}
			}
			for i,v in pairs(EquippedTable) do
				if i == "Accessory" then	--Accessory
					for a,b in pairs(v) do
						local name,numb = string.match(a,"(%a+)(%d+)") print(name,numb,b)
						if not (next(b) == nil) then
							clonetable[2][tonumber(numb)] = ItemDictionaryHandler.DictionaryToData(b)
						else clonetable[2][tonumber(numb)] = {}
						end
					end
				elseif i == "Fishing" then

				elseif i == "Bow" then

				else
					if v.ID ~= nil then
						clonetable[1][EquippedData[i]] = ItemDictionaryHandler.DictionaryToData(v)
					else clonetable[1][EquippedData[i]] = {}
					end
				end
			end
			--print(clonetable)
			if IsLoaded then
				Equipped:Set(clonetable)
			end
		end
	end)
	--while true do
	--	task.wait()
	--	if EquipmentsQueue > 0 or ConsumablesQueue > 0 or MaterialsQueue > 0 or BankQueue > 0 or EquippedQueue > 0 then
	--		print("EquipmentsQueue: "..EquippedQueue)
	--		print("ConsumablesQueue: "..ConsumablesQueue)
	--		print("MaterialsQueue: "..MaterialsQueue)
	--		print("BankQueue: "..BankQueue)
	--		print("EquippedQueue: "..EquippedQueue)
	--		local EquipmentsTable, ConsumablesTable, MaterialsTable, BankTable, EquippedTable = ItemSlotHandler.GetSlots(plr)
	--		if EquipmentsQueue > 0 then
	--			print("EquipmentsQueue: "..EquipmentsQueue)
	--			EquipmentsQueue = EquipmentsQueue - 1
	--			ItemSlotHandler.CorrectSlotNumber(plr,2)
	--			GetEquipmentInventoryDS = {}
	--			print(EquipmentsTable)
	--			for i,v in pairs(EquipmentsTable) do
	--				GetEquipmentInventoryDS[i] = ItemDictionaryHandler.DictionaryToData(v)
	--			end
	--			--print(GetEquipmentInventoryDS)
	--			if IsLoaded then
	--				EquipmentInventory:Set(GetEquipmentInventoryDS)
	--			end
	--		end
	--		if ConsumablesQueue > 0 then
	--			print("ConsumablesQueue: "..ConsumablesQueue)
	--			ConsumablesQueue = ConsumablesQueue - 1
	--			ItemSlotHandler.CorrectSlotNumber(plr,3)
	--			GetConsumableInventoryDS = {}
	--			for i,v in pairs(ConsumablesTable) do
	--				GetConsumableInventoryDS[i] = ItemDictionaryHandler.DictionaryToData(v)
	--			end
	--			--print(GetConsumableInventoryDS)
	--			if IsLoaded then
	--				ConsumableInventory:Set(GetConsumableInventoryDS)
	--			end
	--		end
	--		if MaterialsQueue > 0 then
	--			print("MaterialsQueue: "..MaterialsQueue)
	--			MaterialsQueue = MaterialsQueue - 1
	--			ItemSlotHandler.CorrectSlotNumber(plr,4)
	--			GetMaterialInventoryDS = {}
	--			for i,v in pairs(MaterialsTable) do
	--				GetMaterialInventoryDS[i] = ItemDictionaryHandler.DictionaryToData(v)
	--			end
	--			--print(GetMaterialInventoryDS)
	--			if IsLoaded then
	--				MaterialInventory:Set(GetMaterialInventoryDS)
	--			end
	--		end
	--		if BankQueue > 0 then
	--			print("BankQueue: "..BankQueue)
	--			BankQueue = BankQueue - 1
	--			ItemSlotHandler.CorrectSlotNumber(plr,6)
	--			GetBankDS = {}
	--			for i,v in pairs(BankTable) do
	--				GetBankDS[i] = ItemDictionaryHandler.DictionaryToData(v)
	--			end
	--			--print(string.len(HttpServ:JSONEncode(GetBankDS)))
	--			print(GetBankDS)
	--			if IsLoaded then
	--				Bank:Set(GetBankDS)
	--			end
	--		end
	--		if EquippedQueue > 0 then
	--			--print("EquippedQueue: "..EquippedQueue)
	--			--print(EquippedTable)
	--			EquippedQueue = EquippedQueue - 1
	--			ItemSlotHandler.CorrectSlotNumber(plr,5)
	--			local clonetable = {
	--				[1] = {[1]={},[2]={},[3]={},[4]={},[5]={},[6]={},[7]={},[8]={}},
	--				[2] = {},
	--				[3] = {[1]={},[2]={},[3]={}},
	--				[4]={[1]={},[2]={}},
	--				[5]={[1]={},[2]={},[3]={}}
	--			}
	--			for i,v in pairs(EquippedTable) do
	--				if i == "Accessory" then	--Accessory
	--					for a,b in pairs(v) do
	--						local name,numb = string.match(a,"(%a+)(%d+)") print(name,numb,b)
	--						if not (next(b) == nil) then
	--							clonetable[2][tonumber(numb)] = ItemDictionaryHandler.DictionaryToData(b)
	--						else clonetable[2][tonumber(numb)] = {}
	--						end
	--					end
	--				elseif i == "Fishing" then
						
	--				elseif i == "Bow" then
						
	--				else
	--					if v.ID ~= nil then
	--						clonetable[1][EquippedData[i]] = ItemDictionaryHandler.DictionaryToData(v)
	--					else clonetable[1][EquippedData[i]] = {}
	--					end
	--				end
	--			end
	--			--print(clonetable)
	--			if IsLoaded then
	--				Equipped:Set(clonetable)
	--			end
	--		end
	--		--DataLoaded.Value = DataLoaded.Value - 1
	--	end
	--end

end

game.Players.PlayerAdded:Connect(function(plr)

	local CanAutoSave = true
	local PlayerStat = script:WaitForChild("PlayerData"):Clone()
	PlayerStat.Parent = plr -- Gọi tên player

	--local AddictionStr = PlayerStat:SetAttribute("AddictionStr",0)
	--local AddictionDex = PlayerStat:SetAttribute("AddictionDex",0)
	--local AddictionInt = PlayerStat:SetAttribute("AddictionInt",0)
	--local AddictionVit = PlayerStat:SetAttribute("AddictionVit",0)
	--local AddictionHealth = PlayerStat:SetAttribute("AddictionHealth",0)
	--local AddictionDefense = PlayerStat:SetAttribute("AddictionDefense",0)
	--local AddictionMana = PlayerStat:SetAttribute("AddictionMana",0)
	--local AddictionSpeed = PlayerStat:SetAttribute("AddictionSpeed",0)
	--local AddictionJumpPower = PlayerStat:SetAttribute("AddictionJumpPower",0)
	--local AddictionDamage = PlayerStat:SetAttribute("AddictionDamage",0)
	--local AddictionCritChance = PlayerStat:SetAttribute("AddictionCritChance",0)
	--local AddictionCritDamage = PlayerStat:SetAttribute("AddictionCritDamage",0)
	--local AddictionFerocity = PlayerStat:SetAttribute("AddictionFerocity",0)
	--local AddictionAttackSpeed = PlayerStat:SetAttribute("AddictionAttackSpeed",0)
	--local AddictionHealthRegenRate = PlayerStat:SetAttribute("AddictionHealthRegenRate",0)
	--local AddictionManaRegenRate = PlayerStat:SetAttribute("AddictionManaRegenRate",0)
	--local AddictionRangedDefense = PlayerStat:SetAttribute("AddictionRangedDefense",0)
	--local AddictionMagicDefense = PlayerStat:SetAttribute("AddictionMagicDefense",0)
	--local AddictionRangedAttack = PlayerStat:SetAttribute("AddictionRangedAttack",0)
	--local AddictionMagicAttack = PlayerStat:SetAttribute("AddictionMagicAttack",0)
	--InventoryBois
	local PlayerInventory = script:WaitForChild("Inventory"):Clone()
	PlayerInventory.Parent = plr
	local PlayerBank = script:WaitForChild("Bank"):Clone()
	PlayerBank.Parent = plr
	local NewNotifyData = Instance.new("NumberValue",game:GetService("ReplicatedStorage"):WaitForChild("PlayerDataHolder"):WaitForChild("Notify"))
	NewNotifyData.Name = plr.Name
	
	wait()

	--local a,b = pcall(function()
	LoadData(plr,PlayerStat,PlayerInventory,PlayerBank)
	--end)
	--print(a,b)
	ItemSlotHandler.CorrectSlotNumber(plr)
end)
