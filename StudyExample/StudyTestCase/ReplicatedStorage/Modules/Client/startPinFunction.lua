--[[
	ej0w @ October 2024
	StartPinFunction
	
	Used to make dynamic UIs that can be dragged and resized
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--> References
local CurrentCamera = workspace.CurrentCamera

--> Dependencies
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local DraggableObject = require(ReplicatedStorage.Modules.Client.DraggableObject)

local GameConfig = require(ReplicatedStorage.GameConfig)

--------------------------------------------------------------------------------

return function(PinFrame)
	local Hovering = false
	local Pressing = false
	
	local RecordedLast = nil
	local NowPosition = nil
	
	local DraggablePinGui = DraggableObject.new(PinFrame)
	DraggablePinGui:Enable()

	PinFrame.Resize.MouseEnter:Connect(function()
		if PinFrame.GroupTransparency ~= 1 then
			Hovering = true
		end
	end)

	PinFrame.Resize.MouseLeave:Connect(function()
		Hovering = false
	end)

	UserInputService.InputBegan:Connect(function(Input)
		if (Input.UserInputType == Enum.UserInputType.MouseButton1 
			or Input.UserInputType == Enum.UserInputType.Touch 
			or Input.UserInputType == Enum.UserInputType.Gamepad1) 
			and Hovering 
		then
			Pressing = true
			RecordedLast = UserInputService:GetMouseLocation()
		end
	end)

	UserInputService.InputEnded:Connect(function(Input)
		if (Input.UserInputType == Enum.UserInputType.MouseButton1 
			or Input.UserInputType == Enum.UserInputType.Touch 
			or Input.UserInputType == Enum.UserInputType.Gamepad1)  
		then
			Pressing = false
			RecordedLast = UserInputService:GetMouseLocation()
		end
	end)

	UserInputService.InputChanged:Connect(function(Input)
		if Pressing and RecordedLast then
			NowPosition = UserInputService:GetMouseLocation()

			local Change = NowPosition - RecordedLast
			RecordedLast = NowPosition

			PinFrame.Size = UDim2.fromOffset(
				math.clamp(PinFrame.AbsoluteSize.X + Change.X, 160, CurrentCamera.ViewportSize.X / 2), 
				math.clamp(PinFrame.AbsoluteSize.Y + Change.Y, 160, CurrentCamera.ViewportSize.Y)
			)
		end
	end)
end