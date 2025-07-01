--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Dependencies
local ProductLib = require(ReplicatedStorage.Modules.Shared.Product)

--------------------------------------------------------------------------------

return function(Player, Tool, Damage)
	local Character = Player.Character
	local ItemConfig = require(Tool.ItemConfig)
	
	local Products = ProductLib:GetProducts(Player)
	local ProductMultiplier = 0
	for _, Product in Products do
		local Buffs = Product.Buffs
		if not Buffs or not Buffs.Damage then
			continue 
		end
		ProductMultiplier += Buffs.Damage
	end
	
	return Damage * (ProductMultiplier + 1)
end