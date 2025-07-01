--[[
	ej0w @ September 2024
	ToolLook
	
	Tool moves in the direction that the player's mouse is (if enabled)
]]

--> Services
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Player
local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

--> References
local Camera = workspace.CurrentCamera

--> Variables
local Cache = {}

--> Configuration
local GameConfig = require(ReplicatedStorage.GameConfig)

--------------------------------------------------------------------------------

local CachedConfigurations = {}
local function GetConfiguration(Tool)
	if Tool then
		local Config = CachedConfigurations[Tool.Name]
		if not Config then
			local WeaponConfig = Tool:FindFirstChild("ItemConfig")
			Config = WeaponConfig and require(WeaponConfig)

			CachedConfigurations[Tool.Name] = Config
		end

		return Config
	end
end

local function IsFirstPerson()
	local Character = Player.Character
	local Head = Character and Character:FindFirstChild("Head")
	if not Head then return end
	return (Head.CFrame.Position - Camera.CFrame.Position).Magnitude <= 0.75
end

local function GetMouseHit(Filter, Position, Include): Vector3
	local RaycastParams = RaycastParams.new()
	RaycastParams.FilterType = Include and Enum.RaycastFilterType.Include or Enum.RaycastFilterType.Exclude
	RaycastParams.FilterDescendantsInstances = {
		workspace:WaitForChild("Temporary"), workspace:WaitForChild("Characters"),
		workspace:WaitForChild("Mobs"), workspace.Zones, workspace.Teleports, 
		Filter and unpack(Filter)
	}
	RaycastParams.RespectCanCollide = true

	local MouseLocation = UserInputService:GetMouseLocation()
	local ViewportRay = workspace.CurrentCamera:ViewportPointToRay(MouseLocation.X, MouseLocation.Y)
	local RaycastResult = workspace:Raycast(ViewportRay.Origin, ViewportRay.Direction * 1e3, RaycastParams)
	return Position and (RaycastResult and RaycastResult.Position or (ViewportRay.Origin + ViewportRay.Direction.Unit * 1e3)) or RaycastResult
end

local function UpdateCharacterArm()
	debug.profilebegin("primaryCharacterLimbStepped")
	
	local Character = Player.Character
	local rootPart = Character and Character:FindFirstChild("HumanoidRootPart")
	local torso = Character and Character:FindFirstChild("Torso")
	if not torso or not rootPart then return end

	local rShoulder = torso and torso:FindFirstChild("Right Shoulder")
	if not rShoulder then return end

	local rShoulderOrigin = rShoulder and (rShoulder:GetAttribute("Origin") or rShoulder.C0)
	
	local function RevertMotors(NoLerp)
		rShoulder.C0 = (NoLerp and rShoulderOrigin) or rShoulder.C0:Lerp(rShoulderOrigin, 0.25)
	end

	local Tool = Character:FindFirstChildWhichIsA("Tool")
	local Config = Tool and GetConfiguration(Tool)
	if not Config or not Config.ToolLook then
		return RevertMotors(true)
	end


	if not rShoulder:GetAttribute("Origin") then 
		rShoulder:SetAttribute("Origin", rShoulderOrigin) 
	end

	-- ignore mathy :sob:
	local rootJoint = rootPart.RootJoint
	local camDir = Mouse.Hit.LookVector
	local multiplier = 0.75

	local headDir = torso.CFrame:ToObjectSpace(Character.Head.CFrame).LookVector
	local rArmDir = torso.CFrame:ToObjectSpace(Character["Right Arm"].CFrame).LookVector

	local _, _, z = rootJoint.Transform:ToOrientation()
	rShoulder.C0 = rShoulderOrigin * CFrame.Angles(0,-z,0) * CFrame.Angles(0,0,math.asin(camDir.Y) * multiplier)

	--RevertMotors(true)
	debug.profileend()
end

RunService:BindToRenderStep("ToolLook", Enum.RenderPriority.Character.Value - 1, UpdateCharacterArm)
return {}