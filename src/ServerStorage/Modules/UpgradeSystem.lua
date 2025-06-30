--APIs
--[[
Main APIs:
local a = require(game.ServerStorage.Modules.UpgradeSystem) local b,c = a.ApplyUpgrader(game.Players.tano_dev,"Equipments_4",999,true) print(b,c)
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
--local NameOrIDConverter = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("NameOrIDConverter"))
local ItemDictionaryHandler = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("ItemDictionaryHandler"))
local ItemSlotHandler = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("ItemSlotHandler"))
local CopyTable = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("CopyTable"))
local ItemStateData = require(game:GetService("ReplicatedStorage"):WaitForChild("GameItems"):WaitForChild("ItemStateData"))
local EquipmentFormat = require(game:GetService("ReplicatedStorage"):WaitForChild("Format"):WaitForChild("EquipmentFormat"))
local Material_ConsumableFormat = require(game:GetService("ReplicatedStorage"):WaitForChild("Format"):WaitForChild("Material_ConsumableFormat"))
local RngModule = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("RngModule"))
local ItemHandler =  require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("ItemHandler"))
local FormatFolder = game:GetService("ReplicatedStorage"):WaitForChild("Format")
local StatsPriority = require(game:GetService("ReplicatedStorage"):WaitForChild("Format"):WaitForChild("StatsPriority"))
local Equipment = FormatFolder:WaitForChild("Equipment")
local Material_Consumable = FormatFolder:WaitForChild("Material_Consumable")
local StringConverterPattern = "(%a+)%s?_%s?(%d+)"
local UpgradeStringConverterPattern = "(%d+)%s?:%s?(%d+)%s?:([+-]?%d+)"
local StatStringConverterPattern = "(%d+)%s?:%s?(%d+)"
local ConditionStringConverterPattern = "(%a+)%s?_([+-]?%d+)_([+-]?%d+)"
local ItemType = require(game:GetService("ReplicatedStorage"):WaitForChild("GameItems"):WaitForChild("ItemType"))
local Stats = {
	"Str",
	"Dex",
	"Int",
	"Vit",
	"Health",
	"Defense",
	"Mana",
	"Speed",
	"JumpPower",
	"Damage",
	"CritChance",
	"CritDamage",
	"Ferocity",
	"AttackSpeed",
	"HealthRegenRate",
	"ManaRegenRate",
	"RangedDefense",
	"MagicDefense",
	"RangedAttack",
	"MagicAttack",
	"DodgeChance",
	"MissChance",
}
local BaseStats = {
	--Str = 1,
	--Dex = 1,
	--Int = 1,
	--Vit = 1,
	--Health = 15,
	--Defense = 3,
	--Mana = 15,
	--Speed = 1,
	--JumpPower = 1,
	--Damage = 3,
	--CritChance = 0.5,
	--CritDamage = 5,
	--Ferocity = 0.5,
	--AttackSpeed = 1,
	--HealthRegenRate = 0.5,
	--ManaRegenRate = 0.5,
	--RangedDefense = 3,
	--MagicDefense = 3,
	--RangedAttack = 3,
	--MagicAttack = 3,
	--DodgeChance = 0.5,
	--MissChance = 0.5,
	Health = 5,
	Defense = 2,
	Damage = 1,
	CritChance = 0.3,
	CritDamage = 3,
	Mana = 5,
	AttackSpeed = 1,
	Ferocity = 0.5,
	HealthRegenRate = 0.5,
	ManaRegenRate = 0.5,
	ActionTurn = 0.1,
	ActionBonusRate = 5,
	Speed = 1,
	Jump = 1,
	Luck = 5,
	BonusCoins = 5,
	RangedDamage = 1,
	RangedDefense = 1,
	MagicDamage = 1,
	MagicDefense = 1,
	TrueDamage = 1,
	TrueDefense = 1,
	DefenseFierce = 1,
	MissChance = 1,
	DodgeChance = 1,
	DamageReduction = 1,
	ProfessionExp = 1,
	ClassExp = 1,
	SpellExp = 1,
	Strength = 1,
	Dexterity = 1,
	Intelligence = 1,
	Vitality = 1,
	Looting = 1,
	Proficiency = 1,
	HarvestSpeed = 5,
	FarmingFortune = 5,
	FarmingPristine = 5,
	CuttingPower = 5,
	CuttingSpeed = 5,
	ForagingFortune = 5,
	ForagingPristine = 5,
	ReelingPower = 5,
	Lure = 5,
	RareFishChance = 5,
	TreasureChance = 5,
	MiningPower = 5,
	MiningSpeed = 5,
	MiningFortune = 5,
	MiningPristine = 5,
	GemPower = 5,
	GemChance = 5,
	Refinery = 5,
	Duration = 5,
	Effectiveness = 5,
	CookingSpeed = 5,
	RareEnchantChance = 5,
}
local EquippedTab = {
	"Weapon",
	"OffHand",
	"Aura",
	"Pet",
	"Helmet",
	"Chestplate",
	"Boots",
	Accessory = {
		"Slot1",
		"Slot2",
		"Slot3",
		"Slot4",
		"Slot5",
		"Slot6",
		"Slot7",
		"Slot8",
		"Slot9",
	}
}
--local SpecialUpgradeStats = {
--	"ResetStats",
--	"ResetFailedUpgrades",
--	"ResetUpgradeSlots",
--	"BaseStats",
--}
--local OnSuccessSpecialStats = {
--	"UpgradeAttempts",
--	"SetPurity",
--	"SetCorruption",
--}
local function Round(n, decimals)
	decimals = decimals or 0
	return math.floor(n * 10^decimals) / 10^decimals
end
local function AddValue(Table,Key,Value)
	if type(Value) == "boolean" then
		Table[Key] = Value	
	elseif type(Value) == "table" then
		Table[Key] = Value	
	else
		if Table[Key] then
			Table[Key]= Table[Key] + Value
		else
			Table[Key] = Value
		end
	end
end
local UpgradeSystem = {}
function UpgradeSystem.ApplyUpgrader(Player,SelectedSlot,UpgraderSlot,Mode)
	local IsAdmin = Mode or false
	local Bank = Player:WaitForChild("Bank")
	local Inventory = Player:WaitForChild("Inventory")
	local Equipments = Inventory:WaitForChild("Equipments")
	local Consumables = Inventory:WaitForChild("Consumables")
	local Equipped = Inventory:WaitForChild("Equipped")
	local MainTab = Equipped:WaitForChild("Main")
	local AccessoryTab = Equipped:WaitForChild("Accessory")
	local SelectedItem
	local UpgraderItem
	--Where magic begin
	local SelectedName, SelectedNumber = string.match(SelectedSlot,StringConverterPattern) -- Getting Slot Location
	local UpgraderName, UpgraderNumber
	--Getting Upgrade Item
	if not IsAdmin then
		UpgraderName, UpgraderNumber = string.match(UpgraderSlot,StringConverterPattern)
	end
	if SelectedName == "Equipments" then
		if #Equipments:FindFirstChild("Slot_"..SelectedNumber):GetChildren() == 1 then
			SelectedItem = Equipments:FindFirstChild("Slot_"..SelectedNumber):FindFirstChildOfClass("NumberValue")
		else
			return false,"SelectedSlot can be empty or more than 1"
		end
	elseif table.find(EquippedTab,SelectedSlot) and SelectedName == nil and SelectedNumber == nil then
		if #MainTab:FindFirstChild(SelectedSlot):GetChildren() == 1 then
			SelectedItem = MainTab:FindFirstChild(SelectedSlot):FindFirstChildOfClass("NumberValue")
		else
			return false,"SelectedSlot can be empty or more than 1"
		end
	else
		return false, "Something wrong with SelectedSlot"
	end

	--Getting Upgrader
	if not IsAdmin then
		if UpgraderName == "Consumables" then
			if #Consumables:FindFirstChild("Slot_"..UpgraderNumber):GetChildren() == 1 then
				UpgraderItem = Consumables:FindFirstChild("Slot_"..UpgraderNumber):FindFirstChildOfClass("NumberValue")
			else
				return false,"SelectedSlot can be empty or more than 1"
			end
		end
	end
	local SName,SType,SSubType = ItemDictionaryHandler.IDToName(SelectedItem.Value)
	local UName,UType,USubType
	if not IsAdmin then
		UName,UType,USubType = ItemDictionaryHandler.IDToName(UpgraderItem.Value)
	else
		UName,UType,USubType = ItemDictionaryHandler.IDToName(UpgraderSlot)
	end

	if SSubType == "Pet" then return false, "Wrong SS SubType" end
	if (not USubType) == "Upgrader" then return false, "Wrong US SubType" end
	local Selected 
	local Upgrader 
	--Getting Selected/Upgrader
	if ReplicatedStorage:WaitForChild("GameItems"):WaitForChild("Equipments"):WaitForChild(SName) then
		Selected = require(ReplicatedStorage:WaitForChild("GameItems"):WaitForChild("Equipments"):WaitForChild(SName))
	else return false,"Couldn't find selected" end
	if ReplicatedStorage:WaitForChild("GameItems"):WaitForChild("Consumables"):WaitForChild(UName) then
		Upgrader = require(ReplicatedStorage:WaitForChild("GameItems"):WaitForChild("Consumables"):WaitForChild(UName))
	else return false,"Couldn't find upgrader" end
	--Get State
	local ItemState = {}
	if SelectedItem:GetAttribute("State") == "" then
		ItemState = {}
	else
		local strstate = SelectedItem:GetAttribute("State")
		for i,v in pairs(strstate:split(":")) do
			table.insert(ItemState,tonumber(v))
		end
	end
	print(ItemState)
	--Into upgrading stuffs
	local Modification = Upgrader.Modification
	local UpgradeRng = Modification.UpgradeRng
	local UpgradeRange = Modification.UpgradeRange
	local SuccessRate = Modification.SuccessRate
	local OnFailRange = Modification.OnFailRange
	local UpgradeCount = Modification.UpgradeCount
	local Weight = Modification.Weight
	--Tables
	local Conditions = Modification.Conditions
	local AcceptType = Modification.AcceptType
	local Upgrade = Modification.Upgrade
	local OnFail = Modification.OnFail
	local Successed = Upgrade.Successed
	local Failed = OnFail.Failed
	--Variants
	local ConCodeName, ConRate, ConCap 
	local FinalSuccessRate = 0
	local FinalWeight = 0
	local WeightDivision = 0
	--Lil check b4 continue 
	if table.find(ItemState,8) then
		return false, "SayNoWithUpgrades"
	end
	-- No holies
	if table.find(ItemState,7) then
		if not IsAdmin then
			if UpgraderItem.Value == 100 then
				return false, "SayNoWithHolies"
			end
		else
			if UpgraderSlot == 100 then
				return false, "SayNoWithHolies"
			end
		end
	end
	if tonumber(SelectedItem:GetAttribute("UpgradeAttemptSuccessed")) + SelectedItem:FindFirstChild("Upgrades").Value >= tonumber(SelectedItem:GetAttribute("UpgradeAttempts")) then
		if UpgradeCount > 0 then
			return false,"No more spare slots"
		end
	end
	--Cody
	if Conditions == nil then
		FinalSuccessRate = SuccessRate
		ConCodeName = nil
		ConRate = 0
		ConCap = 100
	else
		for i,v in pairs(Conditions) do
			ConCodeName, ConRate, ConCap = string.match(v,ConditionStringConverterPattern)
			if ConCodeName == "Purity" then
				if math.abs(tonumber(ConRate)*tonumber(SelectedItem:GetAttribute("Purity"))) <= tonumber(ConCap) then
					FinalSuccessRate = FinalSuccessRate + (tonumber(ConRate)*tonumber(SelectedItem:GetAttribute("Purity")))/100
				else
					if tonumber(ConRate) < 0 then
						FinalSuccessRate = FinalSuccessRate - (tonumber(ConCap))/100
					else
						FinalSuccessRate = FinalSuccessRate + (tonumber(ConCap))/100
					end

				end
			elseif ConCodeName == "Corruption" then
				if tonumber(ConRate)*tonumber(SelectedItem:GetAttribute("Corruption")) <= tonumber(ConCap) then
					FinalSuccessRate = FinalSuccessRate + (tonumber(ConRate)*tonumber(SelectedItem:GetAttribute("Corruption")))/100
				else
					if tonumber(ConRate) < 0 then
						FinalSuccessRate = FinalSuccessRate - (tonumber(ConCap))/100
					else
						FinalSuccessRate = FinalSuccessRate + (tonumber(ConCap))/100
					end
				end
			elseif ConCodeName == "Rarity" then
				local RarityLevel
				if Selected.Rarity == "Common" then
					RarityLevel = 1
				elseif Selected.Rarity == "Uncommon" then
					RarityLevel = 2
				elseif Selected.Rarity == "Rare" then
					RarityLevel = 3
				elseif Selected.Rarity == "Epic" then
					RarityLevel = 4
				elseif Selected.Rarity == "Legendary" then
					RarityLevel = 5
				elseif Selected.Rarity == "Mythic" then
					RarityLevel = 6
				elseif Selected.Rarity == "Supreme" then
					RarityLevel = 7
				end
				if tonumber(ConRate)*RarityLevel <= tonumber(ConCap) then
					FinalSuccessRate = FinalSuccessRate + (tonumber(ConRate)*RarityLevel)/100
				else
					if tonumber(ConRate) < 0 then
						FinalSuccessRate = FinalSuccessRate - (tonumber(ConCap))/100
					else
						FinalSuccessRate = FinalSuccessRate + (tonumber(ConCap))/100
					end
				end
			elseif ConCodeName == "OnLessUpgradeAttempts" then
				if tonumber(ConRate)*SelectedItem:FindFirstChild("Upgrades").Value <= tonumber(ConCap) then
					FinalSuccessRate = FinalSuccessRate + (tonumber(ConRate)*SelectedItem:FindFirstChild("Upgrades").Value)/100
				else
					if tonumber(ConRate) < 0 then
						FinalSuccessRate = FinalSuccessRate - (tonumber(ConCap))/100
					else
						FinalSuccessRate = FinalSuccessRate + (tonumber(ConCap))/100
					end
				end
			elseif ConCodeName == "OnMoreUpgradeAttempts" then
				local LessUpgradeAttemptsRate = SelectedItem:GetAttribute("UpgradeAttempts")-SelectedItem:FindFirstChild("Upgrades").Value

				if tonumber(ConRate)*LessUpgradeAttemptsRate <= tonumber(ConCap) then
					FinalSuccessRate = FinalSuccessRate + (tonumber(ConRate)*LessUpgradeAttemptsRate)/100
				else
					if tonumber(ConRate) < 0 then
						FinalSuccessRate = FinalSuccessRate - (tonumber(ConCap))/100
					else
						FinalSuccessRate = FinalSuccessRate + (tonumber(ConCap))/100
					end
				end
			elseif ConCodeName == "NotUpgraded" then
				if  SelectedItem:GetAttribute("UpgradeAttempts") == Selected.UpgradeAttempts and SelectedItem:FindFirstChild("Upgrades").Value == 0 and SelectedItem:GetAttribute("UpgradeAttemptSuccessed") == 0 then
					FinalSuccessRate = tonumber(ConRate)/100
				else
					FinalSuccessRate = 0
					return false, "Item already upgraded"
				end 
			end
		end
		FinalSuccessRate = SuccessRate + FinalSuccessRate
	end
	print(FinalSuccessRate)
	if FinalSuccessRate <= 0 then
		return false,"Cannot apply this upgrade since the chance is 0<"
	elseif FinalSuccessRate > 1 then
		FinalSuccessRate = 1
	end
	if UpgradeRng == false then
		UpgradeRange = 1
	end
	--Moment of Truth
	local BruhMomento = RngModule.RNG(1,FinalSuccessRate)
	if table.find(ItemState,6) then
		BruhMomento = true
	end
	local UpgradeTable = CopyTable.Copy(Upgrade)
	local FinalUpgrade = {}
	local FakeUpgrade = {}
	local BackupUpgrade = {}
	UpgradeTable.Successed = {}
	if BruhMomento then
		local RngRolla = RngModule.RNG(2,1,UpgradeRange)
		local function Upgrading(UpgradingTable)
			BackupUpgrade = CopyTable.Copy(FakeUpgrade)
			for UpgradeIndex,UpgradeValue in pairs(UpgradingTable) do
				local Min,Max,Type = string.match(UpgradeIndex,UpgradeStringConverterPattern)
				if RngRolla <= tonumber(Max) and RngRolla >= tonumber(Min) then
					local AvailableUpgrades = {}
					for name,value in pairs(UpgradeValue) do
						table.insert(AvailableUpgrades,name)
					end
					if tonumber(Type) > 0 then
						local GainedWeight = 0
						for i = 1,tonumber(Type) do
							local RandomNumbering = math.random(#AvailableUpgrades)
							local RandomTable = AvailableUpgrades[RandomNumbering]
							local SelectedUpgrade = UpgradeValue[RandomTable]
							local SecondaryRng = RngModule.RNG(2,1,UpgradeRange)
							for IndexName,UValue in pairs(SelectedUpgrade) do
								local SelectedUpgradeMin,SelectedUpgradeMax = string.match(IndexName,StatStringConverterPattern)
								if SecondaryRng <= tonumber(SelectedUpgradeMax) and SecondaryRng >= tonumber(SelectedUpgradeMin) then
									local Amounts
									if UValue.LevelScale then
										local ItemLevel = Selected.ItemLevel/100
										local ItemLevelCalc = math.round(-0.5*ItemLevel^2+130*ItemLevel)
										local MinNum,MaxNum = string.match(UValue.Value,"([+-]?%d+):([+-]?%d+)")
										print(ItemLevelCalc)
										if ItemLevelCalc < MinNum then
											Amounts = MinNum
										elseif ItemLevelCalc > MaxNum then
											Amounts = MaxNum
										else
											Amounts = ItemLevelCalc
										end
									elseif UValue.Value then
										if type(UValue.Value) == "boolean" then
											Amounts = UValue.Value
										elseif type(UValue.Value) == "table" then
											Amounts = UValue.Value
										else 
											local MinNum,MaxNum = string.match(UValue.Value,"([+-]?%d+):([+-]?%d+)")
											Amounts = RngModule.RNG(2,tonumber(MinNum),tonumber(MaxNum))
										end 
									end
									AddValue(FakeUpgrade,RandomTable,Amounts)
									table.remove(AvailableUpgrades,RandomNumbering)
									GainedWeight = GainedWeight + UValue.Weight
								end
							end
						end
						GainedWeight = GainedWeight/tonumber(Type)
						if FinalWeight + GainedWeight <= Weight then
							FinalWeight = FinalWeight + GainedWeight
						else 
							FakeUpgrade = BackupUpgrade
						end
					elseif tonumber(Type) == 0 then
						local GainedWeight = 0

						local numb = {}
						for a,b in pairs(UpgradeValue) do
							table.insert(numb,a)
						end
						for i = 1,#numb do
							local RandomNumbering = math.random(#AvailableUpgrades)
							local RandomTable = AvailableUpgrades[RandomNumbering]
							local SelectedUpgrade = UpgradeValue[RandomTable]
							local SecondaryRng = RngModule.RNG(2,1,UpgradeRange)
							for IndexName,UValue in pairs(SelectedUpgrade) do
								local SelectedUpgradeMin,SelectedUpgradeMax = string.match(IndexName,StatStringConverterPattern)
								if SecondaryRng <= tonumber(SelectedUpgradeMax) and SecondaryRng >= tonumber(SelectedUpgradeMin) then
									local Amounts
									if UValue.LevelScale then
										print("a")
										local ItemLevel = Selected.ItemLevel/100
										local ItemLevelCalc = math.round(-0.5*ItemLevel^2+130*ItemLevel)
										local MinNum,MaxNum = string.match(UValue.LevelScale,"([+-]?%d+):([+-]?%d+)")
										print(ItemLevelCalc)
										if ItemLevelCalc < tonumber(MinNum) then
											Amounts = tonumber(MinNum)
										elseif ItemLevelCalc > tonumber(MaxNum) then
											Amounts = tonumber(MaxNum)
										else
											Amounts = ItemLevelCalc
										end
									elseif UValue.Value then
										if type(UValue.Value) == "boolean" then
											Amounts = UValue.Value
										elseif type(UValue.Value) == "table" then
											Amounts = UValue.Value
										else 
											local MinNum,MaxNum = string.match(UValue.Value,"([+-]?%d+):([+-]?%d+)")
											Amounts = RngModule.RNG(2,tonumber(MinNum),tonumber(MaxNum))
										end 
									end
									AddValue(FakeUpgrade,RandomTable,Amounts)
									table.remove(AvailableUpgrades,RandomNumbering)
									GainedWeight = GainedWeight + UValue.Weight
								end
							end
						end
						GainedWeight = GainedWeight/#numb
						if FinalWeight + GainedWeight <= Weight then
							FinalWeight = FinalWeight + GainedWeight
						else 
							FakeUpgrade = BackupUpgrade
						end
					elseif tonumber(Type) == -1 then
						local GainedWeight = 0
						local numb = {}
						for a,b in pairs(UpgradeValue) do
							table.insert(numb,a)
						end
						local ee = math.random(#numb)
						for i = 1,ee do
							local RandomNumbering = math.random(#AvailableUpgrades)
							local RandomTable = AvailableUpgrades[RandomNumbering]
							local SelectedUpgrade = UpgradeValue[RandomTable]
							local SecondaryRng = RngModule.RNG(2,1,UpgradeRange)
							for IndexName,UValue in pairs(SelectedUpgrade) do
								local SelectedUpgradeMin,SelectedUpgradeMax = string.match(IndexName,StatStringConverterPattern)
								if SecondaryRng <= tonumber(SelectedUpgradeMax) and SecondaryRng >= tonumber(SelectedUpgradeMin) then
									local Amounts
									if UValue.LevelScale then
										local ItemLevel = Selected.ItemLevel/100
										local ItemLevelCalc = math.round(-0.5*ItemLevel^2+130*ItemLevel)
										local MinNum,MaxNum = string.match(UValue.Value,"([+-]?%d+):([+-]?%d+)")
										print(ItemLevelCalc)
										if ItemLevelCalc < MinNum then
											Amounts = MinNum
										elseif ItemLevelCalc > MaxNum then
											Amounts = MaxNum
										else
											Amounts = ItemLevelCalc
										end
									elseif UValue.Value then
										if type(UValue.Value) == "boolean" then
											Amounts = UValue.Value
										elseif type(UValue.Value) == "table" then
											Amounts = UValue.Value
										else 
											local MinNum,MaxNum = string.match(UValue.Value,"([+-]?%d+):([+-]?%d+)")
											Amounts = RngModule.RNG(2,tonumber(MinNum),tonumber(MaxNum))
										end 
									end
									AddValue(FakeUpgrade,RandomTable,Amounts)
									table.remove(AvailableUpgrades,RandomNumbering)
									GainedWeight = GainedWeight + UValue.Weight
								end
							end
						end
						GainedWeight = GainedWeight/ee
						if FinalWeight + GainedWeight <= Weight then
							FinalWeight = FinalWeight + GainedWeight
						else 
							FakeUpgrade = BackupUpgrade
						end
					end
					--[[if Type == "Double" then
					--	local GainedWeight = 0
					--	for i = 1,2 do
					--		local RandomNumbering = math.random(#AvailableUpgrades)
					--		local RandomTable = AvailableUpgrades[RandomNumbering]
					--		local SelectedUpgrade = va[RandomTable]
					--		local SecondaryRng = RngModule.RNG(2,1,UpgradeRange)
					--		for i,v in pairs(SelectedUpgrade) do
					--			local SelectedUpgradeMin,SelectedUpgradeMax = string.match(i,StatStringConverterPattern)
					--			if SecondaryRng <= tonumber(SelectedUpgradeMax) and SecondaryRng >= tonumber(SelectedUpgradeMin) then
					--				local Amounts
					--				if type(v.Value) == "boolean" then
					--					Amounts = v.Value
					--				elseif type(v.Value) == "table" then
					--					Amounts = v.Value
					--				else 
					--					local MinNum,MaxNum = string.match(v.Value,"([+-]?%d+):([+-]?%d+)")
					--					Amounts = RngModule.RNG(2,tonumber(MinNum),tonumber(MaxNum))
					--				end 
					--				AddValue(FakeUpgrade,RandomTable,Amounts)
					--				table.remove(AvailableUpgrades,RandomNumbering)
					--				GainedWeight = GainedWeight + v.Weight
					--			end
					--		end
					--	end
					--	GainedWeight = GainedWeight/2
					--	if FinalWeight + GainedWeight <= Weight then
					--		FinalWeight = FinalWeight + GainedWeight
					--	else 
					--		FakeUpgrade = BackupUpgrade
					--	end
					--elseif Type == "Triple" then
					--	local GainedWeight = 0
					--	for i = 1,3 do
					--		local RandomNumbering = math.random(#AvailableUpgrades)
					--		local RandomTable = AvailableUpgrades[RandomNumbering]
					--		local SelectedUpgrade = va[RandomTable]
					--		local SecondaryRng = RngModule.RNG(2,1,UpgradeRange)
					--		for i,v in pairs(SelectedUpgrade) do
					--			local SelectedUpgradeMin,SelectedUpgradeMax = string.match(i,StatStringConverterPattern)
					--			if SecondaryRng <= tonumber(SelectedUpgradeMax) and SecondaryRng >= tonumber(SelectedUpgradeMin) then
					--				local Amounts
					--				if type(v.Value) == "boolean" then
					--					Amounts = v.Value
					--				elseif type(v.Value) == "table" then
					--					Amounts = v.Value
					--				else 
					--					local MinNum,MaxNum = string.match(v.Value,"([+-]?%d+):([+-]?%d+)")
					--					Amounts = RngModule.RNG(2,tonumber(MinNum),tonumber(MaxNum))
					--				end 
					--				AddValue(FakeUpgrade,RandomTable,Amounts)
					--				table.remove(AvailableUpgrades,RandomNumbering)
					--				GainedWeight = GainedWeight + v.Weight
					--			end
					--		end
					--	end
					--	GainedWeight = GainedWeight/3
					--	if FinalWeight + GainedWeight <= Weight then
					--		FinalWeight = FinalWeight + GainedWeight
					--	else 
					--		FakeUpgrade = BackupUpgrade
					--	end
					--elseif Type == "Quadruple" then
					--	local GainedWeight = 0
					--	for i = 1,4 do
					--		local RandomNumbering = math.random(#AvailableUpgrades)
					--		local RandomTable = AvailableUpgrades[RandomNumbering]
					--		local SelectedUpgrade = va[RandomTable]
					--		local SecondaryRng = RngModule.RNG(2,1,UpgradeRange)
					--		for i,v in pairs(SelectedUpgrade) do
					--			local SelectedUpgradeMin,SelectedUpgradeMax = string.match(i,StatStringConverterPattern)
					--			if SecondaryRng <= tonumber(SelectedUpgradeMax) and SecondaryRng >= tonumber(SelectedUpgradeMin) then
					--				local Amounts
					--				if type(v.Value) == "boolean" then
					--					Amounts = v.Value
					--				elseif type(v.Value) == "table" then
					--					Amounts = v.Value
					--				else 
					--					local MinNum,MaxNum = string.match(v.Value,"([+-]?%d+):([+-]?%d+)")
					--					Amounts = RngModule.RNG(2,tonumber(MinNum),tonumber(MaxNum))
					--				end 
					--				AddValue(FakeUpgrade,RandomTable,Amounts)
					--				table.remove(AvailableUpgrades,RandomNumbering)
					--				GainedWeight = GainedWeight + v.Weight
					--			end
					--		end
					--	end
					--	GainedWeight = GainedWeight/4
					--	if FinalWeight + GainedWeight <= Weight then
					--		FinalWeight = FinalWeight + GainedWeight
					--	else 
					--		FakeUpgrade = BackupUpgrade
					--	end
					--elseif Type == "Random" then
					--	local GainedWeight = 0
					--	local numb = {}
					--	for a,b in pairs(va) do
					--		table.insert(numb,a)
					--	end
					--	local ee = math.random(#numb)
					--	for i = 1,ee do
					--		local RandomNumbering = math.random(#AvailableUpgrades)
					--		local RandomTable = AvailableUpgrades[RandomNumbering]
					--		local SelectedUpgrade = va[RandomTable]
					--		local SecondaryRng = RngModule.RNG(2,1,UpgradeRange)
					--		for i,v in pairs(SelectedUpgrade) do
					--			local SelectedUpgradeMin,SelectedUpgradeMax = string.match(i,StatStringConverterPattern)
					--			if SecondaryRng <= tonumber(SelectedUpgradeMax) and SecondaryRng >= tonumber(SelectedUpgradeMin) then
					--				local Amounts
					--				if type(v.Value) == "boolean" then
					--					Amounts = v.Value
					--				elseif type(v.Value) == "table" then
					--					Amounts = v.Value
					--				else 
					--					local MinNum,MaxNum = string.match(v.Value,"([+-]?%d+):([+-]?%d+)")
					--					Amounts = RngModule.RNG(2,tonumber(MinNum),tonumber(MaxNum))
					--				end 
					--				AddValue(FakeUpgrade,RandomTable,Amounts)
					--				table.remove(AvailableUpgrades,RandomNumbering)
					--				GainedWeight = GainedWeight + v.Weight
					--			end
					--		end
					--	end
					--	GainedWeight = GainedWeight/ee
					--	if FinalWeight + GainedWeight <= Weight then
					--		FinalWeight = FinalWeight + GainedWeight
					--	else 
					--		FakeUpgrade = BackupUpgrade
					--	end
					--elseif Type == "All" then
					--	local GainedWeight = 0

					--	local numb = {}
					--	for a,b in pairs(va) do
					--		table.insert(numb,a)
					--	end
					--	for i = 1,#numb do
					--		local RandomNumbering = math.random(#AvailableUpgrades)
					--		local RandomTable = AvailableUpgrades[RandomNumbering]
					--		local SelectedUpgrade = va[RandomTable]
					--		local SecondaryRng = RngModule.RNG(2,1,UpgradeRange)
					--		for i,v in pairs(SelectedUpgrade) do
					--			local SelectedUpgradeMin,SelectedUpgradeMax = string.match(i,StatStringConverterPattern)
					--			if SecondaryRng <= tonumber(SelectedUpgradeMax) and SecondaryRng >= tonumber(SelectedUpgradeMin) then
					--				local Amounts
					--				if type(v.Value) == "boolean" then
					--					Amounts = v.Value
					--				elseif type(v.Value) == "table" then
					--					Amounts = v.Value
					--				else 
					--					local MinNum,MaxNum = string.match(v.Value,"([+-]?%d+):([+-]?%d+)")
					--					Amounts = RngModule.RNG(2,tonumber(MinNum),tonumber(MaxNum))
					--				end 
					--				AddValue(FakeUpgrade,RandomTable,Amounts)
					--				table.remove(AvailableUpgrades,RandomNumbering)
					--				GainedWeight = GainedWeight + v.Weight
					--			end
					--		end
					--	end
					--	GainedWeight = GainedWeight/#numb
					--	if FinalWeight + GainedWeight <= Weight then
					--		FinalWeight = FinalWeight + GainedWeight
					--	else 
					--		FakeUpgrade = BackupUpgrade
					--	end
					--elseif Type == "Nil" then
					--	local GainedWeight = 0
					--	local RandomNumbering = math.random(#AvailableUpgrades)
					--	local RandomTable = AvailableUpgrades[RandomNumbering]
					--	local SelectedUpgrade = va[RandomTable]
					--	local SecondaryRng = RngModule.RNG(2,1,UpgradeRange)
					--	for i,v in pairs(SelectedUpgrade) do
					--		local SelectedUpgradeMin,SelectedUpgradeMax = string.match(i,StatStringConverterPattern)
					--		if SecondaryRng <= tonumber(SelectedUpgradeMax) and SecondaryRng >= tonumber(SelectedUpgradeMin) then
					--			local Amounts
					--			if type(v.Value) == "boolean" then
					--				Amounts = v.Value
					--			elseif type(v.Value) == "table" then
					--				Amounts = v.Value
					--			else 
					--				local MinNum,MaxNum = string.match(v.Value,"([+-]?%d+):([+-]?%d+)")
					--				Amounts = RngModule.RNG(2,tonumber(MinNum),tonumber(MaxNum))
					--			end 
					--			AddValue(FakeUpgrade,RandomTable,Amounts)
					--			table.remove(AvailableUpgrades,RandomNumbering)
					--			GainedWeight = GainedWeight + v.Weight
					--		end
					--	end
					--	if FinalWeight + GainedWeight <= Weight then
					--		FinalWeight = FinalWeight + GainedWeight
					--	else 
					--		FakeUpgrade = BackupUpgrade
					--	end
					--end]]
				end
			end
		end
		repeat 
			if Upgrade["OnAll"] then
				Upgrading(Upgrade["OnAll"] )
			elseif table.find(ItemType.Weapon,SSubType) and not Upgrade["OnAll"] and Upgrade["OnWeapon"] then
				Upgrading(Upgrade["OnWeapon"])
			elseif SSubType == "Headgear" and not Upgrade["OnAll"] and Upgrade["OnHeadgear"] then
				Upgrading(Upgrade["OnHeadgear"])
			elseif SSubType == "Chestplate" and not Upgrade["OnAll"] and Upgrade["OnChestplate"] then
				Upgrading(Upgrade["OnChestplate"])
			elseif SSubType == "Boots" and not Upgrade["OnAll"] and Upgrade["OnBoots"] then
				Upgrading(Upgrade["OnBoots"])
			elseif table.find(ItemType.Armor,SSubType) and not Upgrade["OnAll"] and Upgrade["OnArmor"] then
				Upgrading(Upgrade["OnArmor"])
			elseif SSubType == "Accessory" and not Upgrade["OnAll"] and Upgrade["OnAccessory"] then
				Upgrading(Upgrade["OnAccessory"])
			elseif table.find(ItemType.Tool,SSubType) and not Upgrade["OnAll"] and Upgrade["OnTool"] then
				Upgrading(Upgrade["OnTool"])
			end
		until FinalWeight >= Weight 
		FinalUpgrade = FakeUpgrade
		local function ApplyUpgrade(UpgradingTable)
			if UpgradingTable["Reset"] then
				SelectedItem:FindFirstChild("Upgrades").Value = 0
				SelectedItem:SetAttribute("UpgradeAttempts",Selected.UpgradeAttempts)
				SelectedItem:SetAttribute("UpgradeAttemptSuccessed",0)
				SelectedItem:SetAttribute("Purity",0)
				SelectedItem:SetAttribute("Corruption",0)
				for i,v in pairs(SelectedItem:FindFirstChild("Upgrades"):GetAttributes()) do
					SelectedItem:FindFirstChild("Upgrades"):SetAttribute(i,nil)
				end
				UpgradingTable["Reset"] = nil
			end
			if UpgradingTable["ResetUpgrades"] then
				SelectedItem:FindFirstChild("Upgrades").Value = 0
				SelectedItem:SetAttribute("UpgradeAttempts",Selected.UpgradeAttempts)
				SelectedItem:SetAttribute("UpgradeAttemptSuccessed",0)
				for i,v in pairs(SelectedItem:FindFirstChild("Upgrades"):GetAttributes()) do
					SelectedItem:FindFirstChild("Upgrades"):SetAttribute(i,nil)
				end
				UpgradingTable["ResetUpgrades"] = nil
			end
			if UpgradingTable["ResetUpgradeSlots"] then
				SelectedItem:SetAttribute("UpgradeAttempts",Selected.UpgradeAttempts)
				UpgradingTable["ResetUpgradeSlots"] = nil
			end
			if UpgradingTable["ResetPurity"] then
				SelectedItem:SetAttribute("Purity",0)
				UpgradingTable["ResetPurity"] = nil
			end
			if UpgradingTable["ResetCorruption"] then
				SelectedItem:SetAttribute("Corruption",0)
				UpgradingTable["ResetCorruption"] = nil
			end
			if UpgradingTable["ResetFailedUpgrades"] then
				SelectedItem:FindFirstChild("Upgrades").Value = 0
				UpgradingTable["ResetFailedUpgrades"] = nil
			end
			if UpgradingTable["ApplyState"] then
				print("applying state")
				print(UpgradingTable["ApplyState"])
				local currentstate = SelectedItem:GetAttribute("State")
				for n,m in pairs(UpgradingTable["ApplyState"]) do
					if not table.find(ItemState,m) then
						if currentstate == "" then
							currentstate = m
						else
							currentstate = currentstate..":"..m
						end
					end
				end
				SelectedItem:SetAttribute("State",currentstate)
				UpgradingTable["ApplyState"] = nil
			end
			if UpgradingTable["BaseStats"] then
				print(UpgradingTable["BaseStats"])
				print(UpgradingTable)
				local NewBaseStats = {}
				local BaseStatAmounts = UpgradingTable["BaseStats"]
				for key,value in pairs(Selected.BaseStats) do
					print(key,value)
					NewBaseStats[StatsPriority[key]] = key
					--table.insert(NewBaseStats,key)
				end
				print(NewBaseStats)
				repeat
					for i,v in pairs(NewBaseStats) do
						if BaseStats[v] then
							if BaseStatAmounts == 0 then
								break
							end
							AddValue(UpgradingTable,v,BaseStats[v])
							BaseStatAmounts -= 1
						end
					end
				until BaseStatAmounts == 0
				UpgradingTable["BaseStats"] = nil
			end
			print(UpgradingTable)
			for i,v in pairs(UpgradingTable) do
				local OriginalValue = SelectedItem:FindFirstChild("Upgrades"):GetAttribute(i) or 0
				SelectedItem:FindFirstChild("Upgrades"):SetAttribute(i,OriginalValue+v)
			end
			local currentcount = SelectedItem:GetAttribute("UpgradeAttemptSuccessed")
			SelectedItem:SetAttribute("UpgradeAttemptSuccessed",currentcount+UpgradeCount)
		end
		for i,v in pairs(Upgrade.Successed) do
			local Min,Max = string.match(i,StatStringConverterPattern)
			if RngRolla <= tonumber(Max) and RngRolla >= tonumber(Min) then
				print(FinalUpgrade)
				ApplyUpgrade(FinalUpgrade)
				for a,b in pairs(v) do
					if a == "SetPurity" then
						if not table.find(ItemState,4) then
							local currentpurity = SelectedItem:GetAttribute("Purity")
							SelectedItem:SetAttribute("Purity",currentpurity + b)
						end
					elseif a == "SetCorruption" then
						if not table.find(ItemState,5) then
							local currentcorruption = SelectedItem:GetAttribute("Corruption")
							SelectedItem:SetAttribute("Corruption",currentcorruption + b)
						end
					elseif a == "UpgradeSlots" then
						local currentslot = SelectedItem:GetAttribute("UpgradeAttempts")
						SelectedItem:SetAttribute("UpgradeAttempts",currentslot + b)
					elseif a == "ResetStats" then
						if b == "All" then
							for e,c in pairs(SelectedItem:FindFirstChild("Upgrades"):GetAttributes()) do
								SelectedItem:FindFirstChild("Upgrades"):SetAttribute(i,nil)
							end
						else
							for g,f in pairs(b) do
								SelectedItem:FindFirstChild("Upgrades"):SetAttribute(f,nil)
							end
						end
					end
				end
				if not IsAdmin then
					UpgraderItem:Destroy()
				end
				return true,v.Message,v.MessageColor
			end
		end
	else
		--Fail
		local F = {}
		local RngRolla = RngModule.RNG(2,1,OnFailRange)
		local function Failing(FailingTable)
			for i,v in pairs(FailingTable) do
				local Min,Max = string.match(i,StatStringConverterPattern)
				if RngRolla <= tonumber(Max) and RngRolla >= tonumber(Min) then
					print(v)
					for name,value in pairs(v) do
						F[name] = value
					end
				end
			end
		end
		--[[
		if Upgrade["OnAll"] then
				Upgrading(Upgrade["OnAll"] )
			elseif table.find(ItemType.Weapon,SSubType) and not Upgrade["OnAll"] and Upgrade["OnWeapon"] then
				Upgrading(Upgrade["OnWeapon"])
			elseif table.find(ItemType.Armor,SSubType) and not Upgrade["OnAll"] and Upgrade["OnArmor"] then
				Upgrading(Upgrade["OnArmor"])
			elseif SSubType == "Headgear" and not Upgrade["OnAll"] and Upgrade["OnHeadgear"] then
				Upgrading(Upgrade["OnHeadgear"])
			elseif SSubType == "Chestplate" and not Upgrade["OnAll"] and Upgrade["OnChestplate"] then
				Upgrading(Upgrade["OnChestplate"])
			elseif SSubType == "Boots" and not Upgrade["OnAll"] and Upgrade["OnBoots"] then
				Upgrading(Upgrade["OnBoots"])
			elseif SSubType == "Accessory" and not Upgrade["OnAll"] and Upgrade["OnAccessory"] then
				Upgrading(Upgrade["OnAccessory"])
			elseif table.find(ItemType.Tool,SSubType) and not Upgrade["OnAll"] and Upgrade["OnTool"] then
				Upgrading(Upgrade["OnTool"])
			end
		]]
		if OnFail["OnAll"] then
			Failing(OnFail["OnAll"] )
		elseif table.find(ItemType.Weapon,SSubType) and not OnFail["OnAll"] and OnFail["OnWeapon"] then
			Failing(OnFail["OnWeapon"])
		elseif SSubType == "Headgear" and not OnFail["OnAll"] and OnFail["OnHeadgear"] then
			Failing(OnFail["OnHeadgear"])
		elseif SSubType == "Chestplate" and not OnFail["OnAll"] and OnFail["OnChestplate"] then
			Failing(OnFail["OnChestplate"])
		elseif SSubType == "Boots" and not OnFail["OnAll"] and OnFail["OnBoots"] then
			Failing(OnFail["OnBoots"])
		elseif table.find(ItemType.Armor,SSubType) and not Upgrade["OnAll"] and Upgrade["OnArmor"] then
			Failing(OnFail["OnArmor"])
		elseif SSubType == "Accessory" and not OnFail["OnAll"] and OnFail["OnAccessory"] then
			Failing(OnFail["OnAccessory"])
		elseif table.find(ItemType.Tool,SSubType) and not Upgrade["OnAll"] and Upgrade["OnTool"] then
			Failing(OnFail["OnTool"])
		end

		local function ApplyFail(UpgradingTable)
			for i,v in pairs(UpgradingTable) do
				if i == "Destroy" then
					if table.find(ItemState,1) then
						SelectedItem:FindFirstChild("Upgrades").Value = SelectedItem:FindFirstChild("Upgrades").Value + 1
					elseif table.find(ItemState,1) and table.find(ItemState,3) then
						--nothing happened
					else
						local PurityLevel = SelectedItem:GetAttribute("Purity")
						local CorruptionLevel = SelectedItem:GetAttribute("Corruption")
						if PurityLevel > 0 and PurityLevel <= 2 then
							local pityrng = RngModule.RNG(2,1,3)
							ItemHandler.ItemIncrement(Player,98,pityrng)
						elseif PurityLevel > 2 and PurityLevel < 10 then
							local pitymin = PurityLevel - 1
							local pitymax = PurityLevel + 3
							local pityrng = RngModule.RNG(2,pitymin,pitymax)
							ItemHandler.ItemIncrement(Player,98,pityrng)
						elseif PurityLevel >= 10 then
							local pityitem = (PurityLevel-PurityLevel%10)/10
							local pitymin = PurityLevel - 10*pityitem 
							local pitymax = (PurityLevel - 10*pityitem) + 5
							if PurityLevel >= pityitem*10 + 2 then
								local pityrng = RngModule.RNG(2,pitymin,pitymax)
								ItemHandler.ItemIncrement(Player,98,pityrng)
								ItemHandler.ItemIncrement(Player,105,pityitem)
							else
								ItemHandler.ItemIncrement(Player,105,pityitem)
							end
						end
						if CorruptionLevel > 1 and CorruptionLevel <= 3 then
							local pityrng = RngModule.RNG(2,2,4)
							ItemHandler.ItemIncrement(Player,99,pityrng)
						elseif CorruptionLevel > 3 and CorruptionLevel < 10 then
							local pitymin = CorruptionLevel - 1
							local pitymax = CorruptionLevel + 6
							local pityrng = RngModule.RNG(2,pitymin,pitymax)
							ItemHandler.ItemIncrement(Player,99,pityrng)
						elseif CorruptionLevel >= 10 then
							local pityitem = (CorruptionLevel-CorruptionLevel%10)/10
							local pitymin = CorruptionLevel - 10*pityitem+ 2
							local pitymax = (CorruptionLevel - 10*pityitem) + 9
							if CorruptionLevel >= pityitem*10 + 2 then
								local pityrng = RngModule.RNG(2,pitymin,pitymax)
								ItemHandler.ItemIncrement(Player,99,pityrng)
								ItemHandler.ItemIncrement(Player,106,pityitem)
							else
								ItemHandler.ItemIncrement(Player,106,pityitem)
							end
						end
						SelectedItem.Parent = nil
						SelectedItem:Destroy()
					end

				elseif i == "SetPurity" then
					if not table.find(ItemState,4) then
						local currentpurity = SelectedItem:GetAttribute("Purity")
						SelectedItem:SetAttribute("Purity",currentpurity + v)
					end
				elseif i == "SetCorruption" then
					if not table.find(ItemState,5) then
						local currentcorruption = SelectedItem:GetAttribute("Corruption")
						SelectedItem:SetAttribute("Corruption",currentcorruption + v)
					end
				elseif i == "UpgradeAttempts" then
					if not table.find(ItemState,3) then
						SelectedItem:FindFirstChild("Upgrades").Value = SelectedItem:FindFirstChild("Upgrades").Value + v
					end
				elseif i == "ApplyState" then
					local currentstate = SelectedItem:GetAttribute("State")
					for n,m in pairs(v) do
						if not table.find(ItemState,m) then
							if currentstate == "" then
								currentstate = m
							else
								currentstate = currentstate..":"..m
							end
						end
					end
					SelectedItem:SetAttribute("State",currentstate)

				elseif i == "UpgradeSlots" then
					if table.find(ItemState,2) then
						SelectedItem:FindFirstChild("Upgrades").Value = SelectedItem:FindFirstChild("Upgrades").Value + 1
					elseif table.find(ItemState,2) and table.find(ItemState,3) then
						--nothing happened
					else
						local currentslot = SelectedItem:GetAttribute("UpgradeAttempts")
						SelectedItem:SetAttribute("UpgradeAttempts",currentslot - v)
					end

				else
					local SelectedUpgradeMin,SelectedUpgradeMax = string.match(v,StatStringConverterPattern)
					local NewNumber = RngModule.RNG(2,tonumber(SelectedUpgradeMin),tonumber(SelectedUpgradeMax))
					local current = SelectedItem:FindFirstChild("Upgrades"):GetAttribute(v)
					SelectedItem:FindFirstChild("Upgrades"):SetAttribute(v,current + NewNumber)
				end
			end
		end
		for a,b in pairs(OnFail.Failed) do
			local Min,Max = string.match(a,StatStringConverterPattern)
			if RngRolla <= tonumber(Max) and RngRolla >= tonumber(Min) then
				ApplyFail(F)
				if not IsAdmin then
					UpgraderItem:Destroy()
				end
				return false,b.Message,b.MessageColor
			end
		end
	end
	--local scripterror = 0
	--print("error occured, attempting to reapply")
	--repeat
	--	scripterror = scripterror + 1
	--	UpgradeSystem.ApplyUpgrader(Player,SelectedSlot,UpgraderSlot)
	--until scripterror == 5
end
return UpgradeSystem