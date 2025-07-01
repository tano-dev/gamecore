--[[
	TweenCFrame
	Uses a CFrameValue to tween a given object's cframe
]]

--> Services
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

--------------------------------------------------------------------------------

return function(Part: BasePart, Info: TweenInfo, Goal: CFrame)
	local isMotor6D = Part:IsA("Motor6D")
	
	local CFrameValue = Instance.new("CFrameValue")
	CFrameValue.Value = (isMotor6D and Part.C0) or Part.CFrame
	
	local Tween = TweenService:Create(CFrameValue, Info, {Value = Goal})
	Tween:Play()
	
	Tween.Completed:Once(function()
		CFrameValue:Destroy()
		
		Tween:Destroy()
		Tween = nil
	end)
	
	local TweenConnection = nil :: RBXScriptConnection
	local Elapsed = 0
	
	local function RequestHeartbeatStepped(Delta: number)
		Elapsed = Elapsed + Delta
		
		if isMotor6D then
			Part.C0 = CFrameValue.Value
		elseif not isMotor6D then
			Part.CFrame = CFrameValue.Value
		end
		
		if Elapsed >= Info.Time then
			TweenConnection:Disconnect()
		end
	end

	TweenConnection = RunService.Heartbeat:Connect(RequestHeartbeatStepped)
	
	return TweenConnection
end
