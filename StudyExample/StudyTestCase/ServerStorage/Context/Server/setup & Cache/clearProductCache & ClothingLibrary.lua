--> Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Dependencies
local ClothingLibrary = require(ReplicatedStorage.Modules.Shared.ClothingLibrary)
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)

local GameConfig = require(ReplicatedStorage.GameConfig)

--------------------------------------------------------------------------------

local function ClearPlayerCache(Player)
	local Attributes = AttributeModule:GetAttributes(Player)
	for Name, Value in Attributes do
		if Value == true or not tonumber(Name) then
			continue
		end
		
		AttributeModule:SetAttribute(Player, Name, nil)
	end
end

while true do
	for _, Player in Players:GetPlayers() do
		ClearPlayerCache(Player)
	end
	
	task.wait(GameConfig.ProductCacheCleanup)
end

return {}