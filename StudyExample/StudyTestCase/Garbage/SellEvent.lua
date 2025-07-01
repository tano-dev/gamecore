_Module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ItemStorage = ReplicatedStorage:WaitForChild("GameItems")

function _Module.Sell(plr,item,cost)
	local BP = plr:WaitForChild("Backpack")
	local SG = plr:WaitForChild("StarterGear")
	local lstats = plr:WaitForChild("leaderstats")
	local stat = lstats:WaitForChild("Gold")
	local BPG = BP:FindFirstChild(item)
	local SGG = SG:FindFirstChild(item)
	if (not stat) then return end
	if (BPG~=nil) and (SGG~=nil) then
		stat.Value = stat.Value + cost
		BPG:Destroy(); SGG:Destroy()
	elseif (BPG==nil) and (SGG~=nil) then
		stat.Value = stat.Value + cost
		BPG:Destroy(); SGG:Destroy()
	end
end

return _Module

-- By Evercyan (https://www.roblox.com/users/111334263/profile)