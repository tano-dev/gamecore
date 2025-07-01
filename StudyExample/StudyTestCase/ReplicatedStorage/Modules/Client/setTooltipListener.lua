--[[
	ej0w @ October 2024
	SetTooltipListener
	
	Used to create tooltips on a specific frame --> hovered
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--> References
local TooltipFrame = PlayerGui:WaitForChild("Tooltip"):WaitForChild("Frame")

--> Dependencies
local TooltipController = require(ReplicatedStorage.Modules.Client.TooltipController)
local ColorModule = require(ReplicatedStorage.Modules.Shared.Color)

local GameConfig = require(ReplicatedStorage.GameConfig)

--> Configuration
local CONFIG_ENABLE_TOUCHPAN_MOBILE = false

--------------------------------------------------------------------------------

return function(Frame: TextButton, ItemInstance, PrimaryColor)
	local Connections = {}
	
	local CanvasGroup = Frame:FindFirstAncestorWhichIsA("CanvasGroup")
	if CanvasGroup then
		Connections[#Connections + 1] = CanvasGroup:GetPropertyChangedSignal("GroupTransparency"):Connect(function()
			local Transparency = CanvasGroup.GroupTransparency
			if Transparency == 1 then
				TooltipController:Clear()
			end
		end)
	end
	
	local ItemConfig = ItemInstance:FindFirstChild("ItemConfig") and require(ItemInstance.ItemConfig)
	local ItemType = (ItemConfig and ItemConfig.Type) or (ItemInstance:IsA("Tool") and "Tool")
	
	local function RequestHovered()
		if Frame.Visible == false
			or Frame:GetAttribute("DisableTooltip")
			or CanvasGroup and CanvasGroup.GroupTransparency == 1 
		then
			TooltipController:Clear()
			return
		end

		local Info = ""
		local Type = (ItemConfig and ItemConfig.WeaponType) or ItemType
		local Level = (ItemConfig and " [Lv. ".. ItemConfig.Level .."]") or ""
		
		local CustomBackground = ItemConfig and ItemConfig.CustomBackground
		local Gradient = (CustomBackground and ReplicatedStorage.Assets.Gradients:FindFirstChild(CustomBackground)) :: UIGradient
		if Gradient then
			CustomBackground = Gradient.Color.Keypoints[1].Value
		end
		
		local SpecialColor = ItemConfig and ItemConfig.SpecialColor
		
		local RequestedColor = CustomBackground or SpecialColor
		RequestedColor = RequestedColor and ColorModule:ConvertToRawHSV(RequestedColor)
		
		TooltipFrame.GroupColor3 = RequestedColor or PrimaryColor or GameConfig.PrimaryColor

		Info = TooltipController:ReturnInfo(ItemInstance, ItemConfig, Info, ItemType, Type, Level)
		TooltipController:Set(`<b>{ItemInstance.Name}</b> <font size="12" transparency="0.2">[{(ItemConfig and ItemConfig.ToolType) or Type}]{Level}</font>{Info}`)
	end
	
	if CONFIG_ENABLE_TOUCHPAN_MOBILE and UserInputService.TouchEnabled then
		Connections[#Connections + 1] = Frame.TouchPan:Connect(function(_, _, _, State)
			if State == Enum.UserInputState.Begin then
				RequestHovered()
			elseif State == Enum.UserInputState.End then
				TooltipController:Clear()
			end
		end)
	else
		Connections[#Connections + 1] = Frame.MouseEnter:Connect(RequestHovered)
	end
	
	Connections[#Connections + 1] = Frame.MouseLeave:Connect(function()
		TooltipController:Clear()
	end)
	
	return Connections
end
