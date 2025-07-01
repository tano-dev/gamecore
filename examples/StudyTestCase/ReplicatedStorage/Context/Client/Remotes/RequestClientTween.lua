--[[
	ej0w @ October 2024
	RequestClientTween

	Handles server-sided tweens.
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Dependencies
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)

--> Variables
local Remotes = {}

--------------------------------------------------------------------------------

-- Modify this function in order to change remote callback
function Remotes:OnEvent(Object, Info, Parameters)
	Tween:Play(Object, Info, Parameters)
end

return Remotes