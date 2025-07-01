--[[
	ej0w @ October 2024
	CreateValue
	
	Used for item libraries to add new items
]]

return function(pData, Item, Amount, Library)
	Amount = Amount or 1
	
	local ItemValue = pData.Items[Library]:FindFirstChild(Item.Name)
	if not ItemValue then return end

	if ItemValue.Value - Amount <= 0 then
		ItemValue:Destroy()
	else
		ItemValue.Value -= Amount
	end
end