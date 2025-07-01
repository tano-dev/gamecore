--[[
	ej0w @ October 2025
	Quest
	
	Handles NPC dialogue & quests & quest inventory
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer

local pData = ReplicatedStorage:WaitForChild("PlayerData"):WaitForChild(Player.UserId)

local StatsFolder = pData:WaitForChild("Stats")
local Level = StatsFolder:WaitForChild("Level")

local ItemsFolder = pData:WaitForChild("Items")
local Quests = pData:WaitForChild("Quests")

--> References
local CurrentCamera = workspace.CurrentCamera

--> Dependencies
local ContentLibrary = require(ReplicatedStorage.Modules.Shared.ContentLibrary)
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)
local ColorModule = require(ReplicatedStorage.Modules.Shared.Color)
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)

local RbxUtility = require(ReplicatedStorage.Modules.Shared.RbxUtility)

local UpdatePopupInfo = require(ReplicatedStorage.Modules.Client.updatePopupInfo)
local CreateNotification = require(ReplicatedStorage.Modules.Client.createNotification)
local SetTooltipListener = require(ReplicatedStorage.Modules.Client.setTooltipListener)

local SetCanvasGroupVisibility = require(ReplicatedStorage.Modules.Client.setCanvasGroupVisibility)
local WaitForDescendant = require(ReplicatedStorage.Modules.Client.waitForDescendant)

local GetQuestProgress = require(ReplicatedStorage.Modules.Shared.getQuestProgress)
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)
local QuestLibrary = require(ReplicatedStorage.Modules.Shared.QuestLibrary)

local StartPinFunction = require(ReplicatedStorage.Modules.Client.startPinFunction)
local TweenCFrame = require(ReplicatedStorage.Modules.Client.tweenCFrame)
local NPCFunctions = require(ReplicatedStorage.Modules.Client.NPCFunctions)

local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local OriginTweenInfo = TweenInfo.new(0.65, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return function()
	if not GameConfig.EnabledFeatures.Quests then
		return
	end
	
	--> References
	local PlayerGui = Player.PlayerGui
	
	local DialogueGui = PlayerGui:WaitForChild("Dialogue")
	local QuestGui = PlayerGui:WaitForChild("Quest")
	
	local PinGui = PlayerGui:WaitForChild("Pin")
	local QuestPinFrame = PinGui:WaitForChild("Quest")
	
	local QuestScroller = QuestGui:WaitForChild("MainFrame"):WaitForChild("Content"):WaitForChild("ScrollingFrame")

	local Canvas = DialogueGui:WaitForChild("Canvas")

	local ExitButton = Canvas:WaitForChild("Title"):WaitForChild("ExitButton")
	local Continue = Canvas:WaitForChild("Continue")
	local Display = Canvas.Description.Display
	
	local PopupBackground = QuestPinFrame.PopupBackground
	local PopupScroller = PopupBackground.Background.ScrollingFrame
	
	--> Variables
	local Primary, Secondary, Background = ColorModule:ConvertToHSV3(GameConfig.FrameColors.Quests)
	
	---- Pin system ----------------------------------------------------------
	
	local PinThread = nil
	local PinQuest = nil

	local PinConnections = {}
	local PinUpdateTime = os.clock()
	
	local function ClosePinFrame()
		if PinThread ~= nil then
			task.cancel(PinThread)
			PinThread = nil
		end

		local Clock = os.clock()
		PinUpdateTime = Clock

		PinQuest = nil

		SetCanvasGroupVisibility(QuestPinFrame, false)
	end

	local function OpenPinFrame(QuestName, Data)
		if PinQuest ~= nil then
			ClosePinFrame()
		end
		
		PinQuest = QuestName
		
		if PinThread ~= nil then
			task.cancel(PinThread)
			PinThread = nil
		end
		
		local Clock = os.clock()
		PinUpdateTime = Clock

		for _, Connection in PinConnections do
			Connection:Disconnect()
			Connection = nil
		end
		
		-- Initialize & setup the pin
		local function RemoveItems(Parent, Callback)
			for _, Frame in Parent:GetChildren() do
				if Frame:IsA("Frame") or Frame:IsA("TextLabel") then
					task.spawn(Callback, Frame)
				end
			end
			
			Parent.Parent.Visible = false
		end
		
		PopupBackground.Background.Fill.UIGradient.Offset = Vector2.zero
		
		-- I physically cannot make this look clean
		RemoveItems(PopupScroller.Mobs.Items, function(Frame)
			Frame:Destroy()
		end)

		RemoveItems(PopupScroller.Objectives.Items, function(Frame)
			Frame:Destroy()
		end)

		RemoveItems(PopupScroller.Statistics.Items, function(Frame)
			Frame.Visible = false
		end)
		
		PopupBackground.Title.Display.Text = QuestName
		
		local Mouse = UserInputService:GetMouseLocation()
		QuestPinFrame.Position = UDim2.fromOffset(Mouse.X + 15, Mouse.Y - 25)
		QuestPinFrame.Size = UDim2.fromOffset(263, math.min(CurrentCamera.ViewportSize.Y / 2, 321))
		
		-- Update loop to check pin progress & individual item charter
		local Slots = {}
		Slots.Objectives = {}
		Slots.Mobs = {}
		
		local function CheckPinProgress()
			local QuestProgress, AllItems, QuestRequirements = GetQuestProgress(QuestName)
			if not AllItems then
				return
			end
			
			local CurrentQuest = pData.Quests.Active:FindFirstChild(QuestName)
			
			local ObjectivesCount = 0
			local StatisticsCount = 0
			local MobsCount = 0
			
			for Name, Value in (AllItems.Statistics or {}) do
				local Requirements = QuestRequirements.Statistics[Name]
				local Statistic = pData.Stats:FindFirstChild(Name)
				
				local Slot = PopupScroller.Statistics.Items:FindFirstChild(Name)
				if Slot then
					Slot.StatCount.Text = `{FormatNumber(Statistic.Value, "Suffix")}/<b>{FormatNumber(Requirements, "Suffix")}</b> {Name}`

					Slot.StatCount.TextTransparency = (Value == true and 0.5) or 0
					Slot.StatIcon.ImageTransparency = (Value == true and 0.5) or 0

					Slot.Visible = true

					StatisticsCount += 1
				else
					warn(`[KIT: Leaderstat slot for Quest Pin UI, named {Name} doesn't exist: please add it!]`)
				end
			end
			
			for Name, Value in (AllItems.Mobs or {}) do
				local Requirements = QuestRequirements.Mobs[Name]
				
				local Slot = Slots.Mobs[Name]
				if not Slot then
					local NewSlot = script.PinMob:Clone()
					NewSlot.Name = Name
					
					NewSlot.Visible = true
					NewSlot.Parent = PopupScroller.Mobs.Items
					
					Slot = NewSlot
					Slots.Mobs[Name] = NewSlot
				end
				
				local MobValue = CurrentQuest:FindFirstChild("Mobs") and CurrentQuest.Mobs:FindFirstChild(Name)
				local NewValue = (MobValue and MobValue.Value) or 0
				
				Slot.StatCount.Text = `Kill {FormatNumber(NewValue, "Suffix")}/<b>{FormatNumber(Requirements, "Suffix")}</b> '{Name}'`
				
				Slot.StatCount.TextTransparency = (Value == true and 0.5) or 0
				Slot.StatIcon.ImageTransparency = (Value == true and 0.5) or 0
				
				MobsCount += 1
			end
			
			for Name, Value in (AllItems.Objectives or {}) do
				local Slot = Slots.Objectives[Name]
				
				if not Slot then
					local NewSlot = script.PinObjective:Clone()
					NewSlot.Name = "Objective"
					NewSlot.Text = `{Name}`

					NewSlot.Visible = true
					NewSlot.Parent = PopupScroller.Objectives.Items
					
					Slot = NewSlot
					Slots.Objectives[Name] = NewSlot
				end
				
				Slot.TextTransparency = (Value == true and 0.5) or 0
				
				ObjectivesCount += 1
			end
			
			PopupScroller.Objectives.Visible = ObjectivesCount > 0
			PopupScroller.Statistics.Visible = StatisticsCount > 0
			PopupScroller.Mobs.Visible = MobsCount > 0
			
			Tween:Play(PopupBackground.Background.Fill.UIGradient, {0.5, "Circular"}, {Offset = Vector2.new(QuestProgress, 0)})
			PopupBackground.Background.Percentage.Text = `{math.round(QuestProgress * 100)}%`
		end
		
		PinThread = task.spawn(function()
			while PinUpdateTime == Clock do
				CheckPinProgress()
				
				task.wait(1 / 10)
			end
		end)
		
		PinGui.Enabled = true
		QuestPinFrame.UIScale.Scale = 0.75
		
		CheckPinProgress()
		SetCanvasGroupVisibility(QuestPinFrame, true)
		
		Tween:Play(QuestPinFrame.UIScale, {0.3, "Back", "Out"}, {Scale = 1})
	end
	
	-- Create leaderstat display
	for Name, Leaderstat in GameConfig.Leaderstats do
		local Stat = PopupScroller.Statistics.Items.Template:Clone()
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
		Stat.Parent = PopupScroller.Statistics.Items
	end

	QuestPinFrame.PopupBackground.Title.ExitButton.Activated:Connect(ClosePinFrame)
	ClosePinFrame()
	
	StartPinFunction(QuestPinFrame)
	
	---- Quest inventory system ----------------------------------------------------------
	
	local QuestSlots = {}
	
	local function UpdateQuestProgress(Name, Slot)
		local QuestProgress = GetQuestProgress(Name)
		Slot.Percentage.Text = `{math.round(QuestProgress * 100)}%`
		
		Tween:Play(Slot.Fill.UIGradient, {0.5, "Circular"}, {Offset = Vector2.new(QuestProgress, 0)})
		
		local IsCompleted = QuestProgress >= 1
		Slot.Buttons.Finish.AutoButtonColor = IsCompleted
		Slot.Buttons.Finish.BackgroundTransparency = (IsCompleted and 0.25) or 0.5
		
		return QuestProgress
	end
	
	local function UpdateQuestUIDisplay()
		local Visible = 0
		for _, Frame in QuestScroller:GetChildren() do
			if Frame:IsA("GuiObject") and Frame.Visible == true then
				Visible += 1
			end
		end

		QuestGui.MainFrame.NoItemsWarning.Visible = (Visible == 0)
	end
	
	local function RequestActiveQuestAdded(QuestFolder: Folder)
		local Slot = script.SlotTemplate:Clone()
		Slot.Name = QuestFolder.Name
		
		-- Update slot color
		Slot.BG.BackgroundColor3 = Secondary
		Slot.Fill.BackgroundColor3 = Primary
		
		Slot.Buttons.Finish.BackgroundColor3 = Primary
		Slot.Buttons.Finish.ImageLabel.ImageColor3 = Secondary
		
		Slot.Buttons.Exit.BackgroundColor3 = Primary
		Slot.Buttons.Exit.ImageLabel.ImageColor3 = Secondary
		
		Slot.Pin.BackgroundColor3 = Primary
		Slot.Pin.ImageLabel.ImageColor3 = Secondary
		
		Slot.Label.ImageColor3 = Primary
		Slot.Display.TextColor3 = Primary
		Slot.Percentage.TextColor3 = Primary
		
		Slot.Fill.UIGradient.Offset = Vector2.zero
		
		-- Update slot information & initialize
		local QuestData = QuestLibrary[QuestFolder.Name]
		UpdateQuestProgress(QuestFolder.Name, Slot)
		
		Slot.Display.Text = QuestFolder.Name 
		
		Slot.Visible = true
		Slot.Parent = QuestScroller
		
		-- Finalize slot
		QuestFolder.AncestryChanged:Connect(function(Child, Parent)
			if Parent == nil then
				if PinQuest == QuestFolder.Name then
					ClosePinFrame()
				end
				
				QuestSlots[QuestFolder.Name] = nil
				Slot:Destroy()
				
				task.defer(UpdateQuestUIDisplay)
			end
		end)
		
		Slot.Pin.Activated:Connect(function()
			OpenPinFrame(QuestFolder.Name, QuestData)
		end)
		
		-- Quest claiming
		local function RequestCompleteQuest()
			local QuestProgress = GetQuestProgress(QuestFolder.Name)
			if QuestProgress and QuestProgress >= 1 then
				EventModule:InvokeServer("QuestComplete", QuestFolder.Name)
			end
		end
		
		local isAutoclaimable = GameConfig.AutoCompleteQuests
		if isAutoclaimable then
			task.spawn(function()
				while QuestFolder.Parent ~= nil do
					RequestCompleteQuest()
					
					task.wait(GameConfig.QuestRefresh)
				end
			end)
		elseif not isAutoclaimable then
			Slot.Buttons.Finish.Activated:Connect(RequestCompleteQuest)
		end
		
		Slot.Buttons.Exit.Activated:Connect(function()
			EventModule:FireServer("ExitQuest", QuestFolder.Name)
		end)
		
		Slot.Buttons.Finish.Visible = not isAutoclaimable
		
		-- Return
		QuestSlots[QuestFolder.Name] = {
			Frame = Slot,
			Data = QuestData,
		}
		
		task.spawn(UpdateQuestUIDisplay)
		return Slot
	end

	for _, Quest in Quests.Active:GetChildren() do
		task.spawn(RequestActiveQuestAdded, Quest)
	end
	
	Quests.Active.ChildAdded:Connect(RequestActiveQuestAdded)
	
	-- Loop to cycle through %'s and activated button cuz im too lazy to spam connections :3
	local function CyclePerSlot(Name, Slot)
		UpdateQuestProgress(Name, Slot.Frame)
	end
	
	task.spawn(function()
		while true do
			for Name, Slot in QuestSlots do
				task.spawn(CyclePerSlot, Name, Slot)
			end
			
			task.wait(GameConfig.DefaultClientRefresh)
		end
	end)
	
	---- Quest position markers ----------------------------------------------------------
	
	local QuestPositions = {}
	
	RunService:BindToRenderStep("QuestMarkerDistanceUpdate", Enum.RenderPriority.Character.Value + 10, function()
		local Character = Player.Character
		
		local RootPart = Character and Character:FindFirstChild("HumanoidRootPart")
		if RootPart then
			for _, Marker in QuestPositions do
				local Distance = (RootPart.Position - Marker.Position).Magnitude
				
				Marker.Billboard.Enabled = Distance > 50
				Marker.Billboard.Distance.Text = FormatNumber(math.round(Distance), "Suffix") .. " studs"
			end
		end
	end)
	
	local function RequestNewQuestMarker(QuestFolder)
		if QuestPositions[QuestFolder.Name] then
			return
		end
		
		local QuestData = QuestLibrary[QuestFolder.Name]
		if QuestData and QuestData.Position then
			local QuestMarker = ReplicatedStorage.Assets.Scripts.QuestPosition:Clone()
			QuestMarker.Name = QuestFolder.Name
			
			QuestMarker.QuestBillboard.Canvas.Display.Text = QuestFolder.Name
			QuestMarker.QuestBillboard.Canvas.GroupColor3 = Primary
			
			QuestMarker.Position = QuestData.Position
			QuestMarker.Parent = workspace.Map.Client
			
			QuestPositions[QuestFolder.Name] = {Position = QuestData.Position, Billboard = QuestMarker.QuestBillboard}
		end
	end
	
	local function RemoveQuestMarker(QuestFolder)
		local Marker = QuestPositions[QuestFolder.Name]
		if Marker and Marker.Billboard.Parent then
			Marker.Billboard.Parent:Destroy()
		end
		
		QuestPositions[QuestFolder.Name] = nil
	end
	
	for _, Quest in Quests.Active:GetChildren() do
		task.spawn(RequestNewQuestMarker, Quest)
	end

	Quests.Active.ChildAdded:Connect(RequestNewQuestMarker)
	Quests.Active.ChildRemoved:Connect(RemoveQuestMarker)
	
	---- Dialogue / NPC system ----------------------------------------------------------
	
	local CancelDialogue = Instance.new("BindableEvent")
	
	local CurrentNPC = nil
	local OriginNeckC0 = nil
	local TargetedQuest = nil
	local CurrentConfig = nil
	local LastTalkedNPC = nil
	local FocusRenderStepped = nil
	local OriginCFrameRotation = nil
	
	local isOpen = false
	local CanCycle = true
	
	local DialogueIndex = 1
	
	local NPCGoBackTweens = {}
	
	local function StopDialogue(NPC)
		isOpen = false
		CurrentConfig = nil
		
		if OriginCFrameRotation and CurrentNPC then
			local HumanoidRootPart = CurrentNPC:FindFirstChild("HumanoidRootPart")
			local Neck = CurrentNPC:FindFirstChild("Neck", true)
			
			if Neck and HumanoidRootPart then
				local NeckConnection = TweenCFrame(Neck, OriginTweenInfo, OriginNeckC0)
				local RootPartConnection = TweenCFrame(HumanoidRootPart, OriginTweenInfo, CFrame.new(HumanoidRootPart.Position) * OriginCFrameRotation)
				
				table.insert(NPCGoBackTweens[CurrentNPC], NeckConnection)
				table.insert(NPCGoBackTweens[CurrentNPC], RootPartConnection)
			end
		end
		
		if FocusRenderStepped then
			RunService:UnbindFromRenderStep(FocusRenderStepped)
			FocusRenderStepped = nil
		end
		
		OriginCFrameRotation = nil
		CurrentNPC = nil
		
		SetCanvasGroupVisibility(Canvas, false)
		Tween:Play(DialogueGui.Padding, {0.2, "Back", "In"}, {PaddingBottom = UDim.new(0, 25)})
		
		return LastTalkedNPC == NPC
	end
	
	local function HideActivatedGUIButton()
		Continue.BackgroundTransparency = 0.3
		Continue.AutoButtonColor = false
	end
	
	local function CycleDialogueText(Locked, ForcedDialogue)
		if Locked then
			HideActivatedGUIButton()
		end

		Display.MaxVisibleGraphemes = 0
		
		Display.Text = ForcedDialogue
			or TargetedQuest.Dialogues[DialogueIndex]
			or "n/a"

		Tween:Play(Display, {0.5, "Circular"}, {MaxVisibleGraphemes = utf8.len(Display.Text)})
	end
	
	local function StartDialogue(NPC, Config)
		isOpen = true
		CanCycle = true
		
		LastTalkedNPC = NPC
		CurrentConfig = Config
		DialogueIndex = 1
		
		CurrentNPC = NPC
		
		if NPCGoBackTweens[NPC] then
			for _, Connection in NPCGoBackTweens[NPC] do
				Connection:Disconnect()
			end
		end
		
		NPCGoBackTweens[NPC] = {}
		
		-- UI
		Continue.BackgroundTransparency = 0.15
		Continue.AutoButtonColor = true
		Display.MaxVisibleGraphemes = 0
		Canvas.Title.Display.Text = Config.Name
		
		local isQuest = (Config.QuestOffers and true) or false
		Canvas.Title.Quest.Visible = isQuest
		
		-- Set default values for pivoting
		local Character = Player.Character or Player.CharacterAdded:Wait()
		
		local RootPart = Character:WaitForChild("HumanoidRootPart")
		local CharHead = Character:WaitForChild("Head")
		
		local HumanoidRootPart = NPC:FindFirstChild("HumanoidRootPart")
		local Head = NPC:FindFirstChild("Head")
		
		local Torso = NPC:FindFirstChild("Torso")
		local Neck = Torso and Torso:FindFirstChild("Neck") :: Motor6D
		
		OriginNeckC0 = Neck and (AttributeModule:GetAttribute(NPC, "OriginNeck") or Neck.C0)
		AttributeModule:SetAttribute(NPC, "OriginNeck", OriginNeckC0)
		
		OriginCFrameRotation = HumanoidRootPart and (AttributeModule:GetAttribute(NPC, "OriginRotation") or HumanoidRootPart:GetPivot().Rotation)
		AttributeModule:SetAttribute(NPC, "OriginRotation", OriginCFrameRotation)
		
		-- Check for next dialogue
		local PreviousName = nil
		local ForcedDialogue = nil
		
		local ChosenDialogue = 1
		
		if isQuest then
			local AllQuests = {}
			for Iteration, Data in Config.QuestOffers do
				AllQuests[Data.Name] = true

				if PreviousName and not Quests.Completed:FindFirstChild(PreviousName) then
					break
				end

				if not Quests.Completed:FindFirstChild(Data.Name) then
					ChosenDialogue = Iteration
				end

				PreviousName = Data.Name
			end

			-- Exceptions for dialogue
			for _, Active in Quests.Active:GetChildren() do
				if AllQuests[Active.Name] then
					ForcedDialogue = Config.AlreadyTakenDialogue
					CanCycle = false
				end
			end
		end
		
		local NewData = isQuest and Config.QuestOffers[ChosenDialogue]
		
		if not isQuest or NewData then
			if isQuest and Quests.Completed:FindFirstChild(NewData.Name) then
				ForcedDialogue = Config.NoMoreQuestsDialogue
				CanCycle = false
			elseif isQuest and (Level.Value < NewData.Level) then
				ForcedDialogue = string.format(Config.TooLowLevelDialogue, FormatNumber(NewData.Level, "Suffix"))
				CanCycle = false
			end
			
			local isLocked = not CanCycle
			if not isLocked then
				TargetedQuest = (isQuest and NewData) or Config
			end

			CycleDialogueText(isLocked, ForcedDialogue)
			
			if not FocusRenderStepped then
				local function UpdateCFrame()
					if HumanoidRootPart then
						local OriginPivot = HumanoidRootPart:GetPivot()
						local NewPivot = CFrame.lookAt(HumanoidRootPart.Position, RootPart.Position * Vector3.new(1, 0, 1) + HumanoidRootPart.Position * Vector3.new(0, 1, 0))

						HumanoidRootPart:PivotTo(OriginPivot:Lerp(NewPivot, 0.03))
					end
					
					if Neck and HumanoidRootPart then
						local CameraDirection = (CFrame.new(HumanoidRootPart.Position, RootPart.Position):inverse() * HumanoidRootPart.CFrame).LookVector * -1
						local CameraDirectionY = math.clamp(math.asin(CameraDirection.Y), -0.75, 0.75)

						local Goal = CFrame.new(0, Neck.C0.Y, 0) * CFrame.Angles(0, -math.asin(CameraDirection.X), 0) * CFrame.Angles(CameraDirectionY, 0, 0)
						Neck.C0 = Neck.C0:Lerp(Goal * CFrame.Angles(math.rad(90), math.rad(180), 0), 0.03)
					end
				end
				
				RunService:BindToRenderStep(Config.Name, Enum.RenderPriority.Character.Value - 10, UpdateCFrame)
				FocusRenderStepped = Config.Name
			end
		else
			warn("Quest/Dialogue: Something went wrong when trying to find dialogue for " .. Config.Name .. "!")
		end
	
		SetCanvasGroupVisibility(Canvas, true)

		DialogueGui.Enabled = true
		DialogueGui.Padding.PaddingBottom = UDim.new(0, 25)

		Tween:Play(DialogueGui.Padding, {0.3, "Back", "Out"}, {PaddingBottom = UDim.new()})
	end
	
	local function RequestNextPage()
		if not CanCycle then 
			return
		end
		
		-- Cycle
		if TargetedQuest then
			DialogueIndex += 1
			
			local isEnding = DialogueIndex > #TargetedQuest.Dialogues
			if isEnding then
				EventModule:FireServer("TalkToNPC", CurrentNPC)
				StopDialogue()
				
				local isQuest = not TargetedQuest.CloseDistance
				if isQuest then
					EventModule:InvokeServer("QuestStart", TargetedQuest.Name)
				end
			elseif not isEnding then
				CycleDialogueText()
				
				DialogueGui.Padding.PaddingBottom = UDim.new(0, 25)
				Tween:Play(DialogueGui.Padding, {0.3, "Back", "Out"}, {PaddingBottom = UDim.new()})
			end
		end
	end
	
	ExitButton.Activated:Connect(StopDialogue)
	Continue.Activated:Connect(RequestNextPage)
	
	---- NPC system
	
	local function RequestCheck()
		return isOpen
	end
	
	local function PerNPC(NPC: Model)
		AttributeModule:CreateAttributeFolder(NPC)
		NPCFunctions:CreateProximityPrompt(NPC, RequestCheck, ExitButton.Activated, StopDialogue, StartDialogue)
		NPCFunctions:AnimateNPC(NPC)
	end
	
	local function UpdatePerCollection(Name)
		for _, NPC in CollectionService:GetTagged(Name) do
			task.spawn(PerNPC, NPC)
		end
		CollectionService:GetInstanceAddedSignal(Name):Connect(PerNPC)
	end
	
	UpdatePerCollection("Quest")
	UpdatePerCollection("Dialogue")
	
	---- Update UI color ----------------------------------------------------------
	
	-- Dialogue
	local Canvas = DialogueGui:WaitForChild("Canvas")
	Canvas.Title.ExitButton.TextColor3 = Primary
	Canvas.Title.Display.TextColor3 = Primary
	Canvas.Continue.BackgroundColor3 = Primary
	Canvas.Continue.TextColor3 = Secondary
	Canvas.Title.Quest.ImageColor3 = Primary
	
	Canvas.Description.BackgroundColor3 = Background
	Canvas.Title.BackgroundColor3 = Background
	
	-- Quest inventory
	local MainFrame = QuestGui:WaitForChild("MainFrame")
	MainFrame.Titlebar.BackgroundColor3 = Primary
	MainFrame.Titlebar.TextColor3 = Secondary
	MainFrame.ExitButton.TextColor3 = Secondary
	MainFrame.Content.Frame.BackgroundColor3 = Secondary
	MainFrame.Content.ScrollingFrame.ScrollBarImageColor3 = Primary
	MainFrame.BackgroundColor3 = Background
	MainFrame.UIStroke.Color = Background
	
	-- Pin frame
	local PopupBackground = QuestPinFrame:WaitForChild("PopupBackground")
	PopupBackground.BackgroundColor3 = Background
	PopupBackground.Title.ExitButton.TextColor3 = Primary
	PopupBackground.Title.Display.TextColor3 = Primary
	PopupBackground.Background.BackgroundColor3 = Background
	PopupBackground.Background.Percentage.TextColor3 = Primary
	PopupBackground.Background.ScrollingFrame.ScrollBarImageColor3 = Primary
	PopupBackground.Background.Frame.BackgroundColor3 = Background
	PopupBackground.Background.Fill.BackgroundColor3 = Primary
	
	PopupBackground.Background.ScrollingFrame.Mobs.Items.BackgroundColor3 = Background
	PopupBackground.Background.ScrollingFrame.Objectives.Items.BackgroundColor3 = Background
	PopupBackground.Background.ScrollingFrame.Statistics.Items.BackgroundColor3 = Background
	
	QuestPinFrame.Resize.BackgroundColor3 = Background
	QuestPinFrame.Resize.ImageLabel.ImageColor3 = Primary
	
	-------------------------------

	DialogueGui:WaitForChild("Padding")
	StopDialogue()
	ClosePinFrame()
end