--[[
	ej0w @ October 2024
	Morph
	
	Used to morph all given accessories, armors, clothing, and more.
	Can be used cross-referenced to other scripts (ie. morphing mobs w/ armor)
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Dependencies
local ClothingLibrary = require(ReplicatedStorage.Modules.Shared.ClothingLibrary)

--> Variables
local Morph = {}

--------------------------------------------------------------------------------

function Morph:UpdateLimbTransparency(Character: Model, Armor)
	for _, Instance in Character:GetChildren() do
		local Transparency = if Armor then Armor.Config.BodyPartsVisible[Instance.Name] and 0 or 1 else Instance:GetAttribute("OriginalTransparency")
		if Instance:IsA("BasePart") and Transparency then
			if not Instance:GetAttribute("OriginalTransparency") then
				Instance:SetAttribute("OriginalTransparency", Instance.Transparency)
			end
			
			Instance.Transparency = Transparency
		end
	end
end

-- Welds an armor's limb (Model) to the character's body limb.
local function WeldArmorLimb(ArmorLimb: Model, BodyLimb: BasePart)
	local Middle = ArmorLimb:FindFirstChild("Middle")
	
	-- Weld the entire armor limb together (to Middle)
	for _, Piece: Instance in ArmorLimb:GetDescendants() do
		if Piece:IsA("BasePart") then
			Piece.Anchored = false
			Piece.CanCollide = false
			Piece.CanQuery = false
			Piece.Massless = true
			
			if Piece.Name ~= "Middle" then
				local Weld = Instance.new("Weld")
				Weld.Name = Piece.Name .."/".. Middle.Name
				Weld.Part0 = Middle
				Weld.Part1 = Piece
				Weld.C1 = Piece.CFrame:Inverse() * Middle.CFrame
				Weld.Parent = Middle
			end
		end
	end
	
	-- Weld the armor limb base (Middle) to the body limb
	local Weld = Instance.new("Weld")
	Weld.Name = BodyLimb.Name .."/".. Middle.Name
	Weld.Part0 = BodyLimb
	Weld.Part1 = Middle
	Weld.Parent = Middle
end

function Morph:CreatePhysicalModel(Player: Player, Object, Group)
	local Character = if Player:IsA("Model") then Player else Player.Character
	if not Character then return end
	
	for _, Limb in Object.Instance:GetChildren() do
		if not Limb:IsA("Model") then
			Limb:Clone().Parent = Group
			continue
		end

		Limb = Limb:Clone()

		local Middle = Limb:FindFirstChild("Middle")
		local BodyLimb = Character:FindFirstChild(Limb.Name)

		if Middle and BodyLimb then
			WeldArmorLimb(Limb, BodyLimb)
			Limb.Parent = Group
		elseif not Middle then
			warn(("Model limb %s/%s is missing a \"Middle\" BasePart!"):format(Object.Name, Limb.Name))
		end
	end
	
	return Group
end

--------------------------------------------------------------------------------

local SavedIndex = {}

function Morph:UpdateAccessoriesTransparency(Character: Model, Item, Index)
	SavedIndex[Character] = (SavedIndex[Character] or {
		Armor = nil,
		Accessories = {},
	})
	
	if Index then
		SavedIndex[Character].Accessories[Index] = Item
	else
		SavedIndex[Character].Armor = Item
	end
	
	-- Callbacks
	local function IsAccessoryFullyVisible(AccessoryType)
		local function CheckPerCategory(Category)
			if not Category then
				return true
			end
			
			local IsNotVisible = not Category.Config.AccessoryTypesVisible 
				or not Category.Config.AccessoryTypesVisible[AccessoryType.Name]
			
			return not IsNotVisible
		end
		
		for _, Accessory in SavedIndex[Character].Accessories do
			local Result = CheckPerCategory(Accessory)
			
			if not Result then
				return false
			end
		end
		
		local Result = CheckPerCategory(SavedIndex[Character].Armor)
		
		if not Result then
			return false
		end
		
		return true
	end
	
	local function CheckEachAccessory(Accessory: Accessory)
		for _, Piece in Accessory:GetDescendants() do
			local IsFullyVisible = IsAccessoryFullyVisible(Accessory.AccessoryType)
			
			if Piece:IsA("BasePart") and not Piece:GetAttribute("OriginalTransparency") then
				Piece:SetAttribute("OriginalTransparency", Piece.Transparency)
			end
			
			local Transparency = (IsFullyVisible and Piece:GetAttribute("OriginalTransparency")) or 1

			if Piece:IsA("BasePart") then
				Piece.Transparency = Transparency
			else
				local isParticle = Piece:IsA("Fire") 
					or Piece:IsA("ParticleEmitter") 
					or Piece:IsA("Sparkles") 
					or Piece:IsA("Smoke")

				if isParticle then
					Piece.Enabled = IsFullyVisible
				end
			end
		end
	end
	
	-- Run
	for _, Accessory in Character:GetChildren() do
		if Accessory:IsA("Accessory") then
			task.defer(CheckEachAccessory, Accessory)
		end
	end
end

--------------------------------------------------------------------------------
-- Armor

function Morph:ApplyOutfit(Player: Player, Armor)
	local Character = if Player:IsA("Model") then Player else Player.Character
	if not Character then return end
	
	if Character:FindFirstChild("ArmorGroup") then
		self:ClearOutfit(Player)
	end
	
	-- Create armor group
	local ArmorGroup = Instance.new("Folder")
	ArmorGroup.Name = "ArmorGroup"
	
	-- Update limb & accessory transparency
	self:UpdateLimbTransparency(Character, Armor)
	self:UpdateAccessoriesTransparency(Character, Armor)
	
	-- Update clothing
	for _, ClassName in {"Shirt", "Pants"} do
		local ClothingID = ClothingLibrary[Armor.Name][ClassName]
		local ConfigID = Armor.Config[ClassName .. "ID"]
		
		local _Clothing = Character:FindFirstChildWhichIsA(ClassName)
		
		local function UpdateClothes(Clothing)
			if Clothing then
				Clothing:SetAttribute("OriginalID", Clothing:GetAttribute("OriginalID") or Clothing[ClassName .. "Template"])
			end
			
			if ClothingID then
				if not Clothing then
					Clothing = Instance.new(ClassName)
					Clothing.Parent = Character
				end

				Clothing[ClassName .. "Template"] = ClothingID
			end
		end
		
		if not _Clothing then
			local Connection; Connection = Character.ChildAdded:Connect(function(Child)
				if ArmorGroup.Parent == nil then
					Connection:Disconnect()
					return
				end
				
				if Child:IsA(ClassName) then
					Connection:Disconnect()
					UpdateClothes(Child)
				end
			end)
		end
		
		UpdateClothes(_Clothing)
	end
	
	self:CreatePhysicalModel(Player, Armor, ArmorGroup)
	ArmorGroup.Parent = Character
end

function Morph:ClearOutfit(Player: Player)
	local Character = if Player:IsA("Model") then Player else Player.Character
	if not Character then return end
	
	self:UpdateLimbTransparency(Character)
	self:UpdateAccessoriesTransparency(Character)
	
	for _, ClassName in {"Shirt", "Pants"} do
		local Clothing = Character:FindFirstChildWhichIsA(ClassName)
		if Clothing then
			local OriginalID = Clothing:GetAttribute("OriginalID")
			if OriginalID and OriginalID ~= true then
				Clothing[ClassName .. "Template"] = OriginalID
			elseif not OriginalID then
				Clothing:Destroy()
			end
		end
	end
	
	local ArmorGroup = Character:FindFirstChild("ArmorGroup")
	if ArmorGroup then
		ArmorGroup:Destroy()
	end
end

--------------------------------------------------------------------------------
-- Accessories

function Morph:AddAccessory(Player: Player, Accessory, Index)
	local Character = if Player:IsA("Model") 
		then Player 
		else Player.Character
	
	if not Character then 
		return 
	end
	
	local AccessoryGroup = Character:FindFirstChild("AccessoryGroup") or Instance.new("Folder")
	AccessoryGroup.Name = "AccessoryGroup"
	
	local oldAccessory = AccessoryGroup:FindFirstChild(tostring(Index))
	if oldAccessory then
		oldAccessory:Destroy()
	end
	
	local AccessoryModel = Instance.new("Model")
	AccessoryModel.Parent = AccessoryGroup
	AccessoryModel.Name = tostring(Index)
	
	self:UpdateAccessoriesTransparency(Character, Accessory, Index)
	self:CreatePhysicalModel(Player, Accessory, AccessoryModel)
	
	AccessoryGroup.Parent = Character
	return AccessoryGroup
end

function Morph:RemoveAccessory(Player: Player, Index)
	local Character = if Player:IsA("Model") 
		then Player 
		else Player.Character
	
	if not Character then
		return
	end
	
	local AccessoryGroup = Character:FindFirstChild("AccessoryGroup")
	
	local Accessory = AccessoryGroup and AccessoryGroup:FindFirstChild(tostring(Index))
	if Accessory then
		Accessory:Destroy()
	end
	
	self:UpdateAccessoriesTransparency(Character, nil, Index)
end

return Morph