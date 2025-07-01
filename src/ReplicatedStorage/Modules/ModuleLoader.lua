--[[
	ModuleLoader
	A caching module loader for efficient module management
	
	Usage:
	local Loader = require(ReplicatedStorage.Modules.ModuleLoader)
	local MyModule = Loader("MyModuleName")
	
	or for nested modules:
	local MyModule = Loader("SubFolder/MyModuleName")
]]

--> Variables
local Cache = {}
local ModuleLoader = {}

--------------------------------------------------------------------------------

-- Main loader function
function ModuleLoader.Load(moduleName)
	if not moduleName or type(moduleName) ~= "string" then
		warn("[ModuleLoader]: Invalid module name provided")
		return nil
	end
	
	-- Check cache first
	if Cache[moduleName] then
		return Cache[moduleName]
	end
	
	-- Handle nested paths (e.g., "SubFolder/ModuleName")
	local pathParts = string.split(moduleName, "/")
	local currentScript = script
	
	-- Navigate through the path
	for _, part in ipairs(pathParts) do
		local child = currentScript:FindFirstChild(part)
		if not child then
			warn("[ModuleLoader]: Module '" .. moduleName .. "' not found at path: " .. part)
			return nil
		end
		currentScript = child
	end
	
	-- Ensure it's a ModuleScript
	if not currentScript:IsA("ModuleScript") then
		warn("[ModuleLoader]: '" .. moduleName .. "' is not a ModuleScript")
		return nil
	end
	
	-- Require and cache the module
	local success, result = pcall(require, currentScript)
	if success then
		Cache[moduleName] = result
		return result
	else
		warn("[ModuleLoader]: Error loading module '" .. moduleName .. "': " .. tostring(result))
		return nil
	end
end

-- Clear cache (useful for debugging)
function ModuleLoader.ClearCache()
	Cache = {}
end

-- Get cache contents (for debugging)
function ModuleLoader.GetCache()
	return Cache
end

-- Check if module is cached
function ModuleLoader.IsCached(moduleName)
	return Cache[moduleName] ~= nil
end

--------------------------------------------------------------------------------

-- Make it callable directly
setmetatable(ModuleLoader, {
	__call = function(_, moduleName)
		return ModuleLoader.Load(moduleName)
	end
})

return ModuleLoader
