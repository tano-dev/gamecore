--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

--> Player
local Player = Players.LocalPlayer

--> References
local Modules = ReplicatedStorage.Modules
local Effects = ReplicatedStorage.Assets.Effects

--> Variables
local Magic = {}

--------------------------------------------------------------------------------
-- Utilities

--------------------------------------------------------------------------------
-- Configured via the suite's itemtype in magic ItemConfig, if exists, will automatically run this function
-- & the one on the serverside (MagicLib)

function Magic:Arbiter(Tool, StartPosition, EndPosition, Params)
	local Arbiter = Effects.Arbiter

	local ItemConfig = require(Tool.ItemConfig)
	local ItemSuite = ItemConfig.Suite[2]

	local CanExplode = Params.CanExplode

	local BezierModule = require(Arbiter.BezierModule)
	local Circle = require(Arbiter.Circle)
	local Boom = require(Arbiter.CreateBoom)

	local Projectile = Arbiter.Projectiles:FindFirstChild(ItemSuite.Projectile)

	local Fire = Projectile:Clone()
	task.wait(0.03)
	
	local Size = ItemSuite.BlastRadius * 2

	local Magnitude = (StartPosition - EndPosition).Magnitude
	local Midpoint = (StartPosition - EndPosition) / 2

	local PointA = CFrame.new(CFrame.new(StartPosition) * (Midpoint / -1.5)).Position
	local PointB = CFrame.new(CFrame.new(EndPosition) * (Midpoint / 1.5)).Position

	local Offset = math.min(Magnitude / 2, 45)
	PointA = PointA + Vector3.new(math.random(-Offset,Offset),math.random(5, 15),math.random(-Offset,Offset))
	PointB = PointB + Vector3.new(math.random(-Offset,Offset),math.random(5, 15),math.random(-Offset,Offset))

	Fire.Parent = workspace.Temporary
	Fire.Position = StartPosition
	Fire.Attachment2.TrailTing.Lifetime = 0.25

	if not CanExplode then
		Fire.Attachment2.TrailTing.Transparency = NumberSequence.new(0.75)
		Fire.Transparency = 1
	end

	local Speed = 4
	for Iteration = 5, Magnitude, Speed do
		local Percent = Iteration/Magnitude
		local Coordinate = BezierModule:cubicBezier(Percent, StartPosition, PointA, PointB, EndPosition)
		Fire.CFrame = Fire.CFrame:Lerp(CFrame.new(Coordinate, EndPosition), Percent)
		RunService.Heartbeat:Wait()
	end

	if CanExplode then
		TweenService:Create(Fire,TweenInfo.new(math.random(3,9)*0.1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Size = Vector3.new(Size, Size, Size),
			Transparency = 1,
			CFrame = Fire.CFrame * CFrame.Angles(math.rad(math.random(-50,50)),math.rad(math.random(-50,50)),math.rad(math.random(-50,50))),
		}):Play()
		Debris:AddItem(Fire, 1)
		Boom.Create(Fire, ItemSuite.VFX, ItemSuite.Data)
	else
		Debris:AddItem(Fire, 0.25)
	end
end

return Magic