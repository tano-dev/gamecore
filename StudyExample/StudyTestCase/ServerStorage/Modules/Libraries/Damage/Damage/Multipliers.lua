--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

--> Configuration
local STREN_DAMAGE_BOOST = GameConfig.Attributes.Strength.Boost[2]
local STREN_DAMAGE_ADD = GameConfig.Attributes.Strength.Boost[1]

--------------------------------------------------------------------------------

return function(Player, Tool, Damage, Mob)
	local ItemConfig = require(Tool:FindFirstChild("ItemConfig"))
	
	if ItemConfig and ItemConfig.DamageTypes and Mob.Config.MobTypes then
		local TotalModifier = 0
		
		for _, Type in ItemConfig.DamageTypes do
			if table.find(Mob.Config.MobTypes, Type[1]) then
				TotalModifier += Type[2]
			end
		end
		
		Damage *= (1 + TotalModifier)
	end
	
	return Damage
end