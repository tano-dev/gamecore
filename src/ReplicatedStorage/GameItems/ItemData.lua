--[[
	ItemData - Legacy file, now redirects to ItemDataStogare
	
	This file is kept for backward compatibility.
	All new code should use the unified ItemDataStogare.lua
]]

-- Import the unified item data
local ItemDataStogare = require(script.Parent.ItemDataStogare)

-- Return the ByID table for backward compatibility
return ItemDataStogare.ByID
