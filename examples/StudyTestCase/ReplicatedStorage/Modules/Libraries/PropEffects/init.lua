-- [CLIENT]

--[[
	ej0w @ November 2024
	PropEffects
	
	Only here for continuity with other libraries, nothing's ran through here on runtime.
]]

local PropEffects = {}

--------------------------------------------------------------------------------

function PropEffects:RequestEffect(Prop, Name)
	local PropInstance = Prop.Instance :: Model

	local PropModule = Prop.Config.PropEffectName and script:FindFirstChild(Prop.Config.PropEffectName) 
		or script:FindFirstChild(Prop.Config.Name) 
		or script:FindFirstChild("Default")

	PropModule = PropModule and require(PropModule)

	local Callback = PropModule and PropModule[Name]
	if Callback then
		task.spawn(Callback, nil, Prop)
	end
end

return PropEffects