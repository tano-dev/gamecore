--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local ContentLibrary = require(ReplicatedStorage.Modules.Shared.ContentLibrary)

--> Variables
local Remotes = {}

--------------------------------------------------------------------------------

-- Modify this function in order to change remote callback
function Remotes:OnEvent(Player, SlotNumber: number, ItemName: string)
	if not SlotNumber or typeof(SlotNumber) ~= "number" then return end
	if not ItemName or typeof(ItemName) ~= "string" or #ItemName > 200 then return end

	local pData = PlayerData:FindFirstChild(Player.UserId)
	local Hotbar = pData and pData:FindFirstChild("Hotbar")
	local ValueObject = Hotbar and Hotbar:FindFirstChild(SlotNumber)

	if ValueObject then
		ValueObject.Value = ItemName
	end
end

return Remotes