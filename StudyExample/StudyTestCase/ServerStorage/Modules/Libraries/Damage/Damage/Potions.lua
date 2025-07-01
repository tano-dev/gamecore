return function(Player, Tool, Damage)
	local Character = Player.Character
	local ItemConfig = require(Tool.ItemConfig)
	
	local Statuses = Player:FindFirstChild("Statuses")
	if Statuses then
		local Potion = Statuses.Strength
		Damage = Damage * Potion:GetAttribute("Boost")
	end
	
	return Damage
end