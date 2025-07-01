--[[
	Evercyan @ March 2023
	MeleeMobAlign
	
	MeleeMobAlign is a client-sided script that automatically rotates your body rotation to face any
	nearby mobs when holding a melee weapon (Config.WeaponType == "Melee").
	
	This feature is used in Infinity's Occultation Update, as it greatly improves user experience when
	fighting any enemy with a melee weapon, especially on platforms like mobile, where shift lock may not be a feature.
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
local Focus: Model?

--> Configuration
local GameConfig = require(ReplicatedStorage.GameConfig)

--------------------------------------------------------------------------------

if (not GameConfig.MeleeMobAlign or GameConfig.CharacterOrbit) and not (UserInputService.TouchEnabled and GameConfig.DoesMobileUseMeleeMobAlign) then
	return {}
end

local function GetNearestMob()
	local Character = Player.Character
	if not Character then return end
	
	local Closest = {MobInstance = nil, Distance = math.huge}
	for _, MobInstance in CollectionService:GetTagged("Mob") do
		local MobConfig = MobInstance:FindFirstChild("MobConfig") and require(MobInstance.MobConfig)
		local Enemy = MobInstance:FindFirstChild("Enemy")
		if not MobConfig or not Enemy or Enemy.Health == 0 then continue end
		
		local Distance = (Character:GetPivot().Position - MobInstance:GetPivot().Position).Magnitude
		local MaxDistance = MobConfig.FollowDistance or 32
		
		if (Distance < MaxDistance) and (Distance < Closest.Distance) then
			Closest.MobInstance = MobInstance
			Closest.Distance = Distance
		end
	end
	
	return Closest.MobInstance
end

task.defer(function()
	while true do
		task.wait(1/5)
		Focus = GetNearestMob()
	end
end)

RunService:BindToRenderStep("MeleeLock", Enum.RenderPriority.Character.Value + 1, function(DeltaTime: number)
	local Character = Player.Character
	local Humanoid = Character and Character:FindFirstChild("Humanoid") :: Humanoid?
	local HumanoidRootPart = Character and Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not Humanoid or not HumanoidRootPart then return end
	
	local Success = false
	
	if Focus and UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
		local Tool = Character:FindFirstChildOfClass("Tool")
		local ItemConfig = Tool and require(Tool:FindFirstChild("ItemConfig"))
		
		if ItemConfig and ItemConfig.WeaponType == "Melee" then
			local CurrentRotation = HumanoidRootPart.CFrame.Rotation
			local GoalRotation = CFrame.lookAt(HumanoidRootPart.Position, Focus:GetPivot().Position).Rotation
			local _, Y, _ = CurrentRotation:Lerp(GoalRotation, math.clamp(DeltaTime * 30, 0, 1)):ToOrientation()
			local X, _, Z = CurrentRotation:ToOrientation()
			
			Humanoid.AutoRotate = false
			HumanoidRootPart.CFrame = CFrame.Angles(X, Y, Z) + HumanoidRootPart.Position
			
			Success = true
		end
	end
	
	if not Success then
		Humanoid.AutoRotate = true
	end
end)

return {}