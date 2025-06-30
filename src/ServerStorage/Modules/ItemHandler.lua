--APIs
--[[
Main APIs:
	ItemHandler.Create(ID,AutoFill,Parent,IsNotify,Custom)
	ItemHandler.ItemIncrement(ID,Player,Amounts,IsNotify,CustomCondition)
	ItemHandler.ItemReduction(ID,Player,Amounts,IsNotify,CustomCondition)
]]

--[[
Usage:
	local module = require(game.ServerStorage.Modules.ItemHandler) module.Create(1,true,game.Players.Player1,true,{Upgrades = {Damage = 3},UpgradeAttempts = 10 })
	local module = require(game.ServerStorage.Modules.ItemHandler) module.Create(3,true,game.Players.Player1,true,{Amounts = 10})
	local module = require(game.ServerStorage.Modules.ItemHandler) module.ItemIncrement(3,game.Players.tano_dev,233,false) 
]]
local NotifyHolder = game:GetService("ReplicatedStorage"):WaitForChild("PlayerDataHolder"):WaitForChild("Notify")
local ItemDictionaryHandler = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("ItemDictionaryHandler"))
local ItemSlotHandler = require(game:GetService("ServerStorage"):WaitForChild("Modules"):WaitForChild("ItemSlotHandler"))
local EquipmentFormat = require(game:GetService("ReplicatedStorage"):WaitForChild("Format"):WaitForChild("EquipmentFormat"))
local Material_ConsumableFormat = require(game:GetService("ReplicatedStorage"):WaitForChild("Format"):WaitForChild("Material_ConsumableFormat"))
local FormatFolder = game:GetService("ReplicatedStorage"):WaitForChild("Format")
local Equipment = FormatFolder:WaitForChild("Equipment")
local Material_Consumable = FormatFolder:WaitForChild("Material_Consumable")
local GameItems = game:GetService("ReplicatedStorage"):WaitForChild("GameItems")
local ItemStateData = require(GameItems:WaitForChild("ItemStateData"))
local RemoteFunc = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("RemoteFunc"))

local ItemHandler = {}
function ItemHandler.Create(ID,AutoFill,Parent,IsNotify,Custom)
	local IsNotified = false or IsNotify -- For Notification
	local Name, Type, SubType = ItemDictionaryHandler.IDToName(ID)
	if Type == 1 then
		local NewItem = Equipment:Clone()
		NewItem.Name = Name
		for n,v in pairs(EquipmentFormat) do
			if type(v) == "table" then
				if n == "Enchants" then
					for a,b in pairs(v) do
						NewItem:WaitForChild("Enchants"):SetAttribute(a,b.ID..":"..b.Level)
					end
				end
				if n == "Gems" then
					for a,b in pairs(v) do
						NewItem:WaitForChild("Gems"):SetAttribute(a,b.ID)
					end
				end
				if n == "Upgrades" then
					for a,b in pairs(v) do
						NewItem:WaitForChild("Upgrades"):SetAttribute(a,b)
					end
				end
			elseif n == "UpgradeAttemptUsed" then
				NewItem:WaitForChild("Upgrades").Value = tonumber(v)
			elseif n == "GemSlotUsed" then
				NewItem:WaitForChild("Gems").Value = tonumber(v)
			elseif n == "EnchantSlotUsed" then
				NewItem:WaitForChild("Enchants").Value = tonumber(v)
			elseif n == "ID" then
				NewItem.Value = ID
			elseif n == "CurrentSlot" then
				if AutoFill == false then
					NewItem:SetAttribute(n,v)
				end
			else
				NewItem:SetAttribute(n,v)
			end
		end
		if type(Custom) == "table" then
			for n,v in pairs(Custom) do
				if type(v) == "table" then
					if n == "Enchants" then
						for a,b in pairs(v) do
							NewItem:WaitForChild("Enchants"):SetAttribute(a,b.ID..":"..b.Level)
						end
					end
					if n == "Gems" then
						for a,b in pairs(v) do
							NewItem:WaitForChild("Gems"):SetAttribute(a,b.ID)
						end
					end
					if n == "Upgrades" then
						for a,b in pairs(v) do
							NewItem:WaitForChild("Upgrades"):SetAttribute(a,b)
						end
					end

				elseif n == "UpgradeAttemptUsed" then
					NewItem:WaitForChild("Upgrades").Value = tonumber(v)
				elseif n == "GemSlotUsed" then
					NewItem:WaitForChild("Gems").Value = tonumber(v)
				elseif n == "EnchantSlotUsed" then
					NewItem:WaitForChild("Enchants").Value = tonumber(v)
				elseif ItemStateData[n] then
					if NewItem:GetAttribute("State") == "" then
						NewItem:SetAttribute("State",ItemStateData[n])
					else
						local currentstate = NewItem:GetAttribute("State")
						NewItem:SetAttribute("State",currentstate..":"..ItemStateData[n])
					end
				else
					NewItem:SetAttribute(n,v)
				end
			end
		end	
		if AutoFill then
			local Player = Parent
			local success, value = ItemSlotHandler.GetEmptySlots(Player,Type,"GetLowest")
			if success then
				NewItem.Parent = Player:WaitForChild("Inventory"):WaitForChild("Equipments"):WaitForChild("Slot_"..value)
				NewItem:SetAttribute("CurrentSlot",value)
			else
				NewItem.Parent = Player:WaitForChild("Bank")
				NewItem:SetAttribute("CurrentSlot",0)
			end
		else NewItem.Parent = Parent
		end
		if IsNotified and type(Parent) == "userdata" then
			--local NotifyEvent = RemoteFunc.new("OnNotify")
			local ItemModule = require(GameItems:FindFirstChild("Equipments"):FindFirstChild(Name))
			local CreateNotify = Instance.new("ObjectValue",NotifyHolder:FindFirstChild(Parent.Name))
			CreateNotify.Name = Name
			CreateNotify:SetAttribute("Rarity",ItemModule.Rarity) 
			CreateNotify:SetAttribute("Type",1) 
			CreateNotify:AddTag("Notify")
			--local NotifyEventRespond = NotifyEvent.Fire(Parent,1,Name,ItemModule.Rarity)
			--print(NotifyEventRespond, Parent)
		end
	elseif Type == 2 or Type == 3 then
		local NewItem = Material_Consumable:Clone()
		NewItem.Name = Name
		for i,v in pairs(Material_ConsumableFormat) do
			if i == "ID" then
				NewItem.Value = ID
				--elseif AutoFill == false then
				--	NewItem:SetAttribute(i,v)
			else
				NewItem:SetAttribute(i,v)
			end
		end
		if type(Custom) == "table" then
			for i,v in pairs(Custom) do
				NewItem:SetAttribute(i,v)
			end
		end
		if AutoFill then
			print("a")
			local Player = Parent
			local success, value = ItemSlotHandler.GetEmptySlots(Player,Type,"GetLowest")
			--print(Custom.Amounts)
			print(success)
			if success then
				if Type == 2 then
					NewItem.Parent = Player:WaitForChild("Inventory"):WaitForChild("Consumables"):WaitForChild("Slot_"..value)
					NewItem:SetAttribute("CurrentSlot",value)
				elseif Type == 3 then
					NewItem.Parent = Player:WaitForChild("Inventory"):WaitForChild("Materials"):WaitForChild("Slot_"..value)
					NewItem:SetAttribute("CurrentSlot",value)
				end
			else
				if Type ~= 1 then
					print("b")
					local Catagory
					local CatagoryInventory
					local TotalSpareBankItem = 0 
					if Type == 2 then
						Catagory = GameItems:WaitForChild("Consumables")
					elseif Type == 3 then
						Catagory = GameItems:WaitForChild("Materials")
					end
					local ItemData = require(Catagory:WaitForChild(Name))
					if ItemData.Stackable == true then
						local amounts = 1
						if type(Custom) ~= "table" then
							Custom = {Amounts = 1}
						else
							amounts = Custom.Amounts
						end
						for i,v in pairs(Player:FindFirstChild("Bank"):GetChildren()) do
							if v.Name == Name and v.Value == ID then
								print(i,v)
								local IsExact = true
								for a,b in pairs(Custom) do
									if v:GetAttribute(a) ~= b and a ~= "Amounts" then
										IsExact = false
									end
								end
								print(IsExact)
								if IsExact then
									if v:GetAttribute("Amounts") ~= ItemData.StackSize then
										TotalSpareBankItem += ItemData.StackSize - v:GetAttribute("Amounts")
									end
								end
							end
						end
						print(TotalSpareBankItem)
						for i,v in pairs(Player:FindFirstChild("Bank"):GetChildren()) do
							if v.Name == Name and v.Value == ID then
								local IsExact = true
								for a,b in pairs(Custom) do
									if v:GetAttribute(a) ~= b and a ~= "Amounts" then
										IsExact = false
									end
								end
								if IsExact then
									print("E")
									if v:GetAttribute("Amounts") ~= ItemData.StackSize then
										if v:GetAttribute("Amounts") + amounts > ItemData.StackSize then
											amounts -= ItemData.StackSize-v:GetAttribute("Amounts")
											v:SetAttribute("Amounts",ItemData.StackSize)
										else
											v:SetAttribute("Amounts",v:GetAttribute("Amounts")+amounts)
											amounts = 0 
										end

									end
								end
							end
						end
						if amounts ~= 0 then
							NewItem:SetAttribute("Amounts",amounts)
							NewItem:SetAttribute("CurrentSlot",0)
							NewItem.Parent = Player:WaitForChild("Bank")
						else
							NewItem:Destroy()
						end
					else
						NewItem.Parent = Player:WaitForChild("Bank")
						NewItem:SetAttribute("Amounts",0)
						NewItem:SetAttribute("CurrentSlot",0)
					end
				else
					NewItem.Parent = Player:WaitForChild("Bank")
					NewItem:SetAttribute("CurrentSlot",0)
				end

				--if i == "Amounts" and type(Parent) == "userdata" then
				--	if type(Parent) == "userdata" then
				--		local Player = Parent
				--		local Catagory
				--		local CatagoryInventory
				--		local ItemSearch = {}
				--		if Type == 2 then
				--			Catagory = GameItems:WaitForChild("Consumables")
				--		elseif Type == 3 then
				--			Catagory = GameItems:WaitForChild("Materials")
				--		end
				--		local ItemData = require(Catagory:WaitForChild(Name))
				--		local PlayerBank = Player:FindFirstChild("Bank")
				--		for i,v in pairs(PlayerBank:GetChildren()) do
				--			if v.Name == Name and v.Value == ID then
				--				local IsExact = true
				--				for a,b in pairs(Custom) do
				--					if v:GetAttribute(a) ~= b then
				--						IsExact = false
				--					end
				--				end
				--				if IsExact then
				--					if v:GetAttribute("Amounts") ~= ItemData.StackSize then
				--						ItemSearch[tonumber(slotinform[2])] = tonumber(item:GetAttribute("Amounts"))
				--					end
				--				end
				--			end
				--		end
				--	end
			end
		else NewItem.Parent = Parent
		end
	end
end
function ItemHandler.ItemIncrement(ID,Player,Amounts,IsNotify,CustomCondition)
	local ItemName,ItemType = ItemDictionaryHandler.IDToName(ID)
	local Catagory
	local CatagoryInventory
	local CheckTable = CustomCondition or {CustomLore = "",CustomName = ""}
	for i,v in pairs(Material_ConsumableFormat) do
		if i ~= "ID" and i ~= "Amounts" and i~= "CurrentSlot" then
			if CheckTable[i] == nil then CheckTable[i] = v end
		end
	end
	local FinalTable = CustomCondition or {}
	local ItemSearch = {}
	if ItemType == 1 then
		return false, "Cannot increase Equipment."
	elseif ItemType == 2 then
		Catagory = GameItems:WaitForChild("Consumables")
		CatagoryInventory = Player.Inventory.Consumables
	elseif ItemType == 3 then
		Catagory = GameItems:WaitForChild("Materials")
		CatagoryInventory = Player.Inventory.Materials
	end
	local ItemLookUp = Catagory:WaitForChild(ItemName)
	local ItemData = require(ItemLookUp)
	--Main parts
	if ItemData.Stackable == false then
		ItemHandler.Create(ID,true,Player,false,CustomCondition)
	else

		local function SearchItems()
			ItemSearch = {}
			for i,v in pairs(CatagoryInventory:GetChildren()) do -- get existed items
				if v:FindFirstChildOfClass("NumberValue") then
					local item = v:FindFirstChildOfClass("NumberValue") 
					if item.Value == ID then
						--if type(CustomCondition) == "table" then
							local function IsExact()
								local returnvalue = true
								for a,b in pairs(CheckTable) do
									if item:GetAttribute(a) ~= b then
										returnvalue = false
										return returnvalue
									end
								end
								return returnvalue
							end
							local CheckItem = IsExact()
							if CheckItem then
								if item:GetAttribute("Amounts") ~= ItemData.StackSize then
									local slotinform = v.Name:split("_")
									print(slotinform)
									ItemSearch[tonumber(slotinform[2])] = tonumber(item:GetAttribute("Amounts"))
								end
							end
						--else
						--	if item:GetAttribute("Amounts") ~= ItemData.StackSize then
						--		local slotinform = v.Name:split("_")
						--		print(slotinform)
						--		ItemSearch[tonumber(slotinform[2])] = tonumber(item:GetAttribute("Amounts"))
						--	end
						--end
					end

				end
			end
		end

		print(ItemSearch)

		local function Increase()
			print(FinalTable)
			SearchItems()
			if type(next(ItemSearch)) == type(1) then
				print("L175")
				print(ItemSearch)
				for i,v in pairs(ItemSearch) do
					print("L178")
					print(i)
					print(v)
					local slot = CatagoryInventory:FindFirstChild("Slot_"..tostring(i))
					local slotitem = slot:FindFirstChildOfClass("NumberValue")
					if v + Amounts > ItemData.StackSize then
						local oldamounts = slotitem:GetAttribute("Amounts")
						slotitem:SetAttribute("Amounts",ItemData.StackSize)
						Amounts = Amounts - (ItemData.StackSize-oldamounts)
						--Increase()
					elseif v + Amounts <= ItemData.StackSize then
						slotitem:SetAttribute("Amounts",v+Amounts)
						Amounts = 0
					end
				end
			else
				print("L195")
				--if Amounts > ItemData.StackSize then

				--	search()
				--	Increase()
				--else
				if Amounts > ItemData.StackSize then
					FinalTable.Amounts = ItemData.StackSize
					ItemHandler.Create(ID,true,Player,false,FinalTable)
					FinalTable.Amounts = nil
					Amounts = Amounts - ItemData.StackSize
				else
					FinalTable.Amounts = Amounts
					ItemHandler.Create(ID,true,Player,false,FinalTable)
					FinalTable.Amounts = nil
					Amounts = 0
				end
				--if type(CustomCondition) == "table" then

				--else
				--	if Amounts > ItemData.StackSize then
				--		ItemHandler.Create(ID,true,Player,{Amounts = ItemData.StackSize})
				--		Amounts = Amounts - ItemData.StackSize
				--	else
				--		ItemHandler.Create(ID,true,Player,{Amounts = Amounts})
				--		Amounts = 0
				--	end
				--end


				--end
			end
			local function FinalAdding()
				if Amounts > 0 then
					if Amounts > ItemData.StackSize then
						FinalTable.Amounts = ItemData.StackSize
						ItemHandler.Create(ID,true,Player,false,FinalTable)
						FinalTable.Amounts = nil
						Amounts = Amounts - ItemData.StackSize
						Increase()
					else
						FinalTable.Amounts = Amounts
						ItemHandler.Create(ID,true,Player,false,FinalTable)
						FinalTable.Amounts = nil
					end
					Amounts = 0
				end
			end
			FinalAdding()
		end
		Increase()


		return true, "Increased Item!"
	end
end
function ItemHandler.ItemReduction(ID,Player,Amounts,IsNotify,CustomCondition)
	local ItemName,ItemType = ItemDictionaryHandler.IDToName(ID)
	local CheckTable = CustomCondition or {CustomLore = "",CustomName = ""}
	for i,v in pairs(Material_ConsumableFormat) do
		if i ~= "ID" and i ~= "Amounts" and i~= "CurrentSlot" then
			if CheckTable[i] == nil then CheckTable[i] = v end
		end
	end
	print(CheckTable)
	local Catagory
	local CatagoryInventory
	if ItemType == 1 then
		return false, "Cannot decrease Equipment."
	elseif ItemType == 2 then
		Catagory = GameItems:WaitForChild("Consumables")
		CatagoryInventory = Player.Inventory.Consumables
	elseif ItemType == 3 then
		Catagory = GameItems:WaitForChild("Materials")
		CatagoryInventory = Player.Inventory.Materials
	end
	local ItemLookUp = Catagory:WaitForChild(ItemName)
	local ItemData = require(ItemLookUp)
	local ItemSearch = {}
	local function SearchItems()
		ItemSearch = {}
		for i,v in pairs(CatagoryInventory:GetChildren()) do -- get existed items
			if v:FindFirstChildOfClass("NumberValue") then
				local item = v:FindFirstChildOfClass("NumberValue") 
				if item.Value == ID then
					--if type(CustomCondition) == "table" then
						local function IsExact()
							local returnvalue = true
							for a,b in pairs(CheckTable) do
								if item:GetAttribute(a) ~= b then
									returnvalue = false
									return returnvalue
								end
							end
							return returnvalue
						end
						local CheckItem = IsExact()
						if CheckItem then

							local slotinform = v.Name:split("_")
							print(slotinform)
							ItemSearch[tonumber(slotinform[2])] = tonumber(item:GetAttribute("Amounts"))

						end
					--else

					--	local slotinform = v.Name:split("_")
					--	print(slotinform)
					--	ItemSearch[tonumber(slotinform[2])] = tonumber(item:GetAttribute("Amounts"))

					--end
				end

			end
		end
	end
	SearchItems()
	print(ItemSearch)
	if next(ItemSearch) then
		print("a")
		if ItemData.Stackable == false then
			for i,v in pairs(ItemSearch) do
				local slot = CatagoryInventory:FindFirstChild("Slot_"..i)
				local slotitem = slot:FindFirstChildOfClass("NumberValue")
				slotitem:Destroy()
				break
			end
			return true, "Item decreased"
		elseif ItemData.Stackable == true then
			local totalamounts = 0
			for i,v in pairs(ItemSearch) do totalamounts = totalamounts + v end
			print(totalamounts)
			if totalamounts < Amounts then
				Player:Kick("Error while decreasing items")
				return false, "excuse me?"
			else
				for i,v in pairs(ItemSearch) do
					local slot = CatagoryInventory:FindFirstChild("Slot_"..tostring(i))
					local slotitem = slot:FindFirstChildOfClass("NumberValue")
					if v <= Amounts then
						local oldamounts = slotitem:GetAttribute("Amounts")
						slotitem:Destroy()
						Amounts = Amounts - oldamounts
					elseif v > Amounts then
						local oldamounts = slotitem:GetAttribute("Amounts")
						slotitem:SetAttribute("Amounts",oldamounts-Amounts)
						Amounts = 0
					end
				end
				return true, "Decreased Item!"
			end
		end
	else
		Player:Kick("Error while decreasing items")
		return false, "excuse me?"
	end
end
return ItemHandler
