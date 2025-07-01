--[[
	@Author: Spynaz
	@Description: Enables dragging on GuiObjects. Supports both mouse and touch.
	
	For instructions on how to use this module, go to this link:
	https://devforum.roblox.com/t/simple-module-for-creating-draggable-gui-elements/230678
--]]

--[[
	Slightly recoded this system to prevent bugs that occurred & clamping to screen size
	- ej0w
]]

local UDim2_new = UDim2.new

local UserInputService = game:GetService("UserInputService")
local CurrentCamera = workspace.CurrentCamera

local DraggableObject 		= {}
DraggableObject.__index 	= DraggableObject

-- Sets up a new draggable object
function DraggableObject.new(Object)
	local self 			= {}
	self.Object			= Object
	self.DragStarted	= nil
	self.DragEnded		= nil
	self.Dragged		= nil
	self.Dragging		= false
	
	setmetatable(self, DraggableObject)
	
	return self
end

-- Enables dragging
function DraggableObject:Enable()
	local object			= self.Object
	local dragInput			= nil
	local dragStart			= nil
	local startPos			= nil
	local preparingToDrag	= false
	
	-- Updates the element
	local function update(input)
		local delta 		= input.Position - dragStart
		
		local newPosition	= UDim2.fromOffset(startPos.X.Offset + delta.X, startPos.Y.Offset + delta.Y)
		newPosition         = UDim2.fromOffset(
			math.clamp(newPosition.X.Offset, 0, CurrentCamera.ViewportSize.X - object.AbsoluteSize.X),
			math.clamp(newPosition.Y.Offset, 0, CurrentCamera.ViewportSize.Y - object.AbsoluteSize.Y)
		)
		
		object.Position 	= newPosition
		return newPosition
	end
	
	self.InputBegan = object.InputBegan:Connect(function(input)
		local validInput = input.UserInputType == Enum.UserInputType.MouseButton1 
			or input.UserInputType == Enum.UserInputType.Touch 
			or input.UserInputType == Enum.UserInputType.Gamepad1
		
		if validInput then
			preparingToDrag = true

			local connection 
			connection = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End and (self.Dragging or preparingToDrag) then
					self.Dragging = false
					connection:Disconnect()
					
					if self.DragEnded and not preparingToDrag then
						self.DragEnded()
					end
					
					preparingToDrag = false
				end
			end)
		end
	end)
	
	self.InputChanged2 = UserInputService.InputChanged:Connect(function(input)
		local validInput = input.UserInputType == Enum.UserInputType.MouseMovement 
			or input.UserInputType == Enum.UserInputType.Touch 
			or input.UserInputType == Enum.UserInputType.Gamepad1
		
		if validInput then
			if object.Parent == nil then
				self:Disable()
				return
			end
			
			if preparingToDrag then
				preparingToDrag = false

				if self.DragStarted then
					self.DragStarted()
				end

				self.Dragging	= true
				dragStart 		= input.Position
				startPos 		= object.Position
			end

			if self.Dragging then
				local newPosition = update(input)

				if self.Dragged then
					self.Dragged(newPosition)
				end
			end
		end
	end)
end

-- Disables dragging
function DraggableObject:Disable()
	self.InputBegan:Disconnect()
	self.InputChanged2:Disconnect()
	
	if self.Dragging then
		self.Dragging = false
		
		if self.DragEnded then
			self.DragEnded()
		end
	end
end

return DraggableObject
