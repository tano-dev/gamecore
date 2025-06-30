--APIs
--[[
Main APIs:
	CorrectSlotNumber(Player)
	GetSlots(Player,IfCheck)
		> IfCheck is true then fire CorrectSlotNumber
		> return EquipmentsTable, ConsumablesTable, MaterialsTable, BankTable, EquippedTable 
	MoveToSlot(Player,Dictionary,IsBank)
		> IsBank is true then move dictionary to bank
	GetEmptySlots(Player,Mode,Order)
		> Mode:1,2,3,4,5 
			> 1: EquipmentSlots
			> 2: ConsumableSlots
			> 3: MaterialSlots
			> 4: 1+2+3 (will ignore Order)
			> 5: EquippedMainTab + EquippedAccessoryTab
			Note: mode 5 wont return bool
		> Order: GetLowest,GetHighest
			> Will only pass the Lowest/Highest
		> return IfSuccess, {}
	EquipItem(Player,SelectedSlot,IsAccessory,Slot)
		> SelectedSlot must be like Equipments_Number or Consumables_Number
		> Slot must be "Weapon",... .IF IsAccessory true then Slot must be Number
		> return IfSuccess, ErrorMessage
	UnequipItem(Player,SelectedSlot,IsBank)
		> IsBank = true will send item to the bank if inventory is fulled
		> return IfSuccess, errorMessage
	SwapItem(Player,Slot1,Slot2,IsBank)
AdditionAPIs:
	getLowest(Table)
	getHighest(Table)
Note:
--Change the EquipItem(Player,SelectedSlot,IsAccessory,Slot) --> EquipItem(Player,SelectedSlot,Slot) like Accessory_1 instead plr,1,true,slot
--Will rework a bit once started on Addiotion Type/ID (Scroll,Gem,Helmet,...)
]]
local ItemSlotHandler = {}
local CopyTable = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("CopyTable"))
local ItemDictionaryHandler = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("ItemDictionaryHandler"))
local EquipmentFormat = require(game:GetService("ReplicatedStorage"):WaitForChild("Format"):WaitForChild("EquipmentFormat"))
local EquippedFormat = require(game:GetService("ReplicatedStorage"):WaitForChild("Format"):WaitForChild("EquippedFormat"))

--Stogare
local ItemStogare = game:GetService("ReplicatedStorage"):WaitForChild("GameItems")
local EquipmentsStogare = ItemStogare:WaitForChild("Equipments")
local ConsumablesStogare = ItemStogare:WaitForChild("Consumables")
local MaterialsStogare = ItemStogare:WaitForChild("Materials")
--DataType
local WeaponType = {"Longsword","Rapier","Katana","Dagger","Staff","Axe","Hoe","Fishing Rod","Pickaxe"}
local ToolType = {"Axe","Hoe","Fishing Rod","Pickaxe"}
--
local StringConverterPattern = "(%a+)%s?_%s?(%d+)"
local EquippedTab = {
	"Weapon",
	"Offhand",
	"Aura",
	"Pet",
	"Helmet",
	"Chestplate",
	"Boots",
	"Tool",
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
--[[
Mode 1 - ALL 2-Equipments 3-Consumable 4-Material 5-Equipped
Loop -> get player 
]]
function ItemSlotHandler.CorrectSlotNumber(Player,Mode)
	local SelectedMode = Mode or 1
	print("Mode: "..SelectedMode)
	local Bank = Player:WaitForChild("Bank")
	local Inventory = Player:WaitForChild("Inventory")
	local Equipments = Inventory:WaitForChild("Equipments")
	local Consumables = Inventory:WaitForChild("Consumables")
	local Materials = Inventory:WaitForChild("Materials")
	local Equipped = Inventory:WaitForChild("Equipped")
	local MainTab = Equipped:WaitForChild("Main")
	local BowTab = Equipped:WaitForChild("Bow")
	local FishingTab = Equipped:WaitForChild("Fishing")
	local AccessoryTab = Equipped:WaitForChild("Accessory")
	local OccupiedEquipmentSlots = {}
	local EmptyEquipmentSlot = {}
	local OccupiedMaterialSlots = {}
	local EmptyMaterialSlot = {}
	local OccupiedConsumabletSlots = {}
	local EmptyConsumableSlot = {}
	local consumabletable = {}
	local materialtable = {}
	--Equipments
	if SelectedMode == 1 or SelectedMode == 2 then
		--Calling Loop on player equipment inv
		--[[
		B1
		Chọn hết slot rồi xét
		Nếu hơn 2 thì lặp trong slot đó cho đến khi còn 1, phần dư sẽ lưu vào OccupiedEquipmentSlots
		Nếu = 1 thì giữ nguyên
		Nếu bé hơn 1 thì lưu vào các slot du
		B2
		Lấy mỗi OccupiedEquipmentSlots
		Nếu ko còn EmptyEquipmentSlot then cho vào bank
		Nếu còn thì cho vào slot nhỏ nhất
		]]
		for i,v in pairs(Equipments:GetChildren()) do
			local ItemNumber = #v:GetChildren()
			local slot,slotnumber = string.match(v.Name,StringConverterPattern)
			if ItemNumber >= 2 then -- if more than 2 items in then move it to OccupiedEquipmentSlots (convert item to dictionary)

				for a,b in pairs(v:GetChildren()) do -- Getting Children inside by looping til one left
					task.wait()
					print(ItemNumber)  

					if ItemNumber >= 2 then  --If STILL MROE THAN 2

						local NewEquipment = ItemDictionaryHandler.ItemToDictionary(b)
						print(NewEquipment)
						table.insert(OccupiedEquipmentSlots,NewEquipment)
						print(OccupiedEquipmentSlots)
						b:Destroy()
						ItemNumber = ItemNumber - 1

					else  --IF it is last one
						b:SetAttribute("CurrentSlot",tonumber(slotnumber))
					end
				end
			elseif ItemNumber == 1 then -- If one then just recorrect the slot
				print(v)
				local b = v:FindFirstChildOfClass("NumberValue")
				if b:GetAttribute("CurrentSlot") ~= tonumber(slotnumber) then
					if Equipments:FindFirstChild("Slot_"..tostring(b:GetAttribute("CurrentSlot"))) then
						if #Equipments:FindFirstChild("Slot_"..tostring(b:GetAttribute("CurrentSlot"))):GetChildren() > 0 then
							if v:FindFirstChildOfClass("NumberValue") ~= b then
								local NewEquipment = ItemDictionaryHandler.ItemToDictionary(b)
								print(NewEquipment)
								table.insert(OccupiedEquipmentSlots,NewEquipment)
								print(OccupiedEquipmentSlots)
								b:Destroy()
								ItemNumber = ItemNumber - 1
							else
								b:SetAttribute("CurrentSlot",tonumber(slotnumber))
							end

						else 
							b.Parent = Equipments:FindFirstChild("Slot_"..tostring(b:GetAttribute("CurrentSlot")))
						end
					else
						if v:FindFirstChildOfClass("NumberValue") == b then
							b:SetAttribute("CurrentSlot",tonumber(slotnumber))
						else
							local copybankitem = b:Clone()
							copybankitem:SetAttribute("CurrentSlot",0)
							copybankitem.Parent = Bank
							b:Destroy()
						end
					end
				else
					b:SetAttribute("CurrentSlot",tonumber(slotnumber))
				end
			elseif ItemNumber < 1 then
				--Adding to EmptySlots
				table.insert(EmptyEquipmentSlot,tonumber(slotnumber))
			end
			--print(#EmptyEquipmentSlot)
		end
		--print(OccupiedEquipmentSlots)
		for i,v in pairs(OccupiedEquipmentSlots) do
			if #EmptyEquipmentSlot == 0 then -- No slot left
				ItemDictionaryHandler.DictionaryToItem(v,Bank)
			else
				local Index, Low = getLowest(EmptyEquipmentSlot)
				--print("Lowest slot: "..Low.." and index "..Index)
				--print(i)
				--print(v)
				local NewSlot = Equipments:WaitForChild("Slot_"..tostring(Low))
				v["CurrentSlot"] = Low
				ItemDictionaryHandler.DictionaryToItem(v,NewSlot)
				table.remove(EmptyEquipmentSlot,Index)
			end
		end
	end
	--Materials
	if SelectedMode == 1 or SelectedMode == 4 then
		for i,v in pairs(Materials:GetChildren()) do
			local ItemNumber = #v:GetChildren()
			local slot,slotnumber = string.match(v.Name,StringConverterPattern)
			if ItemNumber >= 2 then
				for a,b in pairs(v:GetChildren()) do
					if ItemNumber >= 2 then
						local NewMaterial = ItemDictionaryHandler.ItemToDictionary(b)
						table.insert(OccupiedMaterialSlots,NewMaterial)
						b:Destroy()
						ItemNumber = ItemNumber - 1
					else
						b:SetAttribute("CurrentSlot",tonumber(slotnumber))
					end
				end
			elseif ItemNumber == 1 then
				print(v)
				local b = v:FindFirstChildOfClass("NumberValue")
				local itemdata = require(MaterialsStogare:FindFirstChild(b.Name))
				local IsDestroyed = false
				if itemdata.Stackable == true then
					local amounts = b:GetAttribute("Amounts")
					if amounts > itemdata.StackSize then
						repeat
							amounts = amounts - itemdata.StackSize
							local newitem = ItemDictionaryHandler.ItemToDictionary(b)
							newitem.Amounts = amounts
							table.insert(OccupiedMaterialSlots,newitem)
						until amounts <= itemdata.StackSize
						if amounts <= 0 then
							IsDestroyed = true
							b:Destroy()
						else
							b:SetAttribute("Amounts",itemdata.StackSize)
						end
					elseif amounts <= 0 then
						IsDestroyed = true
						b:Destroy()
					end
				end
				if not IsDestroyed then
					if b:GetAttribute("CurrentSlot") ~= tonumber(slotnumber) then
						if Materials:FindFirstChild("Slot_"..tostring(b:GetAttribute("CurrentSlot"))) then
							if #Materials:FindFirstChild("Slot_"..tostring(b:GetAttribute("CurrentSlot"))):GetChildren() > 0 then
								if v:FindFirstChildOfClass("NumberValue") ~= b then
									local NewMaterial = ItemDictionaryHandler.ItemToDictionary(b)
									table.insert(OccupiedMaterialSlots,NewMaterial)
									b:Destroy()
									ItemNumber = ItemNumber - 1
								else
									b:SetAttribute("CurrentSlot",tonumber(slotnumber))
								end

							else 
								b.Parent = Materials:FindFirstChild("Slot_"..tostring(b:GetAttribute("CurrentSlot")))
							end
						else
							if v:FindFirstChildOfClass("NumberValue") == b then
								b:SetAttribute("CurrentSlot",tonumber(slotnumber))
							else
								local copybankitem = b:Clone()
								copybankitem:SetAttribute("CurrentSlot",0)
								copybankitem.Parent = Bank
								b:Destroy()
							end
						end
					else
						b:SetAttribute("CurrentSlot",tonumber(slotnumber))
					end
				end

			elseif ItemNumber < 1 then
				table.insert(EmptyMaterialSlot,tonumber(slotnumber))
			end
		end
		for i,v in pairs(OccupiedMaterialSlots) do
			if #EmptyMaterialSlot == 0 then
				ItemDictionaryHandler.DictionaryToItem(v,Bank)
			else
				local Index, Low = getLowest(EmptyMaterialSlot)
				local NewSlot = Materials:WaitForChild("Slot_"..Low)
				v.CurrentSlot = Low
				ItemDictionaryHandler.DictionaryToItem(v,NewSlot)
				table.remove(EmptyMaterialSlot,Index)
			end
		end
	end
	--Consumables
	if SelectedMode == 1 or SelectedMode == 3 then
		for i,v in pairs(Consumables:GetChildren()) do
			local ItemNumber = #v:GetChildren()
			local slot,slotnumber = string.match(v.Name,StringConverterPattern)
			if ItemNumber >= 2 then
				for a,b in pairs(v:GetChildren()) do
					if ItemNumber >= 2 then
						local NewConsumable = ItemDictionaryHandler.ItemToDictionary(b)
						table.insert(OccupiedConsumabletSlots,NewConsumable)
						b:Destroy()
						ItemNumber = ItemNumber - 1
					else
						b:SetAttribute("CurrentSlot",tonumber(slotnumber))
					end
				end
			elseif ItemNumber == 1 then
				print(v)
				local b = v:FindFirstChildOfClass("NumberValue")
				--if ConsumablesStogare:FindFirstChild(b.Name) == nil and MaterialsStogare:FindFirstChild(b.Name) == nil and EquipmentsStogare:FindFirstChild(b.Name) == nil then b:Destroy()
				--elseif ConsumablesStogare:FindFirstChild(b.Name) == nil then b:SetAttribute("CurrentSlot",0) b.Parent = Bank end
				local itemdata = require(ConsumablesStogare:FindFirstChild(b.Name))
				local IsDestroyed = false
				if itemdata.Stackable == true then
					local amounts = b:GetAttribute("Amounts")
					if amounts > itemdata.StackSize then
						repeat
							amounts = amounts - itemdata.StackSize
							local newitem = ItemDictionaryHandler.ItemToDictionary(b)
							newitem.Amounts = itemdata.StackSize
							table.insert(OccupiedConsumabletSlots,newitem)
						until amounts <= itemdata.StackSize
						if amounts <= 0 then
							IsDestroyed = true
							b:Destroy()
						else
							b:SetAttribute("Amounts",amounts)
						end
					elseif amounts <= 0 then
						IsDestroyed = true
						b:Destroy()
					end
				end
				if not IsDestroyed then
					if b:GetAttribute("CurrentSlot") ~= tonumber(slotnumber) then
						if Consumables:FindFirstChild("Slot_"..tostring(b:GetAttribute("CurrentSlot"))) then
							if #Consumables:FindFirstChild("Slot_"..tostring(b:GetAttribute("CurrentSlot"))):GetChildren() > 0 then
								if v:FindFirstChildOfClass("NumberValue") ~= b then
									local NewConsumable = ItemDictionaryHandler.ItemToDictionary(b)
									table.insert(OccupiedConsumabletSlots,NewConsumable)
									b:Destroy()
									ItemNumber = ItemNumber - 1
								else
									b:SetAttribute("CurrentSlot",tonumber(slotnumber))
								end

							else 
								b.Parent = Consumables:FindFirstChild("Slot_"..tostring(b:GetAttribute("CurrentSlot")))
							end
						else
							if v:FindFirstChildOfClass("NumberValue") == b then
								b:SetAttribute("CurrentSlot",tonumber(slotnumber))
							else
								local copybankitem = b:Clone()
								copybankitem:SetAttribute("CurrentSlot",0)
								copybankitem.Parent = Bank
								b:Destroy()
							end
						end
					else
						b:SetAttribute("CurrentSlot",tonumber(slotnumber))
					end
				end
			elseif ItemNumber < 1 then
				table.insert(EmptyConsumableSlot,tonumber(slotnumber))
			end
		end
		for i,v in pairs(OccupiedConsumabletSlots) do
			if #EmptyConsumableSlot == 0 then
				ItemDictionaryHandler.DictionaryToItem(v,Bank)
			else
				local Index, Low = getLowest(EmptyConsumableSlot)
				local NewSlot = Consumables:WaitForChild("Slot_"..Low)
				v.CurrentSlot = Low
				ItemDictionaryHandler.DictionaryToItem(v,NewSlot)
				table.remove(EmptyConsumableSlot,Index)
			end
		end
	end
	--Equipped
	if SelectedMode == 1 or SelectedMode == 5 then
		for i,v in pairs(MainTab:GetChildren()) do
			local ItemNumber = #v:GetChildren()
			local slot,slotnumber = string.match(v.Name,StringConverterPattern)
			if ItemNumber >= 2 then
				for a,b in pairs(v:GetChildren()) do
					if ItemNumber >= 2 then
						b:SetAttribute("CurrentSlot",0)
						local NewEquipped = ItemDictionaryHandler.ItemToDictionary(b)
						b:Destroy()
						ItemSlotHandler.MoveToSlot(Player,NewEquipped)
						ItemNumber = ItemNumber - 1
					else
						b:SetAttribute("CurrentSlot",-1)
					end
				end
			elseif ItemNumber == 1 then
				print(v)
				for a,b in pairs(v:GetChildren()) do
					b:SetAttribute("CurrentSlot",-1)
				end
			end
		end
		for i,v in pairs(BowTab:GetChildren()) do
			local ItemNumber = #v:GetChildren()
			local slot,slotnumber = string.match(v.Name,StringConverterPattern)
			if ItemNumber >= 2 then
				for a,b in pairs(v:GetChildren()) do
					if ItemNumber >= 2 then
						b:SetAttribute("CurrentSlot",0)
						local NewEquipped = ItemDictionaryHandler.ItemToDictionary(b)
						b:Destroy()
						ItemSlotHandler.MoveToSlot(Player,NewEquipped)
						ItemNumber = ItemNumber - 1
					else
						b:SetAttribute("CurrentSlot",-1)
					end
				end
			elseif ItemNumber == 1 then
				print(v)
				for a,b in pairs(v:GetChildren()) do
					b:SetAttribute("CurrentSlot",-1)
				end
			end
		end
		for i,v in pairs(FishingTab:GetChildren()) do
			local ItemNumber = #v:GetChildren()
			local slot,slotnumber = string.match(v.Name,StringConverterPattern)
			if ItemNumber >= 2 then
				for a,b in pairs(v:GetChildren()) do
					if ItemNumber >= 2 then
						b:SetAttribute("CurrentSlot",0)
						local NewEquipped = ItemDictionaryHandler.ItemToDictionary(b)
						b:Destroy()
						ItemSlotHandler.MoveToSlot(Player,NewEquipped)
						ItemNumber = ItemNumber - 1
					else
						b:SetAttribute("CurrentSlot",-1)
					end
				end
			elseif ItemNumber == 1 then
				print(v)
				for a,b in pairs(v:GetChildren()) do
					b:SetAttribute("CurrentSlot",-1)
				end
			end
		end
		for i,v in pairs(AccessoryTab:GetChildren()) do
			local ItemNumber = #v:GetChildren()
			local slot,slotnumber = string.match(v.Name,StringConverterPattern)
			if ItemNumber >= 2 then
				for a,b in pairs(v:GetChildren()) do
					if ItemNumber >= 2 then
						b:SetAttribute("CurrentSlot",0)
						local NewEquipped = ItemDictionaryHandler.ItemToDictionary(b)
						b:Destroy()
						ItemSlotHandler.MoveToSlot(Player,NewEquipped)
						ItemNumber = ItemNumber - 1
					else
						b:SetAttribute("CurrentSlot",-1)
					end
				end
			elseif ItemNumber == 1 then
				print(v)
				for a,b in pairs(v:GetChildren()) do
					b:SetAttribute("CurrentSlot",-1)
				end
			end
		end
	end
	if SelectedMode == 6 then
		for i,v in pairs(Bank:GetChildren()) do
			v:SetAttribute("CurrentSlot",0)
		end
	end
end
function ItemSlotHandler.GetSlots(Player,CorrectSlots,Mode)
	local IsCorrectSlots = false or CorrectSlots
	local Bank = Player:WaitForChild("Bank")
	local Inventory = Player:WaitForChild("Inventory")
	local Equipments = Inventory:WaitForChild("Equipments")
	local Consumables = Inventory:WaitForChild("Consumables")
	local Materials = Inventory:WaitForChild("Materials")
	local Equipped = Inventory:WaitForChild("Equipped")
	local MainTab = Equipped:WaitForChild("Main")
	local AccessoryTab = Equipped:WaitForChild("Accessory")
	local FishingTab = Equipped:WaitForChild("Fishing")
	local BowTab = Equipped:WaitForChild("Bow")
	local EquipmentsTable = {}
	local ConsumablesTable = {}
	local MaterialsTable = {}
	local EquippedTable = CopyTable.Copy(EquippedFormat)
	local BankTable = {}
	if IsCorrectSlots then
		ItemSlotHandler.CorrectSlotNumber(Player)
	end
	for i,v in pairs(Equipments:GetChildren()) do
		local Item = v:GetChildren()
		for i,v in pairs(Item) do
			local NewEquipment = ItemDictionaryHandler.ItemToDictionary(v)
			local Name, Type = ItemDictionaryHandler.IDToName(NewEquipment.ID)
			if Type == 2 then
				if tonumber(NewEquipment.CurrentSlot) <= #Consumables:GetChildren() then
					v.Parent = Consumables:FindFirstChild("Slot_"..tostring(NewEquipment.CurrentSlot))
				else
					v.Parent = Bank
				end
				ItemSlotHandler.CorrectSlotNumber(Player)
				table.insert(ConsumablesTable,NewEquipment)
			elseif Type == 3 then
				if tonumber(NewEquipment.CurrentSlot) <= #Materials:GetChildren() then
					v.Parent = Materials:FindFirstChild("Slot_"..tostring(NewEquipment.CurrentSlot))
				else
					v.Parent = Bank
				end
				ItemSlotHandler.CorrectSlotNumber(Player)
				table.insert(MaterialsTable,NewEquipment)
			else
				table.insert(EquipmentsTable,NewEquipment)
			end

		end
	end
	for i,v in pairs(Materials:GetChildren()) do
		local Item = v:GetChildren()
		for i,v in pairs(Item) do
			local NewMaterial = ItemDictionaryHandler.ItemToDictionary(v)
			local Name, Type = ItemDictionaryHandler.IDToName(NewMaterial.ID)
			if Type == 2 then
				if tonumber(NewMaterial.CurrentSlot) <= #Consumables:GetChildren() then
					v.Parent = Consumables:WaitForChild("Slot_"..NewMaterial.CurrentSlot)
				else
					v.Parent = Bank
				end
				ItemSlotHandler.CorrectSlotNumber(Player)
				table.insert(ConsumablesTable,NewMaterial)
			elseif Type == 1 then
				if tonumber(NewMaterial.CurrentSlot) <= #Equipments:GetChildren() then
					v.Parent = Equipments:WaitForChild("Slot_"..NewMaterial.CurrentSlot)
				else
					v.Parent = Bank
				end
				ItemSlotHandler.CorrectSlotNumber(Player)
				table.insert(EquipmentsTable,NewMaterial)
			else
				table.insert(MaterialsTable,NewMaterial)
			end
		end
	end
	for i,v in pairs(Consumables:GetChildren()) do
		local Item = v:GetChildren()
		for i,v in pairs(Item) do
			local NewConsumable = ItemDictionaryHandler.ItemToDictionary(v)
			local Name, Type = ItemDictionaryHandler.IDToName(NewConsumable.ID)
			if Type == 3 then
				if tonumber(NewConsumable.CurrentSlot) <= #Materials:GetChildren() then
					v.Parent = Materials:WaitForChild("Slot_"..NewConsumable.CurrentSlot)
				else
					v.Parent = Bank
				end
				ItemSlotHandler.CorrectSlotNumber(Player)
				table.insert(MaterialsTable,NewConsumable)
			elseif Type == 1 then
				if tonumber(NewConsumable.CurrentSlot) <= #Equipments:GetChildren() then
					v.Parent = Equipments:WaitForChild("Slot_"..NewConsumable.CurrentSlot)
				else
					v.Parent = Bank
				end
				ItemSlotHandler.CorrectSlotNumber(Player)
				table.insert(EquipmentsTable,NewConsumable)
			else
				table.insert(ConsumablesTable,NewConsumable)
			end
		end
	end
	for i,v in pairs(Bank:GetChildren()) do
		local NewItem = ItemDictionaryHandler.ItemToDictionary(v)
		table.insert(BankTable,NewItem)
	end

	for i,v in pairs(MainTab:GetChildren()) do
		if #v:GetChildren() == 1 then
			for a,b in pairs(v:GetChildren()) do
				local NewItem = ItemDictionaryHandler.ItemToDictionary(b)
				EquippedTable[v.Name] = NewItem
			end
		elseif #v:GetChildren() > 1 then
			ItemSlotHandler.CorrectSlotNumber(Player)
		end
	end
	for i,v in pairs(AccessoryTab:GetChildren()) do
		if #v:GetChildren() == 1 then
			for a,b in pairs(v:GetChildren()) do
				local NewItem = ItemDictionaryHandler.ItemToDictionary(b)
				local _,numbvalue = string.match(v.Name,StringConverterPattern)
				print(numbvalue,b)
				EquippedTable.Accessory["Slot"..numbvalue] = NewItem
			end
		elseif #v:GetChildren() > 1 then
			ItemSlotHandler.CorrectSlotNumber(Player)
		end
	end
	for i,v in pairs(BowTab:GetChildren()) do
		if #v:GetChildren() == 1 then
			for a,b in pairs(v:GetChildren()) do
				local NewItem = ItemDictionaryHandler.ItemToDictionary(b)
				local _,numbvalue = string.match(v.Name,StringConverterPattern)
				print(numbvalue,b)
				EquippedTable.Bow["Slot"..numbvalue] = NewItem
			end
		elseif #v:GetChildren() > 1 then
			ItemSlotHandler.CorrectSlotNumber(Player)
		end
	end
	for i,v in pairs(FishingTab:GetChildren()) do
		if #v:GetChildren() == 1 then
			for a,b in pairs(v:GetChildren()) do
				local NewItem = ItemDictionaryHandler.ItemToDictionary(b)
				local _,numbvalue = string.match(v.Name,StringConverterPattern)
				print(numbvalue,b)
				EquippedTable.Fishing["Slot"..numbvalue] = NewItem
			end
		elseif #v:GetChildren() > 1 then
			ItemSlotHandler.CorrectSlotNumber(Player)
		end
	end
	--for i,v in pairs(FishingTab:GetChildren()) do
	--	if #v:GetChildren() == 1 then
	--		for a,b in pairs(v:GetChildren()) do
	--			local NewItem = ItemDictionaryHandler.ItemToDictionary(b)
	--			local _,numbvalue = string.match(v.Name,StringConverterPattern)
	--			print(numbvalue,b)
	--			EquippedTable.Accessory["Slot"..numbvalue] = NewItem
	--		end
	--	elseif #v:GetChildren() > 1 then
	--		ItemSlotHandler.CorrectSlotNumber(Player)
	--	end
	--end
	print(EquippedTable)
	return EquipmentsTable, ConsumablesTable, MaterialsTable, BankTable, EquippedTable
end
function ItemSlotHandler.GetSlotsv2(Player,CorrectSlots,Mode)
	local function processItems(container, tables)
		for _, slot in ipairs(container:GetChildren()) do
			for _, item in ipairs(slot:GetChildren()) do
				local newItem = ItemDictionaryHandler.ItemToDictionary(item)
				local _, itemType = ItemDictionaryHandler.IDToName(newItem.ID)

				local targetContainer, targetTable = tables[itemType].container, tables[itemType].table

				if targetContainer ~= container then
					local newSlot = tonumber(newItem.CurrentSlot)
					if newSlot and newSlot <= #targetContainer:GetChildren() then
						item.Parent = targetContainer:FindFirstChild("Slot_" .. newSlot)
					else
						item.Parent = Player.Bank
					end
					ItemSlotHandler.CorrectSlotNumber(Player)
				end

				table.insert(targetTable, newItem)
			end
		end
	end

	local function processEquippedItems(container, targetTable)
		for _, slot in ipairs(container:GetChildren()) do
			if #slot:GetChildren() == 1 then
				local item = slot:GetChildren()[1]
				local newItem = ItemDictionaryHandler.ItemToDictionary(item)
				local _, slotNumber = string.match(slot.Name, StringConverterPattern)
				targetTable[slot.Name] = newItem
			elseif #slot:GetChildren() > 1 then
				ItemSlotHandler.CorrectSlotNumber(Player)
			end
		end
	end

	local Inventory = Player:WaitForChild("Inventory")
	local Equipped = Inventory:WaitForChild("Equipped")

	local tables = {
		[1] = {container = Inventory:WaitForChild("Equipments"), table = {}},
		[2] = {container = Inventory:WaitForChild("Consumables"), table = {}},
		[3] = {container = Inventory:WaitForChild("Materials"), table = {}}
	}

	local EquippedTable = CopyTable.Copy(EquippedFormat)
	local BankTable = {}
	local equippedContainers = {
		{container = Equipped:WaitForChild("Main"), target = EquippedTable},
		{container = Equipped:WaitForChild("Accessory"), target = EquippedTable.Accessory},
		{container = Equipped:WaitForChild("Bow"), target = EquippedTable.Bow},
		{container = Equipped:WaitForChild("Fishing"), target = EquippedTable.Fishing}
	}
	
	if CorrectSlots then
		ItemSlotHandler.CorrectSlotNumber(Player)
	end
	if Mode == 1 then
		for _, containerInfo in pairs(tables) do
			processItems(containerInfo.container, tables)
		end

		for _, item in ipairs(Player.Bank:GetChildren()) do
			table.insert(BankTable, ItemDictionaryHandler.ItemToDictionary(item))
		end

		for _, containerInfo in ipairs(equippedContainers) do
			processEquippedItems(containerInfo.container, containerInfo.target)
		end

		return tables[1].table, tables[2].table, tables[3].table, BankTable, EquippedTable
	elseif Mode == 2 then
		processItems(Inventory:WaitForChild("Equipments"), tables)
		return tables[1].table
	elseif Mode == 3 then
		processItems(Inventory:WaitForChild("Consumables"), tables)
		return tables[2].table
	elseif Mode == 4 then
		processItems(Inventory:WaitForChild("Materials"), tables)
		return tables[3].table
	elseif Mode == 5 then
		for _, item in ipairs(Player.Bank:GetChildren()) do
			table.insert(BankTable, ItemDictionaryHandler.ItemToDictionary(item))
		end
		return BankTable
	elseif Mode == 6 then
		for _, containerInfo in ipairs(equippedContainers) do
			processEquippedItems(containerInfo.container, containerInfo.target)
		end
		return EquippedTable
	end
	
end
--function ItemSlotHandler.GetSlotsNew(Player,CorrectSlots,Mode)
--	local function processItems(container, targetTable, containerType)
--		for _, slot in ipairs(container:GetChildren()) do
--			for _, item in ipairs(slot:GetChildren()) do
--				local newItem = ItemDictionaryHandler.ItemToDictionary(item)
--				local _, itemType = ItemDictionaryHandler.IDToName(newItem.ID)

--				if itemType ~= containerType then
--					local targetContainer = itemType == 1 and Inventory.Equipments
--						or itemType == 2 and Inventory.Consumables
--						or itemType == 3 and Inventory.Materials
--						or Bank

--					if targetContainer ~= Bank and tonumber(newItem.CurrentSlot) <= #targetContainer:GetChildren() then
--						item.Parent = targetContainer:FindFirstChild("Slot_" .. tostring(newItem.CurrentSlot))
--					else
--						item.Parent = Bank
--					end
--					ItemSlotHandler.CorrectSlotNumber(Player)
--				end

--				table.insert(targetTable, newItem)
--			end
--		end
--	end

--	local function processEquippedItems(container, targetTable)
--		for _, slot in ipairs(container:GetChildren()) do
--			if #slot:GetChildren() == 1 then
--				local item = slot:GetChildren()[1]
--				local newItem = ItemDictionaryHandler.ItemToDictionary(item)
--				local _, slotNumber = string.match(slot.Name, StringConverterPattern)
--				targetTable[slot.Name] = newItem
--			elseif #slot:GetChildren() > 1 then
--				ItemSlotHandler.CorrectSlotNumber(Player)
--			end
--		end
--	end

--	local Inventory = Player:WaitForChild("Inventory")
--	local Bank = Player:WaitForChild("Bank")
--	local Equipped = Inventory:WaitForChild("Equipped")

--	local EquipmentsTable, ConsumablesTable, MaterialsTable = {}, {}, {}
--	local EquippedTable = CopyTable.Copy(EquippedFormat)
--	local BankTable = {}

--	if CorrectSlots then
--		ItemSlotHandler.CorrectSlotNumber(Player)
--	end

--	processItems(Inventory.Equipments, EquipmentsTable, 1)
--	processItems(Inventory.Consumables, ConsumablesTable, 2)
--	processItems(Inventory.Materials, MaterialsTable, 3)

--	for _, item in ipairs(Bank:GetChildren()) do
--		table.insert(BankTable, ItemDictionaryHandler.ItemToDictionary(item))
--	end

--	processEquippedItems(Equipped.Main, EquippedTable)
--	processEquippedItems(Equipped.Accessory, EquippedTable.Accessory)
--	processEquippedItems(Equipped.Bow, EquippedTable.Bow)
--	processEquippedItems(Equipped.Fishing, EquippedTable.Fishing)

--	return EquipmentsTable, ConsumablesTable, MaterialsTable, BankTable, EquippedTable
--end

function ItemSlotHandler.MoveToSlot(Player,Dictionary,IsBank)
	local Bank = Player:WaitForChild("Bank")
	local Inventory = Player:WaitForChild("Inventory")
	local Equipments = Inventory:WaitForChild("Equipments")
	local Consumables = Inventory:WaitForChild("Consumables")
	local Materials = Inventory:WaitForChild("Materials")
	local Name,Type = ItemDictionaryHandler.IDToName(Dictionary.ID)
	if IsBank == true then
		ItemDictionaryHandler.DictionaryToItem(Dictionary,Bank)
	else
		if Type == 1 and tonumber(Dictionary.CurrentSlot) <= 25 and tonumber(Dictionary.CurrentSlot) >= 1 then
			--local NewSlot = Equipments:WaitForChild("Slot_"..Dictionary.CurrentSlot)
			--ItemDictionaryHandler.DictionaryToItem(Dictionary,NewSlot)
			ItemDictionaryHandler.DictionaryToItem(Dictionary,Equipments:WaitForChild("Slot_"..Dictionary.CurrentSlot))
		elseif Type == 2 and tonumber(Dictionary.CurrentSlot) <= 36 and tonumber(Dictionary.CurrentSlot) >= 1  then
			--local NewSlot = Consumables:WaitForChild("Slot_"..Dictionary.CurrentSlot)
			--ItemDictionaryHandler.DictionaryToItem(Dictionary,NewSlot)
			ItemDictionaryHandler.DictionaryToItem(Dictionary,Consumables:WaitForChild("Slot_"..Dictionary.CurrentSlot))
		elseif Type == 3 and tonumber(Dictionary.CurrentSlot) <= 36 and tonumber(Dictionary.CurrentSlot) >= 1  then
			--local NewSlot = Materials:WaitForChild("Slot_"..Dictionary.CurrentSlot)
			--ItemDictionaryHandler.DictionaryToItem(Dictionary,NewSlot)
			ItemDictionaryHandler.DictionaryToItem(Dictionary,Materials:WaitForChild("Slot_"..Dictionary.CurrentSlot))
			
		else
			Dictionary.CurrentSlot = 0
			ItemDictionaryHandler.DictionaryToItem(Dictionary,Bank)
		end
	end
end
function ItemSlotHandler.GetEmptySlots(Player,Mode,Order)
	local Bank = Player:WaitForChild("Bank")
	local Inventory = Player:WaitForChild("Inventory")
	local Equipments = Inventory:WaitForChild("Equipments")
	local Consumables = Inventory:WaitForChild("Consumables")
	local Materials = Inventory:WaitForChild("Materials")
	local Equipped = Inventory:WaitForChild("Equipped")
	local MainTab = Equipped:WaitForChild("Main")
	local AccessoryTab = Equipped:WaitForChild("Accessory")
	local FishingTab = Equipped:WaitForChild("Fishing")
	local BowTab = Equipped:WaitForChild("Bow")
	local EmptyEquipmentSlot = {}
	local EmptyMaterialSlot = {}
	local EmptyConsumableSlot = {}
	local EmptyEquippedMainSlot = {}
	local EmptyEquippedAccessorySlot = {}
	local EmptyEquippedFishingSlot = {}
	local EmptyEquippedBowSlot = {}
	local EmptyAllSlot = {
		EquipmentSlots = {},
		ConsumableSlots = {},
		MaterialSlots = {}
	}
	for i = 1,#Materials:GetChildren() do
		if i <= #Equipments:GetChildren() then
			local EquipmentsNumber = #Equipments:FindFirstChild("Slot_"..i):GetChildren()
			if EquipmentsNumber < 1 then
				table.insert(EmptyEquipmentSlot,i)
				table.insert(EmptyAllSlot.EquipmentSlots,i)
			end
		end
		local ConsumablesNumber = #Consumables:FindFirstChild("Slot_"..i):GetChildren()
		local MaterialsNumber = #Materials:FindFirstChild("Slot_"..i):GetChildren()
		if ConsumablesNumber < 1 then
			table.insert(EmptyConsumableSlot,i)
			table.insert(EmptyAllSlot.ConsumableSlots,i)
		end
		if MaterialsNumber < 1 then
			table.insert(EmptyMaterialSlot,i)
			table.insert(EmptyAllSlot.MaterialSlots,i)
		end
	end
	for i,v in pairs(MainTab:GetChildren()) do
		if #v:GetChildren() == 0 then
			table.insert(EmptyEquippedMainSlot,v.Name)
		end
	end
	for i,v in pairs(AccessoryTab:GetChildren()) do
		if #v:GetChildren() == 0 then
			local slot,slotnumber = string.match(v.Name,StringConverterPattern)
			table.insert(EmptyEquippedAccessorySlot,slotnumber)
		end
	end
	for i,v in pairs(FishingTab:GetChildren()) do
		if #v:GetChildren() == 0 then
			local slot,slotnumber = string.match(v.Name,StringConverterPattern)
			table.insert(EmptyEquippedFishingSlot,slotnumber)
		end
	end
	for i,v in pairs(BowTab:GetChildren()) do
		if #v:GetChildren() == 0 then
			local slot,slotnumber = string.match(v.Name,StringConverterPattern)
			table.insert(EmptyEquippedBowSlot,slotnumber)
		end
	end
	if Mode == 1 then
		if #EmptyEquipmentSlot == 0 then
			return false
		else
			if Order == "GetLowest" then
				local Index, Value = getLowest(EmptyEquipmentSlot)
				if Index == nil and Value == nil then
					return false
				end
				return true,Value
			elseif Order == "GetHighest" then
				local Index, Value = getHighest(EmptyEquipmentSlot)
				if Index == nil and Value == nil then
					return false
				end
				return true,Value
			else
				return true,EmptyEquipmentSlot
			end
		end
	elseif Mode == 2 then
		if #EmptyConsumableSlot == 0 then
			return false
		else
			if Order == "GetLowest" then
				local Index, Value = getLowest(EmptyConsumableSlot)
				if Index == nil and Value == nil then
					return false
				end
				return true,Value
			elseif Order == "GetHighest" then
				local Index, Value = getHighest(EmptyConsumableSlot)
				if Index == nil and Value == nil then
					return false
				end
				return true,Value
			else
				return true,EmptyConsumableSlot
			end
		end
	elseif Mode == 3 then
		if #EmptyMaterialSlot == 0 then
			return false
		else
			if Order == "GetLowest" then
				local Index, Value = getLowest(EmptyMaterialSlot)
				if Index == nil and Value == nil then
					return false
				end
				return true,Value
			elseif Order == "GetHighest" then
				local Index, Value = getHighest(EmptyMaterialSlot)
				if Index == nil and Value == nil then
					return false
				end
				return true,Value
			else
				return true,EmptyMaterialSlot
			end
		end
	elseif Mode == 5 then
		return EmptyEquippedMainSlot, EmptyEquippedAccessorySlot, EmptyEquippedFishingSlot, EmptyEquippedBowSlot
	else 
		if #EmptyAllSlot.EquipmentSlots == 0 and #EmptyAllSlot.ConsumableSlots == 0 and #EmptyAllSlot.MaterialSlots == 0 then
			return false, EmptyEquipmentSlot, EmptyConsumableSlot, EmptyMaterialSlot
		else
			if Order == "GetLowest" then
				local EIndex, EValue = getLowest(EmptyEquipmentSlot)
				if EIndex == nil and EValue == nil then
					EmptyEquipmentSlot = {}
				else
					EmptyEquipmentSlot = EValue
				end
				local CIndex, CValue = getLowest(EmptyConsumableSlot)
				if CIndex == nil and CValue == nil then
					EmptyConsumableSlot = {}
				else
					EmptyConsumableSlot = CValue
				end
				local MIndex, MValue = getLowest(EmptyMaterialSlot)
				if MIndex == nil and MValue == nil then
					EmptyMaterialSlot = {}
				else
					EmptyMaterialSlot = MValue
				end
				return true, EmptyEquipmentSlot, EmptyConsumableSlot, EmptyMaterialSlot
			elseif Order == "GetHighest" then
				local EIndex, EValue = getHighest(EmptyEquipmentSlot)
				if EIndex == nil and EValue == nil then
					EmptyEquipmentSlot = {}
				else
					EmptyEquipmentSlot = EValue
				end
				local CIndex, CValue = getHighest(EmptyConsumableSlot)
				if CIndex == nil and CValue == nil then
					EmptyConsumableSlot = {}
				else
					EmptyConsumableSlot = CValue
				end
				local MIndex, MValue = getHighest(EmptyMaterialSlot)
				if MIndex == nil and MValue == nil then
					EmptyMaterialSlot = {}
				else
					EmptyMaterialSlot = MValue
				end
				return true, EmptyEquipmentSlot, EmptyConsumableSlot, EmptyMaterialSlot
			else
				return true, EmptyEquipmentSlot, EmptyConsumableSlot, EmptyMaterialSlot
			end	
		end
	end
end
function ItemSlotHandler.EquipItem(Player,SelectedSlot,EquipSlot,IsSwap)
	local Name, Number = string.match(SelectedSlot,StringConverterPattern)
	local EquipSlotName,EquipSlotNumber = string.match(EquipSlot,StringConverterPattern)
	local Bank = Player:WaitForChild("Bank")
	local Inventory = Player:WaitForChild("Inventory")
	local Equipped = Inventory:WaitForChild("Equipped")
	local MainTab = Equipped:WaitForChild("Main")
	local AccessoryTab = Equipped:WaitForChild("Accessory")
	local Equipments = Inventory:WaitForChild("Equipments")
	local Consumables = Inventory:WaitForChild("Consumables")
	local Materials = Inventory:WaitForChild("Materials")
	local SwapSlot 
	local WillSwap = false
	local EquippingType
	local Slot
	print(Name)
	print(Number)
	local Main,Accessory = ItemSlotHandler.GetEmptySlots(Player,5)
	print(Main)
	print(Accessory)
	if Name ~= nil and Number ~= nil then
		if Name == "Equipments" then
			Slot = Equipments:FindFirstChild("Slot_"..Number)
			SwapSlot = Name.."_"..Number
		elseif Name == "Consumables" then
			Slot = Consumables:FindFirstChild("Slot_"..Number)
			SwapSlot = Name.."_"..Number
		else
			return false,"Not Accepting material or selectedslot is ????"
		end
	else return false,"Cannot find SelectedSlot"
	end
	if #Slot:GetChildren() ~= 1 then
		return false, "Slot is Empty/not as 1" 
	end
	local ItemName,ItemType,ItemSubType = ItemDictionaryHandler.IDToName(Slot:FindFirstChildOfClass("NumberValue").Value)
	if EquipSlotName == "Accessory"  and EquipSlotNumber ~= nil then
		if Name ~= "Equipments" and ItemSubType ~= "Accessory" then return false,"Cannot equip item to that accessory slot.." end
		if Accessory ~= nil then
			if table.find(Accessory,EquipSlotNumber) == nil and table.find(EquippedTab.Accessory,"Slot"..EquipSlotNumber) and IsSwap == true then
				if IsSwap == true then
					WillSwap = true
				else return false, "Slot is occupied"
				end
			elseif table.find(Accessory,EquipSlotNumber) ~= nil and not table.find(EquippedTab.Accessory,"Slot"..EquipSlotNumber) then
				return false, "Given slot is nil"
			end
			EquippingType = 2
		else
			return false,"AccessoryTable is nil?"
		end
	elseif EquipSlotName == nil and EquipSlotNumber == nil and table.find(EquippedTab,EquipSlot) then
		if Main then
			if not table.find(Main,EquipSlot) and ItemSubType ~= "Accessory" then
				print("eeeee")
				print(IsSwap)
				if IsSwap == true then
					WillSwap = true
					print(WillSwap)

				else return false, "Slot is occupied"
				end
			end
			EquippingType = 1
		else
			return false,"MainTable is nil?"
		end
	else
		return false,"EquipSlot is nil?"
	end

	if #Slot:GetChildren() == 1 then
		for i,v in pairs(Slot:GetChildren()) do
			v:SetAttribute("CurrentSlot",-1)
			local NewItem = ItemDictionaryHandler.ItemToDictionary(v)
			if EquippingType == 1 then
				local IfSuccess, Reason = pcall(function()
					MainTab:FindFirstChild(EquipSlot)
				end)
				if IfSuccess == true then
					print(WillSwap)
					print(table.find(WeaponType,"xd"))
					local NewSlot = MainTab:FindFirstChild(EquipSlot)
					if WillSwap == true then
						local a,b
						if table.find(WeaponType,ItemSubType) ~= nil and NewSlot.Name ~= "Pet" and NewSlot.Name ~= "Chestplates" and NewSlot.Name ~= "Boots" and NewSlot.Name ~= "Helmet" then
							print("this could be?")
							a,b = ItemSlotHandler.SwapSlots(Player,SwapSlot,NewSlot.Name)
						elseif ItemSubType == "Aura" and NewSlot.Name == "Aura" then
							a,b = ItemSlotHandler.SwapSlots(Player,SwapSlot,NewSlot.Name)
						elseif ItemSubType == "Chestplate" and NewSlot.Name == "Chestplate" then
							a,b = ItemSlotHandler.SwapSlots(Player,SwapSlot,NewSlot.Name)
						elseif ItemSubType == "Helmet" and NewSlot.Name == "Helmet" then
							a,b = ItemSlotHandler.SwapSlots(Player,SwapSlot,NewSlot.Name)
						elseif ItemSubType == "Boots" and NewSlot.Name == "Boots" then
							a,b = ItemSlotHandler.SwapSlots(Player,SwapSlot,NewSlot.Name)
						else return false,"wrong type"
						end

						return a,b
					else
						print(table.find(WeaponType,"xd"))
						print(table.find(WeaponType,ItemSubType))
						if (table.find(WeaponType,ItemSubType) == 1 or table.find(WeaponType,ItemSubType) == 4)  and NewSlot.Name == "Offhand"  then
							print("L856")
							ItemDictionaryHandler.DictionaryToItem(NewItem,NewSlot)
							v:Destroy()
						elseif table.find(WeaponType,ItemSubType) ~= nil and NewSlot.Name == "Weapon" then
							ItemDictionaryHandler.DictionaryToItem(NewItem,NewSlot)
							v:Destroy()
						elseif ItemSubType == "Aura" and NewSlot.Name == "Aura" then
							ItemDictionaryHandler.DictionaryToItem(NewItem,NewSlot)
							v:Destroy()
						elseif ItemSubType == "Chestplate" and NewSlot.Name == "Chestplate" then
							ItemDictionaryHandler.DictionaryToItem(NewItem,NewSlot)
							v:Destroy()
						elseif ItemSubType == "Helmet" and NewSlot.Name == "Helmet" then
							ItemDictionaryHandler.DictionaryToItem(NewItem,NewSlot)
							v:Destroy()
						elseif ItemSubType == "Boots" and NewSlot.Name == "Boots" then
							ItemDictionaryHandler.DictionaryToItem(NewItem,NewSlot)
							v:Destroy()
						else return false,"wrong type"
						end

						return true, "Equipped Item!"
					end
				else
					return false, "EquipSlot is Nil"
				end
			elseif EquippingType == 2 then
				local IfSuccess, Reason = pcall(function()
					AccessoryTab:FindFirstChild("AccessorySlot_"..EquipSlotNumber)
				end)
				if IfSuccess == true then
					local NewSlot = AccessoryTab:FindFirstChild("AccessorySlot_"..EquipSlotNumber)
					print(NewSlot)
					print(WillSwap)
					if WillSwap == true then
						local a,b = ItemSlotHandler.SwapSlots(Player,SwapSlot,"Accessory_"..EquipSlotNumber)
						return a,b
					else
						ItemDictionaryHandler.DictionaryToItem(NewItem,NewSlot)
						v:Destroy()
						return true, "Equipped Item!"
					end
				else
					return false, "Given Slot is Nil"
				end
			else return false, "cannot get equippingtype"
			end
		end
	end
end
function ItemSlotHandler.UnequipItem(Player,SelectedSlot,IfBank)
	local Bank = Player:WaitForChild("Bank")
	local Inventory = Player:WaitForChild("Inventory")
	local Equipments = Inventory:WaitForChild("Equipments")
	local Consumables = Inventory:WaitForChild("Consumables")
	local Materials = Inventory:WaitForChild("Materials")
	local Equipped = Inventory:WaitForChild("Equipped")
	local MainTab = Equipped:WaitForChild("Main")
	local AccessoryTab = Equipped:WaitForChild("Accessory")
	local IfSuccess,EquipmentSlot,ConsumableSlot,MaterialSlot = ItemSlotHandler.GetEmptySlots(Player,4,"GetLowest")
	print(IfSuccess, EquipmentSlot)
	if table.find(EquippedTab,SelectedSlot) then
		print("E")
		local Slot = MainTab:FindFirstChild(SelectedSlot)
		if #Slot:GetChildren() == 1 then
			local Item = Slot:FindFirstChildOfClass("NumberValue")
			print(Item)
			local ItemName,ItemType = ItemDictionaryHandler.IDToName(tonumber(Item.Value))
			local NewSlot
			print(type(ItemType))
			if ItemType == 1 then
				if type(EquipmentSlot) == "number" and EquipmentSlot > 0 then
					NewSlot = Equipments:FindFirstChild("Slot_"..EquipmentSlot)
					Item:SetAttribute("CurrentSlot",EquipmentSlot)
					Item.Parent = NewSlot
					return true
				elseif type(EquipmentSlot) == "table" then
					if IfBank == true then
						Item:SetAttribute("CurrentSlot",0)
						Item.Parent = Bank
						return true
					else
						return false
					end
				end
			elseif ItemType == 2 then
				if type(ConsumableSlot) == "number" and ConsumableSlot > 0 then
					NewSlot = Consumables:FindFirstChild("Slot_"..ConsumableSlot)
					Item:SetAttribute("CurrentSlot",ConsumableSlot)
					Item.Parent = NewSlot
					return true
				elseif type(ConsumableSlot) == "table" then
					if IfBank == true then
						Item:SetAttribute("CurrentSlot",0)
						Item.Parent = Bank
						return true
					else
						return false
					end
				end
			elseif ItemType == 3 then
				if type(MaterialSlot) == "number" and MaterialSlot > 0 then
					NewSlot = Materials:FindFirstChild("Slot_"..MaterialSlot)
					Item:SetAttribute("CurrentSlot",MaterialSlot)
					Item.Parent = NewSlot
					return true
				elseif type(MaterialSlot) == "table" then
					if IfBank == true then
						Item:SetAttribute("CurrentSlot",0)
						Item.Parent = Bank
						return true
					else
						return false
					end
				end
			end
		elseif #Slot:GetChildren() < 1 then
			return false, "SelectedSlot is empty"
		else
			ItemSlotHandler.CorrectSlotNumber(Player)
			return false, "SelectedSlot more than 1 items, attempted to correct."
		end
	else
		local Name,Number = string.match(SelectedSlot,StringConverterPattern)
		if EquippedTab[Name] then
			local Slot = AccessoryTab:FindFirstChild("AccessorySlot_"..Number)
			if #Slot:GetChildren() == 1 then
				local Item = Slot:FindFirstChildOfClass("NumberValue")
				local ItemName,ItemType = ItemDictionaryHandler.IDToName(Item.Value)
				local NewSlot
				if ItemType == 1 then
					if type(EquipmentSlot) == "number" and EquipmentSlot > 0 then
						NewSlot = Equipments:FindFirstChild("Slot_"..EquipmentSlot)
						Item:SetAttribute("CurrentSlot",EquipmentSlot)
						Item.Parent = NewSlot
						return true
					elseif type(EquipmentSlot) == "table" then
						if IfBank == true then
							Item:SetAttribute("CurrentSlot",0)
							Item.Parent = Bank
							return true
						else
							return false
						end
					end
				end
			elseif #Slot:GetChildren() < 1 then
				return false,"SelectedSlot is empty"
			else
				ItemSlotHandler.CorrectSlotNumber(Player)
				return false, "SelectedSlot more than 1 items, attempted to correct."
			end
		end
	end
end
function ItemSlotHandler.SwapSlots(Player,SelectedSlot,NewSlot,AutoEquip)
	local Bank = Player:WaitForChild("Bank")
	local Inventory = Player:WaitForChild("Inventory")
	local Equipments = Inventory:WaitForChild("Equipments")
	local Consumables = Inventory:WaitForChild("Consumables")
	local Materials = Inventory:WaitForChild("Materials")
	local Equipped = Inventory:WaitForChild("Equipped")
	local MainTab = Equipped:WaitForChild("Main")
	local AccessoryTab = Equipped:WaitForChild("Accessory")
	if SelectedSlot == NewSlot then
		return false, "same???"
	end
	local SelectedName, SelectedNumber = string.match(SelectedSlot,StringConverterPattern)
	local NewName, NewNumber = string.match(NewSlot,StringConverterPattern)
	print("fired aaaaaaa")
	if table.find(EquippedTab,SelectedSlot) and SelectedName == nil and SelectedNumber == nil then --Check if 1st slot is Equipped main
		local Slot1 = MainTab:FindFirstChild(SelectedSlot)
		if #Slot1:GetChildren() == 1 then
			local FirstItem = Slot1:FindFirstChildOfClass("NumberValue")
			local FirstItemName, FirstItemType = ItemDictionaryHandler.IDToName(tonumber(FirstItem.Value))
			local Slot2
			if table.find(EquippedTab,NewSlot) and NewName == nil and NewNumber == nil then-- if 2nd slot is equipped main too
				Slot2 = MainTab:FindFirstChild(NewSlot)
				if #Slot2:GetChildren() == 1 then
					local SecondaryItem = Slot2:FindFirstChildOfClass("NumberValue")
					FirstItem.Parent = Slot2
					SecondaryItem.Parent = Slot1
					ItemSlotHandler.CorrectSlotNumber(Player)
					return true, "Swapped Item!"
				else
					return false, "EquippedTab cannot be AutoEquipped"
				end
			elseif NewName ~= nil and NewNumber ~= nil then-- if not from equipped then
				if NewName == "Equipments" then -- Equipments
					if FirstItemType == 1 then
						Slot2 = Equipments:FindFirstChild("Slot_"..NewNumber)
						if #Slot2:GetChildren() == 1 then
							local SecondaryItem = Slot2:FindFirstChildOfClass("NumberValue")
							FirstItem.Parent = Slot2
							SecondaryItem.Parent = Slot1
							ItemSlotHandler.CorrectSlotNumber(Player)
							return true, "Swapped Item!"
						end
					else
						return false, "Wrong type"
					end
				elseif NewName == "Consumables" then -- Equipments
					print("test aaa")
					if FirstItemType == 2 then
						Slot2 = Consumables:FindFirstChild("Slot_"..NewNumber)
						if #Slot2:GetChildren() == 1 then
							local SecondaryItem = Slot2:FindFirstChildOfClass("NumberValue")
							FirstItem.Parent = Slot2
							SecondaryItem.Parent = Slot1
							ItemSlotHandler.CorrectSlotNumber(Player)
							return true, "Swapped Item!"
						end
					else
						return false, "Wrong type"
					end
				else
					return false, "Wrong catagory on 2nd slot?"
				end

			end
			--elseif #Slot1:GetChildren() < 1 then
			--Unequip or Equip
		else
			ItemSlotHandler.CorrectSlotNumber(Player)
			return false, "more or less than 1 item in selected slot?"
		end
	elseif EquippedTab[SelectedName] and SelectedName ~= nil and SelectedNumber ~= nil  then -- if 1st slot from accessory
		local Slot1 = AccessoryTab:FindFirstChild("AccessorySlot_"..SelectedNumber)
		if #Slot1:GetChildren() == 1 then
			local FirstItem = Slot1:FindFirstChildOfClass("NumberValue")
			local FirstItemName, FirstItemType = ItemDictionaryHandler.IDToName(tonumber(FirstItem.Value))
			local Slot2
			if EquippedTab[NewName] and NewName ~= nil and NewNumber ~= nil then
				Slot2 = AccessoryTab:FindFirstChild("AccessorySlot_"..NewNumber)
				if #Slot2:GetChildren() == 1 then
					local SecondaryItem = Slot2:FindFirstChildOfClass("NumberValue")
					FirstItem.Parent = Slot2
					SecondaryItem.Parent = Slot1
					ItemSlotHandler.CorrectSlotNumber(Player)
					return true, "Swapped Item!"
				elseif #Slot2:GetChildren() > 1 then
					ItemSlotHandler.CorrectSlotNumber(Player)
					return false, "NewSlot is occupied, attempted to correctslots"
				elseif #Slot2:GetChildren() < 1 then
					return false, "NewSlot is empty"
				end
			elseif NewName == "Equipments" then
				if FirstItemType == 1 then
					Slot2 = Equipments:FindFirstChild("Slot_"..NewNumber)
					if #Slot2:GetChildren() == 1 then
						local SecondaryItem = Slot2:FindFirstChildOfClass("NumberValue")
						FirstItem.Parent = Slot2
						SecondaryItem.Parent = Slot1
						ItemSlotHandler.CorrectSlotNumber(Player)
						return true,"Swapped Item!"
					elseif #Slot2:GetChildren() < 1 then
						local IfSuccess, Error = ItemSlotHandler.UnequipItem(Player,Slot1,false)
						if IfSuccess then
							return true, "Swapped Item!"
						else
							return false, Error
						end
					end
				else
					return false, "Wrong type"
				end
			else
				return false, "NewSlot is inappropriate"
			end
		else
			return false, "more or less thant 1 item in select slot?"
		end
	elseif SelectedName == "Equipments" then
		local Slot1 = Equipments:FindFirstChild("Slot_"..SelectedNumber)
		if #Slot1:GetChildren() == 1 then
			local FirstItem = Slot1:FindFirstChildOfClass("NumberValue")
			local FirstItemName, FirstItemType = ItemDictionaryHandler.IDToName(tonumber(FirstItem.Value))
			local Slot2
			if table.find(EquippedTab,NewSlot) and NewName == nil and NewNumber == nil then
				Slot2 = MainTab:FindFirstChild(NewSlot)
				if #Slot2:GetChildren() == 1 then
					local SecondaryItem = Slot2:FindFirstChildOfClass("NumberValue")
					FirstItem.Parent = Slot2
					SecondaryItem.Parent = Slot1
					ItemSlotHandler.CorrectSlotNumber(Player)
					return true, "Swapped Item!"
				else
					return false, "EquippedTab cannot be AutoEquipped"
				end
			elseif NewName == "Accessory" and NewNumber ~= nil then
				Slot2 = AccessoryTab:FindFirstChild("AccessorySlot_"..NewNumber)
				print(Slot1)
				print(Slot2)
				if #Slot2:GetChildren() == 1 then
					local SecondaryItem = Slot2:FindFirstChildOfClass("NumberValue")
					FirstItem.Parent = Slot2
					SecondaryItem.Parent = Slot1
					--ItemSlotHandler.CorrectSlotNumber(Player)
					return true, "Swapped Item!"
				elseif #Slot2:GetChildren() > 1 then
					ItemSlotHandler.CorrectSlotNumber(Player)
					return false, "NewSlot is occupied, attempted to correctslots"
				elseif #Slot2:GetChildren() < 1 then
					--EquipItem() once i reworked it


					return false, "NewSlot is empty"
				end
			elseif NewName ~= nil and NewNumber ~= nil then
				if NewName == "Equipments" then
					if FirstItemType == 1 then
						Slot2 = Equipments:FindFirstChild("Slot_"..NewNumber)
						if #Slot2:GetChildren() == 1 then
							local SecondaryItem = Slot2:FindFirstChildOfClass("NumberValue")
							FirstItem.Parent = Slot2
							SecondaryItem.Parent = Slot1
							ItemSlotHandler.CorrectSlotNumber(Player)
							return true, "Swapped Item!"
						end
					else
						return false, "Wrong type"
					end
				else
					return false, "Wrong catagory on 2nd slot?"
				end

			end
			--elseif SelectedName == "Equipments" then
			--	local Slot1 = Equipments:FindFirstChild("Slot_"..SelectedNumber)
			--	if #Slot1:GetChildren() == 1 then
			--		local FirstItem = Slot1:FindFirstChildOfClass("NumberValue")
			--		local FirstItemName, FirstItemType = ItemDictionaryHandler.IDToName(tonumber(FirstItem.Value))
			--		local Slot2
			--		if table.find(EquippedTab,NewSlot) and NewName == nil and NewNumber == nil then
			--			Slot2 = MainTab:FindFirstChild(NewSlot)
			--			if #Slot2:GetChildren() == 1 then
			--				local SecondaryItem = Slot2:FindFirstChildOfClass("NumberValue")
			--				FirstItem.Parent = Slot2
			--				SecondaryItem.Parent = Slot1
			--				ItemSlotHandler.CorrectSlotNumber(Player)
			--				return true
			--			else
			--				return false, "EquippedTab cannot be AutoEquipped"
			--			end
			--		elseif EquippedTab[NewName] and NewName ~= nil and NewNumber ~= nil then
			--			Slot2 = AccessoryTab:FindFirstChild("AccessorySlot_"..NewNumber)
			--			if #Slot2:GetChildren() == 1 then
			--				local SecondaryItem = Slot2:FindFirstChildOfClass("NumberValue")
			--				FirstItem.Parent = Slot2
			--				SecondaryItem.Parent = Slot1
			--				ItemSlotHandler.CorrectSlotNumber(Player)
			--				return true
			--			elseif #Slot2:GetChildren() > 1 then
			--				ItemSlotHandler.CorrectSlotNumber(Player)
			--				return false, "NewSlot is occupied, attempted to correctslots"
			--			elseif #Slot2:GetChildren() < 1 then
			--				--EquipItem() once i reworked it


			--				return false, "NewSlot is empty"
			--			end
			--		elseif NewName ~= nil and NewNumber ~= nil then
			--			if NewName == "Equipments" then
			--				if FirstItemType == 1 then
			--					Slot2 = Equipments:FindFirstChild("Slot_"..NewNumber)
			--					if #Slot2:GetChildren() == 1 then
			--						local SecondaryItem = Slot2:FindFirstChildOfClass("NumberValue")
			--						FirstItem.Parent = Slot2
			--						SecondaryItem.Parent = Slot1
			--						ItemSlotHandler.CorrectSlotNumber(Player)
			--						return true
			--					end
			--				else
			--					return false, "Wrong type"
			--				end
			--			else
			--				return false, "Wrong catagory on 2nd slot?"
			--			end
		end

	elseif SelectedName == "Consumables" then
		print("test aaa")
		local Slot1 = Consumables:FindFirstChild("Slot_"..SelectedNumber)
		if #Slot1:GetChildren() == 1 then
			local FirstItem = Slot1:FindFirstChildOfClass("NumberValue")
			local FirstItemName, FirstItemType = ItemDictionaryHandler.IDToName(tonumber(FirstItem.Value))
			print(FirstItemType)
			local Slot2
			if table.find(EquippedTab,NewSlot) and NewName == nil and NewNumber == nil then
				Slot2 = MainTab:FindFirstChild(NewSlot)
				if #Slot2:GetChildren() == 1 then
					local SecondaryItem = Slot2:FindFirstChildOfClass("NumberValue")
					FirstItem.Parent = Slot2
					SecondaryItem.Parent = Slot1
					ItemSlotHandler.CorrectSlotNumber(Player)
					return true, "Swapped Item!"
				else
					return false, "EquippedTab cannot be AutoEquipped"
				end
			elseif NewName ~= nil and NewNumber ~= nil then
				if NewName == "Consumables" then
					if FirstItemType == 2 then
						Slot2 = Consumables:FindFirstChild("Slot_"..NewNumber)
						if #Slot2:GetChildren() == 1 then
							local SecondaryItem = Slot2:FindFirstChildOfClass("NumberValue")
							FirstItem.Parent = Slot2
							SecondaryItem.Parent = Slot1
							ItemSlotHandler.CorrectSlotNumber(Player)
							return true, "Swapped Item!"
						end
					else
						return false, "Wrong type"
					end
				else
					return false, "Wrong catagory on 2nd slot?"
				end
			end
		end 
	elseif SelectedName == "Materials" then
		local Slot1 = Materials:FindFirstChild("Slot_"..SelectedNumber)
		if #Slot1:GetChildren() == 1 then
			local FirstItem = Slot1:FindFirstChildOfClass("NumberValue")
			local FirstItemName, FirstItemType = ItemDictionaryHandler.IDToName(tonumber(FirstItem.Value))
			local Slot2
			if NewName ~= nil and NewNumber ~= nil then
				if NewName == "Materials" then
					if FirstItemType == 3 then
						Slot2 = Materials:FindFirstChild("Slot_"..NewNumber)
						if #Slot2:GetChildren() == 1 then
							local SecondaryItem = Slot2:FindFirstChildOfClass("NumberValue")
							FirstItem.Parent = Slot2
							SecondaryItem.Parent = Slot1
							ItemSlotHandler.CorrectSlotNumber(Player)
							return true, "Swapped Item!"
						end
					else
						return false, "Wrong type"
					end
				else
					return false, "Wrong catagory on 2nd slot?"
				end
			end
		end 
	end
end
function ItemSlotHandler.SplitSlot(Player,SelectedSlot,Amounts)
	--local Bank = Player:WaitForChild("Bank")
	local Inventory = Player:WaitForChild("Inventory")
	local Type 
	local SelectedInventory 
	local SelectedName, SelectedNumber = string.match(SelectedSlot,StringConverterPattern)
	if SelectedName == "Consumables" then
		Type = 2
		SelectedInventory = Inventory:FindFirstChild("Consumables")
	elseif SelectedName == "Materials" then
		Type = 3
		SelectedInventory = Inventory:FindFirstChild("Materials")
	else return false,"Wrong Type?"
	end
	local itemdata = SelectedInventory:FindFirstChild("Slot_"..SelectedNumber):FindFirstChildOfClass("NumberValue")
	local ServerItemData = require(ItemStogare:FindFirstChild(SelectedName):FindFirstChild(itemdata.Name))
	if ServerItemData.Stackable == false then return false,"This item is singularcell" end
	local IsEmpty, EmptySlots = ItemSlotHandler.GetEmptySlots(Player,Type,"GetLowest")
	print(IsEmpty)
	print(type(EmptySlots))
	if IsEmpty == false then return false,"Inv fulled" end
	if itemdata:GetAttribute("Amounts") <= Amounts then return false,"Too many split request" end
	local newitem = ItemDictionaryHandler.ItemToDictionary(itemdata)
	newitem.Amounts = Amounts
	newitem.CurrentSlot = tonumber(EmptySlots)
	itemdata:SetAttribute("Amounts",itemdata:GetAttribute("Amounts") - Amounts)
	ItemSlotHandler.MoveToSlot(Player,newitem)
	return true, "Splitted Item!"
end
function ItemSlotHandler.MoveItem(Player,SelectedSlot,NewSlot)
	--local Bank = Player:WaitForChild("Bank")
	local Inventory = Player:WaitForChild("Inventory")
	local SelectedName, SelectedNumber = string.match(SelectedSlot,StringConverterPattern)
	local NewName, NewNumber = string.match(NewSlot,StringConverterPattern)
	if SelectedName ~= NewName then return false,"Wrong inv type" end
	local SelectedInventory = Inventory:FindFirstChild(SelectedName)
	if SelectedInventory:FindFirstChild("Slot_"..SelectedNumber):FindFirstChildOfClass("NumberValue") == nil then return false, "Cannot Find Item" end
	local itemdata = SelectedInventory:FindFirstChild("Slot_"..SelectedNumber):FindFirstChildOfClass("NumberValue")
	if #SelectedInventory:FindFirstChild("Slot_"..NewNumber):GetChildren() == 1 then
		local a,b = ItemSlotHandler.SwapSlots(Player,SelectedSlot,NewSlot)
		print(b)
		return a,b
	else
		itemdata:SetAttribute("CurrentSlot",tonumber(NewNumber))
		itemdata.Parent = SelectedInventory:FindFirstChild("Slot_"..NewNumber)
		return true,"Moved Item"
	end
end
return ItemSlotHandler