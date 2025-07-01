--[[
	ej0w @ September 2024
	Main
	
	Handles most of the primary UI and a few small tidbits, handling for Attributes UI visibility is housed here
	*If you wish to modify the statistics frame, look for the folder under this script
]]

--> Services
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GroupService = game:GetService("GroupService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer
local pData = ReplicatedStorage:WaitForChild("PlayerData"):WaitForChild(Player.UserId)

local Stats = pData:WaitForChild("Stats")

local XP = Stats:WaitForChild("XP")
local Gold = Stats:WaitForChild("Gold")
local Level = Stats:WaitForChild("Level")
local Kills = Stats:WaitForChild("Kills")

--> References
local Camera = workspace.CurrentCamera

--> Dependencies
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local ColorModule = require(ReplicatedStorage.Modules.Shared.Color)

local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local TooltipController = require(ReplicatedStorage.Modules.Client.TooltipController)
local SetCanvasGroupVisibility = require(ReplicatedStorage.Modules.Client.setCanvasGroupVisibility)

local GameConfig = require(ReplicatedStorage.GameConfig)

local StatisticModules = {}
for _, Module in script.Statistics:GetChildren() do
	StatisticModules[Module.Name] = require(Module)
end

--> Variables
local XPPerLevel = GameConfig.XPPerLevel
local ActivatedColor = GameConfig.PrimaryColor
local DeactivatedColor = GameConfig.SecondaryColor

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return function(Gui)
	--> References
	local BottomLeft = Gui:WaitForChild("BottomLeft")
	local BottomRight = Gui:WaitForChild("BottomRight")

	local OverheadFrame = BottomLeft:WaitForChild("Overhead")
	local ExperienceFrame = BottomLeft:WaitForChild("Experience")
	
	local MainFrame = BottomLeft:WaitForChild("Main")
	local TakenLabel = MainFrame:WaitForChild("DamageTaken")
	
	local EXPFrame = ExperienceFrame:WaitForChild("EXP")
	local EXPFrameFill = EXPFrame:WaitForChild("Fill")
	
	local MPFrame = MainFrame:WaitForChild("MP")
	local MPFrameFill = MPFrame:WaitForChild("Fill")
	
	local HPFrame = MainFrame:WaitForChild("HP")
	local HPFrameFill = HPFrame:WaitForChild("Fill")
	
	local WalkSpeedFrame = OverheadFrame:WaitForChild("WalkSpeed")
	local JumpPowerFrame = OverheadFrame:WaitForChild("JumpPower")
	local GoldFrame = OverheadFrame:WaitForChild("Gold")
	local KillsFrame = OverheadFrame:WaitForChild("Kills")
	
	local StatisticsLabel = BottomRight:WaitForChild("StatisticsLabel")
	local Gained = BottomLeft:WaitForChild("Experience"):WaitForChild("Gained")
	
	local LevelValue = MainFrame:WaitForChild("PlayerIcon"):WaitForChild("LevelValue")
	
	--> Variables
	local SustainedDamageTaken = 0
	local PlayingHealthTweens = {}

	local PreviousHealth = 0
	local DamageClock = os.clock()
	
	local Previous = {
		["XP"] = XP.Value,
		["Gold"] = Gold.Value,
	}
	
	local SustainedStatChange = {}
	local PlayingStatTweens = {}
	local UpdatedStats = {}
	
	--------------------------------------------------------------------------------
	
	local function CancelPlayingHealthTweens()
		for _, Tween in PlayingHealthTweens do
			Tween:Cancel()
			Tween = nil
		end

		PlayingHealthTweens = {}
	end
	
	local function CancelPlayingStatTweens(StatName)
		for _, Tween in (PlayingStatTweens[StatName] or {}) do
			Tween:Cancel()
			Tween = nil
		end

		PlayingStatTweens[StatName] = {}
	end
	
	---- UI meter display
	
	local function UpdateDamageMeter(Humanoid)
		local DamageTaken = math.round(PreviousHealth - Humanoid.Health)
		SustainedDamageTaken += DamageTaken

		task.defer(function()
			if Humanoid.Health == Humanoid.MaxHealth then
				return
			end

			-- Start meter & play
			local Clock = os.clock()
			DamageClock = Clock

			CancelPlayingHealthTweens()

			TakenLabel.Text = `-{FormatNumber(SustainedDamageTaken, "Suffix")}`
			TakenLabel.Padding.PaddingBottom = UDim.new(0, 10)
			TakenLabel.TextStrokeTransparency = 0.7
			TakenLabel.TextTransparency = 0
			TakenLabel.Visible = true

			Tween:Play(TakenLabel:WaitForChild("Padding"), {0.3, "Circular"}, {PaddingBottom = UDim.new(0, 0)})

			task.wait(2)

			-- Remove meter if there isn't any new interactions
			if DamageClock == Clock then
				SustainedDamageTaken = 0

				local PaddingTween = Tween:Play(TakenLabel:WaitForChild("Padding"), {0.3, "Circular"}, {PaddingBottom = UDim.new(0, 10)})
				local TakenLabelTween = Tween:Play(TakenLabel, {0.3, "Circular"}, {TextTransparency = 1})
				table.insert(PlayingHealthTweens, PaddingTween)
				table.insert(PlayingHealthTweens, TakenLabelTween)

				TakenLabel.TextStrokeTransparency = 1

				local NewClock = os.clock()
				DamageClock = NewClock

				task.wait(0.3)

				if NewClock ~= DamageClock then 
					return 
				end
				
				TakenLabel.Visible = false
			end
		end)
	end
	
	local function UpdateStatisticMeter(StatName, Change)
		if not GameConfig.EnabledFeatures.StatChange then
			return
		end
		
		SustainedStatChange[StatName] = math.round((SustainedStatChange[StatName] and SustainedStatChange[StatName] + Change) or Change)
		PlayingStatTweens[StatName] = PlayingStatTweens[StatName] or {}
		
		CancelPlayingStatTweens(StatName)
		
		local GainedFrame = Gained:WaitForChild(StatName)
		GainedFrame.Padding.PaddingBottom = UDim.new(0, 10)
		GainedFrame.GroupTransparency = 0
		GainedFrame.StatCount.Text = `+{FormatNumber(SustainedStatChange[StatName], "Suffix")}`
		GainedFrame.Visible = true
		
		Tween:Play(GainedFrame:WaitForChild("Padding"), {0.3, "Circular"}, {PaddingBottom = UDim.new(0, 0)})
		
		local Clock = os.clock()
		UpdatedStats[StatName] = Clock
		
		task.wait(2)

		-- Remove meter if there isn't any new interactions
		if UpdatedStats[StatName] == Clock then
			SustainedStatChange[StatName] = nil
			
			local PaddingTween = Tween:Play(GainedFrame:WaitForChild("Padding"), {0.3, "Circular"}, {PaddingBottom = UDim.new(0, 10)})
			local TakenLabelTween = Tween:Play(GainedFrame, {0.3, "Circular"}, {GroupTransparency = 1})
			table.insert(PlayingStatTweens[StatName], PaddingTween)
			table.insert(PlayingStatTweens[StatName], TakenLabelTween)

			local NewClock = os.clock()
			UpdatedStats[StatName] = NewClock

			task.wait(0.3)

			if UpdatedStats[StatName] ~= NewClock then
				return 
			end
			
			GainedFrame.Visible = false
		end
	end
	
	---- Regular callbacks
	
	local function UpdateStatsFrame(Reset)
		local XPChange = math.max(0, XP.Value - Previous.XP)
		local GoldChange = math.max(0, Gold.Value - Previous.Gold)
		
		-- Experience
		local XPRequirement = math.ceil((GameConfig.XPModifier == "Multiply" and Level.Value * GameConfig.XPPerLevel)
			or  (GameConfig.XPModifier == "Exponential" and GameConfig.XPPerLevel ^ Level.Value))
		
		local LevelUpPercent = math.clamp(XP.Value / XPRequirement, 0, 1)
		if (Level.Value == GameConfig.MaxLevel) then
			LevelUpPercent = 1
		end

		if Reset then
			EXPFrameFill.UIGradient.Offset = Vector2.zero
		end

		EXPFrame:WaitForChild("Percent").Text = math.round(LevelUpPercent * 100) .. "%"
		EXPFrame:WaitForChild("StatCount").Text = FormatNumber(XP.Value, "Suffix") 
			.. " <font transparency ='0.25' size ='17'>/ " 
			.. FormatNumber(XPRequirement, "Suffix") 
			.. "</font>"

		Tween:Play(EXPFrameFill:WaitForChild("UIGradient"), {0.5, "Circular"}, {
			Offset = Vector2.new(LevelUpPercent, 0)
		})

		-- Other stats
		if GoldChange > 0 then
			task.spawn(UpdateStatisticMeter, "Gold", GoldChange)
		end
		if XPChange > 0 then
			task.spawn(UpdateStatisticMeter, "XP", XPChange)
		end
		
		LevelValue.Text = FormatNumber(Level.Value, "Suffix")
		
		GoldFrame:WaitForChild("StatCount").Text = FormatNumber(Gold.Value, "Suffix")
		KillsFrame:WaitForChild("StatCount").Text = FormatNumber(Kills.Value, "Suffix")
		
		Previous.XP = XP.Value
		Previous.Gold = Gold.Value
	end

	local function UpdateCharacterFrame(ChangedAttribute)
		local Character = Player.Character
		
		local Humanoid = Character and Character:FindFirstChild("Humanoid")
		if not Humanoid then
			return
		end

		-- Health & Damage counter
		local isHealthChanged = ChangedAttribute == true 
			or ChangedAttribute == "Health"
			or ChangedAttribute == "MaxHealth"
		
		if isHealthChanged  then
			local Alpha = Humanoid.Health / Humanoid.MaxHealth

			HPFrame:WaitForChild("StatCount").Text = FormatNumber(math.floor(Humanoid.Health), "Suffix")
			HPFrame:WaitForChild("Percent").Text = math.clamp(math.floor(Alpha*100), 0, 100) .."%"

			Tween:Play(HPFrameFill:WaitForChild("UIGradient"), {0.5, "Circular"}, {
				Offset = Vector2.new(Humanoid.Health/Humanoid.MaxHealth, 0)
			})

			local Goal = (Alpha > 0.66 and GameConfig.PercentageColors.High)
				or (Alpha > 0.33 and GameConfig.PercentageColors.Medium) 
				or GameConfig.PercentageColors.Low
			
			if TakenLabel then
				TakenLabel.TextColor3 = Goal
			end
			
			Tween:Play(HPFrameFill, {0.5, "Circular"}, {BackgroundColor3 = Goal})

			Tween:Play(HPFrame:WaitForChild("StatIcon"), {0.5, "Circular"}, {ImageColor3 = Goal:Lerp(Color3.fromRGB(255, 255, 255), 0.05)})
			Tween:Play(HPFrame:WaitForChild("StatName"), {0.5, "Circular"}, {TextColor3 = Goal:Lerp(Color3.fromRGB(255, 255, 255), 0.05)})
			
			if PreviousHealth > Humanoid.Health and GameConfig.ShowPlayerDamageDisplay then
				task.spawn(UpdateDamageMeter, Humanoid)
			end
		end
		
		PreviousHealth = Humanoid.Health

		-- Other stats
		WalkSpeedFrame:WaitForChild("StatCount").Text = FormatNumber(Humanoid.WalkSpeed, "Suffix")
		JumpPowerFrame:WaitForChild("StatCount").Text = FormatNumber(Humanoid.JumpPower, "Suffix")
	end

	local function UpdateManaBar()
		local Character = Player.Character
		local Humanoid = Character:FindFirstChild("Humanoid")

		local ManaAttributes = Humanoid and Humanoid:FindFirstChild("Mana")
		if not ManaAttributes then 
			return 
		end

		local Mana = ManaAttributes.Mana:GetAttribute("Default")
		
		local MaxMana = 0
		for Name, Value in ManaAttributes.MaxMana:GetAttributes() do
			if Value ~= Value then 
				continue
			end
			
			MaxMana += Value
		end
		
		local OffsetX = MPFrameFill.UIGradient.Offset.X
		if math.clamp(OffsetX, -2, 2) ~= OffsetX or OffsetX ~= OffsetX then
			MPFrameFill.UIGradient.Offset = Vector2.new(Mana/MaxMana, 0)
		end

		MPFrame:WaitForChild("StatCount").Text = FormatNumber(math.floor(Mana), "Suffix")
		MPFrame:WaitForChild("Percent").Text = math.clamp(math.floor(Mana/MaxMana * 100), 0, 100) .."%"

		Tween:Play(MPFrameFill:WaitForChild("UIGradient"), {0.5, "Circular"}, {
			Offset = Vector2.new(Mana/MaxMana, 0)
		})
	end

	---- Update frames & initialize
	
	if GameConfig.ManaPerLevel <= 0 then
		MainFrame:WaitForChild("MP").Visible = false
	end
	
	ExperienceFrame:WaitForChild("EXP"):WaitForChild("Fill"):WaitForChild("UIGradient").Offset = Vector2.zero
	
	ExperienceFrame:WaitForChild("EXP"):WaitForChild("Fill").BackgroundColor3 = GameConfig.LeaderstatIcons.XP.Color or GameConfig.PrimaryColor
	ExperienceFrame:WaitForChild("EXP"):WaitForChild("StatName").TextColor3 = GameConfig.LeaderstatIcons.XP.Color or GameConfig.PrimaryColor
	ExperienceFrame:WaitForChild("EXP"):WaitForChild("StatIcon").ImageColor3 = GameConfig.LeaderstatIcons.XP.Color or GameConfig.PrimaryColor
	
	Gained:WaitForChild("XP").GroupColor3 = GameConfig.LeaderstatIcons.XP.Color or GameConfig.PrimaryColor

	MainFrame:WaitForChild("PlayerIcon"):WaitForChild("PlayerImage").Image = `https://www.roblox.com/headshot-thumbnail/image?userId={Player.UserId}&width=420&height=420&format=png`
	MainFrame:WaitForChild("HP"):WaitForChild("Fill"):WaitForChild("UIGradient").Offset = Vector2.zero
	MainFrame:WaitForChild("MP"):WaitForChild("Fill"):WaitForChild("UIGradient").Offset = Vector2.zero
	
	---- Update character frame
	
	local function OnCharacterAdded(Character: Model)
		local Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
		
		local Properties = {"Health", "MaxHealth", "WalkSpeed", "JumpPower"}
		for _, Name in Properties do
			Humanoid:GetPropertyChangedSignal(Name):Connect(function()
				UpdateCharacterFrame(Name)
			end)
		end
		
		SustainedDamageTaken = 0
		PreviousHealth = Humanoid.MaxHealth
		DamageClock = os.clock()
		
		for Name in Previous do
			Gained:WaitForChild(Name).Visible = false
			CancelPlayingStatTweens(Name)
		end
		
		TakenLabel.Visible = false
		CancelPlayingHealthTweens()

		local ManaAttributes = Humanoid:WaitForChild("Mana")
		ManaAttributes:WaitForChild("Mana").AttributeChanged:Connect(UpdateManaBar)
		ManaAttributes:WaitForChild("MaxMana").AttributeChanged:Connect(UpdateManaBar)

		UpdateManaBar()
		UpdateCharacterFrame(true)
	end
	
	Player.CharacterAdded:Connect(OnCharacterAdded)
	if Player.Character then
		OnCharacterAdded(Player.Character)
	end

	-- Color change
	for _, Frame in CollectionService:GetTagged("Background") do
		Frame.BackgroundColor3 = GameConfig.BackgroundColor
	end
	
	---- Update stats frame

	Stats.ChildAdded:Connect(function(Stat)
		Stat.Changed:Connect(UpdateStatsFrame)
	end)

	for _, Stat in Stats:GetChildren() do
		Stat.Changed:Connect(function()
			UpdateStatsFrame(Stat.Name == "Level")
		end)
	end

	UpdateStatsFrame()

	---- Spawn Button --------------------------------------------------------------

	local Debounce = false
	local TeleportTime = 2

	local SpawnButton = Gui:WaitForChild("SpawnButton")
	SpawnButton.BackgroundColor3 = ActivatedColor
	SpawnButton.ImageLabel.ImageColor3 = DeactivatedColor
	SpawnButton.TextLabel.TextColor3 = DeactivatedColor

	local Label = Gui:WaitForChild("SpawnDuration")
	Label.TextColor3 = ActivatedColor
	Label.Visible = false

	local function ActivatedTeleportRequest()
		if Debounce then
			return
		end

		Debounce = true
		task.delay(TeleportTime + 0.05, function()
			Debounce = false
		end)

		-- Timer text
		task.spawn(function()
			Tween:Play(SpawnButton, {0.2, "Exponential"}, {BackgroundColor3 = DeactivatedColor})
			Tween:Play(SpawnButton.ImageLabel, {0.25, "Sine"}, {ImageColor3 = ActivatedColor})
			Tween:Play(SpawnButton.TextLabel, {0.25, "Sine"}, {TextColor3 = ActivatedColor})
			Label.Visible = true

			for Iteration = 1, (TeleportTime * 10) - 1 do
				Label.Text = `{(math.round((TeleportTime * 10) - Iteration) / 10)}s`
				task.wait(0.1)
			end

			Tween:Play(SpawnButton, {0.2, "Exponential"}, {BackgroundColor3 = ActivatedColor})
			Tween:Play(SpawnButton.ImageLabel, {0.25, "Sine"}, {ImageColor3 = DeactivatedColor})
			Tween:Play(SpawnButton.TextLabel, {0.25, "Sine"}, {TextColor3 = DeactivatedColor})
			Label.Visible = false
		end)

		-- Teleport
		local Character = Player.Character
		
		local Humanoid = Character and Character:FindFirstChild("Humanoid")
		if Humanoid and Humanoid.Health > 0 then
			local Position = GameConfig.SpawnLocation
			if not Position then
				local SpawnLocation = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
				Position = SpawnLocation and SpawnLocation.Position
			end
			
			if Position then
				EventModule:Fire("ClientRequestTeleport", Position, true)
			else
				warn("[KIT: TeleportToSpawn has neither a GameConfig position or any active spawn locations!]")
			end
		end
	end

	SpawnButton.Activated:Connect(ActivatedTeleportRequest)
	UserInputService.InputBegan:Connect(function(Input: InputObject, GPE)
		if not GPE and Input.KeyCode == Enum.KeyCode.T then
			ActivatedTeleportRequest()
		end
	end)

	---- Bottom right information ----------------------------------------------------------------
	
	local previousPotionsVisible = false
	local previousStatisticsVisible = false
	
	local Statuses = Player:WaitForChild("Statuses")
	
	local StatisticsFrame = BottomRight:WaitForChild("Statistics")
	local PotionFrame = BottomRight:WaitForChild("Potions")
	local LabelTemplate = PotionFrame:WaitForChild("Label")
	local PotionsLabel = BottomRight:WaitForChild("PotionsLabel")
	
	PotionFrame.Visible = false
	PotionsLabel.Visible = false
	LabelTemplate.Visible = false
	StatisticsFrame.Visible = false
	
	-- Inverse scale notifications
	local Bottom = BottomRight:WaitForChild("Bottom")
	local Buttons = Bottom:WaitForChild("Buttons")
	local UIListLayout = Bottom:WaitForChild("UIListLayout")

	local function UpdateNotificationScale()
		local BiggestSize = StatisticsFrame.AbsoluteSize.X
		if PotionFrame.AbsoluteSize.X > BiggestSize then
			BiggestSize = PotionFrame.AbsoluteSize.X
		end

		local Goal = {Padding = UDim.new(0, math.max(((BiggestSize - Buttons.AbsoluteSize.X) / Gui.UIScale.Scale) + 6, 6))}
		Tween:Play(UIListLayout, {0.15}, Goal)
	end

	Bottom.ChildAdded:Connect(UpdateNotificationScale)
	Bottom.ChildRemoved:Connect(UpdateNotificationScale)
	
	---- Info UI
	
	local function FormatNumberToTime(Number)
		local TotalHours = math.floor(Number / 3600)
		local TotalMinutes = math.floor((Number - (TotalHours * 3600)) / 60)
		local TotalSeconds = Number - (TotalHours * 3600) - (TotalMinutes * 60)
		if TotalHours > 0 then
			return `{TotalHours}h {TotalMinutes}m {TotalSeconds}s`
		elseif TotalMinutes > 0 then
			return `{TotalMinutes}m {TotalSeconds}s`
		else
			return `{TotalSeconds}s`
		end
	end

	local function UpdateAllStatistics()
		local Character = Player.Character
		
		local Tool = Character and Character:FindFirstChildWhichIsA("Tool")
		
		local Humanoid = Character and Character:FindFirstChild("Humanoid")
		if not Humanoid then 
			return 
		end

		-- Update statistics frames
		for _, Callback in StatisticModules do
			Callback(Character, Tool)
		end

		-- Update the label visibility
		local TotalVisible = 0
		for _, Label in StatisticsFrame:GetChildren() do
			if Label:IsA("TextLabel") and Label.Visible then
				TotalVisible += 1
			end
		end

		local CanShow = TotalVisible ~= 0

		if not previousStatisticsVisible and CanShow then
			Tween:Play(StatisticsFrame.UIScale, {0.35, "Circular"}, {
				Scale = 1,
			})

			StatisticsFrame.UIScale.Scale = 0.7
		end

		StatisticsFrame.Visible = CanShow
		previousStatisticsVisible = CanShow

		UpdateNotificationScale()
	end
	
	local function UpdatePotionsUI()
		local CanShow = false
		
		for _, Potion in Statuses:GetChildren() do
			local NewLabel = PotionFrame:FindFirstChild(Potion.Name) or LabelTemplate:Clone()
			NewLabel.Parent = PotionFrame
			NewLabel.Name = Potion.Name

			local Duration = Potion:GetAttribute("Duration")
			local IsActive = Duration > 0
			NewLabel.Visible = IsActive

			local TextSuffix = ((Potion:GetAttribute("Addition") == nil or Potion:GetAttribute("Addition") == 0) and `x{Potion:GetAttribute("Boost")}`)
				or `+{FormatNumber(Potion:GetAttribute("Addition"), "Suffix")}`

			NewLabel.Text = `<b>{FormatNumberToTime(Duration)}</b> {Potion.Name} <font size='14' transparency ='0.2'>({TextSuffix})</font>`

			if Duration < 10 then
				Tween:Play(NewLabel, {0.25, "Quad", "InOut"}, {TextColor3 = Color3.fromRGB(255, 78, 78)})
				task.delay(0.35, function()
					Tween:Play(NewLabel, {0.25, "Quad", "InOut"}, {TextColor3 = Color3.fromRGB(223, 223, 223)})
				end)
			end

			if IsActive then
				CanShow = true
			end
		end
		
		if not previousPotionsVisible and CanShow then
			Tween:Play(PotionFrame.UIScale, {0.35, "Circular"}, {
				Scale = 1,
			})

			PotionFrame.UIScale.Scale = 0.7
		end
		
		if CanShow ~= previousPotionsVisible then
			task.defer(UpdateAllStatistics)
		end

		PotionFrame.Visible = CanShow
		previousPotionsVisible = CanShow
		
		UpdateNotificationScale()
	end

	local function CharacterAddedSuite(Character: Model)
		local Humanoid = Character:WaitForChild("Humanoid")

		-- Update statistics
		local Statistics = Humanoid:WaitForChild("Statistics")
		for _, Statistic in Statistics:GetChildren() do
			Statistic.AttributeChanged:Connect(UpdateAllStatistics)
		end

		-- Update tools/armor
		Character.ChildAdded:Connect(function(Child)
			if Child:IsA("Tool") or Child.Name == "ArmorGroup" then
				task.defer(UpdateAllStatistics)
			end
		end)
		
		Character.ChildRemoved:Connect(function(Child)
			if Child:IsA("Tool") or Child.Name == "ArmorGroup" then
				task.defer(UpdateAllStatistics)
			end
		end)

		UpdateAllStatistics()
	end
	
	if GameConfig.EnabledFeatures.InfoUI then
		for _, Potion in Statuses:GetChildren() do
			Potion.AttributeChanged:Connect(UpdatePotionsUI)
		end
		
		UpdatePotionsUI()

		-- Statistics frame
		StatisticsLabel.Visible = false

		-- Update attributes
		local Attributes = pData:WaitForChild("Attributes")
		for _, Attribute in Attributes:GetChildren() do
			Attribute.Changed:Connect(UpdateAllStatistics)
		end

		if Player.Character then
			CharacterAddedSuite(Player.Character)
		end
		Player.CharacterAdded:Connect(CharacterAddedSuite)
		
		-- Update based on equipped accessories
		for _, Slot in pData:WaitForChild("EquippedSlots"):GetChildren() do
			Slot.Changed:Connect(function()
				task.defer(UpdateAllStatistics)
			end)
		end
	end

	---- Kit Credit ----------------------------------------------------------------
	
	local OpenX = UserInputService.TouchEnabled 
		and -38
		or 0
	
	local CloseX = UserInputService.TouchEnabled 
		and -38 - 16 
		or -16
	
	local OriginY = -8
	local KitOpen = false
	local OpenedTime = os.clock()
	
	local KitButton = BottomRight:WaitForChild("Bottom"):WaitForChild("Buttons"):WaitForChild("KitButton")
	local KitPopup = KitButton:WaitForChild("Popup")

	local function ToggleKitFrame(Enabled: boolean?)
		KitOpen = if Enabled == nil then not KitOpen else Enabled
		KitPopup.Position = KitOpen and UDim2.new(1, 16, 0, -16) or KitPopup.Position
		
		local Clock = os.clock()
		OpenedTime = Clock
		
		if KitOpen then
			KitPopup.Visible = true
		elseif not KitOpen then
			task.delay(0.2, function()
				if OpenedTime ~= Clock then
					return
				end
				
				KitPopup.Visible = false
			end)
		end
		
		Tween:Play(KitPopup, {0.2, "Sine"}, {Position = UDim2.new(1, KitOpen and OpenX or CloseX, 0, OriginY)})
		
		Tween:Play(KitButton, {0.2, "Exponential"}, {BackgroundColor3 = KitOpen and ActivatedColor or DeactivatedColor})
		Tween:Play(KitButton:WaitForChild("ImageLabel"), {0.2, "Exponential"}, {ImageColor3 = KitOpen and DeactivatedColor or ActivatedColor})
		
		Tween:Play(KitPopup, {0.2, "Exponential"}, {GroupTransparency = KitOpen and 0 or 1})
		Tween:Play(KitPopup:WaitForChild("UIStroke"), {0.2, "Exponential"}, {Transparency = KitOpen and 0.4 or 1})
	end

	local function GetCreatorName()
		local Success, Response
		
		local isPlaceOwner = game.CreatorType == Enum.CreatorType.User
		if isPlaceOwner then
			Success, Response = pcall(function()
				return Players:GetNameFromUserIdAsync(game.CreatorId)
			end)
		elseif not isPlaceOwner then
			Success, Response = pcall(function()
				return GroupService:GetGroupInfoAsync(game.CreatorId).Name
			end)
		end
		
		return Success and Response or "to the creator"
	end

	KitButton.Activated:Connect(function()
		ToggleKitFrame()
	end)
	
	ToggleKitFrame(false)

	-- Change UI
	local KitText1 = KitPopup:WaitForChild("Text1")
	KitText1.Text = string.gsub(KitPopup.Text1.Text, "<name>", GetCreatorName())

	local KitText2 = KitPopup:WaitForChild("Text2")
	KitText2.Text = string.gsub(KitPopup.Text2.Text, "<name>", GameConfig.SubsetKitUsername)

	local KitText3 = KitPopup:WaitForChild("Text3")
	KitText3.TextColor3 = ActivatedColor

	local TakeButton = KitPopup:WaitForChild("TakeButton")
	TakeButton.BackgroundColor3 = ActivatedColor
	TakeButton.TextLabel.TextColor3 = DeactivatedColor
	
	TakeButton.Activated:Connect(function()
		if KitPopup.GroupTransparency ~= 1 then
			game:GetService("MarketplaceService"):PromptPurchase(Player, 1498988226)
		end
	end)

	local TakeSubset = KitPopup:WaitForChild("TakeSubset")
	TakeSubset.BackgroundColor3 = ActivatedColor
	TakeSubset.TextLabel.TextColor3 = DeactivatedColor
	
	TakeSubset.Activated:Connect(function()
		if KitPopup.GroupTransparency ~= 1 then
			game:GetService("MarketplaceService"):PromptPurchase(Player, GameConfig.SubsetKitID)
		end
	end)

	if not GameConfig.EnableSupportGui then
		KitButton.Visible = false
	end
	
	---- Frame opens ----------------------------------------------------------------
	
	local Functions = {}

	local function CloseOtherGUIs(NewName)
		for Name, Callback in Functions do
			if string.find(Name, "Close") and not string.find(Name, NewName) then
				task.spawn(Callback)
			end
		end
	end
	
	---- Quest frame open
	
	do
		local QuestsOpen = false

		local QuestsButton = BottomRight:WaitForChild("Bottom"):WaitForChild("Buttons"):WaitForChild("Quests")
		
		local Gui = Player.PlayerGui:WaitForChild("Quest")
		local QuestsMainFrame = Gui:WaitForChild("MainFrame")
		local Padding = Gui:WaitForChild("Padding")
		
		local Primary, Secondary, Background = ColorModule:ConvertToHSV3(GameConfig.FrameColors.Quests)

		local function OpenQuests()
			CloseOtherGUIs("Quests")
			
			SetCanvasGroupVisibility(QuestsMainFrame, true)
			
			Gui.Enabled = true
			Padding.PaddingTop = UDim.new(0, 50)
			
			Tween:Play(Padding, {0.3, "Back", "Out"}, {PaddingTop = UDim.new()})
		end

		local function CloseQuests()
			SetCanvasGroupVisibility(QuestsMainFrame, false)
			
			Tween:Play(Padding, {0.2, "Back", "In"}, {PaddingTop = UDim.new(0, 50)})
		end

		local function ToggleQuestsFrame(Enabled: boolean?)
			QuestsOpen = if Enabled == nil then not QuestsOpen else Enabled
			if QuestsOpen then
				OpenQuests()
			else
				CloseQuests()
			end

			Tween:Play(QuestsButton, {0.2, "Exponential"}, {BackgroundColor3 = QuestsOpen and Primary or Secondary})
			Tween:Play(QuestsButton:WaitForChild("ImageLabel"), {0.2, "Exponential"}, {ImageColor3 = QuestsOpen and Secondary or Primary})
		end
		
		function Functions.CloseQuests()
			ToggleQuestsFrame(false)
		end

		QuestsButton.Activated:Connect(function()
			ToggleQuestsFrame()
		end)
		
		QuestsMainFrame:WaitForChild("ExitButton").Activated:Connect(function()
			ToggleQuestsFrame(false)
		end)
		ToggleQuestsFrame(false)

		local IsQuestsEnabled = GameConfig.EnabledFeatures.Quests
		if not IsQuestsEnabled then
			QuestsButton.Visible = false
		end
	end

	---- Attributes frame open
	
	do
		local AttributesOpen = false

		local PointsValue = pData:WaitForChild("Points")
		local AttributesButton = BottomRight:WaitForChild("Bottom"):WaitForChild("Buttons"):WaitForChild("Attributes")
		
		local Gui = Player.PlayerGui:WaitForChild("Attributes")
		local AttributesMainFrame = Gui:WaitForChild("MainFrame")
		local AttributesPopupFrame = Gui:WaitForChild("PopupFrame")
		local Padding = Gui:WaitForChild("Padding")
		
		local Primary, Secondary, Background = ColorModule:ConvertToHSV3(GameConfig.FrameColors.Attributes)
		
		local function PointsValueChanged()
			if PointsValue.Value > 0 then
				if PointsValue.Value >= 1000 then
					AttributesButton.Frame.TextLabel.Rotation = 10
					AttributesButton.Frame.TextLabel.TextXAlignment = Enum.TextXAlignment.Center
				else
					AttributesButton.Frame.TextLabel.Rotation = 0
					AttributesButton.Frame.TextLabel.TextXAlignment = Enum.TextXAlignment.Left
				end
				AttributesButton.Frame.Visible = true
				AttributesButton.Frame.TextLabel.Text = FormatNumber(PointsValue.Value, "Suffix")
			else
				AttributesButton.Frame.Visible = false
			end
		end

		PointsValueChanged()
		PointsValue.Changed:Connect(PointsValueChanged)

		local function OpenAttributes()
			CloseOtherGUIs("Attributes")
			
			SetCanvasGroupVisibility(AttributesPopupFrame, false)
			SetCanvasGroupVisibility(AttributesMainFrame, true)
			
			Gui.Enabled = true
			
			Padding.PaddingTop = UDim.new(0, 50)
			Tween:Play(Padding, {0.3, "Back", "Out"}, {PaddingTop = UDim.new()})
		end

		local function CloseAttributes()
			SetCanvasGroupVisibility(AttributesPopupFrame, false)
			SetCanvasGroupVisibility(AttributesMainFrame, false)
			
			Tween:Play(Padding, {0.2, "Back", "In"}, {PaddingTop = UDim.new(0, 50)})
		end

		local function ToggleAttributesFrame(Enabled: boolean?)
			AttributesOpen = if Enabled == nil then not AttributesOpen else Enabled
			if AttributesOpen then
				OpenAttributes()
			else
				CloseAttributes()
			end

			Tween:Play(AttributesButton, {0.2, "Exponential"}, {BackgroundColor3 = AttributesOpen and Primary or Secondary})
			Tween:Play(AttributesButton:WaitForChild("ImageLabel"), {0.2, "Exponential"}, {ImageColor3 = AttributesOpen and Secondary or Primary})
		end
		
		function Functions.CloseAttributes()
			ToggleAttributesFrame(false)
		end

		AttributesButton.Activated:Connect(function()
			ToggleAttributesFrame()
		end)
		AttributesMainFrame:WaitForChild("ExitButton").Activated:Connect(function()
			ToggleAttributesFrame(false)
		end)
		ToggleAttributesFrame(false)

		local IsAttributesEnabled = GameConfig.EnabledFeatures.Attributes
		if not IsAttributesEnabled then
			AttributesButton.Visible = false
		end
	end
	
	---- Label visibility
	
	local TotalVisible = 0 
	for _, Frame in BottomRight:WaitForChild("Bottom"):WaitForChild("Buttons"):GetChildren() do
		if not Frame:IsA("UIListLayout") and Frame.Visible then
			TotalVisible += 1
		end
	end
	
	if TotalVisible <= 0 then
		BottomRight.Label.Visible = false
	end
	
	---- Level progress ----------------------------------------------------------------
	
	if GameConfig.EnabledFeatures.AreaProgress then
		local Statistics = pData:WaitForChild("Stats")
		local Level = Statistics:WaitForChild("Level")
		
		local TooltipScreenGui = Player.PlayerGui:WaitForChild("Tooltip")
		local ProgressCanvas = TooltipScreenGui:WaitForChild("Progress")
		local ProgressFrame = ProgressCanvas:WaitForChild("Frame")
		
		local LevelText = BottomLeft:WaitForChild("Main"):WaitForChild("PlayerIcon"):WaitForChild("LevelValue") :: TextLabel
		
		---- Function callbacks
		
		local AreaCache = {}
		
		local function CycleThroughAllAreas(Callback, Added)
			for _, Name in {"Portal", "Level Door"} do
				local Tagged = CollectionService:GetTagged(Name)
				for _, Object in Tagged do
					Callback(Object)
				end
				
				if Added then
					CollectionService:GetInstanceAddedSignal(Name):Connect(Callback)
				end
			end
		end
		
		CycleThroughAllAreas(function(Object)
			local Config = Object:FindFirstChild("Config") and require(Object.Config)
			if Config then
				Object.Name = Config.Name
				AreaCache[Config.Name] = Config
			end
		end, true)
		
		local function RequestEnableTooltip()
			local PreviousArea = {Name = nil, Level = 0}
			local NextArea = {Name = nil, Level = math.huge}
			
			CycleThroughAllAreas(function(Object)
				local Config = AreaCache[Object.Name]
				
				local Color = Config.Color 
					or (Object:FindFirstChild("Base") and Object.Base.Color)

				if Config and Config.Level <= NextArea.Level and Config.Level >= Level.Value then
					if NextArea.Color and NextArea.Level == Config.Level and not Color then
						return
					end
					NextArea = {Name = Config.Name, Level = Config.Level, Color = Color}
				end
			end)
			
			CycleThroughAllAreas(function(Object)
				local Config = AreaCache[Object.Name]
				
				local Color = Config.Color 
					or (Object:FindFirstChild("Base") and Object.Base.Color)
				
				if Config and Config.Level > PreviousArea.Level and Config.Level < NextArea.Level then
					PreviousArea = {Name = Config.Name, Level = Config.Level, Color = Color}
				end
			end)
			
			local CurrentLevelProgress = Level.Value - (PreviousArea.Level or 0)
			local NextLevelDifference = (NextArea.Level ~= math.huge and NextArea.Level or (PreviousArea.Level or 0)) - (PreviousArea.Level or 0)
			
			local Percentage = math.clamp(CurrentLevelProgress / NextLevelDifference, 0, 1)
			
			local RequestedColor = (NextArea.Level == math.huge and PreviousArea.Color or NextArea.Color) :: Color3
			RequestedColor = RequestedColor and ColorModule:ConvertToRawHSV(RequestedColor)
			
			ProgressCanvas.GroupColor3 = RequestedColor or LevelText.TextColor3
			
			local Area = `{PreviousArea.Name or "Spawn"}`
			if NextArea.Name then
				Area ..= ` • {NextArea.Name or "Max"}`
			end
			
			ProgressFrame.Area.Text = Area
			ProgressFrame.Percentage.Text = `<b>{math.round(Percentage * 100)}%</b> Progress to next area`
			
			local Statistics = (NextArea.Level == math.huge and `Level requirement: <b>{FormatNumber(PreviousArea.Level, "Suffix")}</b>`)
				or `Level requirements: <b>{FormatNumber(Level.Value, "Suffix")}</b>`
			
			if NextArea.Level ~= math.huge then
				Statistics ..= ` / {NextArea.Level ~= math.huge and FormatNumber(NextArea.Level, "Suffix") or "Max"}`
			end
			
			ProgressFrame.Statistics.Text = Statistics
			LevelText.UIPadding.PaddingBottom = UDim.new(0, -2)
			
			ProgressFrame.Fill.UIGradient.Offset = Vector2.new(0, 0)
			Tween:Play(ProgressFrame.Fill.UIGradient, {0.5, "Circular"}, {Offset = Vector2.new(Percentage, 0)})
			
			TooltipController:StartTooltipFrame(ProgressCanvas)
		end
		
		local function RequestCloseTooltip()
			LevelText.UIPadding.PaddingBottom = UDim.new(0, 0)
			
			TooltipController:StopTooltipFrame(ProgressCanvas)
		end
		
		-- Connections
		LevelText.MouseEnter:Connect(RequestEnableTooltip)
		LevelText.MouseLeave:Connect(RequestCloseTooltip)
	end

	---- Scaling -------------------------------------------------------------------
	
	local ReferenceSize = 824
	
	local Clamp1 = GameConfig.UIScaleClamp[1]
	if UserInputService.TouchEnabled then
		Clamp1 *= 0.75
	end
	
	local function UpdateScale(UIScale)
		local Scale = Camera.ViewportSize.Y / ReferenceSize
		UIScale.Scale = math.clamp(Scale, Clamp1, GameConfig.UIScaleClamp[2])
	end

	local function UpdateInverseScale(UIScale)
		local Scale = Camera.ViewportSize.Y / ReferenceSize
		local NewScale = 1 / math.clamp(Scale, Clamp1, GameConfig.UIScaleClamp[2])
		UIScale.Scale = NewScale
	end

	local function AdaptScreenSize()
		for _, UIScale: UIScale in CollectionService:GetTagged("UIScale") do
			UpdateScale(UIScale)
		end
		
		if not UserInputService.TouchEnabled then
			for _, UIScale: UIScale in CollectionService:GetTagged("InverseScale") do
				UpdateInverseScale(UIScale)
			end
		end

		UpdateNotificationScale()
	end
	
	if GameConfig.ScaleUIs then
		if not UserInputService.TouchEnabled then
			CollectionService:GetInstanceAddedSignal("InverseScale"):Connect(UpdateInverseScale)
		end
		
		CollectionService:GetInstanceAddedSignal("UIScale"):Connect(UpdateScale)
		
		Camera:GetPropertyChangedSignal("ViewportSize"):Connect(AdaptScreenSize)
		AdaptScreenSize()
	end
	
	-- Mobile UI changes
	if UserInputService.TouchEnabled then
		if GameConfig.MobileAdaptUI then
			local UIPadding = Instance.new("UIPadding")
			UIPadding.PaddingTop = UDim.new(0, 70)
			UIPadding.Parent = BottomLeft

			BottomLeft.UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top

			UIPadding:Clone().Parent = BottomRight

			BottomRight.UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
			BottomRight.Bottom.Notifications.UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
			BottomRight.Label.LayoutOrder = -10
			BottomRight.Bottom.LayoutOrder = -9

			KitButton.Popup.AnchorPoint = Vector2.new(1, 0)

			local Keybind = Player.PlayerGui:WaitForChild("Keybind")
			Keybind.Padding.PaddingBottom = UDim.new(0, 0)
			Keybind.Padding.PaddingTop = UDim.new(0, 280)
			Keybind.UIListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
		end
		
		local InventoryScreenGui = Player.PlayerGui:WaitForChild("Inventory")
		
		local AbsoluteSizeY = InventoryScreenGui.AbsoluteSize.Y 
		local AbsoluteSizeX = InventoryScreenGui.AbsoluteSize.X 
		
		if GameConfig.MobileBackpackUIScaling and GameConfig.MobileBackpackUIScaling ~= 1 then
			AbsoluteSizeY *= GameConfig.MobileBackpackUIScaling
		end
		
		if GameConfig.MobileUsesLessSlots then
			AbsoluteSizeX = 500
		end
		
		InventoryScreenGui.Main.Inventory.Size = UDim2.fromOffset(AbsoluteSizeX, AbsoluteSizeY)
	end
	
	---- Update UI themes & fonts (future?) -------------------------------------------------------------------
	
	for Name, Data in GameConfig.LeaderstatIcons do
		local Color = Data.Color or GameConfig.UIColors.PrimaryColor
		local Image = `rbxassetid://{Data.Image or ""}`
		
		local function RequestItemAdded(Item)
			if Item:IsA("ImageLabel") then
				Item.ImageColor3 = Color
				Item.Image = Image
			elseif Item:IsA("TextLabel") then
				Item.TextColor3 = Color
			end
		end
		
		for _, Tagged in CollectionService:GetTagged("Leaderstat" .. Name) do
			task.spawn(RequestItemAdded, Tagged)
		end
		
		CollectionService:GetInstanceAddedSignal("Leaderstat" .. Name):Connect(RequestItemAdded)
	end

	--------------------------------------------------------------------------------

	Gui:WaitForChild("Version").Text = GameConfig.GameName .. " " .. GameConfig.GameVersion
end