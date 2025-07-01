--[[
	ej0w @ September 2024
	CharacterOrbit
	
	I used this feature in Crazy Party RPG and a couple other projects,
	basically the antithesis to melee mob align for those who want a more manual approach
	
	It overrides melee mob align if enabled.
]]

--> Services
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Player
local Player = Players.LocalPlayer

--> Variables
local Cache = {}

--> Configuration
local GameConfig = require(ReplicatedStorage.GameConfig)

--------------------------------------------------------------------------------

if not GameConfig.CharacterOrbit or (UserInputService.TouchEnabled and GameConfig.DoesMobileUseMeleeMobAlign) then
	return {}
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

local function UpdateCharacterOrbit(DeltaTime: number)
	local Character = Player.Character
	local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart")
	if not HumanoidRootPart then 
		return 
	end

	debug.profilebegin("primaryUpdateOrbit")

	local Tool = Character:FindFirstChildWhichIsA("Tool")
	local Humanoid = Character:FindFirstChild("Humanoid") :: Humanoid

	local ItemConfig = Tool and Tool:FindFirstChild("ItemConfig")
	if not ItemConfig then
		Humanoid.AutoRotate = true
		return
	end

	if Cache[Tool.Name] == nil then
		Cache[Tool.Name] = require(ItemConfig)
	end
	ItemConfig = Cache[Tool.Name]
	
	if (ItemConfig and ItemConfig.Damage) and Humanoid and not Humanoid.Sit and not Humanoid.PlatformStand then
		local Position = GetMouseHit({Character}, true)
		local Focus = CFrame.new(HumanoidRootPart.Position, Vector3.new(Position.X, HumanoidRootPart.Position.Y, Position.Z))

		local CurrentRotation = HumanoidRootPart.CFrame.Rotation
		local GoalRotation = Focus.Rotation
		local _, Y, _ = CurrentRotation:Lerp(GoalRotation, math.clamp(DeltaTime * 30, 0, 1)):ToOrientation()
		local X, _, Z = CurrentRotation:ToOrientation()

		Humanoid.AutoRotate = false
		HumanoidRootPart.CFrame = CFrame.Angles(X, Y, Z) + HumanoidRootPart.Position
	else
		Humanoid.AutoRotate = true
	end

	debug.profileend()
end

RunService:BindToRenderStep("CharacterOrbit", Enum.RenderPriority.Character.Value + 1, function(DeltaTime: number)
	if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
		UpdateCharacterOrbit(DeltaTime)
	else
		local Character = Player.Character
		local Humanoid = Character and Character:FindFirstChild("Humanoid") :: Humanoid
		if Humanoid then
			Humanoid.AutoRotate = true
		end
	end
end)

return {}