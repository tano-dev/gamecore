--[[
	ej0w @ October 2024
	CreateValue
	
	Used for item libraries to add new items
]]

return function(pData, Item, DontSave, Amount, Library)
	Amount = Amount or 1
	
	local ValueObject = pData.Items[Library]:FindFirstChild(Item.Name)
	if not ValueObject then
		ValueObject = Instance.new("NumberValue")
		ValueObject.Parent = pData.Items[Library]
		ValueObject.Name = Item.Name
	end
	
	ValueObject.Value += Amount or 1

	if DontSave then
		local DontSaveAttribute = ValueObject:GetAttribute("DontSave") or 0
		ValueObject:SetAttribute("DontSave", DontSaveAttribute + (typeof(DontSave) == "boolean" and 1 or DontSave))
	end

	return ValueObject
end