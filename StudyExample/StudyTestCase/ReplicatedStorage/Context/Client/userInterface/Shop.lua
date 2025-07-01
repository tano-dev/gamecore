--[[
	Evercyan @ March 2023
	Shop
	
	ShopGuiScript handles code relating to the shop gui. The code to open up the interface by
	ProximityPrompt is held here as well.
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer

local pData = ReplicatedStorage:WaitForChild("PlayerData"):WaitForChild(Player.UserId)
local ItemsFolder = pData:WaitForChild("Items")

local StatsFolder = pData:WaitForChild("Stats")
local Level = StatsFolder:WaitForChild("Level")

--> Dependencies
local ContentLibrary = require(ReplicatedStorage.Modules.Shared.ContentLibrary)
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)
local SFX = require(ReplicatedStorage.Modules.Shared.SFX)
local ColorModule = require(ReplicatedStorage.Modules.Shared.Color)
local RbxUtility = require(ReplicatedStorage.Modules.Shared.RbxUtility)
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)

local UpdatePopupInfo = require(ReplicatedStorage.Modules.Client.updatePopupInfo)
local CreateNotification = require(ReplicatedStorage.Modules.Client.createNotification)
local SetTooltipListener = require(ReplicatedStorage.Modules.Client.setTooltipListener)

local SetCanvasGroupVisibility = require(ReplicatedStorage.Modules.Client.setCanvasGroupVisibility)
local WaitForDescendant = require(ReplicatedStorage.Modules.Client.waitForDescendant)
local NPCFunctions = require(ReplicatedStorage.Modules.Client.NPCFunctions)

local GameConfig = require(ReplicatedStorage.GameConfig)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return function(Gui)
	if not GameConfig.EnabledFeatures.BuyShop then
		return
	end
	
	--> References
	local MainFrame = Gui:WaitForChild("MainFrame")
	local ExitButton = MainFrame:WaitForChild("Display"):WaitForChild("ExitButton")
	local PopupFrame = Gui:WaitForChild("PopupFrame")

	local AmountTextBox = PopupFrame:WaitForChild("Content"):WaitForChild("List"):WaitForChild("Amount")
	local PurchaseButton = PopupFrame:WaitForChild("Content"):WaitForChild("List"):WaitForChild("Purchase")
	
	--> Variables
	local ItemSlots = {}
	local SlotConnections = {}
	
	local isOpen = false
	local RequestBuyAmount = nil
	
	--------------------------------------------------------------------------------
	
	local ActiveColor = ColorModule:GetBaseColor()

	local function UpdatePopupColor(Color: Color3)
		local Titlebar = PopupFrame:WaitForChild("Titlebar")
		local Primary, Secondary, Background = ColorModule:ConvertToHSV3(Color)

		Titlebar.BackgroundColor3 = Primary
		PopupFrame.Titlebar.BackgroundColor3 = Primary
		PopupFrame.ExitButton.TextColor3 = Secondary
		PopupFrame.Content.List.Purchase.BackgroundColor3 = Primary
		PopupFrame.Content.List.Purchase.TextColor3 = Secondary
		PopupFrame.Content.List.Amount.BackgroundColor3 = Primary
		PopupFrame.Content.List.Amount.PlaceholderColor3 = Secondary:Lerp(Primary, 0.05)
		PopupFrame.Content.List.Amount.TextColor3 = Secondary
		PopupFrame.Content.ItemIcon.BackgroundColor3 = Secondary
		PopupFrame.BackgroundColor3 = Background
		PopupFrame.UIStroke.Color = Background

		return Primary, Secondary, Background
	end

	local function UpdateShopColor(Color: Color3)
		local Titlebar = MainFrame:WaitForChild("Display"):WaitForChild("Body"):WaitForChild("Titlebar")
		local Primary, Secondary, Background = ColorModule:ConvertToHSV3(Color)

		ActiveColor.Primary = Primary
		ActiveColor.Secondary = Secondary
		ActiveColor.Background = Background

		Titlebar.BackgroundColor3 = Primary
		Titlebar.TextColor3 = Secondary

		MainFrame.Display.ExitButton.TextColor3 = Secondary
		MainFrame.Display.Content.ScrollingFrame.ScrollBarImageColor3 = Primary
		MainFrame.Display.Content.Frame.BackgroundColor3 = Secondary
		MainFrame.Display.BackgroundColor3 = Background
		MainFrame.Display.UIStroke.Color = Background
	end

	-- Sets slot colors based off the active colors, and the given state value.
	-- If true, the base uses primary (brighter/owned). If false, the base uses secondary (darker/default)
	local function UpdateSlotColor(Slot)
		local Color = ColorModule:GetPrimaryColor(Slot.Item)
		local Primary, Secondary, Background = ColorModule:ConvertToHSV3(Color)

		local Background = Secondary
		local Foreground = Primary
		local Frame = Slot.Frame

		Frame.BackgroundColor3 = Background
		Frame.ItemIcon.BackgroundColor3 = Background
		Frame.ItemName.TextColor3 = Foreground
		Frame.ItemLevel.TextColor3 = Foreground
		Frame.ItemCost.TextColor3 = Foreground
		Frame.Locked.Icon.ImageColor3 = Foreground
		Frame.Locked.TextLabel.TextColor3 = Foreground
		Frame.Owned.Icon.ImageColor3 = Foreground
		Frame.Owned.TextLabel.TextColor3 = Foreground

		return Primary, Secondary, Background
	end

	-- This code is really ugly, I may revamp it in the future
	local function UpdateSlot(Slot)
		local ItemValue = ItemsFolder:WaitForChild(Slot.Item.Type):FindFirstChild(Slot.Item.Name)
		local ItemLocked = Level.Value < Slot.Item.Config.Level
		
		for _, Connection in SlotConnections[Slot] or {} do
			Connection:Disconnect()
			Connection = nil
		end
		
		SlotConnections[Slot] = {}
		
		local Frame = Slot.Frame

		local Primary, Secondary, Background = UpdateSlotColor(Slot)
		
		local Connections = SetTooltipListener(Frame.ItemIcon, Slot.Item.Instance, Primary, Secondary)
		SlotConnections[Slot] = Connections
		
		local isStackable = GameConfig.CanItemsStack 
			or GameConfig.Categories[Slot.Item.Type].IsStackable
		
		local isOwned = ItemValue and (not isStackable or Slot.Item.Config.Cost[4]) and not (ItemValue:IsA("NumberValue") and ItemValue.Value < 1)
		
		if isOwned then
			Frame.BackgroundTransparency = 0.25
			Frame.AutoButtonColor = false
			Frame.ItemName.Visible = true
			Frame.ItemLevel.Visible = true
			Frame.ItemCost.Visible = false
			Frame.ItemIcon.Visible = true
			Frame.Locked.Visible = false
			Frame.Owned.Visible = true
			Frame.ItemIcon:SetAttribute("DisableTooltip", true)
			Frame:SetAttribute("DisableSound", true)
		else
			Frame.Owned.Visible = false
			if ItemLocked then
				Frame.BackgroundTransparency = 0.25
				Frame.AutoButtonColor = false
				Frame.ItemName.Visible = false
				Frame.ItemLevel.Visible = false
				Frame.ItemCost.Visible = false
				Frame.ItemIcon.Visible = false
				Frame.Locked.Visible = true
				Frame.Locked.TextLabel.Text = `Unlocks at Level <b>{FormatNumber(Slot.Item.Config.Level, "Suffix")}</b>`
				Frame.ItemIcon:SetAttribute("DisableTooltip", true)
				Frame:SetAttribute("DisableSound", true)
			else
				Frame.BackgroundTransparency = 0
				Frame.AutoButtonColor = true
				Frame.ItemName.Visible = true
				Frame.ItemLevel.Visible = true
				Frame.ItemCost.Visible = true
				Frame.ItemIcon.Visible = true
				Frame.Locked.Visible = false
				Frame.ItemIcon:SetAttribute("DisableTooltip", false)
				Frame:SetAttribute("DisableSound", false)
			end
		end
	end

	---- POPUP FRAME LOGIC ---------------------------------------------------------

	local PopupItem = nil :: Instance
	local ListenerConnections = {}
	
	local Content = PopupFrame:WaitForChild("Content")

	local function OpenPopupFrame(Item)
		PopupItem = Item

		for _, Connection in ListenerConnections do
			Connection:Disconnect()
			Connection = nil
		end

		local ItemInstance = PopupItem.Instance
		
		local Color = ColorModule:GetPrimaryColor(Item)
		local Primary, Secondary, Background = UpdatePopupColor(Color)
		
		ListenerConnections = SetTooltipListener(Content.ItemIcon, ItemInstance, Primary, Secondary)
		
		if not Item.Config.IconId then
			Content.ItemIcon.Label.Visible = false
		else
			Content.ItemIcon.Label.Visible = true
			Content.ItemIcon.Label.Image = "rbxthumb://type=Asset&h=150&w=150&id=".. Item.Config.IconId
		end

		local Currency = PopupItem.Config.Cost[1] == "Statistic" and pData.Stats[PopupItem.Config.Cost[2]] or pData.Items[PopupItem.Config.Cost[1]]:FindFirstChild(PopupItem.Config.Cost[2])
		local MaxBuyable = math.floor(Currency.Value / PopupItem.Config.Cost[3])

		AmountTextBox.PlaceholderText = FormatNumber(math.min(GameConfig.Categories[PopupItem.Type].BulkBuyMax, MaxBuyable), "Suffix")
		
		local IsStackable = GameConfig.CanItemsStack or GameConfig.Categories[Item.Type].IsStackable
		AmountTextBox.Visible = IsStackable

		Content.ItemName.Text = Item.Name
		Content.ItemType.Text = Item.Type
		Content.ItemLevel.Text = `<b>Level</b> {FormatNumber(Item.Config.Level, "Suffix")}`
		
		Content.ItemCost.Text = `-{FormatNumber(Item.Config.Cost[3], "Suffix")} {Item.Config.Cost[2]}`
		Content.ItemCost.TextColor3 = Item.Config.Cost[1] == "Statistic" 
			and ((GameConfig.LeaderstatIcons[Currency.Name] and GameConfig.LeaderstatIcons[Currency.Name].Color) or GameConfig.UIColors.PrimaryColor)
			or (ContentLibrary[Item.Config.Cost[1]][Item.Config.Cost[2]].SpecialColor or GameConfig.Categories[Item.Config.Cost[1]].Color or GameConfig.UIColors.PrimaryColor)

		UpdatePopupInfo(Item, Content)
		
		AmountTextBox.Text = " "
		task.defer(function()
			AmountTextBox.Text = ""
		end)

		SetCanvasGroupVisibility(MainFrame, false)
		SetCanvasGroupVisibility(PopupFrame, true)
	end

	local function ClosePopupFrame()
		SetCanvasGroupVisibility(MainFrame, true)
		SetCanvasGroupVisibility(PopupFrame, false)
	end

	local function ClearFocus()
		AmountTextBox.Text = ""
		
		Content.ItemCost.Text = ((PopupItem and PopupItem.Config.Cost) 
			and `-{FormatNumber(PopupItem.Config.Cost[3], "Suffix")} {PopupItem.Config.Cost[2]}`) 
			or "0"
		
		RequestBuyAmount = nil
	end

	PurchaseButton.Activated:Connect(function()
		if not PopupItem then 
			return 
		end
		
		local RequestedBuyAmount = (GameConfig.CanRequestItemWithNoAmountInput and math.clamp(RequestBuyAmount or 1, 1, math.huge))
			or RequestBuyAmount
			or not GameConfig.CanItemsStack and not GameConfig.Categories[PopupItem.Type].IsStackable and 1
		
		local OldRequestedBuyAmount = RequestedBuyAmount
		local OldPopupItem = PopupItem
		
		if not RequestedBuyAmount or RequestedBuyAmount < 1 or PopupFrame.GroupTransparency == 1 then
			return
		end
		
		local Success, Response = EventModule:InvokeServer("BuyItem", OldPopupItem.Type, OldPopupItem.Name, RequestedBuyAmount)
		if Success then
			ClearFocus()
			ClosePopupFrame()
			
			UpdateSlot(ItemSlots[OldPopupItem.Name])
			
			local newText = `{OldPopupItem.Name} (x{FormatNumber(OldRequestedBuyAmount, "Suffix")}) has been purchased!`
			CreateNotification("Purchase Success!", newText, 12900311398)
			SFX:Play2D(GameConfig.PurchaseSFX[1], {Volume = GameConfig.PurchaseSFX[2]})
		else
			CreateNotification("Purchase Failure!", Response, 12900311562)
		end
	end)

	AmountTextBox:GetPropertyChangedSignal("Text"):Connect(function()
		local Text = AmountTextBox.Text
		local Amount = tonumber(Text)
		Amount = Amount and math.floor(Amount)

		if (Text == "" or not Amount or math.abs(Amount) ~= Amount) and not string.find(Text, "e") then
			return ClearFocus()
		end

		local Currency = PopupItem.Config.Cost[1] == "Statistic" and pData.Stats[PopupItem.Config.Cost[2]] or pData.Items[PopupItem.Config.Cost[1]]:FindFirstChild(PopupItem.Config.Cost[2])
		local MaxBuyable = math.floor((Currency and Currency.Value or 0) / PopupItem.Config.Cost[3])
		
		if Amount ~= nil then
			if PopupItem then
				Content.ItemCost.Text = `-{FormatNumber(PopupItem.Config.Cost[3] * Amount, "Suffix")} {PopupItem.Config.Cost[2]}`
			end
			
			Amount = math.min(Amount, GameConfig.Categories[PopupItem.Type].BulkBuyMax, MaxBuyable)
			AmountTextBox.Text = Amount
		end

		RequestBuyAmount = Amount
	end)

	PopupFrame:WaitForChild("ExitButton").Activated:Connect(function()
		ClosePopupFrame()
	end)

	---- MAIN FRAME LOGIC ----------------------------------------------------------
	
	local CategoryFrames = {}
	
	local function OpenShop(Shop, ShopConfig)
		isOpen = true
		
		for _, Slot in ItemSlots do
			Slot.Frame.Visible = false
			Slot.Frame.Parent = nil
		end
		
		MainFrame.Display.Body.Titlebar.Text = ShopConfig.Name
		UpdateShopColor(ShopConfig.Color)

		-- Grab the slots that need to appear for this shop
		local SlotsToOpen = {}
		for Id, ItemInfo in ShopConfig.Items do
			local ItemType = ItemInfo[1]
			local ItemName = ItemInfo[2]

			local Item = ContentLibrary[ItemType][ItemName]
			local Slot = ItemSlots[ItemName]
			
			if not Item then
				warn(`Item "{ItemName}" failed to load in the shop since the item doesn't exist (is the name correct?).`)
				continue
			end
			
			if not Slot then
				warn(`Item "{ItemName}" doesn't have a suggested slot: either Item.Config.Cost is nil or another issue arised (likely to do with preloading).`)
				continue
			end

			table.insert(SlotsToOpen, Slot)
		end

		-- Sort the slots by item level
		table.sort(SlotsToOpen, function(A, B)
			return A.Item.Config.Level < B.Item.Config.Level
		end)

		for LayoutOrder, Slot in SlotsToOpen do
			UpdateSlot(Slot)
			
			Slot.Frame.LayoutOrder = LayoutOrder
			Slot.Frame.Visible = true
			Slot.Frame.Parent = CategoryFrames[Slot.Item.Type].Items
		end

		MainFrame.Display.Content.ScrollingFrame.CanvasSize = UDim2.fromOffset(0, MainFrame.Display.Content.ScrollingFrame.UIListLayout.AbsoluteContentSize.Y)

		Gui.Enabled = true
		Gui.Padding.PaddingTop = UDim.new(0, 50)
		
		ClosePopupFrame()
		SetCanvasGroupVisibility(MainFrame, true)
		
		Tween:Play(Gui.Padding, {0.3, "Back", "Out"}, {PaddingTop = UDim.new()})
	end

	local function CloseShop()
		isOpen = false

		ClosePopupFrame()
		SetCanvasGroupVisibility(MainFrame, false)
		
		Tween:Play(Gui.Padding, {0.2, "Back", "In"}, {PaddingTop = UDim.new(0, 50)})
		
		return true
	end
	
	local function RequestCheck()
		return isOpen
	end

	local function PerShop(Shop: Model)
		NPCFunctions:CreateProximityPrompt(Shop, RequestCheck, ExitButton.Activated, CloseShop, OpenShop)
		NPCFunctions:CreateDialogue(Shop)
		NPCFunctions:AnimateNPC(Shop)
	end

	CollectionService:GetInstanceAddedSignal("BuyShop"):Connect(PerShop)
	for _, Shop in CollectionService:GetTagged("BuyShop") do
		task.spawn(PerShop, Shop)
	end
	
	---- Categories ---------------------------------------------------------------------
	
	local InventoryList = MainFrame.Display.Content.ScrollingFrame
	local CategoryButtons = MainFrame.Display:WaitForChild("Categories")
	
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

	for Name, CategoryInfo in GameConfig.Categories do
		local Frame = script:WaitForChild("CategoryTemplate"):Clone()
		Frame.Name = Name
		Frame.Header.Text = Name
		Frame.Header.TextColor3 = CategoryInfo.Color
		Frame.Items.BackgroundColor3 = CategoryInfo.Color

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
	
	---- Setup ---------------------------------------------------------------------
	
	for _, Items in ContentLibrary do
		for _, Item in Items do
			task.spawn(function()
				if not Item.Config.Cost then 
					return 
				end

				local Frame = script.SlotTemplate:Clone()

				ItemSlots[Item.Name] = {
					Item = Item,
					Frame = Frame
				}

				Frame.Name = Item.Name
				Frame.ItemName.Text = Item.Name
				Frame.ItemLevel.Text = `Level <b>{FormatNumber(Item.Config.Level, "Suffix")}</b>`

				local IsStackable = GameConfig.CanItemsStack or GameConfig.Categories[Item.Type].IsStackable
				local PurchasesSuffix = (not Item.Config.Cost[4]) and IsStackable and ` <font size="13" transparency = "0.4" weight="Medium">(Multiple)</font>` or ""
				Frame.ItemCost.Text = FormatNumber(Item.Config.Cost[3], "Suffix") .." ".. Item.Config.Cost[2] .. PurchasesSuffix

				if Item.Config.IconId then
					Frame.ItemIcon.Label.Image = tonumber(Item.Config.IconId) and `rbxassetid://{Item.Config.IconId}` or Item.Config.IconId or ""
				end
				Frame.Visible = false
				--Frame.Parent = CategoryFrames[Item.Type].Items

				Frame.Activated:Connect(function()
					local ItemValue = ItemsFolder:WaitForChild(Item.Type):FindFirstChild(Item.Name)
					local ItemOwned = ItemValue and not (ItemValue:IsA("NumberValue") and ItemValue.Value > 0)
					local ItemLocked = StatsFolder:WaitForChild("Level").Value < Item.Config.Level

					local IsStackable = GameConfig.CanItemsStack or GameConfig.Categories[Item.Type].IsStackable
					local isForceLocked = ItemValue and (not IsStackable or Item.Config.Cost[4]) and not (ItemValue:IsA("NumberValue") and ItemValue.Value < 1)

					if Item.Config.Cost and not isForceLocked and not ItemLocked then
						OpenPopupFrame(Item)
					end
				end)
			end)
		end
	end

	-------------------------------

	Gui:WaitForChild("Padding")
	CloseShop()
end