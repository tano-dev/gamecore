--[[
	Evercyan @ March 2023
	Maid
	
	Maid is a utility module used for making garbage collection of lots of RBXScriptConnections
	a lot easier and safer to deal with to avoid memory leaks. It is currently only used in very
	few spots in the kit, so you shouldn't need to worry about it much.
	
	Memory leaks are an issue where if you don't disconnect connections, or remove instances added
	up over time, it may cause the memory or performance of your game to increase over time. This can
	lead to server/client lag, crashes, or worse, such as data loss due to a lack of available resources.
	
	Most memory leaks are harmless and are only noticeable in a server that has been up for days at a time, but
	they are still a problem you don't want.
	
	There's a lot you may need to learn to understand what these are though, but I'm sure that gives you the gist of it.
	
	Basically, don't touch anything below unless if you know what you're doing. Same thing wherever this is accessed.
]]

local Maid = {}
Maid.__index = Maid

local function isSignalConnection(Value)
	return typeof(Value) == "table" and Value._signal ~= nil
end

function Maid.new()
	return setmetatable({
		_tasks = {},
		_binds = {},
		_destroyed = false
	}, Maid)
end

function Maid:__newindex(Index, Task)
	local Tasks = self._tasks
	local oldTask = Tasks[Index]
	
	Tasks[Index] = Task
	
	if oldTask then
		if typeof(oldTask) == "RBXScriptConnection" or isSignalConnection(oldTask) then
			oldTask:Disconnect()
		elseif typeof(oldTask) == "table" and oldTask.Destroy ~= nil then
			oldTask:Destroy()
		end
	end
	
	return Task
end

function Maid:Add(Task)
	table.insert(self._tasks, Task)
	
	return Task
end

function Maid:Destroy()
	local Tasks = self._tasks
	local Binds = self._binds
	
	self._destroyed = true
	
	for Index, Task in pairs(Tasks) do
		Tasks[Index] = nil
		if typeof(Task) == "RBXScriptConnection" or isSignalConnection(Task) then
			Task:Disconnect()
		elseif typeof(Task) == "table" and Task.Destroy ~= nil then
			Task:Destroy()
		end
	end
	
	for Index, Bind in ipairs(Binds) do
		Binds[Index] = nil
		Bind()
	end
end

return Maid