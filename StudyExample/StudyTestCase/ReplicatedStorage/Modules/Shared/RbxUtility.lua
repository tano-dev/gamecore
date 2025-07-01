--> @e0w @5/15/2024
-- will just dump random functions into here yeah
-- ogs get the reference

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local GameConfig = require(game:GetService("ReplicatedStorage").GameConfig)

local Player, pData
if RunService:IsClient() then
	Player = Players.LocalPlayer
	pData = ReplicatedStorage:WaitForChild("PlayerData"):WaitForChild(Player.UserId)
end

local RbxUtility = {}

local Easing = Enum.EasingStyle
local Direction = Enum.EasingDirection

local Presets = {
	QuadInOut = function(Time)
		return TweenInfo.new(Time, Easing.Quad, Direction.InOut)
	end,
	QuadOut = function(Time)
		return TweenInfo.new(Time, Easing.Quad, Direction.Out)
	end,
	CircularOut = function(Time)
		return TweenInfo.new(Time, Easing.Circular, Direction.Out)
	end,
	CircularIn = function(Time)
		return TweenInfo.new(Time, Easing.Circular, Direction.In)
	end,
}

function RbxUtility.SoftAssert(Value, Assertion)
	local Return = Value == false or Value == nil
	
	if Return then
		local String = `RbxUtility Assertion: {Assertion}`
		local Traceback = debug.traceback(String, 3)
		warn(Traceback)
	end
	
	return Return
end

function RbxUtility.Create(ClassName: string, Parent: any, Properties: {}) : any
	local Object = nil :: any
	
	-- Assert arguments
	if RbxUtility.SoftAssert(ClassName, "argument 'ClassName' does not exist.") then
		return
	end
	if RbxUtility.SoftAssert(Parent, "argument 'Parent' does not exist.") then
		return
	end
	if RbxUtility.SoftAssert(Properties, "argument 'Properties' does not exist.") then
		return
	end
	
	-- Create Instance
	Object = Instance.new(ClassName)
	Object.Parent = Parent
	
	for Name, Value in Properties do
		local Success, Return = pcall(function()
			Object[Name] = Value
		end)
		if not Success then
			RbxUtility.SoftAssert(nil, `property '{Name}' is not a valid type for '{ClassName}'.`)
		end
	end
	
	return Object
end

function RbxUtility.SafeTween(Object: Instance, PresetStyle: any, Properties: {}, Bind: boolean?) : Tween
	local Info = nil :: TweenInfo
	
	-- Assert arguments
	if RbxUtility.SoftAssert(Object, "argument 'Object' does not exist.") then
		return
	end
	if RbxUtility.SoftAssert(PresetStyle, "argument 'PresetStyle' does not exist.") then
		return
	end
	if RbxUtility.SoftAssert(Properties, "argument 'Properties' does not exist.") then
		return
	end
	
	-- Create TweenInfo
	if typeof(PresetStyle) == "TweenInfo" then
		Info = PresetStyle
	elseif typeof(PresetStyle) == "number" then
		Info = TweenInfo.new(PresetStyle, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	elseif typeof(PresetStyle) == "table" then
		local Preset = Presets[PresetStyle[2]]
		local Time = PresetStyle[1]
		Info = Preset(Time)
	end
	
	-- Create Tween
	local Tween = TweenService:Create(Object, Info, Properties)
	Tween:Play()
	
	-- Create Binding
	local Binding = nil :: BindableEvent
	if Bind then
		Binding = Instance.new("BindableEvent")
	end
	
	-- Completed
	Tween.Completed:Connect(function()
		if Bind then
			Binding:Fire()
			
			task.defer(function()
				Binding:Destroy()
			end)
		end
		
		Tween:Destroy()
	end)
	
	return Tween, Binding.Event
end

function RbxUtility.CreateHighlight(Model, Duration, Color, Transparency)
	local OldHiglight = Model:FindFirstChildWhichIsA("Highlight")
	if OldHiglight then
		OldHiglight:Destroy()
	end
	
	local Goal = Color or Color3.fromRGB(255, 0, 0)
	
	local Highlight = RbxUtility.Create("Highlight", Model, {
		OutlineTransparency = 1,
		FillTransparency = 1,
		FillColor = Goal,
		Name = "DamageHighlight",
		Adornee = Model,
		DepthMode = Enum.HighlightDepthMode.Occluded,
		Enabled = false,
	}) :: Highlight
	
	task.delay(0.05, function()
		Highlight.Adornee = Model
		Highlight.FillTransparency = Transparency or 0.35
		Highlight.Enabled = true
		RbxUtility.SafeTween(Highlight, {Duration * 1.5, "CircularOut"}, {FillTransparency = 1}, true)

		task.delay(Duration, function()
			if not Highlight then
				return
			end
			Highlight:Destroy()
		end)
	end)
	
	return Highlight
end

function RbxUtility.Fireworks(Position, Count)
	local Colors = {
		Color3.fromRGB(170, 170, 255),
		Color3.fromRGB(255, 170, 127),
		Color3.fromRGB(255, 170, 255),
	}
	
	for Iteration = 1, Count do
		local Firework = RbxUtility.Create("Part", workspace.Temporary, {
			Material = Enum.Material.SmoothPlastic,
			Transparency = 0,
			CastShadow = false,
			Color = Colors[math.random(1, #Colors)],
			Size = Vector3.new(1, 1, 1),
			Shape = "Ball",
			Anchored = true,
			CanCollide = false,
			Position = Position,
		})
		
		local Position = Position + Vector3.new(math.random(-15, 15), math.random(0, 10), math.random(-15, 15))
		RbxUtility.SafeTween(Firework, {2.5, "CircularOut"}, {Position = Position, Transparency = 1}, true)
		
		Debris:AddItem(Firework, 2.5)
	end
end

return RbxUtility