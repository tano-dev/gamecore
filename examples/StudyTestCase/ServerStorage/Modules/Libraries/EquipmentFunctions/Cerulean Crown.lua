-- [SERVER]

--> Variables
local Callback = {}

-- VV Remove this line or set to false to make this run, left this here for a reference for scripters!
Callback.Disabled = false 

--------------------------------------------------------------------------------

function Callback:OnEquipped(Player, Config)
	local Character = Player.Character

	local Humanoid = Character and Character:FindFirstChildWhichIsA("Humanoid")
	if not Humanoid then return end

	local Boosts = Humanoid:WaitForChild("Boosts")

	-- Change string name to not override others
	Boosts.Melee:SetAttribute("AccessoryAdditive", 5) -- Deals 5 additive DMG
end

function Callback:OnUnequipped(Player, Config)
	local Character = Player.Character

	local Humanoid = Character and Character:FindFirstChildWhichIsA("Humanoid")
	if not Humanoid then return end

	local Boosts = Humanoid:WaitForChild("Boosts")
	Boosts.Melee:SetAttribute("AccessoryAdditive", nil)
end

return Callback
