--[[
	ej0w @ October 2024
	ReplicaMagicCalled
	
	Handles the clientside of ReplicaMagic.
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Dependencies
local Suites = require(script.Suites)

--> Variables
local Remotes = {}

--------------------------------------------------------------------------------

-- Modify this function in order to change remote callback
function Remotes:OnEvent(Type, Tool, StartPosition, EndPosition, Params)
	local Callback = Suites[Type]
	if Callback then
		return Callback(nil, Tool, StartPosition, EndPosition, Params)
	end
end

return Remotes