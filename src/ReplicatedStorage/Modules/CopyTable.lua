--APIs
--[[
	Copy(Table)
		> return CopiedTable
]]
local CopyTable = {}
function CopyTable.Copy(Table)
	local NewCopy = {}
	for k, v in pairs(Table) do
		if type(v) == "table" then
			v = CopyTable.Copy(v)
		end
		NewCopy[k] = v
	end
	return NewCopy
end
return CopyTable
