local RemoteFunc = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("RemoteFunc"))
local CollectionService = game:GetService("CollectionService")
local OnNotify = RemoteFunc.new("OnNotify")

-- Save the connections so they can be disconnected when the tag is removed
-- This table maps BaseParts with the tag to their Touched connections
local connections = {}

local function onInstanceAdded(object)
	-- Remember that any tag can be applied to any object, so there's no
	-- guarantee that the object with this tag is a BasePart.
	if object:IsA("ObjectValue") then
		connections[object] = coroutine.wrap(function()
			
			local respond
			local Player = game.Players:FindFirstChild(object.Parent.Name)
			if object:GetAttribute("Type") == 1 then
				object:SetAttribute("Timer",10)
				respond = OnNotify:Fire(Player,object:GetAttribute("Type"),object.Name,object:GetAttribute("Rarity"),object)
			elseif object:GetAttribute("Type") == 3 then
				object:SetAttribute("Timer",8)
				respond = OnNotify:Fire(Player,object:GetAttribute("Type"),object:GetAttribute("Profession"),object:GetAttribute("Level"),object)
			end
			
			print(respond)
			while true do
				--// Code
				task.wait(0.5);
				if object:GetAttribute("Timer") <= 0 then object:Destroy() break
				else object:SetAttribute("Timer",object:GetAttribute("Timer")-0.5) end
			end
		end)()
		 --// Don't forget to call it!
	end
end

local function onInstanceRemoved(object)
	-- If we made a connection on this object, disconnect it (prevent memory leaks)
	if connections[object] then
		connections[object]:Disconnect()
		connections[object] = nil
	end
end

-- Listen for this tag being applied to objects
CollectionService:GetInstanceAddedSignal("Notify"):Connect(onInstanceAdded)
CollectionService:GetInstanceRemovedSignal("Notify"):Connect(onInstanceRemoved)

-- Also detect any objects that already have the tag
--for _, object in pairs(CollectionService:GetTagged(tag)) do
--	onInstanceAdded(object)
--end