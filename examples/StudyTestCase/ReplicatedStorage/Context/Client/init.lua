-- Simply a holder script for the ones below, acts as a folder. (ie. Client("Collection"))

--> Variables
local Cache = {}

--------------------------------------------------------------------------------

return function(Name)
	local Module = script:FindFirstChild(Name)
	
	if Module and Module:IsA("ModuleScript") then
		local Cached = Cache[Module.Name] or require(Module)
		Cache[Module.Name] = Cached
		
		return Cached
	end
end