--[[
	ej0w @ October 2024
	Crafting
	
	Uses a similar system to shop, additionally handles crafting pin.
]]

--> Services
local UserInputService = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local pData = ReplicatedStorage:WaitForChild("PlayerData"):WaitForChild(Player.UserId)
local ItemsFolder = pData:WaitForChild("Items")

local StatsFolder = pData:WaitForChild("Stats")
local Level = StatsFolder:WaitForChild("Level")

--> References
local CurrentCamera = workspace.CurrentCamera

--> Dependencies
local ContentLibrary = require(ReplicatedStorage.Modules.Shared.ContentLibrary)
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)
local SFX = require(ReplicatedStorage.Modules.Shared.SFX)
local RbxUtility = require(ReplicatedStorage.Modules.Shared.RbxUtility)
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)

local UpdatePopupInfo = require(ReplicatedStorage.Modules.Client.updatePopupInfo)
local CreateNotification = require(ReplicatedStorage.Modules.Client.createNotification)
local SetTooltipListener = require(ReplicatedStorage.Modules.Client.setTooltipListener)

local CountTotalCopies = require(ReplicatedStorage.Modules.Shared.countTotalCopies)
local GetMaxCraftable = require(ReplicatedStorage.Modules.Shared.getMaxCraftable)
local ColorModule = require(ReplicatedStorage.Modules.Shared.Color)

local StartPinFunction = require(ReplicatedStorage.Modules.Client.startPinFunction)
local SetCanvasGroupVisibility = require(ReplicatedStorage.Modules.Client.setCanvasGroupVisibility)
local WaitForDescendant = require(ReplicatedStorage.Modules.Client.waitForDescendant)
local NPCFunctions = require(ReplicatedStorage.Modules.Client.NPCFunctions)

local GameConfig = require(ReplicatedStorage.GameConfig)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return function(Gui)
	if not GameConfig.EnabledFeatures.Crafting then
		return
	end
	
	--> References
	local MainFrame = Gui:WaitForChild("MainFrame")
	local ExitButton = MainFrame:WaitForChild("Display"):WaitForChild("ExitButton")
	local PopupFrame = Gui:WaitForChild("PopupFrame")
	
	local PinGui = PlayerGui:WaitForChild("Pin")
	local CraftingPinFrame = PinGui:WaitForChild("Crafting")

	local AmountTextBox = PopupFrame:WaitForChild("Content"):WaitForChild("List"):WaitForChild("Amount")
	local CraftButton = PopupFrame:WaitForChild("Content"):WaitForChild("List"):WaitForChild("Craft")

	local PopupBackground = CraftingPinFrame:WaitForChild("PopupBackground")
	local Resize = CraftingPinFrame:WaitForChild("Resize")

	local ScrollingFrame = PopupBackground:WaitForChild("Background"):WaitForChild("ScrollingFrame")
	local StatisticsFrame = ScrollingFrame:WaitForChild("Statistics")

	local Stats = pData:WaitForChild("Stats")
	
	--------------------------------------------------------------------------------
	
	local SlotConnections = {}
	local ActiveColor = ColorModule:GetBaseColor()

	local function UpdatePinColor(Color)
		local Primary, Secondary, Background = ColorModule:ConvertToHSV3(Color)

		CraftingPinFrame.Resize.ImageLabel.ImageColor3 = Primary
		CraftingPinFrame.Resize.BackgroundColor3 = Background
		CraftingPinFrame.PopupBackground.BackgroundColor3 = Background
		CraftingPinFrame.PopupBackground.Background.BackgroundColor3 = Background
		CraftingPinFrame.PopupBackground.Background.Frame.BackgroundColor3 = Background
		CraftingPinFrame.PopupBackground.Background.Fill.BackgroundColor3 = Primary
		CraftingPinFrame.PopupBackground.Background.Fill.BackgroundColor3 = Primary
		CraftingPinFrame.PopupBackground.Background.ScrollingFrame.ScrollBarImageColor3 = Primary
		CraftingPinFrame.PopupBackground.Background.Percentage.TextColor3 = Primary
		CraftingPinFrame.PopupBackground.Title.ExitButton.TextColor3 = Primary
		CraftingPinFrame.PopupBackground.Title.Display.TextColor3 = Primary	
		
		return Primary, Secondary, Background
	end

	local function UpdatePopupColor(Color: Color3)
		local Titlebar = PopupFrame:WaitForChild("Titlebar")
		local Primary, Secondary, Background = ColorModule:ConvertToHSV3(Color)

		Titlebar.BackgroundColor3 = Primary
		PopupFrame.Titlebar.BackgroundColor3 = Primary
		PopupFrame.ExitButton.TextColor3 = Secondary
		PopupFrame.Content.List.Craft.BackgroundColor3 = Primary
		PopupFrame.Content.List.Craft.TextColor3 = Secondary
		PopupFrame.Content.Recipe.BackgroundColor3 = Secondary
		PopupFrame.Content.Recipe.Icon.ImageColor3 = Primary
		PopupFrame.Content.Recipe.Label.TextColor3 = Primary
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

		Frame.BG.BackgroundColor3 = Background
		Frame.Button.BackgroundColor3 = Background
		Frame.Pin.BackgroundColor3 = Foreground
		Frame.Pin.ImageLabel.ImageColor3 = Background
		Frame.ItemIcon.BackgroundColor3 = Background
		Frame.ItemName.TextColor3 = Foreground
		Frame.ItemLevel.TextColor3 = Foreground
		Frame.Locked.Icon.ImageColor3 = Foreground
		Frame.Locked.TextLabel.TextColor3 = Foreground
		Frame.Owned.Icon.ImageColor3 = Foreground
		Frame.Owned.TextLabel.TextColor3 = Foreground
		
		return Primary, Secondary, Background
	end

	-- This code is really ugly, I may revamp it in the future
	local function UpdateSlot(Slot)
		local ItemValue = ItemsFolder:WaitForChild(Slot.Item.Type):FindFirstChild(Slot.Item.Name)
		local ItemLocked = Level.Value < Slot.Data.Level

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
		
		local isOwned = ItemValue and (not isStackable or not Slot.Data.CraftMultiple) and not (ItemValue:IsA("NumberValue") and ItemValue.Value < 1)
		
		if isOwned then
			Frame.Button.BackgroundTransparency = 0.25
			Frame.BG.BackgroundTransparency = 0.25
			Frame.Button.AutoButtonColor = false
			Frame.Pin.AutoButtonColor = false
			Frame.ItemName.Visible = true
			Frame.ItemLevel.Visible = true
			Frame.ItemIcon.Visible = true
			Frame.Locked.Visible = false
			Frame.Pin.Visible = true
			Frame.Pin.Active = false
			Frame.Owned.Visible = true
			Frame.ItemIcon:SetAttribute("DisableTooltip", true)
			Frame.Button:SetAttribute("DisableSound", true)
			Frame.Pin:SetAttribute("DisableSound", true)
		else
			Frame.Owned.Visible = false
			if ItemLocked then
				Frame.Button.BackgroundTransparency = 0.25
				Frame.BG.BackgroundTransparency = 0.25
				Frame.Button.AutoButtonColor = false
				Frame.Pin.AutoButtonColor = false
				Frame.ItemName.Visible = false
				Frame.ItemLevel.Visible = false
				Frame.ItemIcon.Visible = false
				Frame.Pin.Visible = false
				Frame.Pin.Active = false
				Frame.Locked.Visible = true
				Frame.Locked.TextLabel.Text = `Unlocks at Level <b>{FormatNumber(Slot.Data.Level, "Suffix")}</b>`
				Frame.ItemIcon:SetAttribute("DisableTooltip", true)
				Frame.Button:SetAttribute("DisableSound", true)
				Frame.Pin:SetAttribute("DisableSound", true)
			else
				Frame.Button.BackgroundTransparency = 0
				Frame.BG.BackgroundTransparency = 0
				Frame.Button.AutoButtonColor = true
				Frame.Pin.AutoButtonColor = true
				Frame.ItemName.Visible = true
				Frame.ItemLevel.Visible = true
				Frame.ItemIcon.Visible = true
				Frame.Pin.Visible = true
				Frame.Pin.Active = true
				Frame.Locked.Visible = false
				Frame.ItemIcon:SetAttribute("DisableTooltip", false)
				Frame.Button:SetAttribute("DisableSound", false)
				Frame.Pin:SetAttribute("DisableSound", false)
			end
		end
	end

	---- PIN FRAME LOGIC ---------------------------------------------------------
	
	local TotalItemsChecking = {}
	local PinConnections = {}
	local PinTemporary = {}
	
	local PinItem = nil
	
	local function UpdatePinPercentage(Origin)
		local Fill = PopupBackground.Background.Fill
		if Origin then
			Fill.UIGradient.Offset = Vector2.new(0, 0)
		end

		local TotalAmountRequired = 0
		local AmountCompleted = 0
		
		for _, Boolean in TotalItemsChecking do
			if Boolean then
				AmountCompleted += 1
			end
			TotalAmountRequired += 1
		end

		local Percent = AmountCompleted / TotalAmountRequired
		PopupBackground.Background:WaitForChild("Percentage").Text = `{math.round(Percent * 100)}%`

		Tween:Play(Fill.UIGradient, {0.5, "Circular"}, {Offset = Vector2.new(Percent, 0)})
	end

	local function ClosePinFrame()
		PinItem = nil

		SetCanvasGroupVisibility(CraftingPinFrame, false)
	end

	local function OpenPinFrame(Item, Data)
		if PinItem then
			ClosePinFrame()
		end
		
		PinItem = Item

		for _, Instance in PinTemporary do
			Instance:Destroy()
		end
		PinTemporary = {}

		for _, Connection in PinConnections do
			Connection:Disconnect()
			Connection = nil
		end
		
		-- Update UI
		for _, Frame in StatisticsFrame.Items:GetChildren() do
			if Frame:IsA("Frame") then
				Frame.StatIcon.ImageTransparency = 0
				Frame.StatCount.TextTransparency = 0
				
				Frame.Visible = false
			end
		end

		local Mouse = UserInputService:GetMouseLocation()
		CraftingPinFrame.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y - 25)
		CraftingPinFrame.Size = UDim2.fromOffset(263, math.min(CurrentCamera.ViewportSize.Y / 2, 321))

		PopupBackground.Title.Display.Text = Item.Name
		
		local Color = ColorModule:GetPrimaryColor(Item)
		local Primary, Secondary, Background = UpdatePinColor(Color)

		-- Set recipe
		local CurrentCategories = {["Statistics"] = true}
		local CurrentSorts = {}
			
		local CheckIsVisible = false
			
		TotalItemsChecking = {}
		
		for Category, Items in Data.Recipe do
			local DataLibrary = pData.Items:FindFirstChild(Category)

			if not CurrentCategories[Category] then
				local NewCategory = script.PinCategoryTemplate:Clone()
				NewCategory.Header.Text = Category
				if Category == "Material" then
					NewCategory.Items.UIGridLayout.CellSize = UDim2.fromOffset(40, 40)
				end
				NewCategory.Items.BackgroundColor3 = Background

				CurrentSorts[Category] = {}
				CurrentCategories[Category] = NewCategory

				NewCategory.Parent = ScrollingFrame
				NewCategory.Visible = true
				table.insert(PinTemporary, NewCategory)
			end

			for _, Stat in Items do
				local IsStatistics = Category == "Statistics"
				if IsStatistics then
					local Frame = StatisticsFrame.Items:FindFirstChild(Stat[1])
					if Frame then
						local Value = Stats:FindFirstChild(Stat[1])
						local function UpdateCheckVisibility()
							local IsObtained = Value.Value >= Stat[2]
							Frame.StatIcon.ImageTransparency = IsObtained and 0.5 or 0
							Frame.StatCount.TextTransparency = IsObtained and 0.5 or 0

							TotalItemsChecking[Stat[1]] = IsObtained
							UpdatePinPercentage()
						end

						PinConnections[#PinConnections + 1] = Value.Changed:Connect(UpdateCheckVisibility)
						UpdateCheckVisibility()

						CheckIsVisible = true
						Frame.Visible = true
						Frame.StatCount.Text = FormatNumber(Stat[2], "Suffix")
					end
				elseif not IsStatistics then
					local Frame = script.PinSlotTemplate:Clone()
					Frame.BackgroundTransparency = 0.25
					Frame.BackgroundColor3 = Background
					Frame.Amount.Text = `x{FormatNumber(Stat[2], "Suffix")}`
					Frame.ItemName.Text = Stat[1]

					local Item = ContentLibrary[Category][Stat[1]]

					local ItemInstance = Item.Instance
					local DataValue = DataLibrary:FindFirstChild(Stat[1])

					local function UpdateCheckVisibility()
						local AmountOwned = CountTotalCopies(Item)

						local IsObtained = AmountOwned >= Stat[2]
						Frame.BackgroundTransparency = IsObtained and 0.5 or 0.25
						Frame.ItemIcon.ImageTransparency = IsObtained and 0.5 or 0
						Frame.Amount.TextTransparency = IsObtained and 0.5 or 0
						Frame.ItemName.TextTransparency = IsObtained and 0.5 or 0

						TotalItemsChecking[Stat[1]] = IsObtained
						UpdatePinPercentage()
					end
					
					local function CheckIsNumberValue(DataValue)
						local IsOnlyAmount = DataValue and DataValue:IsA("NumberValue")
						if IsOnlyAmount then
							PinConnections[#PinConnections + 1] = DataValue.Changed:Connect(UpdateCheckVisibility)
						end
					end

					PinConnections[#PinConnections + 1] = DataLibrary.ChildAdded:Connect(function(Child)
						CheckIsNumberValue(Child)
						UpdateCheckVisibility()
					end)
					
					PinConnections[#PinConnections + 1] = DataLibrary.ChildRemoved:Connect(UpdateCheckVisibility)
					
					CheckIsNumberValue(DataValue)
					UpdateCheckVisibility()

					local IsAnIcon = Item.Config.IconId
					if IsAnIcon then
						Frame.ItemIcon.Image = tonumber(Item.Config.IconId) and `rbxassetid://{Item.Config.IconId}` or Item.Config.IconId
					end
					Frame.ItemIcon.Visible = IsAnIcon
					Frame.Parent = CurrentCategories[Category].Items

					table.insert(CurrentSorts[Category], {
						Item = Item,
						Frame = Frame,
						Amount = Stat[2]
					})
					table.insert(PinTemporary, Frame)
				end
			end
		end

		for _, Category in CurrentSorts do
			table.sort(Category, function(A, B)
				return A.Amount < B.Amount
			end)
			for LayoutOrder, Slot in Category do
				Slot.Frame.LayoutOrder = LayoutOrder
				Slot.Frame.Visible = true
			end
		end

		StatisticsFrame.Visible = CheckIsVisible
		
		PinGui.Enabled = true
		CraftingPinFrame.UIScale.Scale = 0.75
		
		UpdatePinPercentage(true)
		SetCanvasGroupVisibility(CraftingPinFrame, true)
		
		Tween:Play(CraftingPinFrame.UIScale, {0.3, "Back", "Out"}, {Scale = 1})
	end
	
	-- Create leaderstat display
	for Name, Leaderstat in GameConfig.Leaderstats do
		local Stat = StatisticsFrame.Items.Template:Clone()
		Stat.Name = Name

		local StatColor = GameConfig.UIColors.PrimaryColor

		local StatIconData = GameConfig.LeaderstatIcons[Name]
		if StatIconData and StatIconData.Image then
			if StatIconData.Color then
				StatColor = StatIconData.Color
			end
			Stat.StatIcon.Image = tonumber(StatIconData.Image) and "rbxassetid://" .. StatIconData.Image or StatIconData.Image
		else
			Stat.StatIcon.Visible = false
		end

		Stat.StatIcon.ImageColor3 = StatColor
		Stat.StatCount.TextColor3 = StatColor

		Stat.Visible = true
		Stat.Parent = StatisticsFrame.Items
	end

	PopupBackground.Title.ExitButton.Activated:Connect(ClosePinFrame)
	ClosePinFrame()
	
	StartPinFunction(CraftingPinFrame)

	---- POPUP FRAME LOGIC ---------------------------------------------------------
	
	local RequestCraftAmount = nil
	local CurrentSmithery = nil
	local SmitheryConfig = nil
	local PopupItem = nil
	
	local ListenerConnections = {}
	local ItemSlots = {}
	
	local Content = PopupFrame:WaitForChild("Content")

	local function OpenPopupFrame(Item, Data)
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
			Content.ItemIcon.Label.Image = tonumber(Item.Config.IconId) and `rbxthumb://type=Asset&h=150&w=150&id={Item.Config.IconId}` or Item.Config.IconId
		end
		
		local MaxCraftable = GetMaxCraftable(Data)
		
		AmountTextBox.PlaceholderText = FormatNumber(math.min(GameConfig.Categories[PopupItem.Type].BulkBuyMax, MaxCraftable), "Suffix")
		
		local IsStackable = GameConfig.CanItemsStack or GameConfig.Categories[Item.Type].IsStackable
		AmountTextBox.Visible = IsStackable
		
		Content.ItemName.Text = Item.Name
		
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
		RequestCraftAmount = nil
	end

	CraftButton.Activated:Connect(function()
		if not PopupItem then 
			return 
		end
		
		local RequestedCraftAmount = (GameConfig.CanRequestItemWithNoAmountInput and math.clamp(RequestCraftAmount or 1, 1, math.huge))
			or RequestCraftAmount
			or not GameConfig.CanItemsStack and not GameConfig.Categories[PopupItem.Type].IsStackable and 1
		
		if not RequestedCraftAmount or RequestedCraftAmount < 1 or PopupFrame.GroupTransparency == 1 then
			return
		end
		
		local Item = PopupItem
		local Slot = ItemSlots[Item.Name]
		
		local Success, Response = EventModule:InvokeServer("CraftItem", {Slot.Data.Item[1], Slot.Data.Item[2]}, CurrentSmithery, RequestedCraftAmount)
		if Success then
			ClosePopupFrame()
			ClearFocus()
			UpdateSlot(ItemSlots[Item.Name])
			CreateNotification("Craft Success!", `{Item.Name} (x{FormatNumber(Response, "Suffix")}) has been crafted!`, 12900311398)
			SFX:Play2D(GameConfig.CraftSFX[1], {Volume = GameConfig.CraftSFX[2]})
		else
			CreateNotification("Craft Failure!", Response, 12900311562)
		end
	end)

	AmountTextBox:GetPropertyChangedSignal("Text"):Connect(function()
		local Text = AmountTextBox.Text
		local Amount = tonumber(Text)
		Amount = Amount and math.floor(Amount)

		if (Text == "" or not Amount or math.abs(Amount) ~= Amount) and not string.find(Text, "e") then
			return ClearFocus()
		end

		local Slot = ItemSlots[PopupItem.Name]

		if Amount ~= nil then
			Amount = math.min(Amount, GameConfig.Categories[PopupItem.Type].BulkBuyMax, GetMaxCraftable(Slot.Data))
			AmountTextBox.Text = Amount
		end

		RequestCraftAmount = Amount
	end)

	PopupFrame:WaitForChild("ExitButton").Activated:Connect(function()
		ClosePopupFrame()
	end)

	PopupFrame.Content:WaitForChild("Recipe").Activated:Connect(function()
		local CurrentItem = PopupItem
		local Slot = ItemSlots[CurrentItem.Name]
		
		OpenPinFrame(CurrentItem, Slot.Data)
	end)
	
	---- Categories ---------------------------------------------------------------------

	local InventoryList = MainFrame.Display.Content.ScrollingFrame
	local CategoryButtons = MainFrame.Display:WaitForChild("Categories")

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
	
	local isOpen = false
	
	local function OpenCrafting(Shop, ShopConfig)
		isOpen = true
		CurrentSmithery = Shop
		SmitheryConfig = ShopConfig

		for _, Slot in ItemSlots do
			Slot.Frame.Visible = false
		end
		
		MainFrame.Display.Body.Titlebar.Text = ShopConfig.Name
		UpdateShopColor(ShopConfig.Color)

		-- Clear current crafting slots
		for Name, Slot in ItemSlots do
			Slot.Frame:Destroy()

			for _, Connection in Slot.Connections do
				Connection:Disconnect()
				Connection = nil
			end

			ItemSlots[Name] = nil
		end

		local SlotsToOpen = {}
		ItemSlots = {}

		-- Add items to the crafting ui
		-- We're doing it this way because hint hint some items have unique level reqs
		for _, Data in ShopConfig.Smithery do
			local ItemName = Data.Item[2]
			local ItemCategory = Data.Item[1]
			local ItemLevel = Data.Level

			local Item = ContentLibrary[ItemCategory][ItemName]
			local ItemConfig = Item.Config

			local CraftMultiple = Data.CraftMultiple

			local Frame = script.SlotTemplate:Clone()
			Frame.Name = ItemName
			Frame.ItemName.Text = ItemName
			Frame.ItemLevel.Text = `Level <b>{FormatNumber(ItemLevel, "Suffix")}</b>`
			
			if ItemConfig.IconId then
				Frame.ItemIcon.Label.Image = tonumber(ItemConfig.IconId) and `rbxassetid://{ItemConfig.IconId}` or ItemConfig.IconId
			end
			Frame.Visible = false
			Frame.Parent = CategoryFrames[Item.Type].Items

			local Category = {Item = Item, Data = Data, Frame = Frame}
			local Primary, Secondary, Tertiary = UpdateSlot(Category)

			local Connections = SetTooltipListener(Frame.ItemIcon, Item.Instance, Primary, Secondary)
			Category.Connections = Connections
			Category.Connections[#Category.Connections + 1] = Level.Changed:Connect(function()
				UpdateSlot(Category)
			end)

			Frame.Button.Activated:Connect(function()
				local ItemValue = ItemsFolder:WaitForChild(ItemCategory):FindFirstChild(ItemName)
				local ItemOwned = ItemValue and not (ItemValue:IsA("NumberValue") and ItemValue.Value > 0)
				local ItemLocked = Level.Value < ItemLevel
				
				local IsStackable = GameConfig.CanItemsStack or GameConfig.Categories[Item.Type].IsStackable
				local isForceLocked = ItemValue and (not IsStackable or not CraftMultiple) and not (ItemValue:IsA("NumberValue") and ItemValue.Value < 1)
				
				if not isForceLocked and not ItemLocked then
					OpenPopupFrame(Item, Data)
				end
			end)

			Frame.Pin.Activated:Connect(function()
				OpenPinFrame(Item, Data)
			end)

			ItemSlots[ItemName] = Category
			table.insert(SlotsToOpen, Category)
		end

		-- Sort the slots by item level
		table.sort(SlotsToOpen, function(A, B)
			return A.Data.Level < B.Data.Level
		end)

		for LayoutOrder, Slot in SlotsToOpen do
			Slot.Frame.LayoutOrder = LayoutOrder
			Slot.Frame.Visible = true
		end
		
		MainFrame.Display.Content.ScrollingFrame.CanvasSize = UDim2.fromOffset(0, MainFrame.Display.Content.ScrollingFrame.UIListLayout.AbsoluteContentSize.Y)

		Gui.Enabled = true
		Gui.Padding.PaddingTop = UDim.new(0, 50)
		
		ClosePopupFrame()
		SetCanvasGroupVisibility(MainFrame, true)
		
		Tween:Play(Gui.Padding, {0.3, "Back", "Out"}, {PaddingTop = UDim.new()})
	end

	local function CloseCrafting()
		isOpen = false
		CurrentSmithery = nil
		SmitheryConfig = nil

		ClosePopupFrame()
		SetCanvasGroupVisibility(MainFrame, false)
		
		Tween:Play(Gui.Padding, {0.2, "Back", "In"}, {PaddingTop = UDim.new(0, 50)})
		
		return true
	end
	
	local function RequestCheck()
		return isOpen
	end

	local function PerCrafting(Shop: Model)
		NPCFunctions:CreateProximityPrompt(Shop, RequestCheck, ExitButton.Activated, CloseCrafting, OpenCrafting)
		NPCFunctions:CreateDialogue(Shop)
		NPCFunctions:AnimateNPC(Shop)
	end

	CollectionService:GetInstanceAddedSignal("Smithery"):Connect(PerCrafting)
	for _, Shop in CollectionService:GetTagged("Smithery") do
		task.spawn(PerCrafting, Shop)
	end

	Gui:WaitForChild("Padding")
	CloseCrafting()
end