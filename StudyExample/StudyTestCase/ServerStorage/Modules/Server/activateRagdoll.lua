--[[
	ej0w @ October 2024
	ActivateRagdoll
	
	Ragdolls the mob/player
]]

return function(Entity)
	for _, Item in Entity:GetDescendants() do
		if Item:IsA("Motor6D") and not Item:FindFirstAncestorWhichIsA("Tool") then
			local Attachment0 = Instance.new("Attachment")
			Attachment0.CFrame = Item.C0
			Attachment0.Parent = Item.Part0

			local Attachment1 = Instance.new("Attachment")
			Attachment1.CFrame = Item.C1
			Attachment1.Parent = Item.Part1

			local Constraint = Instance.new("BallSocketConstraint")
			Constraint.Attachment0 = Attachment0
			Constraint.Attachment1 = Attachment1
			Constraint.LimitsEnabled = true
			Constraint.TwistLimitsEnabled = true
			Constraint.Parent = Item.Parent

			Item.Enabled = false
		end
	end

	local Head = Entity:FindFirstChild("Head")
	if Head then
		Head.CanCollide = true
	end

	local Humanoid = Entity:FindFirstChildWhichIsA("Humanoid") :: Humanoid
	if Humanoid then
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, true)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
		Humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)

		Humanoid.WalkSpeed = 0
		Humanoid.JumpPower = 0
	end

	local Root = Entity:FindFirstChild("HumanoidRootPart")
	if Root then
		Root:ApplyImpulse(-Root.CFrame.LookVector * Root.AssemblyMass * 100)
		
		pcall(function()
			Root:SetNetworkOwner(nil)
		end)
	end
end