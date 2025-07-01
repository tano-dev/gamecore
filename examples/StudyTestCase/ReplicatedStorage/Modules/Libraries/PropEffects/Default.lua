-- CLIENT

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

--> Dependencies
local TweenModel = require(ReplicatedStorage.Modules.Client.tweenModel)

--> References
local _Assets = ReplicatedStorage.Assets
local _PropEffects = _Assets.Effects.Props

--> Variables
local PropEffects = {}

--------------------------------------------------------------------------------

function PropEffects:OnHit(Prop)
	local PropInstance = Prop.Instance
	
	local PropEffect = _PropEffects:FindFirstChild(Prop.Config.PropType)
	if PropEffect then
		for _, Particle in PropEffect:GetDescendants() do
			local Part = PropInstance:FindFirstChild(Particle.Name)
			local Color = Part and Part.Color

			if Color or Particle.Name == "Material" then
				Color = ColorSequence.new(Color or Prop.Config.Color)

				local NewParticle = Particle:Clone()
				NewParticle.Parent = (PropInstance.PrimaryPart or PropInstance:FindFirstChildWhichIsA("BasePart"))
				NewParticle.Color = Color	

				NewParticle:Emit(NewParticle:GetAttribute("Emit"))
				Debris:AddItem(NewParticle, 5)
			end
		end
	end

	local Scale = PropInstance:GetScale()
	task.delay(0.125, function()
		TweenModel(Scale * 0.9, Scale, TweenInfo.new(0.125), Prop.Instance)
	end)
	
	TweenModel(Scale, Scale * 0.9, TweenInfo.new(0.125), Prop.Instance)
end

function PropEffects:OnDeath(Prop)
	-- Add prop effect here :p
end

return PropEffects
