serv = game:GetService("DataStoreService")
local HttpServ = game:GetService("HttpService")
local Stats = serv:GetDataStore("StatsDS")
local EquipmentInventory = serv:GetDataStore("EquipmentInventoryDS")
local ConsumableInventory = serv:GetDataStore("ConsumableInventoryDS")
local MaterialInventory = serv:GetDataStore("MaterialInventoryDS")
local BankInventory = serv:GetDataStore("BankDS")
local RunService = game:GetService("RunService")
--Modules
local EquipmentFormat = require(game:GetService("ReplicatedStorage"):WaitForChild("Format"):WaitForChild("EquipmentFormat"))
local ItemDictionaryHandler = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("ItemDictionaryHandler"))
local ItemSlotHandler = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("ItemSlotHandler"))
local CopyTable = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("CopyTable"))
local CreateItem = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("CreateItem"))

LoadData = function(plr,PlayerStat,PlayerInventory)
	-- Stats
	
	pcall(function()
		local GetStatsDS = Stats:GetAsync(plr.UserId)
		local GetEquipmentInventoryDS = EquipmentInventory:GetAsync(plr.UserId)
		print(EquipmentInventory)
		local GetConsumableInventoryDS = ConsumableInventory:GetAsync(plr.UserId)
		local GetMaterialInventoryDS = MaterialInventory:GetAsync(plr.UserId)
		local GetBankInventoryDS = BankInventory:GetAsync(plr.UserId)
		--Stats
		if GetStatsDS then
			print("found data")
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
		else
			print("not found")
			--PlayerStat:SetAttribute("Level",1)
			--PlayerStat:SetAttribute("Exp",0)
			PlayerStat:SetAttribute("Gold",100)
			--PlayerStat:SetAttribute("Superiority",0)
		end
		--EquipmentInventory
		if GetEquipmentInventoryDS then
			for i,v in pairs(GetEquipmentInventoryDS) do
				ItemSlotHandler.MoveToSlot(plr,v)
			end
		else
			CreateItem.Create(1,true,plr)
		end
		if GetConsumableInventoryDS then
			for i,v in pairs(GetConsumableInventoryDS) do
				ItemSlotHandler.MoveToSlot(plr,v)
			end
		end
		if GetMaterialInventoryDS then
			for i,v in pairs(GetMaterialInventoryDS) do
				ItemSlotHandler.MoveToSlot(plr,v)
			end
		end
		if GetBankInventoryDS then
			for i,v in pairs(GetBankInventoryDS) do
				ItemSlotHandler.MoveToSlot(plr,v,true)
			end
		end
		print(GetEquipmentInventoryDS)
		print("GetStatsDS: "..string.len(HttpServ:JSONEncode(GetStatsDS)))
		print("GetEquipmentInventoryDS: "..string.len(HttpServ:JSONEncode(GetEquipmentInventoryDS)))
		local DataLoadBoolean = Instance.new("BoolValue")
		DataLoadBoolean.Name = "DataLoaded"
		DataLoadBoolean.Parent = plr
	end)
end

SaveData = function(plr)
	pcall(function()
		local PlayerStat = plr:FindFirstChild("PlayerData")
		local Inventory = plr:FindFirstChild("Inventory")
		local Equipments = Inventory:FindFirstChild("Equipments")
		local Materials = Inventory:FindFirstChild("Materials")
		local Consumables = Inventory:FindFirstChild("Consumables")
		local Bank = plr:FindFirstChild("Bank")
		local EquipmentsTable, ConsumablesTable, MaterialsTable, BankTable = ItemSlotHandler.GetSlots(plr)
		if (PlayerStat~=nil) then
			local Level = PlayerStat:GetAttribute("Level")
			local Exp = PlayerStat:GetAttribute("Exp")
			local Gold = PlayerStat:GetAttribute("Gold")
			local Superiority = PlayerStat:GetAttribute("Superiority")
			local StatPoints = PlayerStat:GetAttribute("StatPoints")
			local AssignedStatPoints = PlayerStat:GetAttribute("AssignedStatPoints")
			local Str = PlayerStat:GetAttribute("Str")
			local Dex = PlayerStat:GetAttribute("Dex")
			local Int = PlayerStat:GetAttribute("Int")
			local Vit = PlayerStat:GetAttribute("Vit")
			local Health = PlayerStat:GetAttribute("Health")
			local Defense = PlayerStat:GetAttribute("Defense")
			local Mana = PlayerStat:GetAttribute("Mana")
			local Speed = PlayerStat:GetAttribute("Speed")
			local JumpPower = PlayerStat:GetAttribute("JumpPower")
			local BaseDamage = PlayerStat:GetAttribute("BaseDamage")
			local BaseCritChance = PlayerStat:GetAttribute("BaseCritChance")
			local BaseCritDamage = PlayerStat:GetAttribute("BaseCritDamage")
			local Ferocity = PlayerStat:GetAttribute("Ferocity")
			local AttackSpeed = PlayerStat:GetAttribute("AttackSpeed")
			local HealthRegenRate = PlayerStat:GetAttribute("HealthRegenRate")
			local ManaRegenRate = PlayerStat:GetAttribute("ManaRegenRate")
			local RangedDefense = PlayerStat:GetAttribute("RangedDefense")
			local MagicDefense = PlayerStat:GetAttribute("MagicDefense")
			local RangedAttack = PlayerStat:GetAttribute("RangedAttack")
			local MagicAttack = PlayerStat:GetAttribute("MagicAttack")
			local StatsTable = {Level,Exp,Gold,Superiority,StatPoints,AssignedStatPoints,Str,Dex,Int,Vit,Health,Defense,Mana,Speed,JumpPower,BaseDamage,BaseCritChance,BaseCritDamage,Ferocity,AttackSpeed,HealthRegenRate,ManaRegenRate,RangedDefense,MagicDefense,RangedAttack,MagicAttack}
			for i,v in pairs(StatsTable) do
				if v == nil then
					print("removed nil value")
					table.remove(StatsTable,v)
				end
			end
			Stats:SetAsync(plr.UserId,StatsTable)
			print("Saved Datas")
		end
		ItemSlotHandler.CorrectSlotNumber(plr)
		if (Equipments ~= nil) then
			EquipmentInventory:SetAsync(plr.UserId,EquipmentsTable)
		end
		if (Consumables ~= nil) then
			ConsumableInventory:SetAsync(plr.UserId,ConsumablesTable)
		end
		if (Materials ~= nil) then
			MaterialInventory:SetAsync(plr.UserId,MaterialsTable)
		end
		if (Bank ~= nil) then
			BankInventory:SetAsync(plr.UserId,BankTable)
		end
	end)
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

	pcall(function()
		LoadData(plr,PlayerStat,PlayerInventory)
	end)
	ItemSlotHandler.CorrectSlotNumber(plr)
	while wait(60) do
		if (plr~=nil) then
			pcall(function()
				SaveData(plr)
				print("Auto Saved")
			end)
		else break
		end
	end
end)

game.Players.PlayerRemoving:Connect(function(plr)
	if (not plr) then return end
	pcall(function()
		SaveData(plr)
	end)
end)

local ServerTimeout = 15
if RunService:IsStudio() then
	ServerTimeout = 5
end
game:BindToClose(function()
	if #game.Players:GetPlayers() <= 1 then return end
	for _,v in pairs(game.Players:GetPlayers()) do
		if (v~=nil) then SaveData(v) end
	end
	wait(ServerTimeout)
end)