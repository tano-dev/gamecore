--[[
	ej0w @ August 2024
	Spawners
	
	I reccomend to remove the 'Mob' tag from a mob before you add it into the spawnable mobs folder,
	There's no real guarantee that it'll replicate correctly if not with how the framework is written
 	
	Once you have put the mob into the new folder, add a new dict for its data and you'll be fine else

	Handles the configuration of said spawned mobs
	 --> 'Clock' spawn type = every xx seconds
	 --> 'Event' spawn type = whenever an event is triggered (e.b. workspace:GetAttributeChangedSignal("CanSpawnMob") --> RBXScriptConnection)
	 --> 'Check' spawn type = every 1 second, checks whether parameters are given truthful
	
	["Pirate"] = {
		Type = "Clock", -- Event, Clock, Check
		
		Time = 1, -- Clock only
		
		Connection = xx: RBXScriptConnection, -- Event only
		
		Request = function()
			return true / false
		end): Boolean, -- Check only
		
		Despawn = 1, -- Optional
		
		Position = Vector3.new(0, 15, 0),
		Color = Color3.fromRGB(255, 0, 0),
	}
]]

--------------------------------------------------------------------------------

return {
	["Pirate"] = {
		Type = "Clock", -- ^^^ check instructions
		Time = 30, -- Duration until despawn (if time)
		
		Despawn = 60, -- Despawn time if not interacted w/
		
		Position = nil, -- Vector3, if set to nil, will spawn at model origin
		Color = Color3.fromRGB(255, 61, 61), -- Color of the message in chat
	}
}