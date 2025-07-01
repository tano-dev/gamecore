--[[
	TweenModel
	Tweens a model based on a start/end scale, used for ore breaking
]]

--> Services
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

--------------------------------------------------------------------------------

return function(Start: number, End: number, TweenInfo: TweenInfo, Model: Model)
	local Elapsed = 0
	local Scale = 0
	
	local TweenConnection = nil :: RBXScriptConnection
	local function RequestHeartbeatStepped(Delta: number)
		Elapsed = Elapsed + Delta

		local Alpha = TweenService:GetValue(Elapsed / TweenInfo.Time, TweenInfo.EasingStyle, TweenInfo.EasingDirection) 
		Scale = Start + Alpha * (End - Start)
		Model:ScaleTo(Scale)

		if Elapsed >= TweenInfo.Time then
			TweenConnection:Disconnect()
		end
	end

	TweenConnection = RunService.Heartbeat:Connect(RequestHeartbeatStepped)
end
