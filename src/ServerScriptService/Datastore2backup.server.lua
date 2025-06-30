local DS2 = require(game:GetService("ServerScriptService"):WaitForChild("DataStore2"))
local HttpServ = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ItemStorage = game:GetService("ReplicatedStorage"):WaitForChild("GameItems")
DS2.Combine("DATA", "StatsDS","EquipmentInventoryDS","ConsumableInventoryDS","MaterialInventoryDS","BankDS","EquippedDS")
--Modules
local EquipmentFormat = require(game:GetService("ReplicatedStorage"):WaitForChild("Format"):WaitForChild("EquipmentFormat"))
local ItemDictionaryHandler = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("ItemDictionaryHandler"))
local NameOrIDConverter = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("NameOrIDConverter"))
local ItemSlotHandler = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("ItemSlotHandler"))
local CopyTable = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("CopyTable"))
local CreateItem = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("CreateItem"))
local ItemType = require(game:GetService("ReplicatedStorage"):WaitForChild("GameItems"):WaitForChild("ItemType"))
local NonSaveStats = {"AddictionStr","AddictionDex","AddictionInt","AddictionVit","AddictionHealth","AddictionDefense","AddictionMana","AddictionSpeed","AddictionJumpPower","AddictionDamage","AddictionCritChance","AddictionCritDamage","AddictionFerocity","AddictionAttackSpeed","AddictionHealthRegenRate","AddictionManaRegenRate","AddictionRangedDefense","AddictionMagicDefense","AddictionRangedAttack","AddictionMagicAttack"}
local Priority = {
	Level = 1,
	Exp = 2,
	Gold = 3,
	Superiority = 4,
	StatPoints = 5,
	AssignedStatPoints = 6,
	Str = 7,
	Dex = 8,
	Int = 9,
	Vit = 10,
	Health = 11,
	Defense = 12,
	Mana = 13,
	Speed = 14,
	JumpPower = 15,
	BaseDamage = 16,
	BaseCritChance = 17,
	BaseCritDamage = 18,
	Ferocity = 19,
	AttackSpeed = 20,
	HealthRegenRate = 21,
	ManaRegenRate = 22,
	RangedDefense = 23,
	MagicDefense = 24,
	RangedAttack = 25,
	MagicAttack = 26,
}
LoadData = function(plr,PlayerStat,PlayerInventory,PlayerBank)
	-- Stats
	local Stats = DS2("StatsDS",plr)
	local EquipmentInventory = DS2("EquipmentInventoryDS",plr)
	local ConsumableInventory = DS2("ConsumableInventoryDS",plr)
	local MaterialInventory = DS2("MaterialInventoryDS",plr)
	local Bank = DS2("BankDS",plr)
	local Equipped = DS2("EquippedDS",plr)
	local NewSword = ItemDictionaryHandler.ItemToDictionary(script:WaitForChild("Sword"))
	local NewSwordButData = ItemDictionaryHandler.DictionaryToData(NewSword)
	local IsLoaded = false
	--local new = ItemDictionaryHandler.DataToDictionary(NewSwordButData)
	--print(new)
	--print(HttpServ:JSONEncode(NewSword))
	--print(string.len(HttpServ:JSONEncode(NewSwordButData)))
	--print(string.len(NewSwordButData))
	--print(NewSwordButData)
	local function EquippedTable()
		local ETable = {
			[1] = {[1]={},[2]={},[3]={},[4]={},[5]={},[6]={},[7]={},[8]={}},[2] = {[1]={},[2]={},[3]={},[4]={},[5]={},[6]={},[7]={},[8]={},[9]={}},
		}
		return ETable
	end
	--pcall(function()
	local GetStatsDS = Stats:Get({1,0,100,0,0,0,0,0,0,0,100,10,100,21,100,3,5,50,0,100,5,5,0,0,0,0,})
	local GetEquipmentInventoryDS = EquipmentInventory:Get({[1] = NewSwordButData})
	local GetConsumableInventoryDS = ConsumableInventory:Get({})
	local GetMaterialInventoryDS = MaterialInventory:Get({})
	local GetBankDS = Bank:Get({})
	local GetEquippedDS = Equipped:Get(EquippedTable())
	local EquipmentsQueue = 0
	local ConsumablesQueue = 0
	local MaterialsQueue = 0
	local BankQueue = 0
	local EquippedQueue = 0
	while MaterialsQueue >= 1 do
		local EquipmentsTable, ConsumablesTable, MaterialsTable, BankTable, EquippedTable = ItemSlotHandler.GetSlots(plr)
		print("MaterialsQueue: "..MaterialsQueue)
		MaterialsQueue = MaterialsQueue - 1
		ItemSlotHandler.CorrectSlotNumber(plr,4)
		GetMaterialInventoryDS = {}
		for i,v in pairs(MaterialsTable) do
			GetMaterialInventoryDS[i] = ItemDictionaryHandler.DictionaryToData(v)
		end
		print(GetMaterialInventoryDS)
		if IsLoaded then
			MaterialInventory:Set(GetMaterialInventoryDS)
		end
	end
	--Stats
	print(GetStatsDS)
	print("GetStatsDS")
	PlayerStat:SetAttribute("Level",GetStatsDS[1])
	PlayerStat:SetAttribute("Exp",GetStatsDS[2])
	PlayerStat:SetAttribute("Gold",GetStatsDS[3])
	PlayerStat:SetAttribute("Superiority",GetStatsDS[4])
	PlayerStat:SetAttribute("StatPoints",GetStatsDS[5])
	PlayerStat:SetAttribute("AssignedStatPoints",GetStatsDS[6])
	PlayerStat:SetAttribute("Str",GetStatsDS[7])
	PlayerStat:SetAttribute("Dex",GetStatsDS[8])
	PlayerStat:SetAttribute("Int",GetStatsDS[9])
	PlayerStat:SetAttribute("Vit",GetStatsDS[10])
	PlayerStat:SetAttribute("Health",GetStatsDS[11])
	PlayerStat:SetAttribute("Defense",GetStatsDS[12])
	PlayerStat:SetAttribute("Mana",GetStatsDS[13])
	PlayerStat:SetAttribute("Speed",GetStatsDS[14])
	PlayerStat:SetAttribute("JumpPower",GetStatsDS[15])
	PlayerStat:SetAttribute("BaseDamage",GetStatsDS[16])
	PlayerStat:SetAttribute("BaseCritChance",GetStatsDS[17])
	PlayerStat:SetAttribute("BaseCritDamage",GetStatsDS[18])
	PlayerStat:SetAttribute("Ferocity",GetStatsDS[19])
	PlayerStat:SetAttribute("AttackSpeed",GetStatsDS[20])
	PlayerStat:SetAttribute("HealthRegenRate",GetStatsDS[21])
	PlayerStat:SetAttribute("ManaRegenRate",GetStatsDS[22])
	PlayerStat:SetAttribute("RangedDefense",GetStatsDS[23])
	PlayerStat:SetAttribute("MagicDefense",GetStatsDS[24])
	PlayerStat:SetAttribute("RangedAttack",GetStatsDS[25])
	PlayerStat:SetAttribute("MagicAttack",GetStatsDS[26])
	for i,v in pairs(GetEquipmentInventoryDS) do
		local ItemDictionarized = ItemDictionaryHandler.DataToDictionary(v)
		print(ItemDictionarized)
		ItemSlotHandler.MoveToSlot(plr,ItemDictionarized)
	end
	for i,v in pairs(GetConsumableInventoryDS) do
		local ItemDictionarized = ItemDictionaryHandler.DataToDictionary(v)
		print(ItemDictionarized)
		ItemSlotHandler.MoveToSlot(plr,ItemDictionarized)
	end
	for i,v in pairs(GetMaterialInventoryDS) do
		local ItemDictionarized = ItemDictionaryHandler.DataToDictionary(v)
		print(ItemDictionarized)
		ItemSlotHandler.MoveToSlot(plr,ItemDictionarized)
	end
	for i,v in pairs(GetBankDS) do
		local ItemDictionarized = ItemDictionaryHandler.DataToDictionary(v)
		print(ItemDictionarized)
		ItemSlotHandler.MoveToSlot(plr,ItemDictionarized,true)
	end

	--local function OnMainEquippedChanged(Object)
	--	local itemname,itemtype,itemsubtype = NameOrIDConverter.IDToName(Object.Value)
	--	if Object.Parent.Name == "Weapon" then
	--		if itemsubtype[ItemType.Weapon] then

	--		end
	--	end
	--end

	--for i,v in pairs(PlayerInventory:WaitForChild("Equipped"):WaitForChild("Main")) do
	--	v.ChildAdded:Connect()
	--end

	
	--end)
	--EquipmentsQueue > 0 or ConsumablesQueue > 0 or or  BankQueue > 0 
	--while MaterialsQueue >= 1 do
	--	print("while do fired")
	--	wait()
	--	local EquipmentsTable, ConsumablesTable, MaterialsTable, BankTable, EquippedTable = ItemSlotHandler.GetSlots(plr)
	--	if EquipmentsQueue > 0 then
	--		print("EquipmentsQueue: "..EquipmentsQueue)
	--		EquipmentsQueue = EquipmentsQueue - 1
	--		ItemSlotHandler.CorrectSlotNumber(plr,2)
	--		GetEquipmentInventoryDS = {}
	--		for i,v in pairs(EquipmentsTable) do
	--			GetEquipmentInventoryDS[i] = ItemDictionaryHandler.DictionaryToData(v)
	--		end
	--		print(GetEquipmentInventoryDS)
	--		if IsLoaded then
	--			EquipmentInventory:Set(GetEquipmentInventoryDS)
	--		end
	--	end
	--	if ConsumablesQueue > 0 then
	--		print("ConsumablesQueue: "..ConsumablesQueue)
	--		ConsumablesQueue = ConsumablesQueue - 1
	--		ItemSlotHandler.CorrectSlotNumber(plr,3)
	--		GetConsumableInventoryDS = {}
	--		for i,v in pairs(ConsumablesTable) do
	--			GetConsumableInventoryDS[i] = ItemDictionaryHandler.DictionaryToData(v)
	--		end
	--		print(GetConsumableInventoryDS)
	--		if IsLoaded then
	--			ConsumableInventory:Set(GetConsumableInventoryDS)
	--		end
	--	end
	--	if MaterialsQueue > 0 then
	--		print("MaterialsQueue: "..MaterialsQueue)
	--		MaterialsQueue = MaterialsQueue - 1
	--		ItemSlotHandler.CorrectSlotNumber(plr,4)
	--		GetMaterialInventoryDS = {}
	--		for i,v in pairs(MaterialsTable) do
	--			GetMaterialInventoryDS[i] = ItemDictionaryHandler.DictionaryToData(v)
	--		end
	--		print(GetMaterialInventoryDS)
	--		if IsLoaded then
	--			MaterialInventory:Set(GetMaterialInventoryDS)
	--		end
	--	end
	--	if BankQueue > 0 then
	--		print("BankQueue: "..BankQueue)
	--		BankQueue = BankQueue - 1
	--		ItemSlotHandler.CorrectSlotNumber(plr,6)
	--		GetBankDS = {}
	--		for i,v in pairs(BankTable) do
	--			GetBankDS[i] = ItemDictionaryHandler.DictionaryToData(v)
	--		end
	--		print(GetBankDS)
	--		if IsLoaded then
	--			Bank:Set(GetBankDS)
	--		end
	--	end
	--end
	local function OnStatsAttributeChanged(attributeName)
		for name, value in pairs(PlayerStat:GetAttributes()) do
			if Priority[name] then
				GetStatsDS[Priority[name]] = value
			end
		end
		Stats:Set(GetStatsDS)
	end
	local function OnItemChanged(Object,IsBank)
		local counts = 10
		repeat 
			wait() 
			if counts == 0 then
				if ItemStorage:WaitForChild("Equipments")[Object.Name] then
					local backuplookup = require(ItemStorage:WaitForChild("Equipments")[Object.Name])
					Object.Value = backuplookup.ID
				elseif ItemStorage:WaitForChild("Consumables")[Object.Name] then
					local backuplookup = require(ItemStorage:WaitForChild("Consumables")[Object.Name])
					Object.Value = backuplookup.ID
				elseif ItemStorage:WaitForChild("Materials")[Object.Name] then
					local backuplookup = require(ItemStorage:WaitForChild("Materials")[Object.Name])
					Object.Value = backuplookup.ID	
				else
					plr:Kick("Error: Failed to load item (L92,Datastore2), if it keeps happening please contact tanokhoi.")
				end
				break
			end
			counts = counts - 1
		until Object.Value ~= 0
		local itemname,itemtype  = NameOrIDConverter.IDToName(Object.Value)
		if IsBank then
			BankQueue = BankQueue + 1
		else
			local function FireEvent()
				print("Fired")
				if itemtype == 1 then
					EquipmentsQueue = EquipmentsQueue + 1
				elseif itemtype == 2 then
					ConsumablesQueue = ConsumablesQueue + 1
				elseif itemtype == 3 then
					MaterialsQueue = MaterialsQueue + 1
					print("MaterialsQueue: "..MaterialsQueue)
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
		local itemname,itemtype  = NameOrIDConverter.IDToName(Object.Value)
		if IsBank then
			BankQueue = BankQueue + 1
		else
			if itemtype == 1 then
				EquipmentsQueue = EquipmentsQueue + 1
			elseif itemtype == 2 then
				ConsumablesQueue = ConsumablesQueue + 1
			elseif itemtype == 3 then
				MaterialsQueue = MaterialsQueue + 1
				print("MaterialsQueue: "..MaterialsQueue)
			end
		end
	end
	for i = 1,16 do
		wait()
		PlayerInventory:FindFirstChild("Equipments"):FindFirstChild("Slot_"..i).ChildAdded:Connect(OnItemChanged)
		PlayerInventory:FindFirstChild("Equipments"):FindFirstChild("Slot_"..i).ChildRemoved:Connect(OnRemoval)
		PlayerInventory:FindFirstChild("Consumables"):FindFirstChild("Slot_"..i).ChildAdded:Connect(OnItemChanged)
		PlayerInventory:FindFirstChild("Consumables"):FindFirstChild("Slot_"..i).ChildRemoved:Connect(OnRemoval)
		PlayerInventory:FindFirstChild("Materials"):FindFirstChild("Slot_"..i).ChildAdded:Connect(OnItemChanged)
		PlayerInventory:FindFirstChild("Materials"):FindFirstChild("Slot_"..i).ChildRemoved:Connect(OnRemoval)
	end
	PlayerBank.ChildAdded:Connect(function(obj) OnItemChanged(obj,true) end)
	PlayerBank.ChildRemoved:Connect(function(obj) OnRemoval(obj,true) end)
	PlayerStat.AttributeChanged:Connect(OnStatsAttributeChanged)
	IsLoaded = true
	print(plr.Name.." has loaded.")
end

game.Players.PlayerAdded:Connect(function(plr)

	local CanAutoSave = true
	local PlayerStat = script:WaitForChild("PlayerData"):Clone()
	PlayerStat.Parent = plr
	--Main Stats
	local Level = PlayerStat:SetAttribute("Level",1)
	local Exp = PlayerStat:SetAttribute("Exp",0)
	local Gold = PlayerStat:SetAttribute("Gold",0)
	local Superiority = PlayerStat:SetAttribute("Superiority",0)
	--Base Stats
	local StatPoints = PlayerStat:SetAttribute("StatPoints",0)
	local AssignedStatPoints = PlayerStat:SetAttribute("AssignedStatPoints",0)
	local Str = PlayerStat:SetAttribute("Str",0)
	local Dex = PlayerStat:SetAttribute("Dex",0)
	local Int = PlayerStat:SetAttribute("Int",0)
	local Vit = PlayerStat:SetAttribute("Vit",0)
	local Health = PlayerStat:SetAttribute("Health",100)
	local Defense = PlayerStat:SetAttribute("Defense",10)
	local Mana = PlayerStat:SetAttribute("Mana",100)
	local Speed = PlayerStat:SetAttribute("Speed",21)
	local JumpPower = PlayerStat:SetAttribute("JumpPower",100)
	local BaseDamage = PlayerStat:SetAttribute("BaseDamage",3)
	local BaseCritChance = PlayerStat:SetAttribute("BaseCritChance",5)
	local BaseCritDamage = PlayerStat:SetAttribute("BaseCritDamage",50)
	local Ferocity = PlayerStat:SetAttribute("Ferocity",0)
	local AttackSpeed = PlayerStat:SetAttribute("AttackSpeed",100)
	local HealthRegenRate = PlayerStat:SetAttribute("HealthRegenRate",5)
	local ManaRegenRate = PlayerStat:SetAttribute("ManaRegenRate",5)
	local RangedDefense = PlayerStat:SetAttribute("RangedDefense",0)
	local MagicDefense = PlayerStat:SetAttribute("MagicDefense",0)
	local RangedAttack = PlayerStat:SetAttribute("RangedAttack",0)
	local MagicAttack = PlayerStat:SetAttribute("MagicAttack",0)
	-- Addictional Base Stats/Unneccessary stats
	local AddictionStr = PlayerStat:SetAttribute("AddictionStr",0)
	local AddictionDex = PlayerStat:SetAttribute("AddictionDex",0)
	local AddictionInt = PlayerStat:SetAttribute("AddictionInt",0)
	local AddictionVit = PlayerStat:SetAttribute("AddictionVit",0)
	local AddictionHealth = PlayerStat:SetAttribute("AddictionHealth",0)
	local AddictionDefense = PlayerStat:SetAttribute("AddictionDefense",0)
	local AddictionMana = PlayerStat:SetAttribute("AddictionMana",0)
	local AddictionSpeed = PlayerStat:SetAttribute("AddictionSpeed",0)
	local AddictionJumpPower = PlayerStat:SetAttribute("AddictionJumpPower",0)
	local AddictionDamage = PlayerStat:SetAttribute("AddictionDamage",0)
	local AddictionCritChance = PlayerStat:SetAttribute("AddictionCritChance",0)
	local AddictionCritDamage = PlayerStat:SetAttribute("AddictionCritDamage",0)
	local AddictionFerocity = PlayerStat:SetAttribute("AddictionFerocity",0)
	local AddictionAttackSpeed = PlayerStat:SetAttribute("AddictionAttackSpeed",0)
	local AddictionHealthRegenRate = PlayerStat:SetAttribute("AddictionHealthRegenRate",0)
	local AddictionManaRegenRate = PlayerStat:SetAttribute("AddictionManaRegenRate",0)
	local AddictionRangedDefense = PlayerStat:SetAttribute("AddictionRangedDefense",0)
	local AddictionMagicDefense = PlayerStat:SetAttribute("AddictionMagicDefense",0)
	local AddictionRangedAttack = PlayerStat:SetAttribute("AddictionRangedAttack",0)
	local AddictionMagicAttack = PlayerStat:SetAttribute("AddictionMagicAttack",0)
	local DodgeChance = PlayerStat:SetAttribute("DodgeChance",0)
	local MissChance = PlayerStat:SetAttribute("MissChance",0)
	--InventoryBois
	local PlayerInventory = script:WaitForChild("Inventory"):Clone()
	PlayerInventory.Parent = plr
	local PlayerBank = script:WaitForChild("Bank"):Clone()
	PlayerBank.Parent = plr
	wait()

	--local a,b = pcall(function()
	LoadData(plr,PlayerStat,PlayerInventory,PlayerBank)
	--end)
	--print(a,b)
	ItemSlotHandler.CorrectSlotNumber(plr)
end)
