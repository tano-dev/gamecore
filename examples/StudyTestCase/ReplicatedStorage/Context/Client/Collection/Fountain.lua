--[[
	Evercyan @ March 2023
	HealingFountain/Client
	
	Handles visuals on the client-side (such as timer) when healed.
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Dependencies
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)

--> Variables
local WaterColor = {}

--------------------------------------------------------------------------------

local function SetWaterState(Fountain, ReadyToUse: boolean)
	WaterColor[Fountain] = WaterColor[Fountain] or {}
	for _, WaterPart in Fountain.Water:GetChildren() do
		if WaterPart:IsA("BasePart") then
			if not WaterColor[WaterPart] then
				WaterColor[WaterPart] = WaterPart.Color
			end
			Tween:Play(WaterPart, {1, "Circular"}, {Color = ReadyToUse and WaterColor[WaterPart] or Color3.fromRGB(118, 118, 118)})
		end
	end
end

return function(Fountain)
	local HealPart = Fountain:WaitForChild("Heal", math.huge)
	local Healed = Fountain:WaitForChild("Healed")
	local BillboardGui = HealPart:WaitForChild("Attachment"):WaitForChild("BillboardGui")
	
	local Timer = Fountain:GetAttribute("Timer")
	
	local function RequestOnClientEvent(ServerTime: number)
		SetWaterState(Fountain, false)
		Tween:Play(BillboardGui.Header, {1, "Circular"}, {TextTransparency = 0.7})
		BillboardGui.Cooldown.Visible = true

		while true do
			local Difference = workspace:GetServerTimeNow() - ServerTime
			local ReadyToUse = Difference > Timer
			if ReadyToUse then
				break
			end
			BillboardGui.Cooldown.Text = "-".. math.ceil(Timer-Difference) .."-"
			task.wait(0.2)
		end

		SetWaterState(Fountain, true)
		Tween:Play(BillboardGui.Header, {1, "Circular"}, {TextTransparency = 0})
		BillboardGui.Cooldown.Visible = false
	end
		
	Healed.OnClientEvent:Connect(RequestOnClientEvent)
end