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