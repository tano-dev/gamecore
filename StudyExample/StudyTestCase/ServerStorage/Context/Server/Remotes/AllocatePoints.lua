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
function Remotes:OnEvent(Player, Attribute, Amount)
	local pData = PlayerData:FindFirstChild(Player.UserId)
	if not pData then return end
	
	local PointsValue = pData.Points
	local AttributesFolder = pData.Attributes
	
	if Amount == nil or typeof(Amount) ~= "number" or math.abs(Amount) ~= Amount or math.floor(Amount) ~= Amount or Amount ~= Amount then
		return false, "Invalid amount."
	end
	
	if Attribute == nil or typeof(Attribute) ~= "string" or not AttributesFolder:FindFirstChild(Attribute) then
		return false, "Invalid attribute."
	end
	
	if PointsValue.Value <= 0 or PointsValue.Value < Amount then
		return false, "Not enough points to allocate."
	end
	
	local AttributeValue = AttributesFolder:WaitForChild(Attribute)
	local MaxAllocated = GameConfig.Attributes[Attribute].MaxAllocated
	if AttributeValue.Value >= MaxAllocated then
		return false, "Already allocated maximum amount of points into this stat."
	end
	
	if AttributeValue.Value + Amount > MaxAllocated then
		local Addition = MaxAllocated - AttributeValue.Value
		PointsValue.Value -= Addition
		AttributeValue.Value += Addition
	else
		PointsValue.Value -= Amount
		AttributeValue.Value += Amount
	end
	
	return true
end

return Remotes
