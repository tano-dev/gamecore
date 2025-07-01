--[[
	ej0w @ October 2024
	Collection

	Collection is a module which controls workspace objects depending on their
	CollectionService tag. Add a new module below this script & name it the correct
	Tag, and it'll automatically program the objects in Workspace with the same tag
	Depending on the code specified.
]]

--> Services
local CollectionService = game:GetService("CollectionService")

--------------------------------------------------------------------------------

for _, Item in script:GetDescendants() do
	local IsValidModule = Item:IsA("ModuleScript") and 
		not (Item:FindFirstAncestorWhichIsA("ModuleScript") == Item)

	if not IsValidModule then 
		continue 
	end

	local Callback = require(Item)

	local function RequestCollectObject(Object)
		local Thread = task.spawn(Callback, Object)

		Object.AncestryChanged:Connect(function(Child, Parent)
			if Parent == nil then
				task.cancel(Thread)
			end
		end)
	end

	for _, Tagged: Instance in CollectionService:GetTagged(Item.Name) do
		RequestCollectObject(Tagged)
	end
	CollectionService:GetInstanceAddedSignal(Item.Name):Connect(RequestCollectObject)
end

return {}