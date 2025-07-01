--[[
	GoodSignal Class
	stravant @ July 2021
	Edited slightly by Evercyan to add globals & 'Once' method
	
	Used for creating custom Signals - basically the signals like RBXScriptSignal is (workspace.ChildAdded, Players.PlayerAdded are both signals, because you can connect to them!)
	Difference here compared to a BindableEvent is that it's way faster without the need of creating tons of instances using metatable magic!
]]

local freeRunnerThread = nil

local function acquireRunnerThreadAndCallEventHandler(fn, ...)
	local acquiredRunnerThread = freeRunnerThread
	freeRunnerThread = nil
	fn(...)
	freeRunnerThread = acquiredRunnerThread
end

local function runEventHandlerInFreeThread(...)
	acquireRunnerThreadAndCallEventHandler(...)
	while true do
		acquireRunnerThreadAndCallEventHandler(coroutine.yield())
	end
end

---- CONNECTION CLASS ----------------------------------------------------------

local Connection = {}
Connection.__index = Connection

function Connection.new(signal, fn)
	return setmetatable({
		_connected = true,
		_signal = signal,
		_fn = fn,
		_next = false,
	}, Connection)
end

function Connection:Disconnect()
	if not self._connected then
		return
	end 
	self._connected = false
	
	if self._signal._handlerListHead == self then
		self._signal._handlerListHead = self._next
	else
		local prev = self._signal._handlerListHead
		while prev and prev._next ~= self do
			prev = prev._next
		end
		if prev then
			prev._next = self._next
		end
	end
end

setmetatable(Connection, {
	__index = function(tb, key)
		error(("Attempt to get Connection::%s (not a valid member)"):format(tostring(key)), 2)
	end,
	__newindex = function(tb, key, value)
		error(("Attempt to set Connection::%s (not a valid member)"):format(tostring(key)), 2)
	end
})

---- SIGNAL CLASS --------------------------------------------------------------

local Signals = {}

local Signal = {}
Signal.__index = Signal
Signal.ClassName = "Signal"

export type Signal = typeof(Signal)

function Signal.new(Name: string?): Signal
	if Name and Signals[Name] then
		return Signals[Name]
	else
		local signal = setmetatable({
			_handlerListHead = false
		}, Signal)
		
		if Name then
			signal.Name = Name
			Signals[Name] = signal
		end
		
		return signal
	end
end

function Signal:Connect(fn)
	local connection = Connection.new(self, fn)
	if self._handlerListHead then
		connection._next = self._handlerListHead
		self._handlerListHead = connection
	else
		self._handlerListHead = connection
	end
	return connection
end

function Signal:Once(fn)
	local cn; cn = self:Connect(function(...)
		cn:Disconnect()
		fn(...)
	end)
	
	return cn
end

function Signal:DisconnectAll()
	if rawget(self, "Name") then
		Signals[self.Name] = nil
	end
	self._handlerListHead = false
end

Signal.Destroy = Signal.DisconnectAll

function Signal:Fire(...)
	local item = self._handlerListHead
	while item do
		if item._connected then
			if not freeRunnerThread then
				freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
			end
			task.spawn(freeRunnerThread, item._fn, ...)
		end
		item = item._next
	end
end

function Signal:Wait()
	local waitingCoroutine = coroutine.running()
	local cn;
	cn = self:Connect(function(...)
		cn:Disconnect()
		task.spawn(waitingCoroutine, ...)
	end)
	return coroutine.yield()
end

return Signal