--[[
	ej0w @ October 2024
	Animation
	
	Library for animation system & handling, included this because it cluttered the weapon code!!
]]

--> Variables
local Animation = {}

--------------------------------------------------------------------------------

-- Turn an animation table / configurable animation (string & number) into a chosen "rbxassetid://xxx" string.
function Animation:GetAnimationID(ConfigAnimation)
	if ConfigAnimation == nil then
		return
	end

	local isTable = typeof(ConfigAnimation) == "table"
	local ChosenID = isTable and ConfigAnimation[math.random(#ConfigAnimation)] 
		or ConfigAnimation

	if tonumber(ChosenID) then
		ChosenID = `rbxassetid://{ChosenID}`
	end

	return tostring(ChosenID)
end

function Animation:CreateAnimation(Id: number): Animation
	local AnimationInstance = Instance.new("Animation")
	AnimationInstance.AnimationId = self:GetAnimationID(Id)

	return AnimationInstance
end

function Animation:LoadAnimations(Table)
	local NewTable = nil
	
	local isTable = typeof(Table) == "table"
	if isTable then
		for _, ID in Table do
			NewTable = NewTable or {}

			local AnimationInstance = self:CreateAnimation(ID)
			table.insert(NewTable, AnimationInstance)
		end
	elseif Table and not isTable then
		NewTable = {}
		
		local AnimationInstance = self:CreateAnimation(Table)
		table.insert(NewTable, AnimationInstance)
	end

	return NewTable
end

return Animation