--------------------------------------------------------------------------------
-- Create initial folders

local function CreateFolder(Name: string, Parent: Instance)
	local Folder = Instance.new("Folder")
	Folder.Name = Name
	Folder.Parent = Parent
	return Folder
end

local Temporary = CreateFolder("Temporary", workspace)
CreateFolder("ProjectileCache", Temporary)
CreateFolder("Characters", workspace)

return {}
