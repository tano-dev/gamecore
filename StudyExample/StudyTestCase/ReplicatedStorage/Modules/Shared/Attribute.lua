--[[
	ej0w @ November 2024
	Attribute
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local Attribute = {}

--------------------------------------------------------------------------------

function Attribute:CreateAttributeFolder(Parent)
	local HeldAttributes = Instance.new("Configuration")
	HeldAttributes.Parent = Parent
	HeldAttributes.Name = "HeldAttributes"
	return HeldAttributes
end

function Attribute:GetAttributeChanged(Parent, Name)
	local HeldAttributes = Parent:WaitForChild("HeldAttributes", 60)
	if HeldAttributes then
		return HeldAttributes:GetAttributeChangedSignal(Name)
	end
end

function Attribute:AttributeChanged(Parent)
	local HeldAttributes = Parent:WaitForChild("HeldAttributes", 60)
	if HeldAttributes then
		return HeldAttributes.AttributeChanged
	end
end

function Attribute:SetAttribute(Parent, Name, Value)
	local HeldAttributes = Parent:FindFirstChild("HeldAttributes")
	if HeldAttributes then
		HeldAttributes:SetAttribute(Name, Value)
	end
end

function Attribute:GetAttributes(Parent, Name)
	local HeldAttributes = Parent:FindFirstChild("HeldAttributes")
	if HeldAttributes then
		return HeldAttributes:GetAttributes()
	end
end

function Attribute:GetAttribute(Parent, Name)
	local HeldAttributes = Parent:FindFirstChild("HeldAttributes")
	if HeldAttributes then
		return HeldAttributes:GetAttribute(Name)
	end
end

return Attribute