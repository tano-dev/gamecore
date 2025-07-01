--[[
	ej0w @ October 2024
	ArmorObject
	
	Handles clientside model & interperetation of armor objects
]]

--> Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local InsertService = game:GetService("InsertService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

--> Player
local Player = Players.LocalPlayer

local pData = ReplicatedStorage:WaitForChild("PlayerData"):WaitForChild(Player.UserId)
local ArmorData = pData:WaitForChild("Items"):WaitForChild("Armor")

--> Dependencies
local ContentLibrary = require(ReplicatedStorage.Modules.Shared.ContentLibrary)
local ClothingLibrary = require(ReplicatedStorage.Modules.Shared.ClothingLibrary)
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local Format = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local SafeWait = require(ReplicatedStorage.Modules.Client.safeWait)

local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local ArmorObject = {}
ArmorObject.__index = ArmorObject

--------------------------------------------------------------------------------

if not GameConfig.EnabledFeatures.ArmorObject then
	return {}
end

function ArmorObject.new(ArmorInstance: Model)
	if ArmorInstance:GetAttribute("Loaded") then
		return
	end
	
	ArmorInstance:SetAttribute("Loaded", true)
	
	local Torso = SafeWait(ArmorInstance, "Torso") :: Model
	local Middle = SafeWait(Torso, "Middle") :: BasePart
	local ProximityPrompt = SafeWait(Middle, "ProximityPrompt") :: ProximityPrompt
	
	local ArmorConfig = require(SafeWait(ArmorInstance, "Config"))
	
	---- Create object
	
	local Armor = setmetatable({}, ArmorObject)
	Armor.Config = ArmorConfig
	Armor.Instance = ArmorInstance
	Armor.Name = ArmorConfig.Name
	
	local ArmorObj = ContentLibrary.Armor[Armor.Name]
	if ArmorObj then
		for _, Part in ArmorInstance:GetDescendants() do
			if Part:IsA("BasePart") then
				local isVisible = ArmorConfig.BodyPartsVisible[Part.Name]
				Part.Transparency = isVisible and 0 or 1
				Part.CollisionGroup = "Mobs"
			end
		end
		
		for _, ClassName in {"Shirt", "Pants"} do
			local ClothingID = ClothingLibrary[Armor.Name][ClassName]
			local Clothing = ArmorInstance.Rig:FindFirstChildWhichIsA(ClassName)

			if ClothingID and Clothing then
				Clothing[ClassName .. "Template"] = ClothingID
			end
		end
		
		local ArmorModel = ArmorObj.Instance:Clone()
		ArmorModel:PivotTo(ArmorInstance:GetPivot())
		ArmorModel.Parent = ArmorInstance
		ArmorModel.Name = "ArmorModel"
		
		-- Update armor requirements
		local function RequestUpdateArmor()
			local isOwned = ArmorData:FindFirstChild(Armor.Name)
			isOwned = isOwned and (isOwned.Value > 0)
			
			local LevelText = ArmorConfig.Requirements.Level and Format(ArmorConfig.Requirements.Level, "Suffix")
			local OwnedText = ArmorConfig.Requirements.RequiresDataValue and (isOwned and "Owned" or "Not Owned")
			ProximityPrompt.ObjectText = `{Armor.Name}{(LevelText or OwnedText) and " " or ""}{(OwnedText and `[{OwnedText}]`) or ""}{OwnedText and " " or ""}{(LevelText and `[{LevelText}]`) or ""}`
			
			local isEquipped = pData.ActiveArmor.Value == Armor.Name
			ProximityPrompt.ActionText = isEquipped and "Unequip" or "Equip"
		end
		
		RequestUpdateArmor()
		
		ArmorData.ChildAdded:Connect(RequestUpdateArmor)
		ArmorData.ChildRemoved:Connect(RequestUpdateArmor)
		pData.ActiveArmor.Changed:Connect(RequestUpdateArmor)
		
		-- ProximityPrompt connection
		ProximityPrompt.Triggered:Connect(function(newPlayer)
			if newPlayer == Player then
				local isEquipped = pData.ActiveArmor.Value == Armor.Name
				if isEquipped then
					EventModule:FireServer("UnequipObjectArmor", Armor.Name)
				elseif not isEquipped then
					EventModule:FireServer("EquipObjectArmor", Armor.Name)
				end
			end
		end)
	else
		warn("[Kit/ArmorObject/.new]: Armor name " .. Armor.Name .. " is not in ContentLibrary! (check RS --> Items --> Armors)")
	end
	
	return Armor
end

for _, ArmorInstance in CollectionService:GetTagged("Armor") do
	task.spawn(ArmorObject.new, ArmorInstance)
end

CollectionService:GetInstanceAddedSignal("Armor"):Connect(ArmorObject.new)

return {}