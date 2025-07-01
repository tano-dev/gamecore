return {
	--[[
		[SFX]: {ID, Volume} OR {{ID, Volume}, {ID, Volume}, ...}
		*Set to nil to stop
	]]
	SFX = {1843086140, 0.5},
	
	--[[
		[Lighting]: {Properties = {...}, TemplateName = "xxxx"}
			{Properties = {...}} Can add as many properties as you want; anything inside of the Lighting service
			{TemplateName = "xxxx"} Contains the objects for lighting (set to nil for default)
			
		*Set to nil to stop
	]]
	Lighting = nil, 
	
	Area = nil, -- UI that shows up when entered zone, set to nil to show nothing!
	AreaColor = nil, -- The color of the UI when entered, set to nil to change to white
}