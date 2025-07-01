--[[
	ej0w @ October 2024
	HitCycleFunctions
	
	If a mob has any custom hit cycles, set them under this script --> clone the module Default and set it to mob name
	Any melee mob will default to Default if there's no name specified
]]

--> Variables
local HitCycles = {}

local Library = {}
for _, Module in script:GetChildren() do
	Library[Module.Name] = require(Module)
end

--------------------------------------------------------------------------------

function HitCycles:GetHitCycle(Mob)
	return Library[Mob.Config.Name] or Library.Default
end

function HitCycles:GetLibrary()
	return Library
end

return HitCycles