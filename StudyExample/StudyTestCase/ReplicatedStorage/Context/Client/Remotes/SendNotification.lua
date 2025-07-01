--[[
	ej0w @ October 2024
	SendNotification

	Handles server-sided notifications.
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Dependencies
local CreateNotification = require(ReplicatedStorage.Modules.Client.createNotification)

--> Variables
local Remotes = {}

--------------------------------------------------------------------------------

-- Modify this function in order to change remote callback
function Remotes:OnEvent(...)
	return CreateNotification(...)
end

return Remotes