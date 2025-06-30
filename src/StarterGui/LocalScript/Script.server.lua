--Server script
--put it anywhere ya wanted but make sure it will run
local Damage = 20
local function GetTouchingParts(part)
	local connection = part.Touched:Connect(function() end)
	local results = part:GetTouchingParts()
	connection:Disconnect()
	return results
end
local DamageEvent = game.Lighting:WaitForChild("DamageEvent")
local function DealDamage(plr,PassedCFrame,PassedSize)
	local Damager = {}
	local ServerSidedHitbox = Instance.new("Part")
	ServerSidedHitbox.Name = "Hitbox"
	ServerSidedHitbox.CanCollide = false
	ServerSidedHitbox.Anchored = true
	ServerSidedHitbox.Transparency = 1
	ServerSidedHitbox.Size = PassedSize
	ServerSidedHitbox.CFrame = PassedCFrame
	ServerSidedHitbox.Parent = workspace.Terrain 
	local TouchedParts = GetTouchingParts(ServerSidedHitbox)
	for i,v in pairs(TouchedParts) do
		if v.Parent:FindFirstChildOfClass("Humanoid") then
			if not v.Parent:FindFirstChildOfClass("Humanoid"):GetAttribute("Tagged") then
				v.Parent:FindFirstChildOfClass("Humanoid"):SetAttribute("Tagged",plr.Name)
				table.insert(Damager,v.Parent:FindFirstChildOfClass("Humanoid"))
			end
		end
	end
	for i,v in pairs(Damager) do
		v:TakeDamage(Damage)
		v:SetAttribute("Tagged",nil)
	end
	ServerSidedHitbox:Destroy()
end
DamageEvent.OnServerEvent:Connect(DealDamage)