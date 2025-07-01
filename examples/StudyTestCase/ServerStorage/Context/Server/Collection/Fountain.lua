--[[
	Evercyan @ March 2023
	HealingFountain/Server
	
	Handles healing on the server-side
]]

--> Services
local Players = game:GetService("Players")

--------------------------------------------------------------------------------

return function(Fountain)
	local Cooldown = {}
	
	local HealPart = Fountain:WaitForChild("Heal")
	local Timer = Fountain:GetAttribute("Timer")
	
	local Healed = Instance.new("RemoteEvent")
	Healed.Parent = Fountain
	Healed.Name = "Healed"
	
	local function RequestOnTouched(HitPart)
		local Player = Players:GetPlayerFromCharacter(HitPart.Parent)
		local Humanoid = HitPart.Parent:FindFirstChild("Humanoid")

		if Player and Humanoid then
			local Magnitude = (HitPart.Parent:GetPivot().Position - HealPart.Position).Magnitude
			if Magnitude < 100 then -- The client can move this with them on the client-side, and touch events will still pass. Just makes it a tiny bit more tedious, cause then they'd have to TP :3
				if Cooldown[Player] then
					return
				end
				Cooldown[Player] = true

				Humanoid.Health = Humanoid.MaxHealth
				Healed:FireClient(Player, workspace:GetServerTimeNow())

				task.wait(Timer)
				Cooldown[Player] = nil
			end
		end
	end
	
	HealPart.Touched:Connect(RequestOnTouched)
end