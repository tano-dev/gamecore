local ServerFolder = game.ReplicatedStorage:WaitForChild("Server")

local MessagingService = game:GetService("MessagingService")


MessagingService:SubscribeAsync("ServerList", function(data)

	
	data = data.Data
	print(data)
	
	if data.serverId ~= game.JobId then
		
		
		local serverValue = script.ServerName:Clone()

		serverValue.Name = "Server" .. #ServerFolder:GetChildren() + 1
		
		
		serverValue.Value = data.serverId .. " " .. data.players

		serverValue.Parent = ServerFolder
		
		wait(5)
		serverValue:Destroy()
	end
end)


while game.VIPServerId == "" do
		
	
	local data = {
		serverId = game.JobId,
		players = #game.Players:GetPlayers()
	}
	
	MessagingService:PublishAsync("ServerList", data)
	
	
	wait(5)
end