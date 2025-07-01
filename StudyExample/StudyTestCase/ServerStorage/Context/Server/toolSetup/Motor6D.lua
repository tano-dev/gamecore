local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return function(Tool)
	local ItemConfig = require(Tool.ItemConfig)
	local Configuration = ItemConfig.Motor6D
	
	local Motors = Tool:WaitForChild("Motor6D", 0.5) or Instance.new("Folder")
	Motors.Parent = Tool
	Motors.Name = "Motor6D"
	
	local Player: Player = nil
	local Character: Model = nil
	local Humanoid: Humanoid = nil
	local Connection: RBXScriptConnection = nil
	
	--------------------------------------------------------------------------------
	
	local function FindRightGrip(Verdict)
		local RightGrip = Character and Character:WaitForChild("Right Arm"):FindFirstChild("RightGrip") :: Weld
		if RightGrip then
			RightGrip.Enabled = Verdict
		end
	end

	local function ClearMotor6Ds()
		if Connection then
			Connection:Disconnect()
			Connection = nil
		end
		for Index, Motor6D in Motors:GetChildren() do
			Motor6D.Part1 = nil
			Motor6D.Part0 = nil
			Motor6D:Destroy()
		end
		FindRightGrip(true)
	end
	ClearMotor6Ds()

	local function ToolEquipped()
		ClearMotor6Ds()
		
		Character = Tool.Parent
		Humanoid = Character and Character:FindFirstChild("Humanoid")
		if not Humanoid then return end

		for Index, Setup in Configuration do
			local Hand = Character:FindFirstChild(Setup["BodyPart"])
			local ToolPart = Tool:FindFirstChild(Setup["ToolPart"])

			if not Hand then continue end
			if not ToolPart then continue end

			local Motor6D = Instance.new("Motor6D")
			Motor6D.Name = "Link" .. Index
			Motor6D.Parent = Motors

			local GripAttachment = Hand:FindFirstChild("RightGripAttachment") 
				or Hand:FindFirstChild("LeftGripAttachment")
				or Hand:FindFirstChild("FaceCenterAttachment")
				or Hand:FindFirstChild("RightFootAttachment")
				or Hand:FindFirstChild("LeftFootAttachment")
				or Hand:FindFirstChild("WaistCenterAttachment")
				or Hand:FindFirstChildWhichIsA("Attachment")
			
			Motor6D.C1 = Configuration.C1 or Tool.Grip * CFrame.Angles(math.rad(90), 0, 0)
			Motor6D.C0 = Configuration.C0 or GripAttachment.CFrame

			local OffsetC1 = Setup["OffsetC1"]
			if OffsetC1 then
				Motor6D.C1 = Motor6D.C1 + OffsetC1
			end
			
			local OffsetC0 = Setup["OffsetC0"]
			if OffsetC0 then
				Motor6D.C0 = Motor6D.C0 + OffsetC0
			end

			if ToolPart then
				Motor6D.Part1 = (ToolPart:IsA("Model") and ToolPart.PrimaryPart) or ToolPart
			end

			if Hand then
				Motor6D.Part0 = Hand
			end
		end
		
		FindRightGrip(false)
		
		Connection = Character.DescendantAdded:Connect(function()
			FindRightGrip(false)
		end)
	end

	local function ToolUnequipped()
		ClearMotor6Ds()
	end

	Tool.Equipped:Connect(ToolEquipped)
	Tool.Unequipped:Connect(ToolUnequipped)
end