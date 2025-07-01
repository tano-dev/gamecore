--[[
	ej0w @ October 2024
	RunFramework
	
	Runs the client/server framework based on locations, takes in priorities.
]]

return function(Locations)
	local RunPriorities = {}
	
	for _, Location in Locations do
		for _, Item in Location:GetDescendants() do
			local Ancestor = Item:FindFirstAncestorWhichIsA("ModuleScript") 
			local IsValidModule = Item:IsA("ModuleScript") 
				and not (Ancestor and not  Ancestor:GetAttribute("Folder"))
				and not Item:GetAttribute("Folder")

			if not IsValidModule  then 
				continue 
			end

			local Priority = Item:GetAttribute("Priority") or 999

			-- Implementation to replace current priority if already found
			-- Please save me the time and just change the priority.
			local FoundKey = RunPriorities[Priority]
			if FoundKey then
				local HighestIndex = Priority
				for Index, Value in RunPriorities do
					if Index > HighestIndex and Value ~= nil then
						HighestIndex = Index
					end
				end

				Priority = HighestIndex + 1
			end

			RunPriorities[Priority] = Item
		end
	end

	for _, Item in RunPriorities do
		task.defer(function()
			local Contents = require(Item)
			if typeof(Contents) == "function" then
				task.spawn(Contents)
			end
		end)
	end
end
