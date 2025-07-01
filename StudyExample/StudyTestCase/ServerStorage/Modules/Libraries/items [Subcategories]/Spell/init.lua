--[[
	ej0w @ May 2024
	SpellLib
	
	Look under the module 'Spells' to configure how the spell system itself works.
	I reccomend to copypaste this script if you're intending to use anything for new libraries
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local ServerStorage = game:GetService("ServerStorage")

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local CreateValue = require(ServerStorage.Modules.Server.createValue)
local RemoveValue = require(ServerStorage.Modules.Server.removeValue)

local Spells = require(script.Suites)

local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Config
local Library = script.Name

local SpellLib = {}
local Cooldown = {}

--------------------------------------------------------------------------------

local function GetUserID(Player)
	local UserId = Player.UserId; if string.find(UserId, "-") then UserId = string.gsub(UserId, "-", "") end
	return UserId
end

function SpellLib:Give(Player: Player, Tool, DontSave, ShopBought, Amount)
	local pData = PlayerData:WaitForChild(Player.UserId, 5)
	
	local isItem = typeof(Tool) == "table" 
	if not isItem then
		warn(`Item {Library} --> {tostring(Tool) or "nil"} doesn't exist as a table, try using ContentLibrary.`)
		return
	end
	
	if pData then
		local Found = pData.Items[Library]:FindFirstChild(Tool.Name)
		
		local IsStackable = GameConfig.CanItemsStack or GameConfig.Categories[Library].IsStackable
		local CanGive = ((not Found) or IsStackable)
		
		local CanBuyMultiple = ShopBought == "Force" or (ShopBought and (not Tool.Config.Cost[4]) and IsStackable)
		if CanGive or CanBuyMultiple then
			CreateValue(pData, Tool, DontSave, Amount, Library)
			
			local StarterGear = Player:FindFirstChild("StarterGear")
			if StarterGear and not StarterGear:FindFirstChild(Tool.Name) then
				Tool.Instance:Clone().Parent = StarterGear
			end
			
			local Backpack = Player:WaitForChild("Backpack")
			if Backpack and not Backpack:FindFirstChild(Tool.Name) then
				Tool.Instance:Clone().Parent = Backpack
			end

			return true
		end
	else
		warn(("pData for Player '%s' doesn't exist! Did they leave?"):format(Player.Name))
	end
end

function SpellLib:Trash(Player: Player, Tool, Amount)
	local pData = PlayerData:WaitForChild(Player.UserId, 5)

	if pData then
		RemoveValue(pData, Tool, Amount, Library)

		local CompletelyRemoved = not pData.Items[Library]:FindFirstChild(Tool.Name)
		if CompletelyRemoved then
			if Player.StarterGear:FindFirstChild(Tool.Name) then
				Player.StarterGear[Tool.Name]:Destroy()
			end
			if Player.Backpack:FindFirstChild(Tool.Name) then
				Player.Backpack[Tool.Name]:Destroy()
			end
			if Player.Character and Player.Character:FindFirstChild(Tool.Name) then
				Player.Character[Tool.Name]:Destroy()
			end
		end
	else
		warn(("pData for Player '%s' doesn't exist! Did they leave?"):format(Player.Name))
	end
end

function SpellLib:Commit(Player, Spell, MobInstance)
	local Character = Player.Character
	local Enemy = MobInstance and MobInstance:FindFirstChild("Enemy")
	if MobInstance and (not Enemy or Enemy.Health <= 0) then return end
	
	-- Get cooldown checks & tool
	local ItemConfig = Spell:FindFirstChild("ItemConfig") and require(Spell.ItemConfig)
	if not ItemConfig.Suite or ItemConfig.Type ~= "Spell" then return end
	if MobInstance and ((Character:GetPivot().Position - MobInstance:GetPivot().Position).Magnitude > 150) then return end
	
	if not MobInstance or not ItemConfig.Suite[2].Damage then
		if Cooldown[Player] and (os.clock() - Cooldown[Player]) < (ItemConfig.Cooldown / 1.5) then return end
		Cooldown[Player] = os.clock()
	end
	
	-- Get suite
	local Suite = ItemConfig.Suite
	local Process = Suite[1]
	local Properties = Suite[2]
	
	-- Commit function
	local Function = Spells[Process]
	if Function then
		task.spawn(Function, nil, Player, Spell, MobInstance, Properties)
	end
end

-- Remotes
EventModule:GetOnServerInvoke("PlayerSpentMana", function(Player, SpellName)
	local Character = Player.Character
	local Humanoid = Character and Character:FindFirstChild("Humanoid") :: Humanoid
	if not Humanoid or not Character then return end
	
	local Tool = Character:FindFirstChild(SpellName) or Player.Backpack:FindFirstChild(SpellName)
	if not Tool or not Tool:IsA("Tool") then return end
	
	local ItemConfig = Tool:FindFirstChild("ItemConfig") and require(Tool.ItemConfig)
	if not ItemConfig or ItemConfig.Type ~= "Spell" then return end
	
	local ManaAttributes = Humanoid:FindFirstChild("Mana")
	if ItemConfig.ManaCost and (not ManaAttributes or ManaAttributes.Mana:GetAttribute("Default") < ItemConfig.ManaCost) then 
		return 
	end
	
	ManaAttributes.Mana:SetAttribute("Default", ManaAttributes.Mana:GetAttribute("Default") - ItemConfig.ManaCost)
	return true
end)

EventModule:GetOnServerEvent("PlayerUsedSpell"):Connect(function(Player, Spell, MobInstance)
	if not Player.Character or Spell == nil then return end
	if (MobInstance ~= nil and typeof(MobInstance) ~= "Instance") or typeof(Spell) ~= "Instance" then return end
	if not Spell:FindFirstChild("ItemConfig") or (not Spell:IsDescendantOf(Player.Character) and not Spell:IsDescendantOf(Player)) then return end
	if MobInstance and not MobInstance:IsDescendantOf(workspace:WaitForChild("Mobs")) then return end
	
	local UserId = GetUserID(Player)
	local RegenerateTag = MobInstance and MobInstance:FindFirstChild("RegenerateTag")
	local Config = MobInstance and MobInstance:FindFirstChild("MobConfig") and require(MobInstance.MobConfig)
	if MobInstance and (not Config or (Config.InstantRefreshData and Config.InstantRefreshData.CanRefresh and RegenerateTag and (RegenerateTag:GetAttribute("PlayerID") ~= UserId and RegenerateTag:GetAttribute("PlayerID") ~= nil))) then return end
	
	local pData = ReplicatedStorage.PlayerData:FindFirstChild(Player.UserId)
	local Level = pData and pData:FindFirstChild("Stats") and pData.Stats:FindFirstChild("Level")
	if MobInstance and (not Level or (Level.Value < Config.Level[2])) then return end
	
	SpellLib:Commit(Player, Spell, MobInstance)
end)
	
return SpellLib