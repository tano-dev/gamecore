--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Dependencies
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)

--------------------------------------------------------------------------------

return function(CanvasGroup: CanvasGroup, Visible: boolean)
	local Clock = os.clock()
	CanvasGroup:SetAttribute("Clock", Clock)
	CanvasGroup.Visible = true

	local UIStroke = CanvasGroup:FindFirstChildWhichIsA("UIStroke")
	if UIStroke then
		Tween:Play(UIStroke, {0.35, "Exponential"}, {Transparency = Visible and 0.15 or 1})
	end

	Tween:Play(CanvasGroup, {0.35, "Exponential"}, {GroupTransparency = Visible and 0 or 1}).Completed:Once(function()
		if Clock ~= CanvasGroup:GetAttribute("Clock") then return end
		if not Visible and CanvasGroup.GroupTransparency >= 0.99 then
			CanvasGroup.Visible = false
		end
	end)
end
