--[[
	ej0w @ September 2024
	ClientMain
	
	Unloads all client-side code. Add directly to Context.
	Not reccommended to add new pieces of code here, old framework tended to get messy.
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Dependencies
local RunFramework = require(ReplicatedStorage.Modules.Shared.runFramework)

--> Variables
local Locations = {
	ReplicatedStorage.Context.Client,
	ReplicatedStorage.Context.Shared,
	ReplicatedStorage.Modules.Libraries,
	script
}

--------------------------------------------------------------------------------
-- Initially require client-sided modules w/ priority

RunFramework(Locations)