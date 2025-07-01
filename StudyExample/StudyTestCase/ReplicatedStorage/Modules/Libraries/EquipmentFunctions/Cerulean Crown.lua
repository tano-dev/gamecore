-- [CLIENT]

--> Variables
local Callback = {}

-- VV Remove this line or set to false to make this run, left this here for a reference for scripters!
Callback.Disabled = true 

--------------------------------------------------------------------------------

function Callback:OnEquipped(Player, Config)
	print("Armor equipped:", Player, Config)
end

function Callback:OnUnequipped(Player, Config)
	print("Armor unequipped:", Player, Config)
end

return Callback
