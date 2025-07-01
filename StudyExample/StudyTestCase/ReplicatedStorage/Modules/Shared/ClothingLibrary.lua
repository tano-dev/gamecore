--[[
	ej0w @ October 2024
	ClothingLibrary
	
	Pulls all template IDs from armor clothing, returnable w/ Module[ArmorName] --> Shirt/Pants
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Dependencies
local ContentLibrary = require(ReplicatedStorage.Modules.Shared.ContentLibrary)

--> Variables
local ClothingLibrary = {}

--------------------------------------------------------------------------------

for _, Armor in ContentLibrary.Armor do
	local Template = {}

	for _, ClassName in {"Shirt", "Pants"} do
		local ClothingID = Armor.Config[ClassName .. "ID"]
		Template[ClassName] = (tonumber(ClothingID) and "rbxassetid//:" .. ClothingID) or ClothingID
	end

	ClothingLibrary[Armor.Name] = Template
end

return ClothingLibrary
