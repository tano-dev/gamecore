--[[
	ej0w @ May 2024
	MobTarget
	
	Think of the projecile mobs - when they look at you, this is the script that does that
]]

--> Services
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Player
local Player = Players.LocalPlayer

--> References
local Mobs = workspace:WaitForChild("Mobs")

--> Dependencies
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)

--> Variables
local Targeting = {}

--> Configuration
local REFRESH_RATE = 1 / 5

--------------------------------------------------------------------------------

task.spawn(function()
	while task.wait(REFRESH_RATE) do
		Targeting = {}

		local Character = Player.Character
		
		local CharacterPosition = Character and Character:GetPivot().Position
		if not CharacterPosition then
			continue
		end
		
		for _, Mob in Mobs:GetChildren() do
			local RootPart = Mob:FindFirstChild("HumanoidRootPart")
			if not RootPart then 
				continue
			end
			
			local isClose = (RootPart.Position - CharacterPosition).Magnitude < 25
			
			local isTargeting = AttributeModule:GetAttribute(Mob, "Target") == Player.UserId and AttributeModule:GetAttribute(Mob, "Still")
				or AttributeModule:GetAttribute(Mob, "Focus")
			
			if isClose and isTargeting then
				table.insert(Targeting, Mob)
			else
				local Humanoid = Mob:FindFirstChildWhichIsA("Humanoid") :: Humanoid?
				if Humanoid then
					Humanoid.AutoRotate = true
				end
				
				local AlignOrientation = RootPart:FindFirstChild("AlignOrientation")
				if AlignOrientation then
					AlignOrientation:Destroy()
				end
			end
		end
	end
end)

RunService:BindToRenderStep("TargetLock", Enum.RenderPriority.Last.Value, function(DeltaTime: number)
	local Character = Player.Character
	if not Character then
		return
	end
	
	local CharacterPosition = Character:GetPivot().Position
	
	for _, Mob in Targeting do
		local Humanoid = Mob:FindFirstChildWhichIsA("Humanoid") :: Humanoid?
		local RootPart = Mob:FindFirstChild("HumanoidRootPart")
		
		if Humanoid and RootPart then
			local Difference = CharacterPosition - RootPart.Position
			local Angle = math.atan2(Difference.X, Difference.Z)
			
			local newAdd = false

			local AlignOrientation = RootPart:FindFirstChild("AlignOrientation")
			if not AlignOrientation then
				AlignOrientation = Instance.new("AlignOrientation")
				
				local Attachment = RootPart:FindFirstChild("AlignAttachment") or Instance.new("Attachment")
				Attachment.CFrame = CFrame.new() * CFrame.Angles(0, math.rad(180), 0)
				Attachment.Name = "AlignAttachment"
				
				Attachment.Parent = RootPart
				
				AlignOrientation.AlignType = Enum.AlignType.AllAxes
				AlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
				
				AlignOrientation.ReactionTorqueEnabled = false
				AlignOrientation.RigidityEnabled = false
				AlignOrientation.Responsiveness = 20
				
				AlignOrientation.Attachment0 = Attachment
				AlignOrientation.Parent = RootPart
				
				newAdd = true
			end
			
			local newCFrame = CFrame.Angles(0, Angle, 0)
			
			AlignOrientation.CFrame = newAdd and RootPart.CFrame.Rotation 
				or AlignOrientation.CFrame:Lerp(newCFrame, math.clamp(DeltaTime * 30, 0, 1))
			
			AlignOrientation.Enabled = true
			Humanoid.AutoRotate = false
		end
	end
end)

return {}