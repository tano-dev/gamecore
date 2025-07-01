--[[
	ej0w @ November 2024
	AutoUpdateWalkspeed
	
	Updates WalkSpeed / JumpPower on the client
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

--> Configuration
local AUTO_UPDATE = {"WalkSpeed", "JumpPower"}

--------------------------------------------------------------------------------

if not GameConfig.AutoUpdateWalkspeedOnClient then
	return {}
end

local function CharacterAdded(Character)
	local Humanoid = Character:WaitForChild("Humanoid")
	local Attributes = Humanoid:WaitForChild("Attributes")
	
	for _, Attribute in AUTO_UPDATE do
		local Configuration = Attributes:FindFirstChild(Attribute)
		if Configuration then
			local function OnChanged()
				local Total = 0
				for _, Value in Configuration:GetAttributes() do
					Total += Value
				end
				
				Humanoid[Attribute] = Total
			end
			
			Configuration.AttributeChanged:Connect(OnChanged)
			OnChanged()
		end
	end
end

local function PlayerAdded(Player)
	if Player.Character then
		task.spawn(CharacterAdded, Player.Character)
	end
	
	Player.CharacterAdded:Connect(CharacterAdded)
end

for _, Player in Players:GetPlayers() do
	task.spawn(PlayerAdded, Player)
end

Players.PlayerAdded:Connect(PlayerAdded)

return {}