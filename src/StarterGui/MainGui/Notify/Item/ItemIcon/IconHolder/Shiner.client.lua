local button = script.Parent
local gradient = button.UIGradient
--local gradientRarity = button.Rarity:FindFirstChildOfClass("UIGradient")
local ts = game:GetService("TweenService")
local ti = TweenInfo.new(1.3, Enum.EasingStyle.Circular, Enum.EasingDirection.Out)
local offset1 = {Offset = Vector2.new(2, 0)}
local offset2 = {Rotation = 240 + 360}
local create = ts:Create(gradient, ti, offset1)
--local create2 = ts:Create(gradientRarity, ti, offset2)
local startingPos = Vector2.new(-2, 0)
local startingRot = 240
local addWait = 1

gradient.Offset = startingPos

local function animate()
	
	create:Play()
	create.Completed:Wait()
	gradient.Offset = startingPos
	wait(addWait)
	--create2:Play()
	--create2.Completed:Wait()
	--gradientRarity.Rotation = startingRot
	--wait(addWait)
	animate()
	
end

animate()