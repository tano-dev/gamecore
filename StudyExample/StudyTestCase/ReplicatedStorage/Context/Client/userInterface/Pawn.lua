--[[
	Evercyan @ March 2023
	Pawn
	
	PawnGuiScript handles code relating to the pawn gui. The code to open up the interface by
	ProximityPrompt is held here as well. It is a tweaked version of the ShopGuiScript, so avoid
	getting confused by the simularity between each other.
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
local CountTotalCopies = require(ReplicatedStorage.Modules.Shared.countTotalCopies)
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
	if not GameConfig.EnabledFeatures.PawnShop then
		return
	end
	
	--> References
	local MainFrame = Gui:WaitForChild("MainFrame")
	local TabButtons = MainFrame:WaitForChild("Content"):WaitForChild("Buttons")
	local TabFrames = MainFrame:WaitForChild("Content"):WaitForChild("Tabs")
	local ExitButton = MainFrame:WaitForChild("ExitButton")
	local PopupFrame = Gui:WaitForChild("PopupFrame")

	local AmountTextBox = PopupFrame:WaitForChild("Content"):WaitForChild("List"):WaitForChild("Amount")
	local SellButton = PopupFrame:WaitForChild("Content"):WaitForChild("List"):WaitForChild("Sell")
	
	--> Variables
	local ItemSlots = {}
	local ActiveTab
	local isOpen = false

	local RequestSellAmount = nil
	
	--------------------------------------------------------------------------------
	
	local ActiveColor = ColorModule:GetBaseColor()

	local function UpdatePopupColor(Color: Color3)
		local Titlebar = PopupFrame:WaitForChild("Titlebar")
		local Primary, Secondary, Background = ColorModule:ConvertToHSV3(Color)

		Titlebar.BackgroundColor3 = Primary
		PopupFrame.ExitButton.TextColor3 = Secondary
		PopupFrame.Content.List.Sell.BackgroundColor3 = Primary
		PopupFrame.Content.List.Sell.TextColor3 = Secondary
		PopupFrame.Content.List.Amount.BackgroundColor3 = Primary
		PopupFrame.Content.List.Amount.PlaceholderColor3 = Secondary:Lerp(Primary, 0.05)
		PopupFrame.Content.List.Amount.TextColor3 = Secondary
		PopupFrame.Content.ItemIcon.BackgroundColor3 = Secondary
		PopupFrame.BackgroundColor3 = Background
		PopupFrame.UIStroke.Color = Background

		return Primary, Secondary, Background
	end

	local function UpdateShopColor(Color: Color3)
		local Titlebar = MainFrame:WaitForChild("Titlebar")
		local Primary, Secondary, Background = ColorModule:ConvertToHSV3(Color)

		ActiveColor.Primary = Primary
		ActiveColor.Secondary = Secondary
		ActiveColor.Background = Background

		Titlebar.BackgroundColor3 = Primary
		Titlebar.TextColor3 = Secondary

		MainFrame.ExitButton.TextColor3 = Secondary
		MainFrame.BackgroundColor3 = Background
		MainFrame.UIStroke.Color = Background

		-- Tab buttons & frames
		for _, Instance in TabButtons.ScrollingFrame:GetChildren() do
			if Instance:IsA("TextButton") then
				local TabFrame = TabFrames[Instance.Name]
				TabFrame.ScrollingFrame.ScrollBarImageColor3 = Primary
				TabFrame.Frame.BackgroundColor3 = Secondary
				
				local _Primary, _Secondary = ColorModule:ConvertToHSV3(GameConfig.Categories[Instance.Text].Color)
				Instance.BackgroundColor3 = ActiveTab == Instance.Name and _Secondary:Lerp(_Primary, 0.3) or _Primary
				Instance.TextColor3 = ActiveTab == Instance.Name and _Primary or _Secondary:Lerp(_Primary, 0.1)
			end
		end

		-- Item slot frames
		for _, Slot in ItemSlots do
			local Frame = Slot.Frame
			
			local CategoryBaseColor = ColorModule:GetPrimaryColor(Slot.Item)
			local Primary, Secondary, Background = ColorModule:ConvertToHSV3(CategoryBaseColor)
			
			Frame.BackgroundColor3 = Secondary:Lerp(Primary, 0.15)
			Frame.BackgroundTransparency = 0
			Frame:WaitForChild("ItemName").TextColor3 = Primary
			Frame:WaitForChild("ItemLevel").TextColor3 = Primary
			Frame:WaitForChild("ItemCost").TextColor3 = Primary
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
			Content.ItemIcon.Label.Image = tonumber(Item.Config.IconId) and `rbxthumb://type=Asset&h=150&w=150&id={Item.Config.IconId}` or Item.Config.IconId
		end

		local ItemInstance = PopupItem.Instance
		local Owned = CountTotalCopies(PopupItem)

		AmountTextBox.PlaceholderText = FormatNumber(math.min(GameConfig.Categories[PopupItem.Type].BulkSellMax, Owned), "Suffix")
		
		local IsStackable = GameConfig.CanItemsStack or GameConfig.Categories[Item.Type].IsStackable
		AmountTextBox.Visible = IsStackable
		
		local itemType = Item.Config.Sell and Item.Config.Sell[1] or Item.Config.Cost and Item.Config.Cost[1]
		local itemName = Item.Config.Sell and Item.Config.Sell[2] or Item.Config.Cost and Item.Config.Cost[2]
		
		local Currency = itemType == "Statistic" and pData.Stats[itemName] or pData.Items[itemType]:FindFirstChild(itemName)
		local Return = Item.Config.Sell and Item.Config.Sell[3] or Item.Config.Cost and math.floor(Item.Config.Cost[3] / 2)

		Content.ItemName.Text = Item.Name
		Content.ItemType.Text = Item.Type
		Content.ItemLevel.Text = `<b>Level</b> {FormatNumber(Item.Config.Level, "Suffix")}`
		
		Content.ItemCost.Text = `+{FormatNumber(Return, "Suffix")} {itemName}`
		Content.ItemCost.TextColor3 = itemType == "Statistic" 
			and ((GameConfig.LeaderstatIcons[Currency.Name] and GameConfig.LeaderstatIcons[Currency.Name].Color) or GameConfig.UIColors.PrimaryColor)
			or (ContentLibrary[itemType][itemName].SpecialColor or GameConfig.Categories[itemType].Color or GameConfig.UIColors.PrimaryColor)

		UpdatePopupInfo(Item, Content)
		
		AmountTextBox.Text = " "
		task.defer(function()
			AmountTextBox.Text = ""
		end)

		SetCanvasGroupVisibility(MainFrame, false)
		SetCanvasGroupVisibility(PopupFrame, true)
	end

	local function ClosePopupFrame()
		PopupItem = nil

		SetCanvasGroupVisibility(MainFrame, true)
		SetCanvasGroupVisibility(PopupFrame, false)
	end

	local function ClearFocus()
		AmountTextBox.Text = ""
		
		local isAvailible = PopupItem and (PopupItem.Config.Sell or PopupItem.Config.Cost)
		if isAvailible then
			local CostPrice = (PopupItem.Config.Sell and PopupItem.Config.Sell[3]) or PopupItem.Config.Cost and math.floor(PopupItem.Config.Cost[3] / 2)
			Content.ItemCost.Text = `+{FormatNumber(CostPrice, "Suffix")} {(PopupItem.Config.Sell or PopupItem.Config.Cost)[2]}`
		elseif not isAvailible then
			Content.ItemCost.Text = "0"
		end
		
		RequestSellAmount = nil
	end

	SellButton.Activated:Connect(function()
		if not PopupItem then 
			return 
		end
		
		local RequestedSellAmount = (GameConfig.CanRequestItemWithNoAmountInput and math.clamp(RequestSellAmount or 1, 1, math.huge))
			or RequestSellAmount
			or not GameConfig.CanItemsStack and not GameConfig.Categories[PopupItem.Type].IsStackable and 1
		
		local OldRequestedSellAmount = RequestedSellAmount
		local OldPopupItem = PopupItem
		
		if not RequestedSellAmount or RequestedSellAmount < 1 or PopupFrame.GroupTransparency == 1 then
			return
		end
		
		local Success, Response = EventModule:InvokeServer("SellItem", OldPopupItem.Type, OldPopupItem.Name, RequestedSellAmount)
		if Success then
			ClearFocus()
			ClosePopupFrame()
			
			local newText = `{OldPopupItem.Name} (x{FormatNumber(OldRequestedSellAmount, "Suffix")}) has been sold!`
			CreateNotification("Pawn Success!", newText, 12900311398)
			SFX:Play2D(GameConfig.SellSFX[1], {Volume = GameConfig.SellSFX[2]})
		else
			CreateNotification("Pawn Failure!", Response, 12900311562)
		end
	end)

	AmountTextBox:GetPropertyChangedSignal("Text"):Connect(function()
		local Text = AmountTextBox.Text
		local Amount = tonumber(Text)
		Amount = Amount and math.floor(Amount)

		if (Text == "" or not Amount or math.abs(Amount) ~= Amount) and not string.find(Text, "e") then
			return ClearFocus()
		end

		local Owned = CountTotalCopies(PopupItem)
		
		if Amount ~= nil then
			if PopupItem and PopupItem.Config.Sell or PopupItem.Config.Cost then
				local CostPrice = (PopupItem.Config.Sell and PopupItem.Config.Sell[3]) or PopupItem.Config.Cost and math.floor(PopupItem.Config.Cost[3] / 2)
				Content.ItemCost.Text = `+{FormatNumber(CostPrice * Amount, "Suffix")} {(PopupItem.Config.Sell or PopupItem.Config.Cost)[2]}`
			end
			
			Amount = math.min(Amount, GameConfig.Categories[PopupItem.Type].BulkSellMax, Owned)
			AmountTextBox.Text = Amount
		end

		RequestSellAmount = Amount
	end)

	PopupFrame:WaitForChild("ExitButton").Activated:Connect(function()
		ClosePopupFrame()
	end)

	---- MAIN FRAME LOGIC ----------------------------------------------------------

	local function OpenTab(TabName: string)
		if ActiveTab == TabName then 
			return 
		end
		
		local TabFrame = TabFrames[TabName]
		local TabButton = TabButtons.ScrollingFrame[TabName]
		ActiveTab = TabName

		for _, Instance in TabFrames:GetChildren() do
			if Instance:IsA("CanvasGroup") then
				SetCanvasGroupVisibility(Instance, Instance == TabFrame and true or false)
			end
		end
		
		TabFrame.Visible = true

		for _, Instance in TabButtons.ScrollingFrame:GetChildren() do
			if Instance:IsA("GuiButton") then
				local _Primary, _Secondary = ColorModule:ConvertToHSV3(GameConfig.Categories[Instance.Text].Color)
				
				Tween:Play(Instance, {0.5, "Exponential"}, {
					BackgroundColor3 = Instance == TabButton and _Secondary:Lerp(_Primary, 0.3) or _Primary,
					TextColor3 = Instance == TabButton and _Primary or _Secondary:Lerp(_Primary, 0.1)
				})
			end
		end
	end

	local function OpenPawn(Shop, ShopConfig)
		isOpen = true

		MainFrame:WaitForChild("Titlebar").Text = ShopConfig.Name
		UpdateShopColor(ShopConfig.Color)

		Gui.Enabled = true
		Gui.Padding.PaddingTop = UDim.new(0, 50)
		
		ClosePopupFrame()
		SetCanvasGroupVisibility(MainFrame, true)
		
		Tween:Play(Gui.Padding, {0.3, "Back", "Out"}, {PaddingTop = UDim.new()})
	end

	local function ClosePawn()
		isOpen = false

		ClosePopupFrame()
		SetCanvasGroupVisibility(MainFrame, false)
		
		Tween:Play(Gui.Padding, {0.2, "Back", "In"}, {PaddingTop = UDim.new(0, 50)})
		
		return true
	end
	
	local function RequestCheck()
		return isOpen
	end

	local function PerPawn(Pawn: Model)
		NPCFunctions:CreateProximityPrompt(Pawn, RequestCheck, ExitButton.Activated, ClosePawn, OpenPawn)
		NPCFunctions:CreateDialogue(Pawn)
		NPCFunctions:AnimateNPC(Pawn)
	end

	CollectionService:GetInstanceAddedSignal("SellShop"):Connect(PerPawn)
	for _, Pawn in CollectionService:GetTagged("SellShop") do
		task.spawn(PerPawn, Pawn)
	end

	-- Init

	for ItemType, Items in ContentLibrary do
		local TabFrame = script:WaitForChild("TabFrame"):Clone()
		TabFrame.Name = ItemType
		TabFrame.Visible = true
		TabFrame.Parent = TabFrames

		local TabButton = script:WaitForChild("TabButton"):Clone()
		TabButton.Name = ItemType
		TabButton.Text = ItemType
		TabButton.Visible = true
		TabButton.Parent = TabButtons:WaitForChild("ScrollingFrame")
		TabButton.LayoutOrder = GameConfig.Categories[ItemType].LayoutOrder

		-- Switch Tab logic
		TabButton.Activated:Connect(function()
			OpenTab(ItemType)
		end)

		-- Setup all item slots
		for _, Item in Items do
			if not Item.Config.Sell and (not Item.Config.Cost or not GameConfig.SellShopItems) then 
				continue 
			end

			local Return = Item.Config.Sell and Item.Config.Sell[3] or Item.Config.Cost and math.floor(Item.Config.Cost[3] / 2)
			if not Return then
				continue
			end

			local Frame = script.SlotTemplate:Clone()
			Frame.Name = Item.Name
			Frame.ItemName.Text = Item.Name
			Frame.ItemLevel.Text = ` <b>Lv.</b> {FormatNumber(Item.Config.Level, "Suffix")}`
			Frame.ItemCost.Text = `+{FormatNumber(Return, "Suffix")} <b>{Item.Config.Sell and Item.Config.Sell[2] or Item.Config.Cost[2]}</b>`
			Frame.Visible = ItemsFolder[ItemType]:FindFirstChild(Item.Name) ~= nil
			Frame.Parent = TabFrame.ScrollingFrame

			local ItemIcon = (tonumber(Item.Config.IconId) and `rbxassetid://{Item.Config.IconId}`) 
				or typeof(Item.Config.IconId) == "string" and Item.Config.IconId 
				or Item.Instance:IsA("Tool") and (Item.Instance.TextureId ~= "" and Item.Instance.TextureId)
			
			if ItemIcon then
				Frame.ItemIcon.Image = ItemIcon
			end
			
			Frame.ItemIcon.Visible = (ItemIcon and true) or false

			Frame.Activated:Connect(function()
				OpenPopupFrame(Item)
			end)

			ItemSlots[Item.Name] = {
				Item = Item,
				Frame = Frame
			}
		end
		
		TabFrame.ScrollingFrame.CanvasSize = UDim2.fromOffset(0, TabFrame.ScrollingFrame.UIListLayout.AbsoluteContentSize.Y)

		-- Sort all slots by level
		local Sorted = {}
		for _, Slot in ItemSlots do
			table.insert(Sorted, Slot)
		end
		table.sort(Sorted, function(A, B)
			return A.Item.Config.Level < B.Item.Config.Level
		end)
		for LayoutOrder, Slot in Sorted do
			Slot.Frame.LayoutOrder = LayoutOrder
		end

		-- Show/hide slots from pawn when gained/lost
		ItemsFolder:WaitForChild(ItemType).ChildAdded:Connect(function(ValueObject)
			local Slot = ItemSlots[ValueObject.Name]
			if not Slot then
				return
			end

			Slot.Frame.Visible = true
			TabFrame.NoItemsWarning.Visible = false
		end)
		
		ItemsFolder:WaitForChild(ItemType).ChildRemoved:Connect(function(ValueObject)
			local Slot = ItemSlots[ValueObject.Name]
			if not Slot then
				return
			end

			task.defer(function()
				local Owned = CountTotalCopies({Name = ValueObject.Name})
				if Owned > 0 then
					return
				end

				Slot.Frame.Visible = false
				TabFrame.NoItemsWarning.Visible = true
				
				for _, Slot in ItemSlots do
					if Slot.Item.Type == ItemType and Slot.Frame.Visible then
						TabFrame.NoItemsWarning.Visible = false
						break
					end
				end
			end)
		end)

		TabFrame.NoItemsWarning.Visible = true
		for _, Slot in ItemSlots do
			if Slot.Item.Type == ItemType and Slot.Frame.Visible then
				TabFrame.NoItemsWarning.Visible = false
				break
			end
		end
	end

	-------------------------------

	Gui:WaitForChild("Padding")
	TabButtons:WaitForChild("ScrollingFrame")

	OpenTab("Tool")
	ClosePawn()
end