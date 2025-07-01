--[[
	ej0w @ November 2024
	CustomCAS
	
	Serves as a custom ContextActionService module for keybind buttons (displayed above the hotbar)
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer
local ButtonFrame = Player.PlayerGui:WaitForChild("Inventory"):WaitForChild("Main"):WaitForChild("HideCanvas"):WaitForChild("ContextActionButtons")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

local SFX = require(ReplicatedStorage.Modules.Shared.SFX)
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)

--> Variables
local CustomCAS = {}

local ActiveCooldowns = {}
local ActiveKeybindInputs = {}

local RelevancyKeybindSpaces = {"Q", "R", "F", "Z", "X", "C", "V", "G", "B", "Y", "H", "N", "U", "J", "M", "I", "K", "O", "L", "P"}
local KeybindChanged = Instance.new("BindableEvent")

local isNotKeybind = (UserInputService.GamepadEnabled and not RunService:IsStudio()) or UserInputService.TouchEnabled

--------------------------------------------------------------------------------

local function UpdateButtonFrameVisibility()
	local Visible = 0
	for _, Frame in ButtonFrame:GetChildren() do
		if Frame:IsA("GuiObject") and Frame.Visible then
			Visible += 1
		end
	end
	
	ButtonFrame.Visible = Visible > 0
end

function CustomCAS:StartContextInput(Name: string, DisplayName: string, Icon: number, CreateButton: boolean, Key: string, Cooldown: number, CooldownAfterHold: boolean, HoldTime: number, Priority: number, Callback, Validation, KeyName, DontMakeSound, CanNotPress)
	for _, Data in ActiveKeybindInputs do
		if Data[1] == Name then
			return
		end
	end

	local Button = script.ButtonTemplate:Clone()
	Button.Name = Name
	Button.LayoutOrder = Priority or 999
	
	local InputFrame = Button:WaitForChild("InputButton")
	InputFrame.Button:SetAttribute("DisableSound", true)
	
	local Connections = {}

	local function UpdateKeybindTaking()
		local RequestedKey = nil

		if not ActiveKeybindInputs[Key] then
			return Key
		end

		for _, NewKey in RelevancyKeybindSpaces do
			if not ActiveKeybindInputs[NewKey] then
				RequestedKey = NewKey
				break
			end
		end

		return RequestedKey
	end

	local function MakeData()
		return {Name, Cooldown, Button, Connections}
	end

	local ChosenKey = typeof(Key) == "string" and (ActiveKeybindInputs[Key] and UpdateKeybindTaking()) or Key
	if ChosenKey ~= Key and not isNotKeybind then
		local FoundSuccessfulKey = nil :: BindableEvent

		if ChosenKey == nil then
			FoundSuccessfulKey = Instance.new("BindableEvent")
			Connections[#Connections + 1] = FoundSuccessfulKey.Event:Wait()
		end

		Connections[#Connections + 1] = KeybindChanged.Event:Connect(function(KeyChanged)
			local PreviousKey = ChosenKey
			local hasFoundKey = false

			local function UpdateKey(ChosenKey)
				hasFoundKey = true

				ActiveKeybindInputs[ChosenKey] = MakeData()

				ActiveKeybindInputs[PreviousKey] = nil
				KeybindChanged:Fire(PreviousKey)

				Button.Keybind.Text = ChosenKey
			end

			local isOriginalKey = KeyChanged == Key and not ActiveKeybindInputs[Key]
			if isOriginalKey then
				UpdateKey(Key)
			else
				ChosenKey = UpdateKeybindTaking()

				if PreviousKey ~= ChosenKey then
					UpdateKey(ChosenKey)
				end
			end
		end)
	end
	
	if Icon ~= nil then
		if tonumber(Icon) then
			Icon = "rbxassetid://" .. Icon
		end

		Button.Icon.Image = Icon

		Button.Icon.Visible = true
		Button.Display.Visible = false
	end
	
	Tween:Play(Button.UIScale, {0.35, "Circular"}, {
		Scale = 1,
	})

	Button.UIScale.Scale = 0.7
	Button.Input.Visible = isNotKeybind
	
	if KeyName then
		Button.Keybind.TextSize -= 4
	end
	
	Button.Display.Text = DisplayName
	
	Button.Keybind.Visible = not isNotKeybind
	Button.Keybind.Text = (not isNotKeybind and (KeyName or typeof(Key) == "string" and ChosenKey or Key.Name)) or ""
	
	---- Connections
	
	local activatedTime = os.clock()
	local isHeldDown = false
	
	local function OnTimerStarted(_Button)
		local NewButton = _Button or Button
		if NewButton.Parent == nil then
			return
		end
		
		task.spawn(function()
			while ActiveCooldowns[Name] and NewButton.Parent do
				local _Duration = os.clock() - ActiveCooldowns[Name]
				local TimeLeft = (Cooldown - _Duration)
				
				if TimeLeft <= 0.05 then
					break
				end

				NewButton.Timer.Text = math.round(TimeLeft * 10) / 10
				task.wait(1 / 10)
			end

			if NewButton.Parent then
				NewButton.Timer.Visible = false
			end
		end)

		NewButton.Timer.Visible = true
	end
	
	local function OnActivated(Verdict, GPE, fromButton)
		if (Verdict and isHeldDown) or (not Verdict and not isHeldDown) then
			return
		end
		
		isHeldDown = Verdict
				
		local isGoingCooldown = (CooldownAfterHold and not Verdict) or (not CooldownAfterHold and Verdict)
		local Success = (Validation and Validation(Verdict, GPE)) or Validation == nil and true
		
		if Success and (not Cooldown or not ActiveCooldowns[Name]) then
			local Clock = os.clock()
			activatedTime = Clock
			
			if not isGoingCooldown and CooldownAfterHold and HoldTime then
				task.delay(HoldTime, function()
					if activatedTime == Clock then
						OnActivated(false, false)
					end
				end)
			elseif isGoingCooldown then
				if Cooldown and Cooldown > 0 then
					ActiveCooldowns[Name] = os.clock()
					
					local function RequestActivate(_Button)
						local _InputFrame = _Button:WaitForChild("InputButton")
						
						task.delay(Cooldown, function()
							if _InputFrame.Parent ~= nil then
								_InputFrame.Button.AutoButtonColor = true
							end

							ActiveCooldowns[Name] = nil
						end)

						OnTimerStarted(_Button)

						Tween:Play(_Button.Canvas.Cooldown, {Cooldown + 0.1, "Linear", "InOut"}, {
							Size = UDim2.fromScale(1, 0)
						})

						_InputFrame.Button.AutoButtonColor = false
						_Button.Canvas.Cooldown.Size = UDim2.fromScale(1, 1)
					end
					
					if Button.Parent then
						RequestActivate(Button)
					else
						for _Key, Data in ActiveKeybindInputs do
							if Data[1] == Name then
								local _Button = Data[3]
								RequestActivate(_Button)
							end
						end
					end
				end
			end
			
			if isGoingCooldown and not (not fromButton and DontMakeSound) then
				SFX:Play2D(GameConfig.ClickSFX[1], {Volume = GameConfig.ClickSFX[2]})
			end
			
			if Callback then
				Callback(Verdict, GPE)
			end
		end
	end
	
	if not CanNotPress then
		InputFrame.Button.MouseButton1Down:Connect(function()
			OnActivated(true, false, true)
		end)

		InputFrame.Button.MouseButton1Up:Connect(function()
			OnActivated(false, false, true)
		end)
	else
		InputFrame.Button.AutoButtonColor = false
	end
	
	UserInputService.InputBegan:Connect(function(Input: InputObject, GameProcessedEvent: boolean)
		for Key, Data in ActiveKeybindInputs do
			if Data[1] == Name and (typeof(Key) == "string" and Input.KeyCode == Enum.KeyCode[Key] or Input.UserInputType == Key) then
				task.spawn(OnActivated, true, GameProcessedEvent)
			end
		end
	end)
	
	UserInputService.InputEnded:Connect(function(Input: InputObject, GameProcessedEvent: boolean)
		for Key, Data in ActiveKeybindInputs do
			if Data[1] == Name and (typeof(Key) == "string" and Input.KeyCode == Enum.KeyCode[Key] or Input.UserInputType == Key) then
				task.spawn(OnActivated, false, GameProcessedEvent)
			end
		end
	end)
	
	---- Setup
	
	if CreateButton and not (isNotKeybind and CanNotPress) then
		Button.Visible = true
		Button.Parent = ButtonFrame
	end

	if ActiveCooldowns[Name] and Button.Parent then
		local Duration = os.clock() - ActiveCooldowns[Name]
		local TimeLeft = (Cooldown - Duration)

		InputFrame.Button.AutoButtonColor = false

		task.delay(TimeLeft, function()
			if InputFrame.Parent ~= nil then
				InputFrame.Button.AutoButtonColor = true
			end
		end)

		local Percentage = math.clamp(TimeLeft / Cooldown, 0, 1)
		Button.Canvas.Cooldown.Size = UDim2.fromScale(1, Percentage)
		
		OnTimerStarted()

		Tween:Play(Button.Canvas.Cooldown, {TimeLeft, "Linear", "InOut"}, {
			Size = UDim2.fromScale(1, 0)
		})
	else
		Button.Canvas.Cooldown.Size = UDim2.fromScale(1, 0)
	end

	ActiveKeybindInputs[ChosenKey] = MakeData()
	UpdateButtonFrameVisibility()
end

function CustomCAS:StopContextInput(Name: string)
	for _Key, Data in ActiveKeybindInputs do
		if Data[1] == Name then
			Data[3]:Destroy()

			for _, Connection in Data[4] do
				Connection:Disconnect()
				Connection = nil
			end

			ActiveKeybindInputs[_Key] = nil
			KeybindChanged:Fire(_Key)
		end
	end
end

return CustomCAS