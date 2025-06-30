--!strict
local RemoteFunction = require(script.Parent)

local remoteFunction = RemoteFunction.new("Test", function(...)
	print("Client Received:", ...)
	local random = math.random(1, 100)
	print("Client Sent:", random)
	return random
end)

task.wait(4)

for index = 1, 4 do
	print("Client Loop Sent:", index)
	warn("Client Loop Received:", remoteFunction:Fire(index))
	task.wait(8)
end