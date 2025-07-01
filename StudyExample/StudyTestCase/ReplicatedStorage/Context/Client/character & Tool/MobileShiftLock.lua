--[[
	unknown @ October 2024
	MobileShiftLock
	
	Handles mobile shiftlock, took this from a free model and recoded & repurposed it to work with the kit.
]]

--> Services
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)


--> References
local Camera = workspace.CurrentCamera

local Character = nil :: Model
local Humanoid = nil :: Humanoid
local Root = nil :: BasePart

--> Variables
local States = {
	OFF = "rbxasset://textures/ui/mouseLock_off@2x.png",
	ON = "rbxasset://textures/ui/mouseLock_on@2x.png"
}

local MAX_LENGTH = 900000
local ENABLED_OFFSET = CFrame.new(1.7, 0, 0)
local DISABLED_OFFSET = CFrame.new(-1.7, 0, 0)

local Active = false

--------------------------------------------------------------------------------

if not GameConfig.MobileShiftLock or not UserInputService.TouchEnabled then
	return {}
end

--> GUI
local ShiftLockGui = script.Mobile:Clone()
ShiftLockGui.Parent = PlayerGui

local Button = ShiftLockGui:WaitForChild("ImageButton")

local function UpdateImage(STATE)
	Button.Image = States[STATE]
end

local function UpdateAutoRotate(BOOL)
	Humanoid.AutoRotate = BOOL
end

local function GetUpdatedCameraCFrame(ROOT, CAMERA)
	return CFrame.new(Root.Position, Vector3.new(CAMERA.CFrame.LookVector.X * MAX_LENGTH, Root.Position.Y, CAMERA.CFrame.LookVector.Z * MAX_LENGTH))
end

local function EnableShiftlock()
	if Root then
		Root.CFrame = GetUpdatedCameraCFrame(Root, Camera)
	end
	Camera.CFrame = Camera.CFrame * ENABLED_OFFSET
	
	UpdateAutoRotate(false)
	UpdateImage("ON")
end

local function DisableShiftlock()
	Camera.CFrame = Camera.CFrame * DISABLED_OFFSET
	
	if Active then
		Active:Disconnect()
		Active = false
	end
	
	UpdateAutoRotate(true)
	UpdateImage("OFF")
end

UpdateImage("OFF")

function RequestShiftLock()
	local IsNotActive = not Active
	if IsNotActive then
		Active = RunService.RenderStepped:Connect(function()
			EnableShiftlock()
		end)
	elseif not IsNotActive then
		DisableShiftlock()
	end
end

local ShiftLockButton = ContextActionService:BindAction("ShiftLOCK", RequestShiftLock, false, "On")
ContextActionService:SetPosition("ShiftLOCK", UDim2.new(0.8, 0, 0.8, 0))

Button.Activated:Connect(RequestShiftLock)

local function OnCharacterAdded(NewCharacter)
	Character = NewCharacter
	Root = Character:WaitForChild("HumanoidRootPart")
	Humanoid = Character:WaitForChild("Humanoid")
end

Player.CharacterAdded:Connect(OnCharacterAdded)
if Player.Character then
	OnCharacterAdded(Player.Character)
end

return {}
