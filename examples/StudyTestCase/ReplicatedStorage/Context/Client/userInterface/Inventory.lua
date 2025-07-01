--[[
	Evercyan @ March 2023
	Inventory
	
	InventoryGuiScript handles the player inventory - this includes everything relating to the
	inventory system.
]]

--> Services
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer

local pData = ReplicatedStorage:WaitForChild("PlayerData"):WaitForChild(Player.UserId)
local Items = pData:WaitForChild("Items")

--> Dependencies
local ContentLibrary = require(ReplicatedStorage.Modules.Shared.ContentLibrary)
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)
local Maid = require(ReplicatedStorage.Modules.Shared.Maid)
local CountTotalCopies = require(ReplicatedStorage.Modules.Shared.countTotalCopies)
local ColorModule = require(ReplicatedStorage.Modules.Shared.Color)
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)

local SetTooltipListener = require(ReplicatedStorage.Modules.Client.setTooltipListener)
local TooltipController = require(ReplicatedStorage.Modules.Client.TooltipController)

local ActivatedCallbacks = require(ReplicatedStorage.Modules.Client.ActivatedCallbacks)
local KeybindSystem = require(ReplicatedStorage.Modules.Libraries.Keybinds)

local GameConfig = require(ReplicatedStorage.GameConfig)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return function(Gui)
	if not GameConfig.BackpackEnabled then
		Gui:Destroy()
		return
	end
	
	--> References
	local Main = Gui:WaitForChild("Main")
	local Hotbar = Main:WaitForChild("Hotbar")
	local Inventory = Main:WaitForChild("Inventory")
	local InventoryItems = Inventory:WaitForChild("Items")
	local InventoryFrame = InventoryItems:WaitForChild("Frame")
	local InventoryList = InventoryItems:WaitForChild("ScrollingFrame")
	
	local HideCanvas = Main:WaitForChild("HideCanvas")
	local TooltipFrame = Player.PlayerGui:WaitForChild("Tooltip"):WaitForChild("Frame")
	
	--> Variables
	local BackpackItemAdded = Instance.new("BindableEvent")
	local BackpackItemRemoved = Instance.new("BindableEvent")
	local BackpackItemEquipped = Instance.new("BindableEvent")
	local BackpackItemUnequipped = Instance.new("BindableEvent")
	local EquippedTool

	local Slots = {} :: {Slot}
	local HotbarSlots = {} :: {HotbarSlot}
	local InventoryOpen = false

	local StartSlot, StartParent -- Messy way to deal with this, but it work oki ^-^
	local Dragging = false

	--> Configuration
	local SlotTextColor = Color3.fromRGB(255, 255, 255)

	local SlotColor = GameConfig.BackgroundColor
	local EquippedSlotColor = GameConfig.PrimaryColor
	local EquippedSlotTextColor = GameConfig.SecondaryColor
	local UseArmorBustShot = GameConfig.InventoryUsesArmorBustShot
	
	local EquippedSlotPosition = -4
	
	local MAX_HOTBAR_SLOTS = (UserInputService.TouchEnabled and GameConfig.MobileUsesLessSlots and 3) or GameConfig.PCAndConsoleMaxSlots
	
	--------------------------------------------------------------------------------
	
	InventoryFrame.BackgroundColor3 = GameConfig.SecondaryColor
	InventoryList.ScrollBarImageColor3 = GameConfig.PrimaryColor
	
	Inventory.BackgroundColor3 = GameConfig.BackgroundColor
	InventoryItems.BackgroundColor3 = GameConfig.BackgroundColor
	Inventory:WaitForChild("Categories").BackgroundColor3 = GameConfig.BackgroundColor

	type Slot = {
		ItemInstance: Instance,
		ItemType: string,
		ItemConfig: ContentLibrary.ItemConfig?,
		Frame: Frame,
		LayoutOrder: number?,
		HotbarNumber: number?,
		PushToHotbar: (Slot, HotbarSlot) -> (),
		PushToInventory: (Slot) -> (),
		ExchangeWith: (Slot) -> (),
		Destroy: (Slot) -> ()
	}

	type HotbarSlot = {
		Number: number,
		Frame: Frame,
		ActiveSlot: Slot?
	}

	type ArmorSlot = {
		Item: Model,
		ItemConfig: ContentLibrary.ItemConfig,
		Frame: Frame
	}

	--------------------------------------------------------------------------------

	-- Checks to see if there's a slot over the cursor. If there is, return the slot type, as well as the slot object.
	-- SlotType can be either "Hotbar", "Inventory", or nil
	-- Slot is the slot object, either a HotbarSlot or a Slot object.
	local function GetSlotOverCursor(): (("Hotbar" | "Inventory")?, Slot?)
		local MouseLocation = UserInputService:GetMouseLocation() - GuiService:GetGuiInset()
		local GuiObjects = Player.PlayerGui:GetGuiObjectsAtPosition(MouseLocation.X, MouseLocation.Y)
		
		local SlotType, FoundSlot
		for _, GuiObject in GuiObjects do
			if StartSlot and GuiObject == StartSlot.Frame then
				continue -- Ignore the frame being dragged
			end

			if CollectionService:HasTag(GuiObject, "InventorySlot") then
				local SlotIndex = GuiObject:FindFirstChild("SlotIndex")
				if SlotIndex then
					SlotType = "Inventory"
					FoundSlot = Slots[SlotIndex.Value]
					break
				end
			elseif CollectionService:HasTag(GuiObject, "FakeHotbarSlot") then
				local HotbarNumber = GuiObject:GetAttribute("SlotNumber")
				SlotType = "Hotbar"
				FoundSlot = HotbarSlots[HotbarNumber]
			end
		end
		
		if FoundSlot and FoundSlot.ItemInstance 
			and GameConfig.Categories[FoundSlot.ItemType].NotEquippable 
		then
			return
		end

		return SlotType, FoundSlot
	end

	-- Returns the firstmost available HotbarSlot
	local function GetNextHotbarSlot(): HotbarSlot?
		local Slot
		
		for _, HotbarSlot in HotbarSlots do
			if not HotbarSlot.ActiveSlot then
				Slot = HotbarSlot
				break
			end
		end
		
		return Slot
	end

	local function isCursorOverInventory(): boolean
		local MouseLocation = UserInputService:GetMouseLocation()
		local AbsolutePosition = InventoryItems.AbsolutePosition
		local AbsoluteSize = InventoryItems.AbsoluteSize

		local withinX = MouseLocation.X >= AbsolutePosition.X and MouseLocation.X < (AbsolutePosition.X + AbsoluteSize.X)
		local withinY = MouseLocation.Y >= AbsolutePosition.Y and MouseLocation.Y < (AbsolutePosition.Y + AbsoluteSize.Y)

		return withinX and withinY
	end

	local function isSlotInHotbar(Slot: Slot): boolean
		return Slot.HotbarNumber ~= nil
	end

	local function isSlotInInventory(Slot: Slot): boolean
		return not isSlotInHotbar(Slot)
	end

	local function UpdateSlotState(Slot: Slot, Equipped: boolean)
		if not Slot or not Slot.Frame.Parent then
			return
		end

		local Character = Player.Character
		
		local Humanoid = Character and Character:FindFirstChildWhichIsA("Humanoid")
		if not Humanoid or Humanoid.Health <= 0 or (Slot.ItemInstance:IsA("Tool") and Slot.ItemInstance.Parent ~= Character) then
			Equipped = false
		end

		local DeactivateOverride = Slot.DeactivateOverride
		local ActivateOverride = Slot.ActivateOverride

		local EquippedSlotColor = ActivateOverride or Slot.Primary
		local EquippedSlotTextColor = DeactivateOverride or Slot.Background
		local SlotColor = DeactivateOverride or SlotColor
		
		Slot.Equipped = Equipped
		
		local Tween = Tween:Play(Slot.Frame, {0.25, "Circular"}, {Position = UDim2.fromOffset(0, Equipped and EquippedSlotPosition or 0)})
		Slot.EquippingTween = Tween
		
		local isCustomColor = Slot.Custom
		if isCustomColor then
			Slot.Custom.Frame.BackgroundColor3 = Equipped and Color3.fromRGB(255, 255, 255) 
				or Color3.fromRGB(109, 109, 109)
			
			Slot.Custom.GroupTransparency = Equipped and 0 or 0.2
		elseif not isCustomColor then
			if Equipped then
				Slot.BG.BackgroundColor3 = EquippedSlotColor
				Slot.Frame.HotbarNum.UIStroke.Color = EquippedSlotColor
				Slot.Frame.HotbarNum.TextColor3 = EquippedSlotTextColor
				Slot.Frame.ItemName.UIStroke.Color = EquippedSlotColor
				Slot.Frame.ItemName.TextColor3 = EquippedSlotTextColor
				Slot.Frame.Amount.TextColor3 = EquippedSlotTextColor
				Slot.Frame.Amount.UIStroke.Color = EquippedSlotColor
			elseif not Equipped then
				Slot.BG.BackgroundColor3 = SlotColor
				Slot.Frame.HotbarNum.UIStroke.Color = SlotColor
				Slot.Frame.HotbarNum.TextColor3 = SlotTextColor
				Slot.Frame.ItemName.UIStroke.Color = SlotColor
				Slot.Frame.ItemName.TextColor3 = SlotTextColor
				Slot.Frame.Amount.TextColor3 = SlotTextColor
				Slot.Frame.Amount.UIStroke.Color = SlotColor
			end
		end
	end

	local function UpdateHotbarVisibility()
		local Visible = false
		for _, HotbarSlot in HotbarSlots do
			if HotbarSlot.ActiveSlot then
				Visible = true
			end
		end
		
		for _, Frame in Hotbar:GetChildren() do
			if string.find(Frame.Name, "FullSlot") and #Frame:GetChildren() == 0 then
				Frame.Visible = false
			end
		end

		Hotbar.Visible = Visible or InventoryOpen
	end

	---- SLOTS ---------------------------------------------------------------------

	local Slot = {}
	Slot.__index = Slot
	
	local CategoryFrames = {}
	local CategorySlots = {}
	
	local RecentClosestFrame = nil
	local ForcedCategoryFocus = {nil, os.clock()}
	
	local function FindClosestPosition(Frame)
		local AbsolutePosition = 0
		for _, NewFrame in CategoryFrames do
			if NewFrame.Visible and NewFrame.LayoutOrder < Frame.LayoutOrder then
				AbsolutePosition += NewFrame.AbsoluteSize.Y + 8
			end
		end

		return AbsolutePosition
	end
	
	local function OnUpdatedCanvasPosition(Force)
		local CanvasPositionY = InventoryList.CanvasPosition.Y
		local CanvasSizeY = InventoryList.AbsoluteSize.Y

		local isForced = ForcedCategoryFocus[1] 
			and os.clock() - ForcedCategoryFocus[2] <= (0.5 + 0.03)

		local ClosestFrame = Force and CategoryFrames[Force]
		local ClosestPosition = math.huge

		if not ClosestFrame then
			for Name, Frame in CategoryFrames do
				if Frame.Visible then
					local AbsolutePosition = FindClosestPosition(Frame)
					local Difference = math.abs(CanvasPositionY - AbsolutePosition)
					
					if AbsolutePosition < ClosestPosition and (AbsolutePosition >= CanvasPositionY or Difference < 8) then
						ClosestPosition = AbsolutePosition
						ClosestFrame = Frame
					end
				end
			end
		end

		if isForced or RecentClosestFrame ~= ClosestFrame then
			for Name, Frame in CategorySlots do
				local isEnabled = if isForced 
					then ForcedCategoryFocus[1] == Name 
					else ClosestFrame and (Name == ClosestFrame.Name)

				Tween:Play(Frame.Frame, {0.5, "Circular"}, {
					BackgroundColor3 = isEnabled and Frame.Secondary:Lerp(Frame.Primary, 0.15) or Frame.Primary,
					TextColor3 = isEnabled and Frame.Primary or Frame.Secondary
				})
			end
		end

		RecentClosestFrame = isForced and ForcedCategoryFocus[1] 
			or ClosestFrame
	end
	
	local ItemTypes = {}
	for ItemType, Data in GameConfig.Categories do
		if not Data.ShowInInventory then
			continue
		end
		
		ItemTypes[ItemType] = {
			Color = Data.Color,
			LayoutOrder = Data.LayoutOrder,
			OnActivated = ActivatedCallbacks[ItemType] or ActivatedCallbacks.Default,
		}
	end

	for Name, CategoryInfo in ItemTypes do
		local Frame = script:WaitForChild("CategoryTemplate"):Clone()
		Frame.Name = Name
		Frame.Header.Text = Name
		Frame.Header.TextColor3 = CategoryInfo.Color
		Frame.Items.BackgroundColor3 = CategoryInfo.Color

		local IconSize = GameConfig.Categories[Name].IconSize
		if IconSize then
			Frame.Items.UIGridLayout.CellSize = UDim2.fromOffset(IconSize, IconSize)
		end

		Frame.LayoutOrder = CategoryInfo.LayoutOrder
		Frame.Visible = false
		Frame.Parent = InventoryList
		
		local function CountVisibleItems()
			local Visible = 0
			
			for _, Frame in Frame.Items:GetChildren() do
				if Frame:IsA("GuiObject") and Frame.Visible then
					Visible += 1
				end
			end
			
			return Visible
		end
	
		Frame.Items.ChildAdded:Connect(function(Child)
			Child:GetPropertyChangedSignal("Visible"):Connect(function()
				Frame.Visible = CountVisibleItems() > 0
			end)
			
			Frame.Visible = CountVisibleItems() > 0
		end)

		Frame.Items.ChildRemoved:Connect(function(Child)
			if Frame.Parent == nil then
				return
			end

			Frame.Visible = CountVisibleItems() > 0
		end)
		
		---- Category buttons
		
		local Primary, Secondary, Background = ColorModule:ConvertToHSV3(CategoryInfo.Color)
		
		local CategorySlot = script.CategorySlot:Clone()
		CategorySlot.LayoutOrder = CategoryInfo.LayoutOrder
		CategorySlot.Name = Name

		CategorySlot.BackgroundColor3 = Primary
		CategorySlot.TextColor3 = Secondary
		
		CategorySlot.Text = string.sub(Name, 0, 1)

		CategorySlot.Activated:Connect(function()
			local AbsolutePosition = FindClosestPosition(Frame)
			
			ForcedCategoryFocus = {Frame.Name, os.clock()}
			OnUpdatedCanvasPosition()
			
			Tween:Play(InventoryList, {0.5, "Back", "Out"}, {CanvasPosition = Vector2.new(0, AbsolutePosition)})
		end)
		
		local CategoryButtons = Inventory:WaitForChild("Categories")
		
		local function UpdateCategoryFrameVisible()
			local isVisible = false
			for _, Frame: GuiObject in CategoryButtons:GetChildren() do
				if Frame:IsA("GuiObject") and Frame.Visible then
					isVisible = true
				end
			end
			
			CategoryButtons.Visible = isVisible
		end
		
		Frame:GetPropertyChangedSignal("Visible"):Connect(function()
			CategorySlot.Visible = Frame.Visible
			
			RecentClosestFrame = nil
			OnUpdatedCanvasPosition()
			UpdateCategoryFrameVisible()
		end)
		
		CategorySlot.Parent =CategoryButtons
		CategorySlot.Visible = Frame.Visible
		
		if CategoryInfo.LayoutOrder <= 1 then
			RecentClosestFrame = Name
		end
		
		CategorySlots[Name] = {Frame = CategorySlot, Primary = Primary, Secondary = Secondary, Background = Background}
		CategoryFrames[Name] = Frame
	end
	
	InventoryList:GetPropertyChangedSignal("CanvasPosition"):Connect(OnUpdatedCanvasPosition)
	OnUpdatedCanvasPosition(RecentClosestFrame)

	local function UpdateOwnership(Frame, Item)
		local Copies = CountTotalCopies(Item)
		
		local Amount = Frame:FindFirstChild("Amount")
		if Amount then
			Amount.Text = `x{FormatNumber(Copies, "Suffix")}`
			Amount.Visible = Copies > 1
		end
	end

	-- ItemInstance represents the physical instance of an object.
	-- Ex: Tool instance instead of ContentLibrary.Tool class.
	-- Ex: Model instance instead of pData.Items.Armor value object used for data saving & replication.
	function Slot.new(ItemInstance: Instance): Slot
		local ItemConfig = ItemInstance:WaitForChild("ItemConfig", 1) and require((ItemInstance :: any).ItemConfig)
		
		local ItemType = (ItemConfig and ItemConfig.Type) 
			or (ItemInstance:IsA("Tool") and "Tool")
		
		local CategoryInfo = GameConfig.Categories[ItemType]
		if not CategoryInfo.ShowInInventory or ItemConfig.DontShowInInventory then
			return
		end
		
		local IconId = ItemConfig and ItemConfig.IconId and (tonumber(ItemConfig.IconId) and `rbxassetid://{ItemConfig.IconId}` or ItemConfig.IconId) 
			or (ItemInstance:IsA("Tool") and ItemInstance.TextureId)
			or ""
		
		-- Create slot's Frame
		local Frame = script:WaitForChild(UseArmorBustShot and ItemType == "Armor" and "ArmorSlotTemplate" or "SlotTemplate"):Clone()
		local ItemIcon = Frame:FindFirstChild("ItemIcon", true) -- Note: We use a custom template for armor, so it can easily use a bust shot.
		local FrameSize = Hotbar.UIGridLayout.CellSize.Y.Offset
		
		Frame.Size = UDim2.fromOffset(FrameSize, FrameSize)
		Frame.Name = ItemInstance.Name
		Frame.ItemName.Visible = #IconId == 0
		Frame.HotbarNum.Visible = false
		Frame.Visible = true
		Frame.Parent = CategoryFrames[ItemType].Items
		
		local Slot = setmetatable({}, Slot)
		Slot.Button = Frame:WaitForChild("SlotButton") :: TextButton
		Slot.BG = Frame:WaitForChild("SlotBackground") :: Frame
		Slot.BG.BackgroundColor3 = SlotColor

		ItemIcon.Visible = #IconId > 0
		if ItemIcon.Visible then
			ItemIcon.Image = IconId
		else
			Frame.ItemName.Text = ItemInstance.Name
		end
		
		-- Seasonal items
		local DeactivateColor, ActivateColor = nil, nil
		if ItemConfig.CustomBackground then
			local Custom = Frame:WaitForChild("Custom")
			Custom.Visible = true
			
			local Gradient = ReplicatedStorage.Assets.Gradients:FindFirstChild(ItemConfig.CustomBackground)
			if Gradient then
				Custom:FindFirstChild("Gradient"):Destroy()
				Gradient:Clone().Parent = Custom
			end
			
			Slot.Custom = Custom
			Slot.BG.Visible = false
		elseif ItemConfig.SpecialColor then
			Frame.Canvas.Visible = true
			Frame.Canvas.GroupColor3 = ItemConfig.SpecialColor
		
			local ActivateColor, _, DeactivateColor = ColorModule:ConvertToHSV3(ItemConfig.SpecialColor)
			Slot.BG.BackgroundColor3 = DeactivateColor
			Slot.DeactivateOverride = DeactivateColor
			Slot.ActivateOverride = ActivateColor
		end
		
		local Primary, Secondary, Background = ColorModule:ConvertToHSV3(CategoryInfo.Color)
		
		Slot.Primary = Primary
		Slot.Secondary = Secondary
		Slot.Background = Background

		-- Copies
		local InventoryCategory = pData.Items[ItemType] 
		local InventoryItem = InventoryCategory:WaitForChild(ItemInstance.Name)
		
		local ContentItem = ContentLibrary[ItemType][ItemInstance.Name]
		
		local UpdateMaid = Maid.new()
		UpdateOwnership(Frame, ContentItem)
		
		UpdateMaid:Add(InventoryCategory.ChildAdded:Connect(function()
			UpdateOwnership(Frame, ContentItem)
		end))
		
		UpdateMaid:Add(InventoryCategory.ChildRemoved:Connect(function()
			UpdateOwnership(Frame, ContentItem)
		end))

		if InventoryItem:IsA("NumberValue") then
			InventoryItem.Changed:Connect(function()
				UpdateOwnership(Frame, ContentItem)
			end)
		end

		---- Connections (handled by garbage collector)
		
		local IsNotEquippable = GameConfig.Categories[ItemType].NotEquippable
		if IsNotEquippable then
			Slot.Button.Active = false
			Slot.Button.AutoButtonColor = false
		elseif not IsNotEquippable then
			Slot.Button.Activated:Connect(function()
				if Dragging then
					return
				end

				if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
					if isSlotInHotbar(Slot) then
						Slot:PushToInventory()
					else
						local HotbarSlot = GetNextHotbarSlot()
						Slot:PushToHotbar(HotbarSlot or HotbarSlots[MAX_HOTBAR_SLOTS])
					end
				elseif not GameConfig.Categories[ItemType].NotEquippable then
					ItemTypes[ItemType]:OnActivated(Slot)
				end
			end)
		end
		
		local PrimaryFrame = Slot.Custom and Slot.Custom.Frame or Slot.BG
		Slot.Button.MouseEnter:Connect(function()
			Tween:Play(PrimaryFrame, {0.25, "Circular"}, {Transparency = 0})
		end)
		Slot.Button.MouseLeave:Connect(function()
			Tween:Play(PrimaryFrame, {0.25, "Circular"}, {Transparency = 0.2})
		end)

		SetTooltipListener(Frame, ItemInstance, Primary, Secondary)

		local ReferenceValue = Instance.new("StringValue")
		ReferenceValue.Name = "SlotIndex"
		ReferenceValue.Value = ItemInstance.Name
		ReferenceValue.Parent = Frame

		CollectionService:AddTag(Frame, "InventorySlot")

		-- Finish creating Slot object
		Slot.ItemInstance = ItemInstance
		Slot.ItemType = ItemType
		Slot.ItemConfig = ItemConfig
		Slot.Frame = Frame
		Slot.Maid = UpdateMaid

		Slots[ItemInstance.Name] = Slot

		-- Sort new slot
		if Slot.SortInventory then
			Slot.SortInventory()
		end

		-- Push slot to Hotbar if it was last in it
		local pData_Hotbar = pData:WaitForChild("Hotbar")
		for n, HotbarSlot in HotbarSlots do
			local DataValue = pData_Hotbar:WaitForChild(n)
			if DataValue.Value == ItemInstance.Name and not HotbarSlots[n].ActiveSlot then
				Slot:PushToHotbar(HotbarSlots[n])
				break
			end
		end
		
		UpdateSlotState(Slot, false)

		return Slot
	end

	-- This Slot function pushes the Slot to the passed HotbarSlot.
	function Slot:PushToHotbar(HotbarSlot: HotbarSlot)
		-- If this slot was previously in a hotbar slot, clear up references & restore the hotbar slot.
		local OldHotbarSlot = HotbarSlots[self.HotbarNumber]
		if HotbarSlot and HotbarSlot.ActiveSlot then
			HotbarSlot.ActiveSlot:PushToInventory()
		end
		if OldHotbarSlot then
			OldHotbarSlot.ActiveSlot = nil
			OldHotbarSlot.Frame.Visible = InventoryOpen
			EventModule:FireServer("HotbarItemChanged", OldHotbarSlot.Number, "")
		end
		HotbarSlot.ActiveSlot = self
		HotbarSlot.Frame.Visible = false

		self.HotbarNumber = HotbarSlot.Number
		--self.Frame.LayoutOrder = HotbarSlot.Number
		self.Frame.HotbarNum.Text = HotbarSlot.Number
		self.Frame.HotbarNum.Visible = true
		
		local FullSlot = Hotbar:WaitForChild(`FullSlot{HotbarSlot.Number}`)
		self.Frame.Parent = FullSlot
		
		FullSlot.LayoutOrder = HotbarSlot.Number
		FullSlot.Visible = true
		
		EventModule:FireServer("HotbarItemChanged", HotbarSlot.Number, self.ItemInstance.Name)
		UpdateHotbarVisibility()
	end

	-- This Slot function pushes the Slot to the inventory.
	function Slot:PushToInventory()
		-- If this slot is in a hotbar slot, clear up references & restore the hotbar slot.
		local HotbarSlot = self.HotbarNumber and HotbarSlots[self.HotbarNumber]
		if HotbarSlot then
			HotbarSlot.ActiveSlot = nil
			HotbarSlot.Frame.Visible = InventoryOpen
			HotbarSlot.FullSlot.Visible = false
		end

		self.HotbarNumber = nil
		self.Frame.LayoutOrder = self.LayoutOrder or 1
		self.Frame.HotbarNum.Visible = false
		
		self.Frame.Parent = CategoryFrames[self.ItemType].Items
		
		if HotbarSlot and HotbarSlot.Number then
			EventModule:FireServer("HotbarItemChanged", HotbarSlot.Number, "")
		end
		UpdateHotbarVisibility()
	end

	-- This Slot function exchanges the place its in with another Slot.
	function Slot:ExchangeWith(Slot: Slot)
		-- We save these are variables to keep a reference to them, since we're actively changing them.
		local StartNumber = self.HotbarNumber
		local EndNumber = Slot.HotbarNumber
		local startInHotbar = isSlotInHotbar(self)
		local endInHotbar = isSlotInHotbar(Slot)

		if not startInHotbar and not endInHotbar then
			return
		end
		
		Slot:PushToInventory()
		if EndNumber then
			self:PushToHotbar(HotbarSlots[EndNumber])
		end
		if startInHotbar and endInHotbar then
			Slot:PushToHotbar(HotbarSlots[StartNumber])
		end
	end

	-- This Slot functions destroys the Slot object, as well as any remaining references of it.
	function Slot:Destroy()
		if self.Destroyed then
			return
		end
		self.Destroyed = true

		-- This slot is in a hotbar slot. Clear up references & restore the hotbar slot.
		local HotbarSlot = self.HotbarNumber and HotbarSlots[self.HotbarNumber]
		if HotbarSlot then
			HotbarSlot.ActiveSlot = nil
			HotbarSlot.Frame.Visible = InventoryOpen
			HotbarSlot.FullSlot.Visible = false
		end

		self.Maid:Destroy()
		self.Frame:Destroy()
		Slots[self.ItemInstance.Name] = nil
		self.Frame = nil
		self.ItemInstance = nil
	end

	-- Function that groups by Level and Name, sorts both of the groups by their sort method,
	-- then runs through them in order to have a consistent order.
	-- Tools are sorted by Level if they have an ItemConfig in them with a numerical Level value
	-- Tools are sorted by Name if they don't have an ItemConfig (say an imported Apple free model)
	function Slot.SortInventory()
		local SortByLevel = {}
		local SortByName = {}

		for _, Slot in Slots do
			if Slot.ItemConfig and Slot.ItemConfig.Level then
				table.insert(SortByLevel, Slot)
			else
				table.insert(SortByName, Slot)
			end
		end

		table.sort(SortByLevel, function(A, B)
			return A.ItemConfig.Level > B.ItemConfig.Level
		end)

		table.sort(SortByName, function(A, B)
			return A.ItemInstance.Name < B.ItemInstance.Name
		end)

		local ind = 1
		for _, t in {SortByLevel, SortByName} do
			for _, Slot in t do
				Slot.LayoutOrder = ind
				if not isSlotInHotbar(Slot) then
					Slot.Frame.LayoutOrder = ind
				end
				ind += 1
			end
		end
	end

	Slot.SortInventory()

	---- HOTBAR LOGIC --------------------------------------------------------------

	---- Create blank hotbar slots
	local KeyboardKeyCodes = {"One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine"}
	for i = 1, MAX_HOTBAR_SLOTS do
		local EmptySlot = script:WaitForChild("EmptySlotTemplate"):Clone()
		EmptySlot.Name = tostring(i)
		EmptySlot.LayoutOrder = i
		EmptySlot.Visible = false
		EmptySlot.HotbarNum.Text = "-".. i .."-"
		EmptySlot.Parent = Hotbar
		EmptySlot:SetAttribute("SlotNumber", i)
		
		local FullSlot = script:WaitForChild("FullSlotTemplate"):Clone()
		FullSlot.Name = "FullSlot" .. tostring(i)
		FullSlot.LayoutOrder = i
		FullSlot.Visible = false
		FullSlot.Parent = Hotbar
		
		CollectionService:AddTag(EmptySlot, "FakeHotbarSlot")

		local HotbarSlot = {
			Number = i,
			Frame = EmptySlot,
			FullSlot = FullSlot,
		} :: HotbarSlot

		table.insert(HotbarSlots, HotbarSlot)

		-- Equip by keycode
		local KeyCode = Enum.KeyCode[KeyboardKeyCodes[i]]
		ContextActionService:BindActionAtPriority("InventoryHotbar_".. KeyCode.Name, function(_, UserInputState, InputObject)
			if UserInputState == Enum.UserInputState.Begin then
				local ActiveSlot = HotbarSlot.ActiveSlot
				local Type = ActiveSlot and ItemTypes[ActiveSlot.ItemType]
				
				if Type and not GameConfig.Categories[ActiveSlot.ItemType].NotEquippable then
					Type:OnActivated(ActiveSlot)
				end
			end
		end, false, 100, KeyCode)

		-- React to server-sided hotbar changes (primarily for setting slot 1 to the starter sword if it's empty)
		pData:WaitForChild("Hotbar")[i].Changed:Connect(function()
			local ItemName = pData.Hotbar[i].Value
			if ItemName ~= "" and not HotbarSlot.ActiveSlot then
				local FoundSlot
				for _, Slot in Slots do
					if Slot.ItemInstance.Name == ItemName then
						Slot:PushToHotbar(HotbarSlot)
						break
					end
				end
			end
		end)
	end

	---- Slot dragging (to & from hotbar)
	local IsInputDown = false
	local CursorStick

	UserInputService.InputBegan:Connect(function(InputObject, GameEvent)
		if not InventoryOpen then
			return
		end

		if table.find({Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch}, InputObject.UserInputType) then
			IsInputDown = true
			local Type, Slot = GetSlotOverCursor()

			if Type == "Inventory" then
				-- Yield until the user moves their cursor a few pixels, and make sure they're still dragging.
				local Origin = UserInputService:GetMouseLocation()
				while (Origin - UserInputService:GetMouseLocation()).Magnitude < 3 do
					if not IsInputDown then
						break
					end
					task.wait()
				end

				if IsInputDown then
					StartSlot = Slot
					
					StartParent = Slot.Frame.Parent
					
					if StartParent.Parent == Hotbar then
						StartParent.Visible = false
					end
					
					Dragging = true

					Slot.Active = false
					
					if Slot.EquippingTween then
						Slot.EquippingTween:Cancel()
					end
					
					local function UpdatePreRender()
						local MouseLocation = UserInputService:GetMouseLocation()
						if Slot.Frame then
							Slot.Frame.Position = UDim2.fromOffset(MouseLocation.X - 32, MouseLocation.Y - 32)
						end
					end
					
					CursorStick = RunService.PreRender:Connect(UpdatePreRender)
					UpdatePreRender()

					-- Temporarily show hotbar slot
					if Slot.HotbarNumber then
						HotbarSlots[Slot.HotbarNumber].Frame.Visible = InventoryOpen
					end

					Slot.Frame.Parent = Gui
				end
			end
		end
	end)

	UserInputService.InputEnded:Connect(function(InputObject, GameEvent)
		if table.find({Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch}, InputObject.UserInputType) then
			IsInputDown = false
			if not Dragging then
				return
			end
			task.delay(nil, function() -- Delay a Heartbeat frame due to race conditions with Slot.Frame.Activated for equipping
				Dragging = false
			end)

			if CursorStick then
				CursorStick:Disconnect()
			end

			local Type, Slot = GetSlotOverCursor()

			if StartSlot then
				StartSlot.Active = false
				StartSlot.Frame.Parent = StartParent
				
				if Slot then
					Slot.Frame.Position = UDim2.fromScale(0, 0)
				end
				
				StartSlot.Frame.Position = UDim2.fromScale(0, 0)
				if StartSlot.Equipped then
					Tween:Play(StartSlot.Frame, {0.25, "Circular"}, {Position = UDim2.fromOffset(0, -4)})
				end
				
				StartParent.Visible = true
				
				if StartSlot.HotbarNumber then
					HotbarSlots[StartSlot.HotbarNumber].Frame.Visible = false
				end

				if isCursorOverInventory() and isSlotInHotbar(StartSlot) then
					StartSlot:PushToInventory()
				else
					if Type == "Hotbar" then
						StartSlot:PushToHotbar(Slot)
					elseif Type == "Inventory" then
						StartSlot:ExchangeWith(Slot)
					end
				end
			end

			StartSlot = nil
			StartParent = nil
		end
	end)

	---- ITEM CODE -----------------------------------------------------------------
	-- Code here manages slot creation and removal for each item type

	---- Tool
	
	local StartTimer = os.clock()
	BackpackItemAdded.Event:Connect(function(BackpackItem: BackpackItem)
		task.defer(function()
			if not Slots[BackpackItem.Name] then
				local Slot = Slot.new(BackpackItem)

				-- Code here lets new tools (say ones bought from the shop) appear in the leftmost available hotbar slot
				if (os.clock() - StartTimer) > 3 then -- Give time for replication to load in initial backpack instances
					local HotbarSlot = GetNextHotbarSlot()
					if HotbarSlot and not Slot.HotbarNumber then
						Slot:PushToHotbar(HotbarSlot)
					end
				end
			end
		end)
	end)

	BackpackItemRemoved.Event:Connect(function(BackpackItem: BackpackItem)
		if BackpackItem.Parent ~= Player.Character then
			local Slot = Slots[BackpackItem.Name]
			if not Slot then
				return
			end
			
			task.defer(function()
				local Copies = 	CountTotalCopies({Name = BackpackItem.Name})
				if Slot and Copies == 0 then
					Slot:Destroy()
				end
			end)
		end
	end)

	BackpackItemEquipped.Event:Connect(function(Item, OldItem)
		local Slot = Slots[Item.Name]
		if Slot then
			UpdateSlotState(Slot, true)
		end
	end)
	BackpackItemUnequipped.Event:Connect(function(Item)
		local Slot = Slots[Item.Name]
		if Slot then
			UpdateSlotState(Slot, false)
		end
	end)

	---- Items
	
	for _, Category in Items:GetChildren() do
		for _, DataValue in Category:GetChildren() do
			local Item = ContentLibrary[Category.Name][DataValue.Name]
			if Slots[Item.Instance.Name] then
				continue
			end
			task.spawn(Slot.new, Item.Instance)
		end

		Category.ChildAdded:Connect(function(DataValue)
			local Item = ContentLibrary[Category.Name][DataValue.Name]
			if Slots[Item.Instance.Name] then
				return
			end
			
			local newSlot = Slot.new(Item.Instance)
			local CategoryConfig = GameConfig.Categories[Item.Type]
			
			local HotbarSlot = GetNextHotbarSlot()
			if HotbarSlot and not DataValue:GetAttribute("DontSave") and not CategoryConfig.AmountOnly then
				newSlot:PushToHotbar(HotbarSlot)
			end
		end)

		Category.ChildRemoved:Connect(function(DataValue)
			local Item = ContentLibrary[Category.Name][DataValue.Name]
			local Slot = Slots[Item.Instance.Name]

			task.defer(function()
				local Copies = 	CountTotalCopies(Item)
				if Slot and (Copies == 0) then
					Slot:Destroy()
				end
			end)
		end)
	end
	
	---- Cosmetic & equipment

	local lastActiveArmor = pData:WaitForChild("ActiveArmor").Value
	local EquippedSlots = pData:WaitForChild("EquippedSlots")
	
	local function UpdateKeybinds(Equipment, Verdict)
		local Keybinds = Equipment 
			and Equipment.Config 
			and Equipment.Config.Keybinds
		
		if not Keybinds then
			return
		end

		for Key, Data in Keybinds do
			KeybindSystem:UpdateKeybind(Key, Data[1], Verdict, Data[2], Data[3], Data[4], {
				Type = Equipment.Config.Type, Name = Equipment.Name
			})
		end
	end
	
	local function CheckActiveArmor()
		local Equipped = pData.ActiveArmor.Value ~= ""

		local ArmorName = (Equipped and pData.ActiveArmor.Value) or lastActiveArmor
		if ArmorName then
			UpdateKeybinds(ContentLibrary.Armor[ArmorName], Equipped)
		end
		
		-- Update now active armor, if not empty
		if pData.ActiveArmor.Value ~= "" then
			local Item = ContentLibrary.Armor[pData.ActiveArmor.Value]
			local Slot = Item and Slots[Item.Instance.Name]
			if Slot then
				UpdateSlotState(Slot, true)	
			end
		end
	end
	
	pData.ActiveArmor.Changed:Connect(function()
		if lastActiveArmor ~= "" then
			local Item = ContentLibrary.Armor[lastActiveArmor]
			local Slot = Item and Slots[Item.Instance.Name]
			if Slot then
				UpdateSlotState(Slot, false)
			end
		end
		
		CheckActiveArmor()
		lastActiveArmor = pData.ActiveArmor.Value
	end)

	task.spawn(CheckActiveArmor)
	
	for _, Slot in EquippedSlots:GetChildren() do
		local LastEquipped = Slot.Value
		if LastEquipped ~= "" then
			task.defer(UpdateKeybinds, ContentLibrary.Accessory[LastEquipped], true)
		end
		
		local function OnUpdatedValue()
			local Equipped = Slot.Value ~= ""
			
			local _Slot = (Equipped and Slots[Slot.Value]) or (LastEquipped and Slots[LastEquipped])
			if _Slot then
				UpdateKeybinds(ContentLibrary.Accessory[_Slot.ItemInstance.Name], Equipped)
				UpdateSlotState(_Slot, Equipped)
			end
			
			LastEquipped = Slot.Value
		end
		
		Slot.Changed:Connect(OnUpdatedValue)
		OnUpdatedValue()
	end

	---- OTHER ---------------------------------------------------------------------
	
	-- Update hide canvas visibility
	local function CheckCanvasVisibility()
		local TotalVisible = 0
		for _, Child in HideCanvas:GetChildren() do
			if Child:IsA("GuiObject") and Child.Visible then
				TotalVisible += 1
			end
		end
		
		HideCanvas.Visible = (not InventoryOpen and TotalVisible > 0) or false
	end
	
	HideCanvas.ChildRemoved:Connect(CheckCanvasVisibility)
	HideCanvas.ChildAdded:Connect(CheckCanvasVisibility)
	
	CheckCanvasVisibility()
	
	-- Inventory frame toggle
	local function ToggleInventory(Enabled: boolean?)
		Enabled = if Enabled ~= nil then Enabled else not Inventory.Visible
		InventoryOpen = Enabled

		TooltipController:Clear()
		Inventory.Visible = Enabled

		-- Toggle hotbar slots
		for n, HotbarSlot in HotbarSlots do
			HotbarSlot.Frame.Visible = Enabled and not HotbarSlot.ActiveSlot
		end

		Hotbar.Size = UDim2.fromOffset(64, 0)
		Tween:Play(Hotbar, {0.4, "Exponential"}, {Size = UDim2.fromOffset(64, 64)})

		-- Update button visuals
		if Enabled then
			Tween:Play(Main.ToggleInventory, {0.5, "Exponential"}, {BackgroundColor3 = EquippedSlotColor})
			Tween:Play(Main.ToggleInventory.Arrow, {0.5, "Exponential"}, {ImageColor3 = EquippedSlotTextColor, Rotation = 180})
		else
			Tween:Play(Main.ToggleInventory, {0.5, "Exponential"}, {BackgroundColor3 = EquippedSlotTextColor})
			Tween:Play(Main.ToggleInventory.Arrow, {0.5, "Exponential"}, {ImageColor3 = EquippedSlotColor, Rotation = 0})
		end

		-- If hotbar dragging, break it
		if StartSlot and not Enabled then
			if CursorStick then
				CursorStick:Disconnect()
			end
			
			StartParent.Visible = true
			StartSlot.Frame.Parent = StartParent
			StartSlot.Frame.Position = UDim2.fromScale(0, 0)
			if StartSlot.Equipped then
				Tween:Play(StartSlot.Frame, {0.25, "Circular"}, {Position = UDim2.fromOffset(0, -4)})
			end
			
			StartSlot = nil
			StartParent = nil
		end
		
		CheckCanvasVisibility()
		UpdateHotbarVisibility()
	end

	Main:WaitForChild("ToggleInventory").Activated:Connect(function()
		ToggleInventory()
	end)
	
	local isOldInventory = GameConfig.UseToggleInventoryButton
	if not isOldInventory and (UserInputService.TouchEnabled or GuiService:IsTenFootInterface() or GameConfig.ShowInventoryBackpackButtonOnPC) then
		local BackpackTemplate = script.BackpackTemplate:Clone()
		BackpackTemplate:WaitForChild("ItemIcon").ImageColor3 = EquippedSlotColor
		
		BackpackTemplate:WaitForChild("Keybind").TextColor3 = EquippedSlotColor
		BackpackTemplate.Keybind.Visible = RunService:IsStudio() or (not UserInputService.TouchEnabled and not UserInputService.GamepadEnabled)
		
		BackpackTemplate.SlotButton.Activated:Connect(function()
			ToggleInventory()
		end)
		
		BackpackTemplate.Parent = Hotbar
		BackpackTemplate.Visible = true
	end
	
	Main.ToggleInventory.Visible = isOldInventory

	local ExitButton = Inventory:WaitForChild("ExitButton")
	ExitButton.BackgroundColor3 = GameConfig.SecondaryColor
	ExitButton.TextColor3 = GameConfig.PrimaryColor

	ExitButton.Activated:Connect(function()
		ToggleInventory(false)
	end)

	ContextActionService:BindAction("InventoryGui", function(_, UserInputState)
		if UserInputState == Enum.UserInputState.Begin then
			ToggleInventory()
		end
	end, false, Enum.KeyCode.Backquote, Enum.KeyCode.E)

	ToggleInventory(false)

	-- Search functionality
	local SearchBox = Inventory:WaitForChild("SearchBox")
	SearchBox.PlaceholderColor3 = GameConfig.PrimaryColor
	SearchBox.BackgroundColor3 = GameConfig.SecondaryColor

	SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
		local Text = SearchBox.Text

		for _, Slot in Slots do
			if isSlotInInventory(Slot) then
				if #Text == 0 then
					Slot.Frame.Visible = true
				else
					local matchesTerm = string.find(string.lower(Slot.ItemInstance.Name), string.lower(Text), 1, true) ~= nil
					Slot.Frame.Visible = matchesTerm
				end
			end
		end
	end)

	---- Cooldown UI (Inventory & item tooltip) ------------------------------------------------------------
	
	local CooldownTooltip = Player.PlayerGui:WaitForChild("Tooltip"):WaitForChild("Cooldown")
	
	local RecentlyActivatedTweens = {}
	local ActivatedCooldowns = {}
	local TweenGoal = 0
	
	local function CancelActivatedTweens()
		for _, Tween in RecentlyActivatedTweens do
			Tween:Cancel()
		end
		RecentlyActivatedTweens = {}
	end
	
	local function StopCooldown()
		CancelActivatedTweens()
		TweenGoal = os.clock()
		CooldownTooltip.Visible = false
	end
	
	local function StartCooldown(TotalTime, TimeLeft)
		for _, Section in CooldownTooltip.Ring:GetChildren() do
			Section.UIGradient.Rotation = 90
		end
		
		local Clock = os.clock()
		TweenGoal = Clock

		task.spawn(function()
			for Index, SectionName in {"TopRight", "TopLeft", "BottomLeft", "BottomRight"} do
				local Section = CooldownTooltip.Ring[SectionName]

				local NewTween = Tween:Play(Section.UIGradient, {TimeLeft / 4, "Linear"}, {Rotation = -1})
				table.insert(RecentlyActivatedTweens, NewTween)
				
				NewTween.Completed:Wait()
				
				if TweenGoal ~= Clock then
					break
				end
			end
		end)
		
		task.delay(TimeLeft, function()
			if TweenGoal == Clock then
				StopCooldown()
			end
		end)
		
		CooldownTooltip.Visible = true
	end
	
	local function CheckPlayerTool(Name, Tool)
		local Character = Player.Character
		local Tool = Tool or (Character and Character:FindFirstChildWhichIsA("Tool"))
		
		local isValidTool = Tool and Tool.Name == Name
		if isValidTool then
			local TimeLeft = math.max(0, ActivatedCooldowns[Tool.Name][1] - (os.clock() - ActivatedCooldowns[Tool.Name][2]))
			StartCooldown(ActivatedCooldowns[Tool.Name][1], TimeLeft)
		end
	end
	
	EventModule:GetOnEvent("PlayerUsedWeapon"):Connect(function(ItemCooldown, Name)
		if ItemCooldown < 0.15 then
			return
		end
		
		local function Play(Frame)
			local Cooldown = Frame.Cooldown
			Cooldown.BackgroundColor3 = GameConfig.BackgroundColor

			local Gradient = Cooldown.UIGradient
			Gradient.Offset = (ItemCooldown < 1 and Vector2.new(0, -1.3)) or Vector2.new(0, -1)

			Tween:Play(Cooldown, {0.1, "Quad", "InOut"}, {BackgroundTransparency = 0.3})
			Tween:Play(Gradient, {ItemCooldown, "Linear", "InOut"}, {Offset = Vector2.new(0, 0)})

			task.delay(ItemCooldown - 0.1, function()
				Tween:Play(Cooldown, {0.1, "Linear", "InOut"}, {BackgroundTransparency = 1})
			end)
		end
		
		if GameConfig.ShowMouseCooldownUI then
			ActivatedCooldowns[Name] = {ItemCooldown, os.clock()}
			CheckPlayerTool(Name)
		end

		local Slot = Slots[Name]
		if Slot then
			Play(Slot.Frame)
		end
	end)
	
	if GameConfig.ShowMouseCooldownUI then
		ContextActionService.LocalToolEquipped:Connect(function(Tool)
			if not ActivatedCooldowns[Tool.Name] then 
				return 
			end

			if os.clock() - ActivatedCooldowns[Tool.Name][2] < ActivatedCooldowns[Tool.Name][1] then
				CheckPlayerTool(Tool.Name, Tool)
			end
		end)

		ContextActionService.LocalToolUnequipped:Connect(function(Tool)
			StopCooldown()
		end)
	end

	---- BACKPACK LOGIC ------------------------------------------------------------

	local function UpdateItemCount()
		if Main.Parent == nil then
			return
		end

		local Count = 0
		for _, Value in pData.Items:GetDescendants() do
			if Value:IsA("Folder") then
				continue
			end

			if Value.ClassName == "NumberValue" then
				Count += Value.Value
			else
				Count += 1
			end
		end

		Main.Inventory.ItemLabel.Text = `({FormatNumber(Count, "Commas")} items)`
	end

	local function OnBackpackAdded(Backpack: Backpack)
		for _, Slot in Slots do
			if not GameConfig.Categories[Slot.ItemType].IsATool then
				continue
			end
			Slot:Destroy()
		end

		local Character = Player.Character or Player.CharacterAdded:Wait()
		local Humanoid = Character:WaitForChild("Humanoid") :: Humanoid

		EquippedTool = nil
		StartTimer = os.clock()

		local function ItemAdded(Item: Instance)
			UpdateItemCount()
			if Item:IsA("BackpackItem") then
				if EquippedTool == Item then
					BackpackItemUnequipped:Fire(Item)
					EquippedTool = nil
				end
				BackpackItemAdded:Fire(Item)
			end
		end
		local function ItemRemoved(Item: Instance)
			if Humanoid.Health <= 0 then
				return
			end
			UpdateItemCount()
			if Item:IsA("BackpackItem") then
				if EquippedTool ~= Item then
					BackpackItemEquipped:Fire(Item)
					EquippedTool = Item
				end
				BackpackItemRemoved:Fire(Item)
			end
		end

		-- Resume after
		task.defer(function()
			Backpack = Player:WaitForChild("Backpack")

			local Added = Backpack.ChildAdded:Connect(ItemAdded)
			local Removing = Backpack.ChildRemoved:Connect(ItemRemoved)
			for _, Item in Backpack:GetChildren() do
				task.spawn(ItemAdded, Item)
			end

			Backpack.Destroying:Once(function()
				Added:Disconnect()
				Removing:Disconnect()
				for _, Item in Backpack:GetChildren() do
					ItemRemoved(Item)
				end
			end)
		end)
	end

	Player.ChildAdded:Connect(function(Child)
		if Child:IsA("Backpack") then
			OnBackpackAdded(Child)
		end
	end)

	local Backpack = Player:FindFirstChildOfClass("Backpack")
	if Backpack then
		OnBackpackAdded(Backpack)
	end

	-- Character-related clean-up
	local function OnCharacterAdded(Character: Model)
		local Humanoid = Character:WaitForChild("Humanoid") :: Humanoid

		local c1; c1 = Humanoid.Died:Once(function()
			Humanoid:UnequipTools()
		end)

		local c2; c2 = Character.ChildRemoved:Connect(function(Child)
			if not Child.Parent then -- Item has likely been sold / removed
				local Slot = Slots[Child.Name]
				local Count = CountTotalCopies({Name = Child.Name})

				if Slot and (Count <= 0) then
					Slot:Destroy()
				elseif Slot and (Count > 0) then
					UpdateSlotState(Slot, false)
				end
			else
				local Slot = Slots[Child.Name]
				UpdateSlotState(Slot, false)
			end
		end)

		Player.CharacterRemoving:Once(function()
			c1:Disconnect()
			c2:Disconnect()
		end)
	end

	Player.CharacterAdded:Connect(OnCharacterAdded)
	if Player.Character then
		OnCharacterAdded(Player.Character)
	end

	---- INIT ----------------------------------------------------------------------
	-- Hacky, but someone experienced issues with backpack not being properly set
	
	while true do
		pcall(function()
			StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
		end)
		
		task.wait(GameConfig.DefaultClientRefresh)
	end
end