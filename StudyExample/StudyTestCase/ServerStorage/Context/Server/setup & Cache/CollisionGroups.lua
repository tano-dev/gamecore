--> Services
local PhysicsService = game:GetService("PhysicsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

--------------------------------------------------------------------------------

-- Create collissions
local function SetCollision(Part: BasePart, Group)
	if not Part:IsA("BasePart") then
		return
	end
	Part.CollisionGroup = Group
end

local function RecursiveSetFolder(Folder, Group)
	for _, Part: BasePart in Folder:GetDescendants() do
		SetCollision(Part, Group)
	end
	Folder.ChildAdded:Connect(function(Model: Model)
		if not Model:IsA("Model") or not Model:FindFirstChildWhichIsA("Humanoid") then
			return
		end
		task.defer(function()
			for _, Part: BasePart in Model:GetDescendants() do
				SetCollision(Part, Group)
			end
		end)
	end)
end

PhysicsService:RegisterCollisionGroup("Mobs")
PhysicsService:RegisterCollisionGroup("Players")
if GameConfig.MobCollisionsEnabled then
	PhysicsService:CollisionGroupSetCollidable("Players", "Mobs", false)
	PhysicsService:CollisionGroupSetCollidable("Mobs", "Mobs", false)
	PhysicsService:CollisionGroupSetCollidable("Players", "Players", false)
end

task.defer(RecursiveSetFolder, workspace:WaitForChild("Mobs"), "Mobs")
task.defer(RecursiveSetFolder, workspace:WaitForChild("Characters"), "Players")
return {}