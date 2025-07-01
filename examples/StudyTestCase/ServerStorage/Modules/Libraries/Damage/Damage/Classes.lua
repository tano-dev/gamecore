return function(Player, Tool, Damage)
	local Character = Player.Character
	local ItemConfig = require(Tool.ItemConfig)
	
	local Humanoid = Character and Character:FindFirstChild("Humanoid")
	local Boosts = Humanoid and Humanoid:WaitForChild("Boosts")

	local ClassBoost = (ItemConfig.WeaponType and Boosts:FindFirstChild(ItemConfig.WeaponType)) or Boosts.Magic
	if Boosts and ClassBoost then
		for Name, Value in ClassBoost:GetAttributes() do
			local AddInstead = string.find(Name, "Additive")
			Damage = (AddInstead and Damage + Value) or Value * Damage
		end
	end

	for Name, Value in Boosts.All:GetAttributes() do
		local AddInstead = string.find(Name, "Additive")
		Damage = (AddInstead and Damage + Value) or Value * Damage
	end
	
	return Damage
end