local UserInputService = game:GetService("UserInputService")
local UIScale = script:WaitForChild("UIScale")
local InteractFrame = script.Parent.Interact.NameFrame
local PercentChanged = 1
local ctrlKeyL = Enum.KeyCode.LeftControl
local ctrlKeyR = Enum.KeyCode.RightControl

-- Return whether left or right shift keys are down
local function isShiftKeyDown()
	return UserInputService:IsKeyDown(ctrlKeyL) or UserInputService:IsKeyDown(ctrlKeyR)
end

-- Handle user input began differently depending on whether a shift key is pressed
local function input(_input, _gameProcessedEvent)
	if not isShiftKeyDown() then
		for i,v in pairs(script.Parent.OnInteract.Frame.HolderFrame.Keybinds:GetChildren()) do
			if v:IsA("TextButton") then
				v.Visible = false
			end
		end
		script.Parent.OnInteract.Frame.HolderFrame.Keybinds.Cancel.Visible = true
		script.Parent.OnInteract.Frame.HolderFrame.Keybinds.Note.Visible = true
		script.Parent.OnInteract.Frame.HolderFrame.Keybinds.Weapon.Visible = true
		script.Parent.OnInteract.Frame.HolderFrame.Keybinds.Offhand.Visible = true
		
	else
		for i,v in pairs(script.Parent.OnInteract.Frame.HolderFrame.Keybinds:GetChildren()) do
			if v:IsA("TextButton") then
				v.Visible = true
			elseif v:IsA("TextLabel") then
				v.Visible = false
			end
		end
	end
end




local function Round(n, decimals)
	decimals = decimals or 0
	return math.floor(n * 10^decimals) / 10^decimals
end
InteractFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	local PercentChanged = InteractFrame.AbsoluteSize.Y/27
	print(PercentChanged)
	for i,v in pairs(script.Parent.Interact.ScrollingFrame:GetChildren())do
		if v:IsA("TextLabel") then
			local NewTextSize = 19*PercentChanged
			if Round(NewTextSize) > v:FindFirstChildWhichIsA("UITextSizeConstraint").MinTextSize then
				v:FindFirstChildWhichIsA("UITextSizeConstraint").MaxTextSize = Round(NewTextSize)
			end
		end
	end
end)
local mouse = game.Players.LocalPlayer:GetMouse()

local function positionAtMouse(box)
	local frameSize = box.AbsoluteSize

	--//positions at left corner of mouse
	box.Position = UDim2.fromOffset(mouse.X+PercentChanged*15, mouse.Y+InteractFrame.AbsoluteSize.Y*1.05)
end
script.Parent.Backpack.Inventory.ItemInventory:WaitForChild("1").MouseMoved:Connect(function()
	--local NewX = script.Parent.Backpack.Inventory.ItemInventory:WaitForChild("1").AbsolutePosition.X+script.Parent.Backpack.Inventory.ItemInventory:WaitForChild("1").AbsoluteSize.X
	--local NewY = script.Parent.Backpack.Inventory.ItemInventory:WaitForChild("1").AbsolutePosition.Y+script.Parent.Backpack.Inventory.ItemInventory:WaitForChild("1").AbsoluteSize.Y
	--script.Parent.Interact.Position = UDim2.fromOffset(NewX*1.01,NewY*1.01)
	positionAtMouse(script.Parent.Interact)
end)
script.Parent.Backpack.Inventory.ItemInventory:WaitForChild("1").MouseLeave:Connect(function()
	script.Parent.Interact.Position = UDim2.new(0, 200,0, 100)
end)
script.Parent.Backpack.Inventory.ItemInventory:WaitForChild("1"):FindFirstChildWhichIsA("TextButton").MouseButton1Click:Connect(function()
	script.Parent.Interact.Visible = false
	local NewX = script.Parent.Backpack.Inventory.ItemInventory:WaitForChild("1").AbsolutePosition.X--+script.Parent.Backpack.Inventory.ItemInventory:WaitForChild("1").AbsoluteSize.X
	local NewY = script.Parent.Backpack.Inventory.ItemInventory:WaitForChild("1").AbsolutePosition.Y--+script.Parent.Backpack.Inventory.ItemInventory:WaitForChild("1").AbsoluteSize.Y
	positionAtMouse(script.Parent.OnInteract)
	script.Parent.OnInteract.Visible = true
	UserInputService.InputBegan:Connect(input)
	script.Parent.Backpack.Inventory.ItemInventory:WaitForChild("1"):FindFirstChildWhichIsA("TextButton").MouseLeave:Connect(function()
		UserInputService.InputBegan:Connect(input):Disconnect()
	end)
end)