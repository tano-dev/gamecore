--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local GetValueScaling = require(ReplicatedStorage.Modules.Shared.getValueScaling)

local GameConfig = require(ReplicatedStorage.GameConfig)

--------------------------------------------------------------------------------

return function(Player, Tool, Damage)
	local ItemConfig = require(Tool.ItemConfig)
	return GetValueScaling(Damage, "Damage", ItemConfig, Player)
end