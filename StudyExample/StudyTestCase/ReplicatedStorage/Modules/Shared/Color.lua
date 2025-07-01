--[[
	ej0w @ October 2024
	Color
	
	Ported from UI scripts, declutter
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local Color = {}

local BaseColor = {
	["Primary"] = GameConfig.UIColors.PrimaryColor,
	["Secondary"] = GameConfig.UIColors.SecondaryColor,
	["Background"] = GameConfig.UIColors.BackgroundColor
}

--------------------------------------------------------------------------------
	
function Color:GetBaseColor()
	return table.clone(BaseColor)
end

function Color:ConvertToHSV3(_Color)
	local Hue, Saturation, Value = _Color:ToHSV()
	
	return Color3.fromHSV(Hue, Saturation, select(3, BaseColor.Primary:ToHSV())), 
		Color3.fromHSV(Hue, Saturation - 0.1, select(3, BaseColor.Secondary:ToHSV())), 
		Color3.fromHSV(Hue, Saturation - 0.2, select(3, BaseColor.Background:ToHSV()))
	
	-- Old color system
	--[[
	return Color3.fromHSV(select(1, _Color:ToHSV()), select(2, BaseColor.Primary:ToHSV()), select(3, BaseColor.Primary:ToHSV())), 
		Color3.fromHSV(select(1, _Color:ToHSV()), select(2, BaseColor.Secondary:ToHSV()), select(3, BaseColor.Secondary:ToHSV())),
		Color3.fromHSV(select(1, _Color:ToHSV()), select(2, BaseColor.Background:ToHSV()), select(3, BaseColor.Background:ToHSV()))
	]]
end

function Color:ConvertToRawHSV(_Color)
	local Hue, Saturation, Value = _Color:ToHSV()
	return Color3.fromHSV(Hue, math.clamp(Saturation + 0.2, 0, 1), math.clamp(Value + 0.5, 0, 1)):Lerp(Color3.fromRGB(255, 255, 255), 0.1)
end

function Color:GetPrimaryColor(Item)
	local CategoryColor = GameConfig.Categories[Item.Type].Color
	local SpecialColor = Item.Config and Item.Config.SpecialColor

	local CustomBackground = Item.Config and Item.Config.CustomBackground
	local Gradient = (CustomBackground and ReplicatedStorage.Assets.Gradients:FindFirstChild(CustomBackground)) :: UIGradient

	if Gradient then
		CustomBackground = Gradient.Color.Keypoints[1].Value
	end

	return CustomBackground or SpecialColor or CategoryColor
end

return Color