--[[
	ej0w @ May 2024
	CreateBoom
]]

local Circle = {}

local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

function Circle.Create(Part, Amount, Colors)
	local Sizes = {
		Vector3.new(8.3, 0.73, 8.3), 
		Vector3.new(9.084, 0.53, 9.084), 
		Vector3.new(7.017, 0.659, 7.017)
	}
	
	local Model = Instance.new("Model")
	Model.Parent = workspace.Temporary
	Model.Name = "Circle" 
	
	for _ = 1, Amount do
		local Effect = script.Circle:Clone()
		Effect.Color = Colors[math.random(1, #Colors)]
		Effect.Size = Sizes[math.random(1, #Sizes)]
		Effect.CFrame = Part.CFrame * CFrame.Angles(math.rad(math.random(-180,180)),math.rad(math.random(-180,180)),math.rad(math.random(-180,180)))
		Effect.Parent = Model
		
		TweenService:Create(Effect,TweenInfo.new(math.random(3,9)*0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Size = Vector3.new(Effect.Size.X, 0, Effect.Size.Z) * math.random(23,30) * 0.1;
			Transparency = 1;
			CFrame = Effect.CFrame * CFrame.Angles(math.rad(math.random(-50,50)),math.rad(math.random(-50,50)),math.rad(math.random(-50,50)))
		}):Play()
	end
	
	Debris:AddItem(Model, .5)
end

return Circle
