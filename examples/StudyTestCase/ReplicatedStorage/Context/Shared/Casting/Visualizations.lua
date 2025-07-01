--[[
	Casting.Visualizations
	This module is used for quickly creating visual segments used for debugging.
	This should NEVER be enabled in non-testing environments.
]]

--> Configuration
local Enabled = false -- Whether or not ray visualizations are enabled. Only for debugging purposes.

--------------------------------------------------------------------------------

local Folder

local function GetFolder()
	if Folder then
		return Folder
	else
		Folder = Instance.new("Folder")
		Folder.Name = "CastingVisualizations"
		Folder.Parent = workspace.Terrain
		return Folder
	end
end

local Visualizations = {}

function Visualizations:CreateSegment(Position, Direction): ConeHandleAdornment?
	if not Enabled then return end
	
	local Adornment = Instance.new("ConeHandleAdornment")
	Adornment.Name = "Segment"
	Adornment.Transparency = 0.1
	Adornment.Color3 = Direction.Magnitude < 8 and Color3.new(0, 0, 0) or Color3.new(1, 1, 1)
	Adornment.Height = Direction.Magnitude
	Adornment.Radius = 0.4
	Adornment.CFrame = CFrame.lookAt(Position - Direction, Position)
	Adornment.AlwaysOnTop = true
	Adornment.Adornee = workspace.Terrain
	Adornment.Parent = GetFolder()
	task.defer(function()
		task.wait(300)
		Adornment:Destroy()
	end)
	
	return Adornment
end

function Visualizations:CreatePoint(Position): SphereHandleAdornment?
	if not Enabled then return end
	
	local Adornment = Instance.new("SphereHandleAdornment")
	Adornment.Name = "Segment"
	Adornment.Transparency = 0.2
	Adornment.Color3 = Color3.fromRGB(30, 35, 40)
	Adornment.Radius = 0.4
	Adornment.CFrame = CFrame.new(Position)
	Adornment.AlwaysOnTop = true
	Adornment.Adornee = workspace.Terrain
	Adornment.Parent = GetFolder()
	task.defer(function()
		task.wait(300)
		Adornment:Destroy()
	end)
	
	return Adornment
end

function Visualizations:CreateHit(Position, Direction): ConeHandleAdornment?
	if not Enabled then return end
	
	local Adornment = Visualizations:CreateSegment(Position, Direction)
	Adornment.Color3 = Color3.fromRGB(195, 176, 70)
	
	return Adornment
end

function Visualizations:CreatePierce(Position, Direction): ConeHandleAdornment?
	if not Enabled then return end
	
	local Adornment = Visualizations:CreateSegment(Position, Direction)
	Adornment.Color3 = Color3.fromRGB(224, 97, 255)
	
	return Adornment
end

function Visualizations:CreateTerminate(Position, Direction): ConeHandleAdornment?
	if not Enabled then return end
	
	local Adornment = Visualizations:CreateSegment(Position, Direction)
	Adornment.Color3 = Color3.fromRGB(195, 69, 69)
	
	return Adornment
end

function Visualizations:CreateOrigin(Position): SphereHandleAdornment?
	if not Enabled then return end
	
	local Adornment = Visualizations:CreatePoint(Position)
	
	return Adornment
end

return Visualizations