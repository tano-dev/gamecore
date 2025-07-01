--[[
	ej0w @ September 2024
	ClickSounds
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

--> Player
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--> References
local Modules = ReplicatedStorage.Modules

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)
local SFX = require(Modules.Shared.SFX)

--------------------------------------------------------------------------------

-- Click sounds
local function InsertClickSound(Instance: GuiButton)
	if not Instance:IsA("GuiButton") then
		return
	end
	
	Instance.Activated:Connect(function()
		local CanvasGroup = Instance:FindFirstAncestorWhichIsA("CanvasGroup")
		if CanvasGroup and CanvasGroup.GroupTransparency == 1 then
			return
		end
		
		if not Instance.AutoButtonColor then
			return
		end
		
		if not Instance:GetAttribute("DisableSound") then
			SFX:Play2D(GameConfig.ClickSFX[1], {Volume = GameConfig.ClickSFX[2]})
		end
	end)
end

for _, Instance in PlayerGui:GetDescendants() do
	InsertClickSound(Instance)
end
PlayerGui.DescendantAdded:Connect(InsertClickSound)

return {}