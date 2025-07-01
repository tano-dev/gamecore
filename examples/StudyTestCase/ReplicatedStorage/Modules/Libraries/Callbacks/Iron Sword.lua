-- [CLIENT] --> Shared to all clients

--> Variables
local Callback = {}

-- VV Remove this line or set to false to make this run, left this here for a reference for scripters!
Callback.Disabled = true 

--------------------------------------------------------------------------------

--> Cycle: Melee only
--> Allows the user to make sequential attacks ie. lightning strike on the 2nd attack
function Callback:OnActivated(Player, Tool, Cycle: number?)
	warn("Client activated:", Player, Tool, Cycle)
end

function Callback:OnBackpackAdded(Player, Tool) -- Note: activates when item added & on player respawned
	warn("Client backpack added:", Player, Tool)
end

function Callback:OnEquipped(Player, Tool)
	warn("Client equipped:", Player, Tool)
end

function Callback:OnUnequipped(Player, Tool)
	warn("Client unequipped:", Player, Tool)
end

function Callback:OnCritical(Player, Tool, EntityInstance)
	print("Server critical hit:", Player, Tool, EntityInstance)
end

function Callback:OnHit(Player, Tool, EntityInstance)
	print("Client hit:", Player, Tool, EntityInstance)
end

function Callback:OnParried(Player, Tool, EntityInstance)
	print("Client parried:", Player, Tool, EntityInstance)
end

--> Ranged only
function Callback:OnImpacted(Player, Tool, Position, Normal, Hit)
	print("Client impacted:", Player, Tool, Position, Normal, Hit)
end

return Callback
