-- SERVER

--> Variables
local PropEffects = {}

--------------------------------------------------------------------------------

function PropEffects:OnHit(Prop)
	-- Add prop effect here :p
end

function PropEffects:OnDeath(Prop)
	for _, Material in Prop.Material do
		Material:Destroy()
	end

	for _, Base in Prop.Base do
		Base.Transparency += 0.6
		Base.CastShadow = false
	end
end

return PropEffects