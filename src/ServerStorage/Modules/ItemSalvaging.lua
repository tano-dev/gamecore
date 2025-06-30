--Modules
local NameOrIDConverter = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("NameOrIDConverter"))
local ItemSlotHandler = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("ItemSlotHandler"))
local EquipmentFormat = require(game:GetService("ReplicatedStorage"):WaitForChild("Format"):WaitForChild("EquipmentFormat"))
local CopyTable = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("CopyTable"))
local ItemDictionaryHandler = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("ItemDictionaryHandler"))
local RngModule = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("RngModule"))
local ItemHandler =  require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("ItemHandler"))
--
local GameItems = game:GetService("ReplicatedStorage"):WaitForChild("GameItems")
local StringConverterPattern = "(%a+)%s?_%s?(%d+)"
--
local function getLowest(TableGiven)
	local low = nil
	local index
	for i, v in pairs(TableGiven) do
		if typeof(v) == "string" then
			v = tonumber(v)
		end
		if typeof(low) == "nil" then
			low = v
			index = i
		end
		if v < low then
			low = v
			index = i
		end
	end
	return index, low
end
local function getHighest(TableGiven)
	local high = nil
	local index
	for i, v in pairs(TableGiven) do
		if typeof(v) == "string" then
			v = tonumber(v)
		end
		if typeof(high) == "nil" then
			high = v
			index = i
		end
		if v > high then
			high = v
			index = i
		end
	end
	return index, high
end
--
local ItemSalvage = {}
function ItemSalvage.Salvage(Player,Slot)
	local CraftingLevel = Player:FindFirstChild("PlayerData"):GetAttribute("Crafting")
	local CraftingExp = Player:FindFirstChild("PlayerData"):GetAttribute("CraftingExp")
	local SlotName, SlotNumber = string.match(Slot,StringConverterPattern)
	if SlotName == nil or not SlotName == "Equipments" or not SlotName == "Consumables" or not SlotName == "Materials" then return false,"Invalid slot" end
	if not Player.Inventory:FindFirstChild(SlotName):FindFirstChild("Slot_"..SlotNumber):FindFirstChildOfClass("NumberValue") then
		return false,"Slot is empty"
	end
	local Item = Player.Inventory:FindFirstChild(SlotName):FindFirstChild("Slot_"..SlotNumber):FindFirstChildOfClass("NumberValue")
	local ItemDictionary = ItemDictionaryHandler.ItemToDictionary(Item)
	local ItemData = require(GameItems:FindFirstChild(SlotName):FindFirstChild(Item.Name))
	if ItemData.Dismantlable == false then return false,"Selected item cannot be Dismantlable" end
	--Rerolling/Level stuffs
	local IncreasedChance = CraftingLevel * 0.4
	local ReRoll = 1
	if CraftingLevel >= 50 then
		ReRoll = 12
	elseif CraftingLevel >= 47 then
		ReRoll = 11
	elseif CraftingLevel >= 42 then
		ReRoll = 10
	elseif CraftingLevel >= 39 then
		ReRoll = 9
	elseif CraftingLevel >= 34 then
		ReRoll = 8
	elseif CraftingLevel >= 27 then
		ReRoll = 7
	elseif CraftingLevel >= 19 then
		ReRoll = 6
	elseif CraftingLevel >= 14 then
		ReRoll = 5
	elseif CraftingLevel >= 10 then
		ReRoll = 4
	elseif CraftingLevel >= 7 then
		ReRoll = 3
	elseif CraftingLevel >= 3 then
		ReRoll = 2
	end
	local AfterDismantle = {}
	for i,v in pairs(ItemData.DismantleDrops) do
		local ItemID,ItemType = NameOrIDConverter.NameToID(i)
		if ItemType == 1 then
			local equipmenttable = {}
			if type(v.Chance) == "string" and v.Chance == "Guaranteed" then
				if v.IsRandom == true then
					local RngNumber = RngModule.RNG(2,v.Min,v.Max)
					equipmenttable[1] = RngNumber
				elseif v.IsRandom == false then
					equipmenttable[1] = v.Max
				end
				if v.KeepStats == "All" then
					local ExtraStats = ItemDictionaryHandler.GetStats(ItemDictionary,1)
					equipmenttable[2] = ExtraStats
				elseif v.KeepStats == "Nil" then
					equipmenttable[2] = {}
				elseif v.KeepStats == "Upgrades" then
					local ExtraStats = ItemDictionaryHandler.GetStats(ItemDictionary,2)
					equipmenttable[2] = ExtraStats
				elseif v.KeepStats == "Enchants" then
					local ExtraStats = ItemDictionaryHandler.GetStats(ItemDictionary,3)
					equipmenttable[2] = ExtraStats
				elseif v.KeepStats == "Gems" then
					local ExtraStats = ItemDictionaryHandler.GetStats(ItemDictionary,4)
					equipmenttable[2] = ExtraStats
				end
				AfterDismantle[ItemID] = equipmenttable
			elseif type(v.Chance) == "number" then
				local FinalRate = v.Chance + IncreasedChance
				local Rolla = false
				if FinalRate >= 1 then
					FinalRate = 1
					Rolla = true
				else
					Rolla = RngModule.RNG(1,FinalRate)
				end
				if Rolla then
					if v.IsRandom == false then
						equipmenttable[1] = v.Max
					elseif v.IsRandom == true then
						local Rolls = {}
						for n =1,ReRoll do
							local rollarolla = RngModule.RNG(2,v.Min,v.Max)
							table.insert(Rolls,rollarolla)
						end
						if ReRoll > 3 then
							local SecondRolls = {}
							for m=1,3 do
								local index,value = getHighest(Rolls)
								table.insert(SecondRolls,value)
							end
							local rollarollarolla = RngModule.RNG(2,1,#SecondRolls)
							equipmenttable[1] = SecondRolls[rollarollarolla]
						else
							local rollarollarolla = RngModule.RNG(2,1,#Rolls)
							equipmenttable[1] = Rolls[rollarollarolla]
						end
					end
					if v.KeepStats == "All" then
						local ExtraStats = ItemDictionaryHandler.GetStats(ItemDictionary,1)
						equipmenttable[2] = ExtraStats
					elseif v.KeepStats == "Nil" then
						equipmenttable[2] = {}
					elseif v.KeepStats == "Upgrades" then
						local ExtraStats = ItemDictionaryHandler.GetStats(ItemDictionary,2)
						equipmenttable[2] = ExtraStats
					elseif v.KeepStats == "Enchants" then
						local ExtraStats = ItemDictionaryHandler.GetStats(ItemDictionary,3)
						equipmenttable[2] = ExtraStats
					elseif v.KeepStats == "Gems" then
						local ExtraStats = ItemDictionaryHandler.GetStats(ItemDictionary,4)
						equipmenttable[2]  = ExtraStats
					end
					AfterDismantle[ItemID] = equipmenttable
				end
			end
		elseif ItemType == 2 or ItemType == 3 then
			if type(v.Chance) == "string" and v.Chance == "Guaranteed" then
				if v.IsRandom == true then
					local RngNumber = RngModule.RNG(2,v.Min,v.Max)
					AfterDismantle[ItemID] = RngNumber
				elseif v.IsRandom == false then
					AfterDismantle[ItemID] = v.Max
				end
			elseif type(v.Chance) == "number" then
				local FinalRate = v.Chance + IncreasedChance
				local Rolla = false
				if FinalRate >= 1 then
					FinalRate = 1
					Rolla = true
				else
					Rolla = RngModule.RNG(1,FinalRate)
				end
				if Rolla == true then
					if v.IsRandom == false then
						AfterDismantle[ItemID] = v.Max
					elseif v.IsRandom == true then
						local Rolls = {}
						for n =1,ReRoll do
							local rollarolla = RngModule.RNG(2,v.Min,v.Max)
							table.insert(Rolls,rollarolla)
						end
						if ReRoll > 3 then
							local SecondRolls = {}
							for m=1,3 do
								local index,value = getHighest(Rolls)
								table.insert(SecondRolls,value)
							end
							local rollarollarolla = RngModule.RNG(2,1,#SecondRolls)
							AfterDismantle[ItemID] = SecondRolls[rollarollarolla]
						else
							local rollarollarolla = RngModule.RNG(2,1,#Rolls)
							AfterDismantle[ItemID] = Rolls[rollarollarolla]
						end
					end
				end

			end
		else return false, "Error L200"
		end
	end
	print(AfterDismantle)
	Item:Destroy()
	for i,v in pairs(AfterDismantle) do
		local ItemName,ItemType = NameOrIDConverter.IDToName(i)
		if ItemType == 1 then
			for a= 1,v[1] do
				ItemHandler.Create(i,true,Player,v[2])
			end
		elseif ItemType == 2 or ItemType == 3 then
			ItemHandler.ItemIncrement(Player,i,v)
		end
	end
	
	Player:FindFirstChild("PlayerData"):SetAttribute("CraftingExp",CraftingExp+ItemData.DismantleExp)
	return true,"Dismantled "..Item.Name.." !"
end
return ItemSalvage
