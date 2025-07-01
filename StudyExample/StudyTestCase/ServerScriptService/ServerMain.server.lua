--[[
	ej0w @ September 2024
	ServerMain
	
	Unloads all client-side code. Add directly to Context.
	Not reccommended to add new pieces of code here, old framework tended to get messy.
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--> Dependencies
local RunFramework = require(ReplicatedStorage.Modules.Shared.runFramework)

--> Variables
local Locations = {
	ServerStorage.Context.Server,
	ServerStorage.Modules.Libraries,
	ReplicatedStorage.Context.Shared,
	script
}

--------------------------------------------------------------------------------
-- Initially require server-sided modules w/ priority

RunFramework(Locations)