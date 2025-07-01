--[[
	ej0w @ October 2024
	CountTotalCopies
	
	Used to check how many copies of an item someone has
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--> Player
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local GameConfig = require(ReplicatedStorage.GameConfig)

--------------------------------------------------------------------------------

return function(Value, Required, ItemConfig, Player)
	Player = Player or Players.LocalPlayer
	
	local pData = PlayerData:WaitForChild(Player.UserId)
	
	local AdditiveValue = 0
	local MultipliedValue = 0

	for Name, Value in ItemConfig do
		if string.find(Name, "Scaling") and string.find(Name, Required) then
			local Header = string.gsub(Name, "Scaling", "")

			for _Name, Data in Value do
				local Statistic = pData:WaitForChild(Data.Type):WaitForChild(_Name)
				local Multiplier = math.clamp(Statistic.Value, 0, Data.Cap or math.huge)

				local BonusText = ""
				if Data.Multiplier and Data.Multiplier ~= 0 then
					MultipliedValue += Data.Multiplier * Multiplier
				end

				if Data.Additive and Data.Additive ~= 0 then
					AdditiveValue += Data.Additive * Multiplier
				end
			end
		end
	end

	return (Value * (1 + MultipliedValue)) + AdditiveValue
end
