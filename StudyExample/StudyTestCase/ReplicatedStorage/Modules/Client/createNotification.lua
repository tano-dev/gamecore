--[[
	ej0w @ October 2024
	CreateNotification
	
	Replacement to the default notification UI
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer

local Main = Player:WaitForChild("PlayerGui"):WaitForChild("Main")
local UIScale = Main:WaitForChild("UIScale")
local BottomRight = Main:WaitForChild("BottomRight")

local Notifications = BottomRight:WaitForChild("Bottom"):WaitForChild("Notifications")

--> References
local Notification = script:WaitForChild("Notification")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)

--------------------------------------------------------------------------------

return function(Title: string, Text: string, IconId: number?, SmallIcon: boolean, ImageColor: Color3?)
	local NewNotification = Notification:Clone()
	NewNotification.Parent = Notifications
	
	IconId = tonumber(IconId) and `rbxassetid://{IconId}` or IconId
	
	local Primary = NewNotification:WaitForChild("Primary")
	local ImageSize = if SmallIcon then 40 else 55
	
	if IconId and ImageColor then
		Primary.ImageLabel.ImageColor3 = ImageColor
	end
	
	if IconId then
		if SmallIcon then
			Primary.ImageLabel.Size = UDim2.fromOffset(ImageSize, ImageSize)
		end
		Primary.ImageLabel.Image = IconId
	elseif not IconId then
		Primary.ImageLabel:Destroy()
	end
	
	local Description = Primary:WaitForChild("Description")
	Description.Label.Text = Title
	Description.Description.Text = Text
	
	task.defer(function()
		local SizeX = NewNotification.AbsoluteSize.X / UIScale.Scale
		Primary.Position = UDim2.fromOffset(-SizeX, 0)
		
		if IconId then
			Description.Size = UDim2.fromOffset(SizeX - ImageSize - 5, 0)
		elseif not IconId then
			Description.Size = UDim2.fromOffset(SizeX + ImageSize + 5, 0)
		end
			
		Tween:Play(Primary, {0.25}, {Position = UDim2.fromOffset(0, 0)})
		Tween:Play(NewNotification, {0.1}, {GroupTransparency = 0})

		task.delay(6, function()
			Tween:Play(Primary, {0.25}, {Position = UDim2.fromOffset(-SizeX, 0)})
			Tween:Play(NewNotification, {0.3}, {GroupTransparency = 1})
		end)
			
		NewNotification.Visible = true
	end)
	
	Debris:AddItem(NewNotification, 6.3)
end