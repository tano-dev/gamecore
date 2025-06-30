local frame = script.Parent
local Ifolder = frame.ItemSecondaryEffect
local Ufolder = frame.UpgradeSecondaryEffect



local function repeatingEffect(num,timer)
	local count = script.Count.Value
	for int = 1,count do
		
		for i,v in pairs(Ifolder:GetChildren()) do
			if tonumber(v.Name) == num then
				v.ImageTransparency -= 1/count
			end
		end
		for i,v in pairs(Ufolder:GetChildren()) do
			if tonumber(v.Name) == num then
				v.ImageTransparency -= 1/count
			end
		end
		task.wait(timer)
	end
	
end
while task.wait(2.5) do
	local timer = script.Timer.Value
	for i,v in pairs(Ifolder:GetChildren()) do
			v.ImageTransparency = 1
	end
	for i,v in pairs(Ufolder:GetChildren()) do
			v.ImageTransparency = 1
	end
	for i = 1,4 do
		repeatingEffect(i,timer)
		
	end
end
