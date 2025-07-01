--[[
	ej0w @ October 2024
	UserInterface
	
	Handles UIs remotely, declutters the StarterGui.
]]

--> Services
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--------------------------------------------------------------------------------

local function RequestAppendInterface(ScreenGui: ScreenGui)
	if ScreenGui:IsA("ScreenGui") then
		local Module = script:FindFirstChild(ScreenGui.Name)
		if Module then
			local Callback = require(Module)
			local Thread = task.spawn(Callback, ScreenGui)
			
			-- Garbagecollect required modules :3
			local function RequestGarbageCollectThread(Child, Parent)
				if Parent == nil then
					task.cancel(Thread)
				end
			end
			
			ScreenGui.AncestryChanged:Connect(RequestGarbageCollectThread)
		end
	end
end

for _, ScreenGui in PlayerGui:GetChildren() do
	task.spawn(RequestAppendInterface, ScreenGui)
end
PlayerGui.ChildAdded:Connect(RequestAppendInterface)

return {}