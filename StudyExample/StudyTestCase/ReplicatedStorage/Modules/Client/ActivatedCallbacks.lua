--[[
	ej0w @ September 2024
	ActivatedCallbacks
	
	Returns when an item of specified type is activated. Else, returns w/ Default
]]

--> Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Player
local Player = Players.LocalPlayer

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")
local pData = PlayerData:WaitForChild(Player.UserId)

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

local SFX = require(ReplicatedStorage.Modules.Shared.SFX)
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local ContentLibrary = require(ReplicatedStorage.Modules.Shared.ContentLibrary)

local KeybindSystem = require(ReplicatedStorage.Modules.Libraries.Keybinds)

--> Variables
local ActivatedCallbacks = {}

--------------------------------------------------------------------------------

---- Utilities

local function PlayBackpackSound(HumanoidRootPart)
	if HumanoidRootPart then
		SFX:Play3D(GameConfig.DefaultEquipSound[1], HumanoidRootPart, {Volume = GameConfig.DefaultEquipSound[2]})
	end
end

---- Callbacks

function ActivatedCallbacks:Material(Slot)
	return
end

function ActivatedCallbacks:Armor(Slot)
	local Character = Player.Character
	local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
	
	if pData.ActiveArmor.Value == Slot.ItemInstance.Name then 
		EventModule:InvokeServer("UnequipArmor", Slot.ItemInstance.Name)
	else
		PlayBackpackSound(HumanoidRootPart)
		EventModule:InvokeServer("EquipArmor", Slot.ItemInstance.Name)
	end
end

function ActivatedCallbacks:Accessory(Slot)
	local Character = Player.Character
	local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
	
	local LowestEmptyIndex = math.huge
	local isUnequipped = false
	
	local function RequestUnequipAccessory(Name, Index)
		EventModule:InvokeServer("UnequipAccessory", Index)
	end
	
	local function RequestEquipAccessory(Name, Index)
		EventModule:InvokeServer("EquipAccessory", Name, LowestEmptyIndex)
	end
	
	local EquippedSlots = pData.EquippedSlots
	for _, NewSlot in EquippedSlots:GetChildren() do
		local Index = tonumber(NewSlot.Name)
		
		if NewSlot.Value == Slot.ItemInstance.Name then
			isUnequipped = true
			
			RequestUnequipAccessory(NewSlot.Value, Index)
		end
		
		if NewSlot.Value == "" and Index < LowestEmptyIndex then
			LowestEmptyIndex = Index
		end
	end
	
	if not isUnequipped then
		PlayBackpackSound(HumanoidRootPart)
		
		if LowestEmptyIndex > GameConfig.EquippedAccessoryMax then
			LowestEmptyIndex = GameConfig.EquippedAccessoryMax 
			
			local NewSlot = EquippedSlots:FindFirstChild(tostring(LowestEmptyIndex))
			RequestUnequipAccessory(NewSlot.Value, LowestEmptyIndex)
		end
		
		RequestEquipAccessory(Slot.ItemInstance.Name, LowestEmptyIndex)
	end
end

-- Calls if there's no other activated callback
function ActivatedCallbacks:Default(Slot)
	local ItemName = Slot.ItemInstance.Name
	
	local Item = Player.Backpack:FindFirstChild(Slot.ItemInstance.Name) 
		or Player.Character:FindFirstChild(ItemName)
	
	Slot.ItemInstance = Item

	local Character = Player.Character
	local Humanoid = Character and Character:FindFirstChild("Humanoid") :: Humanoid?

	-- Equip/unequip
	if Humanoid and Humanoid.Health > 0 then
		if Character:FindFirstChild(Item.Name) then
			Humanoid:UnequipTools()
		else
			Humanoid:EquipTool(Item)
		end
	end
end

return ActivatedCallbacks