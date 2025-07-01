--[[
	FormatLoader
	Loader specifically for Format modules
	
	Usage:
	local FormatLoader = require(ReplicatedStorage.Format.FormatLoader)
	local EquipmentFormat = FormatLoader("EquipmentFormat")
]]

--> Variables
local Cache = {}

--------------------------------------------------------------------------------

local function loadFormat(moduleName)
	if not moduleName or type(moduleName) ~= "string" then
		warn("[FormatLoader]: Invalid module name provided")
		return nil
	end
	
	-- Check cache first
	if Cache[moduleName] then
		return Cache[moduleName]
	end
	
	-- Handle nested paths
	local pathParts = string.split(moduleName, "/")
	local currentScript = script.Parent
	
	-- Navigate through the path
	for _, part in ipairs(pathParts) do
		local child = currentScript:FindFirstChild(part)
		if not child then
			warn("[FormatLoader]: Format module '" .. moduleName .. "' not found at path: " .. part)
			return nil
		end
		currentScript = child
	end
	
	-- Ensure it's a ModuleScript
	if not currentScript:IsA("ModuleScript") then
		warn("[FormatLoader]: '" .. moduleName .. "' is not a ModuleScript")
		return nil
	end
	
	-- Require and cache the module
	local success, result = pcall(require, currentScript)
	if success then
		Cache[moduleName] = result
		return result
	else
		warn("[FormatLoader]: Error loading format module '" .. moduleName .. "': " .. tostring(result))
		return nil
	end
end

return loadFormat
