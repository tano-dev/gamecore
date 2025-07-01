--[[
	SafeWait
	Yields until an instance is found inside of an item. To my knowledge, this is used to counteract issues with streaming.
]]

return function(Item: Instance, Name: string): Instance?
	if not Item then
		return
	elseif Item:FindFirstChild(Name) then
		return Item:FindFirstChild(Name)
	end

	local ItemAdded = Instance.new("BindableEvent")
	local Connections = {}
	
	local function ClearConnections()
		for _, Connection in Connections do
			Connection:Disconnect()
			Connections = nil
		end
		Connections = {}
	end
	
	Connections[#Connections + 1] = Item.ChildAdded:Connect(function(Child)
		if Child.Name == Name then
			ItemAdded:Fire(Child)
			ItemAdded:Destroy()
			ClearConnections()
		end
	end)
	Connections[#Connections + 1] = Item.Destroying:Once(function()
		ItemAdded:Fire()
		ItemAdded:Destroy()
		ClearConnections()
	end)

	return ItemAdded.Event:Wait()
end