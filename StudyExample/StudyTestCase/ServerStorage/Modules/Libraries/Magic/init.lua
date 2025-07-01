--[[
	ej0w @ May 2024
	Magic
	
	Handles serverside & sending to client to replicate magic effect
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")


--> References
local Modules = ServerStorage.Modules

--> Dependancies
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local DamageLib = require(Modules.Libraries.Damage)
local Magic = require(script.Suites)

--> Variables
local ToolLib = {}
local Debounce = {}

--------------------------------------------------------------------------------

-- Invoke
EventModule:GetOnServerInvoke("PlayerCalledMagic", function(Player, MouseHit)
	local Character = Player.Character
	local Humanoid = Character.Humanoid
	local HumanoidRootPart = Character.HumanoidRootPart

	local Tool = Character and Character:FindFirstChildOfClass("Tool")
	local ItemConfig = Tool and Tool:FindFirstChild("ItemConfig") and require(Tool.ItemConfig)
	if not ItemConfig or ItemConfig.WeaponType ~= "Magic" then 
		return 
	end

	local StartPosition = Tool:FindFirstChild("CastPoint", true).WorldPosition
	local EndPosition = MouseHit

	local ManaAttributes = Humanoid:FindFirstChild("Mana")
	if ItemConfig.ManaCost and (not ManaAttributes or ManaAttributes.Mana:GetAttribute("Default") < ItemConfig.ManaCost) then 
		return 
	end

	-- Debounce
	if Debounce[Player.UserId] then return end
	Debounce[Player.UserId] = true
	task.delay(ItemConfig.Cooldown / 1.5, function()
		Debounce[Player.UserId] = nil
	end)

	-- Magnitude/tool
	local function EventCallback(StartPosition, EndPosition, Params)
		return EventModule:FireAllClients("ReplicaMagicCalled", ItemConfig.Suite[1], Tool, StartPosition, EndPosition, Params or {})
	end

	local Success, Hits = nil, nil
	local Callback = ItemConfig.Suite and Magic[ItemConfig.Suite[1]]
	if Callback then
		Success, Hits = Callback(nil, Player, Tool, StartPosition, EndPosition, EventCallback)
	end

	if Success and ItemConfig.ManaCost then
		ManaAttributes.Mana:SetAttribute("Default", ManaAttributes.Mana:GetAttribute("Default") - ItemConfig.ManaCost)
	end
	return Hits
end)

return ToolLib
