-- ServerModules Loader
local Cache = {}
--a
return function(moduleName)
	local Module = script:FindFirstChild(moduleName)
	
	if Module and Module:IsA("ModuleScript") then
		local Cached = Cache[Module.Name] or require(Module)
		Cache[Module.Name] = Cached
		
		return Cached
	end
end
