--[[
	ej0w @ May 2024
	CreateBoom
]]

local Boom = {}

local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local Suite = ReplicatedStorage.Assets.Effects:WaitForChild("Arbiter")
local VFX = Suite.VFX

local Circle = require(Suite.Circle)

function Boom.Create(Fire, Name, Data)
	local Effect = VFX:FindFirstChild(Name)
	assert(Effect, `Asset '{Name}' doesn't exist in 'VFX'.`)
	
	local Smoke = Effect:Clone()
	Smoke.Parent = workspace.Temporary
	Smoke.Position = Fire.Position
	Smoke.Impact.TimePosition = 0
	Smoke.Impact.Pitch = math.random(700,750) / 1000
	Smoke.Impact:Play()
	
	TweenService:Create(Smoke.Impact, TweenInfo.new(1), {Volume = 0}):Play()

	Smoke.Smoke:Emit(Data.EffectEmit)
	Debris:AddItem(Smoke, 1)

	Circle.Create(Fire, Data.CircleAmount, Data.CircleColors)
end

return Boom
