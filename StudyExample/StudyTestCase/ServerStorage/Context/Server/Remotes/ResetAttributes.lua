--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local ContentLibrary = require(ReplicatedStorage.Modules.Shared.ContentLibrary)

local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local Remotes = {}

--------------------------------------------------------------------------------

if not GameConfig.EnabledFeatures.Attributes then
	return {}
end

-- Modify this function in order to change remote callback
function Remotes:OnEvent(Player)
	local pData = PlayerData:FindFirstChild(Player.UserId)
	if not pData then return end
	
	local PointsValue = pData.Points
	local AttributesFolder = pData.Attributes
	
	local TotalAllocated = 0
	for _, Attribute in AttributesFolder:GetChildren() do
		TotalAllocated += Attribute.Value
		Attribute.Value = 0
	end
	
	if TotalAllocated == 0 then
		return false, "No points were allocated to any attributes."
	end
	
	PointsValue.Value += TotalAllocated
	return true
end

return Remotes