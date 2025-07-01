--[[
	ej0w @ September 2024
	Attributes
	
	Regarding customizing the displays for attribute data (e.g. strength %), refer to DynamicStatFunctions
	Customize the descriptions, display, and name of attributes in GameConfig
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer
local pData = ReplicatedStorage:WaitForChild("PlayerData"):WaitForChild(Player.UserId)

local AttributesFolder = pData:WaitForChild("Attributes")
local PointsValue = pData:WaitForChild("Points")

--> Dependencies
local ContentLibrary = require(ReplicatedStorage.Modules.Shared.ContentLibrary)
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)
local ColorModule = require(ReplicatedStorage.Modules.Shared.Color)
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)

local DynamicStatFunctions = require(ReplicatedStorage.Modules.Client.DynamicStatFunctions)
local CreateNotification = require(ReplicatedStorage.Modules.Client.createNotification)
local SetCanvasGroupVisibility = require(ReplicatedStorage.Modules.Client.setCanvasGroupVisibility)

local GameConfig = require(ReplicatedStorage.GameConfig)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return function(Gui)
	if not GameConfig.EnabledFeatures.Attributes then
		return
	end
	
	--> References
	local PopupFrame = Gui:WaitForChild("PopupFrame")

	local MainFrame = Gui:WaitForChild("MainFrame")
	local ExitButton = MainFrame:WaitForChild("ExitButton")
	local Titlebar = MainFrame:WaitForChild("Titlebar")

	local Content = MainFrame:WaitForChild("Content")
	local Header = Content:WaitForChild("Header")
	local List = Content:WaitForChild("List")
	local Scaling = Content:WaitForChild("Scaling")
	local Sidebar = Content:WaitForChild("Sidebar")

	local AmountTextBox = List:WaitForChild("Amount")
	
	--> Variables
	local Primary, Secondary, Background = ColorModule:ConvertToHSV3(GameConfig.FrameColors.Attributes)
	
	local AttributeTab = ""
	local RequestedPoints = 0

	local Connections = {}
	local TabButtons = {}
	
	--------------------------------------------------------------------------------
	
	local function OpenPopupFrame()
		SetCanvasGroupVisibility(MainFrame, false)
		SetCanvasGroupVisibility(PopupFrame, true)
	end

	local function ClosePopupFrame()
		SetCanvasGroupVisibility(MainFrame, true)
		SetCanvasGroupVisibility(PopupFrame, false)
	end
	
	PopupFrame:WaitForChild("Content").Confirm.Activated:Connect(function()
		local CurrentPoints = PointsValue.Value
		local Success, Response = EventModule:InvokeServer("ResetAttributes")
		if Success then
			ClosePopupFrame()

			local Difference = PointsValue.Value - CurrentPoints
			CreateNotification("Reset Success!", `Reset {FormatNumber(Difference, "Suffix")} points.`, 12900311398)
		else
			CreateNotification("Reset Failure!", Response, 12900311562)
		end
	end)
	PopupFrame:WaitForChild("ExitButton").Activated:Connect(function()
		ClosePopupFrame()
	end)

	Sidebar:WaitForChild("Confirm").Activated:Connect(function()
		OpenPopupFrame()
	end)

	---- ATTRIBUTE LOGIC ---------------------------------------------------------

	local function ChangeAmountText(Amount)
		Content.Cost.Text = `Costs <b>{FormatNumber(math.abs(Amount), "Suffix")}</b> Points`
	end

	local function SelectedAttributeTab(Attribute)
		AttributeTab = Attribute

		for _, Connection in Connections do
			Connection:Disconnect()
			Connection = nil
		end
		Connections = {}

		for Label, Button in TabButtons do
			local Activated = Label == Attribute
			Tween:Play(Button, {0.2, "Exponential"}, {
				BackgroundColor3 = Activated and Secondary or Primary,
				TextColor3 = Activated and Primary or Secondary
			})
		end

		Header.Title.Text = `<b>{Attribute}</b>`

		local function AttributePointsChanged()
			local Allocated = AttributesFolder[Attribute].Value
			Header.Spent.Text = ` <b>{FormatNumber(Allocated, "Suffix")}</b> Points`
			Content.Description.Text = GameConfig.Attributes[Attribute].Description

			local IsMaxed = Allocated >= GameConfig.Attributes[Attribute].MaxAllocated
			if IsMaxed then
				List.Confirm.BackgroundTransparency = 0.3
				List.Confirm.BackgroundColor3 = Secondary
				List.Confirm.TextColor3 = Primary
				List.Amount.Visible = false
				List.Confirm.AutoButtonColor = false
				List.Confirm.Active = false
				List.Confirm.Interactable = false
				List.Confirm.Text = "Max"
				Content.Cost.Visible = false
				Scaling.Background.Visible = false
			elseif not IsMaxed then
				List.Confirm.BackgroundTransparency = 0.15
				List.Confirm.BackgroundColor3 = Primary
				List.Confirm.TextColor3 = Secondary
				List.Amount.Visible = true
				List.Confirm.AutoButtonColor = true
				List.Confirm.Active = true
				List.Confirm.Interactable = true
				List.Confirm.Text = "Confirm"
				Content.Cost.Visible = true
				Scaling.Background.Visible = true
			end

			local Callback = DynamicStatFunctions[Attribute]
			if Callback then
				Callback(nil, Content.Description)
			end
		end

		Connections[#Connections+1] = AttributesFolder[Attribute].Changed:Connect(AttributePointsChanged)
		AttributePointsChanged()

		AmountTextBox.Text = ""
		RequestedPoints = 0
		ChangeAmountText(RequestedPoints)
	end

	local function ClearFocus()
		AmountTextBox.Text = ""
		RequestedPoints = 0
		ChangeAmountText(RequestedPoints)
	end

	AmountTextBox:GetPropertyChangedSignal("Text"):Connect(function()
		local Text = AmountTextBox.Text
		local Amount = tonumber(Text)
		Amount = Amount and math.floor(Amount)

		if (Text == "" or not Amount or math.abs(Amount) ~= Amount) and not string.find(Text, "e") then
			return ClearFocus()
		end

		if Amount ~= nil then
			Amount = math.clamp(Amount, 0, PointsValue.Value)
			AmountTextBox.Text = Amount
			ChangeAmountText(Amount)
		end

		RequestedPoints = Amount
	end)

	List:WaitForChild("Confirm").Activated:Connect(function()
		local CurrentTab = AttributeTab

		local CurrentAllocated = RequestedPoints
		if CurrentAllocated == nil or CurrentAllocated < 1 then
			return
		end
		
		local Success, Response = EventModule:InvokeServer("AllocatePoints", CurrentTab, CurrentAllocated)
		if Success then
			ClearFocus()
			CreateNotification("Allocate Success!", `Allocated {FormatNumber(CurrentAllocated, "Suffix")} point(s) to {CurrentTab}.`, 12900311398)
		else
			CreateNotification("Allocate Failure!", Response, 12900311562)
		end
	end)

	local function PointsValueChanged()
		Sidebar.Left.Text = `<b>{FormatNumber(PointsValue.Value, "Suffix")}</b> Point(s) left`
	end

	PointsValueChanged()
	PointsValue.Changed:Connect(PointsValueChanged)

	---- MAIN FRAME LOGIC ----------------------------------------------------------

	-- Update attributes color
	Titlebar.BackgroundColor3 = Primary
	Titlebar.TextColor3 = Secondary

	MainFrame.ExitButton.TextColor3 = Secondary
	MainFrame.BackgroundColor3 = Background
	MainFrame.UIStroke.Color = Background

	Sidebar.Confirm.BackgroundColor3 = Primary
	Sidebar.Confirm.TextColor3 = Secondary
	Scaling.BackgroundColor3 = Background
	Scaling.Background.BackgroundColor3 = Background

	List.Amount.BackgroundColor3 = Primary
	List.Amount.TextColor3 = Secondary
	List.Amount.PlaceholderColor3 = Secondary:Lerp(Primary, 0.05)
	List.Confirm.BackgroundColor3 = Primary
	List.Confirm.TextColor3 = Secondary

	PopupFrame.Titlebar.BackgroundColor3 = Primary
	PopupFrame.ExitButton.TextColor3 = Secondary
	PopupFrame.Content.Confirm.BackgroundColor3 = Primary
	PopupFrame.Content.Confirm.TextColor3 = Secondary
	PopupFrame.BackgroundColor3 = Background
	PopupFrame.UIStroke.Color = Background

	-- Add tab buttons
	for Attribute, Data in GameConfig.Attributes do
		local Frame = script.TabButton:Clone()
		Frame.Parent = Sidebar:WaitForChild("ScrollingFrame")
		Frame.Name = Attribute
		Frame.Text = Attribute
		Frame.LayoutOrder = Data.LayoutOrder
		Frame.BackgroundColor3 = Primary
		Frame.TextColor3 = Secondary
		Frame.Visible = true

		Frame.Activated:Connect(function()
			SelectedAttributeTab(Attribute)
		end)

		TabButtons[Attribute] = Frame
	end

	local FirstOrder = nil
	for Name, Data in GameConfig.Attributes do
		if not FirstOrder then
			FirstOrder = Name
		elseif Data.LayoutOrder < GameConfig.Attributes[FirstOrder].LayoutOrder then
			FirstOrder = Name
		end
	end

	SelectedAttributeTab(FirstOrder)
	
	if GameConfig.ScaleAttributesUI then
		local function UpdateScale()
			task.defer(function()
				local Children = Sidebar:GetChildren()
				local AbsoluteSize = Sidebar.UIListLayout.Padding.Offset * (#Children - 1)
				for _, UI: GuiObject in Children do
					if not UI:IsA("UIListLayout") then
						AbsoluteSize += UI.AbsoluteSize.Y
					end
				end		
				Scaling.Size = UDim2.fromOffset(150, (AbsoluteSize / Gui.UIScale.Scale) + (10 * Gui.UIScale.Scale))
			end)
		end

		UpdateScale()
		Sidebar:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateScale)
		Sidebar.ScrollingFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(UpdateScale)
	end
end