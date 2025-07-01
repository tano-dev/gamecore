--[[
	ej0w @ October 2024
	AttackFunctions
	
	Set custom attack cycles under this script, works similar to hitcyclefunctions
	Defaults to Default if no name is found for the mob
]]

--> Variables
local AttackFunctions = {}

local Library = {}
for _, Module in script:GetChildren() do
	Library[Module.Name] = require(Module)
end

--------------------------------------------------------------------------------

function AttackFunctions:GetAttackCycle(Mob)
	return Library[Mob.Config.Name] or Library.Default
end

function AttackFunctions:GetLibrary()
	return Library
end

return AttackFunctions