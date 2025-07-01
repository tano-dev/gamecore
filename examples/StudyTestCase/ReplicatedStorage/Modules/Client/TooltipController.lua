--[[
	Evercyan @ March 2023
	TooltipController
	
	Require this module to show information under tooltips. Tooltips are floating text,
	usually bits of information, relating to what the user is hovering over, such as
	hovering over slots in the inventory.
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--> References
local Player = Players.LocalPlayer
local Gui = Player:WaitForChild("PlayerGui"):WaitForChild("Tooltip")
local Frame = Gui.Frame

--> Dependencies
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)

local returnInfo = require(ReplicatedStorage.Modules.Client.returnTooltipInfo)
local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local Tooltip = {}
local ChangeIds = {}

--------------------------------------------------------------------------------
-- Utilities

local function ResetTooltipColors(Frame)
	if Frame:GetAttribute("CanReset") then
		Frame.GroupColor3 = Color3.fromRGB(255, 255, 255)
	end
end

local function GetTooltipPosition(Frame): UDim2
	local MouseLocation = UserInputService:GetMouseLocation()
	local ViewportSize = workspace.CurrentCamera.ViewportSize
	
	local FocusPoint = Frame:FindFirstChild("TextLabel")
		or Frame:FindFirstChild("Frame") 
		or Frame
	
	local TooltipSize = FocusPoint.AbsoluteSize
	local Offset = Frame:GetAttribute("Offset")
	
	if Offset then
		return UDim2.fromOffset(
			math.clamp(MouseLocation.X + 16, 0, ViewportSize.X - (TooltipSize.X+Offset)),
			math.clamp(MouseLocation.Y + 16, 0, ViewportSize.Y - (TooltipSize.Y+Offset))
		)
	else
		local DistanceX = UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter and 10 or 0
		local DistanceY = UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter and 22 or 22
		return UDim2.fromOffset(MouseLocation.X + DistanceX, MouseLocation.Y - DistanceY)
	end
end

----- Tooltip callbacks & setting

function Tooltip:ReturnInfo(ItemInstance, ItemConfig, Info, ItemType, Type, Level)
	return returnInfo(ItemInstance, ItemConfig, Info, ItemType, Type, Level)
end

function Tooltip:Set(Text: string)
	Frame:WaitForChild("Frame"):WaitForChild("TextLabel").Text = Text
	
	self:StartTooltipFrame(Frame)
end

function Tooltip:Clear()
	self:StopTooltipFrame(Frame)
end

function Tooltip:StartTooltipFrame(Frame)
	ChangeIds[Frame] = (ChangeIds[Frame] and ChangeIds[Frame] + 1) or 1

	Frame.GroupTransparency = 1
	Frame.Visible = true
	
	Tween:Play(Frame, {0.3, "Exponential"}, {GroupTransparency = 0})
end

function Tooltip:StopTooltipFrame(Frame)
	local Id = ChangeIds[Frame]
	
	Tween:Play(Frame, {0.3, "Exponential"}, {GroupTransparency = 1}).Completed:Once(function()
		if ChangeIds[Frame] == Id then
			Frame.Visible = false
			
			ResetTooltipColors(Frame)
		end
	end)
end

---- Update tooltip position

local function StartTooltipRender(TooltipFrame)
	while TooltipFrame.Parent ~= nil do
		while not TooltipFrame.Visible do
			TooltipFrame.Changed:Wait()
		end

		TooltipFrame.Position = GetTooltipPosition(TooltipFrame)
		RunService.PreRender:Wait()
	end
end

for _, Frame in Gui:GetChildren() do
	if Frame:IsA("CanvasGroup") then
		task.defer(StartTooltipRender, Frame)
		ResetTooltipColors(Frame)
	end
end

return Tooltip