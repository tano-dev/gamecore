--[[
	ej0w @ November 2024
	Event
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local Event = {}

---- Create remotes ----------------------------------------------------------------------------

local Remotes
if RunService:IsServer() then
	Remotes = script:FindFirstChild("Remotes") or Instance.new("Folder")
	Remotes.Name = "Remotes"
	Remotes.Parent = script

	for _, Remote in GameConfig.Remotes do
		if not Remotes:FindFirstChild(Remote[1]) then
			local NewRemote = Instance.new(Remote[2])
			NewRemote.Name = Remote[1]
			NewRemote.Parent = Remotes
		end
	end
end

Remotes = Remotes or script:WaitForChild("Remotes")

function Event:GetRemote(Name)
	return Remotes:FindFirstChild(Name)
end

---- Fire to others ----------------------------------------------------------------------------

function Event:FireServer(Name, ...)
	local Remote = Remotes:FindFirstChild(Name) :: RemoteEvent
	if Remote then
		Remote:FireServer(...)
	end
end

function Event:FireClient(Name, ...)
	local Remote = Remotes:FindFirstChild(Name) :: RemoteEvent
	if Remote then
		Remote:FireClient(...)
	end
end

function Event:FireAllClients(Name, ...)
	local Remote = Remotes:FindFirstChild(Name) :: RemoteEvent
	if Remote then
		Remote:FireAllClients(...)
	end
end

function Event:Fire(Name, ...)
	local Remote = Remotes:FindFirstChild(Name) :: BindableEvent
	if Remote then
		Remote:Fire(...)
	end
end

function Event:InvokeServer(Name, ...)
	local Remote = Remotes:FindFirstChild(Name) :: RemoteFunction
	if Remote then
		return Remote:InvokeServer(...)
	end
end

function Event:InvokeClient(Name, ...)
	local Remote = Remotes:FindFirstChild(Name) :: RemoteFunction
	if Remote then
		return Remote:InvokeClient(...)
	end
end

function Event:Invoke(Name, ...)
	local Remote = Remotes:FindFirstChild(Name) :: BindableFunction
	if Remote then
		return Remote:Invoke(...)
	end
end

---- Get event ----------------------------------------------------------------------------

function Event:GetOnServerEvent(Name): RBXScriptConnection
	local Remote = Remotes:FindFirstChild(Name) :: RemoteEvent
	if Remote then
		return Remote.OnServerEvent
	end
end

function Event:GetOnClientEvent(Name): RBXScriptConnection
	local Remote = Remotes:FindFirstChild(Name) :: RemoteEvent
	if Remote then
		return Remote.OnClientEvent
	end
end

function Event:GetOnEvent(Name): RBXScriptConnection
	local Remote = Remotes:FindFirstChild(Name) :: BindableEvent
	if Remote then
		return Remote.Event
	end
end

function Event:GetOnServerInvoke(Name, Callback)
	local Remote = Remotes:FindFirstChild(Name) :: RemoteFunction
	if Remote then
		Remote.OnServerInvoke = Callback
	end
end

function Event:GetOnClientInvoke(Name, Callback)
	local Remote = Remotes:FindFirstChild(Name) :: RemoteFunction
	if Remote then
		Remote.OnClientInvoke = Callback
	end
end

function Event:GetOnInvoke(Name, Callback)
	local Remote = Remotes:FindFirstChild(Name) :: BindableFunction
	if Remote then
		Remote.OnInvoke = Callback
	end
end

return Event