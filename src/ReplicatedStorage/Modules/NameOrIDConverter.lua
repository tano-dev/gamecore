--APIs
--[[
Main APIs:
	IDToName(ID)
		> return Name, Type, SubType
		note type is a number
	NameToID(Name)
		> return ID, Type, SubType
		note type is a number
	1--Equipment 2--Consumable 3--Material
]]
local NameOrIDConverter = {}
local ItemData = require(game:GetService("ReplicatedStorage"):WaitForChild("GameItems"):WaitForChild("ItemDataStogare"))
function NameOrIDConverter.IDToName(ID)
	if type(ID) == "string" then
		ID = tonumber(ID)
	end
	for i,v in pairs(ItemData) do
		if v.ID == ID then
			return v.Name , v.ItemType, v.SubType
		end
	end
end
function NameOrIDConverter.NameToID(Name)
	for i,v in pairs(ItemData) do
		if i == Name then
			return v.ID , v.ItemType, v.SubType
		end
	end
end
	


return NameOrIDConverter
