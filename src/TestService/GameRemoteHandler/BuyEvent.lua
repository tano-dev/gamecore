_Module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemStorage = ReplicatedStorage:WaitForChild("GameItems")

function _Module.Purchase(plr,item,cost)
	local BP = plr:WaitForChild("Backpack")
	local SG = plr:WaitForChild("StarterGear")
	local lstats = plr:WaitForChild("leaderstats")
	local stat = lstats:WaitForChild("Gold")
	local LoadedGear = ItemStorage:FindFirstChild(item)
	if (not stat) then return end
	if (not LoadedGear) then return end
	if (not BP:FindFirstChild(item)) then
		if (not SG:FindFirstChild(item)) then
			stat.Value = stat.Value - cost
			LoadedGear:Clone().Parent = plr.Backpack
			LoadedGear:Clone().Parent = plr.StarterGear
		end
	end
end

return _Module

-- By Evercyan (https://www.roblox.com/users/111334263/profile)