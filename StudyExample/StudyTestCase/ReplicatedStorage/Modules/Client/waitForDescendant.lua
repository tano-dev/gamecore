--[[
	WaitForDescendant
	Yields until a child which matches the given name has been found
]]

return function(Parent: Instance, Name: string)
	local Item = Parent:FindFirstChild(Name, true)

	if Item then
		return Item
	elseif not Item then
		local BindableEvent = Instance.new("BindableEvent")
		local Connection; Connection = Parent.DescendantAdded:Connect(function(Item)
			if Item.Name == Name then
				BindableEvent:Fire(Item)
			end
		end)

		Item = BindableEvent.Event:Wait()
		Connection:Disconnect()
		return Item
	end
end
