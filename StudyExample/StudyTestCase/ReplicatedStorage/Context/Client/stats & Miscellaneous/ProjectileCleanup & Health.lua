--[[
	ej0w @ September 2024
	Cleamup & Health
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")

--> Player
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

--------------------------------------------------------------------------------

-- Projectile cleanup (not the only way to combat, just reliable if things go wrong)
task.spawn(function()
	while true do
		for _, Projectile in workspace:WaitForChild("Temporary").ProjectileCache:GetChildren() do
			local Modified = Projectile:GetAttribute("Modified")
			if Modified and os.clock() - Modified > 5 then
				Projectile:Destroy()
			end
		end
		
		task.wait(GameConfig.DebrisCleanup)
	end
end)

StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)

return {}