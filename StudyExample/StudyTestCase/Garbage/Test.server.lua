local http = game:GetService("HttpService")
local getAsync = http.GetAsync
local jsonDecode = http.JSONDecode

local serversUrl = "https://games.roproxy.com/v1/games/%s/servers/%s?limit=100&cursor=%s"

local function getServersRecursive(placeId, serverType, cursor, servers, tries)
	placeId = 7165274042
	serverType = serverType or "Public"
	cursor = cursor or ""
	servers = servers or {}
	tries = tries or 5
	if tries == 0 then return {} end

	local requestUrl = serversUrl:format(placeId, serverType, cursor)
	local success, result = pcall(getAsync, http, requestUrl)
	if success then
		if result then
			local success2, result2 = pcall(jsonDecode, http, result)
			if success2 then
				if result2 then
					for _, server in ipairs(result2.data) do
						servers[server.id] = {
							["maxPlayers"] = server.maxPlayers,
							["totalPlayers"] = server.playing,
							["fps"] = server.fps,
							["ping"] = server.ping
						}
					end

					cursor = result2.nextPageCursor
					if cursor then
						return getServersRecursive(placeId, serverType, cursor, servers, tries)
					else
						return servers
					end
				end
			else
				task.wait()
				warn(result2)
				tries -= 1
				return getServersRecursive(placeId, serverType, cursor, servers, tries)
			end
		end
	else
		task.wait()
		warn(result)
		tries -= 1
		return getServersRecursive(placeId, serverType, cursor, servers, tries)
	end
end

local servers = getServersRecursive(1818)
for serverId, serverInfo in pairs(servers) do
	print("ID: "..serverId)
	print("Players: "..serverInfo.totalPlayers.."/"..serverInfo.maxPlayers)
	print("FPS: "..serverInfo.fps)
	print("Ping: "..serverInfo.ping)
	print("")
end