--!strict
local RemoteFunction = require(script.Parent)

local remoteFunction = RemoteFunction.new("Test", function(player, ...)
	print("Server Received:", ...)
	local random = math.random(1, 100)
	print("Server Sent:", random)
	return random
end)

local player = game.Players.PlayerAdded:Wait()

for index = 1, 4 do
	print("Server Loop Sent:", index)
	warn("Server Loop Received:", remoteFunction:Fire(player, index))
	task.wait(8)
end