local LevelingCalculator = require(game:GetService("ReplicatedStorage"):FindFirstChild("Modules"):WaitForChild("LevelingCalculator"))
--function LevelingCalculator.CalculateLevel(Exp)
--local LevelUpMainStats = function(plr,PlayerData,Level,Exp,Superiority)
--	local ExpNeeded = LevelingCalculator.CalculateLevelMain(Level,Superiority)
--	print(ExpNeeded)
--	if Exp >= ExpNeeded then
--		PlayerData:SetAttribute("Exp",Exp - ExpNeeded)
--		PlayerData:SetAttribute("Level",Level + 1)
--	end
--end
--local LevelUpProfession = function(plr,PlayerData,ProfessionName,Profession,ProfessionExp)
--	local ExpNeeded = LevelingCalculator.CalculateLevelProfession(Profession)
--	print(ExpNeeded)
--	if ProfessionExp >= ExpNeeded then
--		PlayerData:SetAttribute(ProfessionName.."Exp",ProfessionExp - ExpNeeded)
--		PlayerData:SetAttribute(ProfessionName,Profession + 1)
--	end
--end

--local GetDatas = function(plr,PlayerData)
--	local Level = PlayerData:GetAttribute("Level")
--	local Exp = PlayerData:GetAttribute("Exp")
--	local Superiority = PlayerData:GetAttribute("Superiority")
--	LevelUpMainStats(plr,PlayerData,Level,Exp,Superiority)
--end
--local GetProfessionDatas = function(plr,PlayerData,ProfessionName)
--	local Profession = PlayerData:GetAttribute(ProfessionName)
--	local ProfessionExp = PlayerData:GetAttribute(ProfessionName.."Exp")
--	LevelUpProfession(plr,PlayerData,ProfessionName,Profession,ProfessionExp)
--end
local RemoteFunc = require(game:GetService("ReplicatedStorage"):FindFirstChild("Modules"):WaitForChild("RemoteFunc"))
--local LevelUp = RemoteFunc.new("OnLevelUp")
local NotifyHolder = game:GetService("ReplicatedStorage"):FindFirstChild("PlayerDataHolder"):WaitForChild("Notify")
--local OnNotify = RemoteFunc.new("OnNotify")
local function OnChanged(PlayerData,Profession)
	local Exp = PlayerData:GetAttribute(Profession)
	local returnlevel,exptonextlvl,nextlvlexp = LevelingCalculator.CalculateLevel(Exp)
	if type(returnlevel) == "boolean" then
		PlayerData:SetAttribute(Profession.."Level",returnlevel)
		PlayerData:SetAttribute(Profession.."ExpLeft",-1)
		PlayerData:SetAttribute(Profession.."NextLevelExp",-1)
	elseif type(returnlevel) == "number"  then
		PlayerData:SetAttribute(Profession.."Level",returnlevel)
		PlayerData:SetAttribute(Profession.."ExpLeft",exptonextlvl)
		PlayerData:SetAttribute(Profession.."NextLevelExp",nextlvlexp)
	end
	
end
local function OnLevelUp(Player,Profession)
	local ProfessionLevel = Player:FindFirstChild("PlayerData"):GetAttribute(Profession.."Level")
	--local LevelUpRespond = LevelUp:Fire(Player, Profession, ProfessionLevel)
	local CreateNotify = Instance.new("ObjectValue",NotifyHolder:FindFirstChild(Player.Name))
	CreateNotify.Name = "LevelUp"
	CreateNotify:SetAttribute("Profession",Profession)
	CreateNotify:SetAttribute("Level",ProfessionLevel) 
	CreateNotify:SetAttribute("Type",3) 
	CreateNotify:AddTag("Notify")
	--print(Player.Name.." is now level ", LevelUpRespond," "..Profession)
end
--[[PlayerStat:SetAttribute("Combat",GetStatsDS[16])
	PlayerStat:SetAttribute("Farming",GetStatsDS[17])
	PlayerStat:SetAttribute("Foraging",GetStatsDS[18])
	PlayerStat:SetAttribute("Fishing",GetStatsDS[19])
	PlayerStat:SetAttribute("Mining",GetStatsDS[20])
	PlayerStat:SetAttribute("Gemcrafting",GetStatsDS[21])
	PlayerStat:SetAttribute("Crafting",GetStatsDS[22])
	PlayerStat:SetAttribute("Alchemy",GetStatsDS[23])
	PlayerStat:SetAttribute("Enchanting",GetStatsDS[24])]]
game.Players.PlayerAdded:Connect(function(plr)
	print(plr)
	plr.CharacterAdded:Connect(function(chr)
		local hum = chr:WaitForChild("Humanoid",10)
		local PlayerData = plr:FindFirstChild("PlayerData")
		--local Level = PlayerData:GetAttribute("Level")
		repeat task.wait() until plr:FindFirstChild("DataLoaded")~=nil
	end)

	local PlayerData = plr:WaitForChild("PlayerData")
	--local Level = PlayerData:GetAttribute("Level")
	--local Exp = PlayerData:GetAttribute("Exp")
	local Superiority = PlayerData:GetAttribute("Superiority")
	--PlayerData:GetAttributeChangedSignal("Superiority"):Connect(function() wait() GetDatas(plr,PlayerData) end)
	repeat task.wait() until plr:FindFirstChild("DataLoaded")~=nil
	PlayerData:GetAttributeChangedSignal("Combat"):Connect(function()OnChanged(PlayerData,"Combat") end)
	PlayerData:GetAttributeChangedSignal("Farming"):Connect(function()OnChanged(PlayerData,"Farming")end)
	PlayerData:GetAttributeChangedSignal("Foraging"):Connect(function()OnChanged(PlayerData,"Foraging")end)
	PlayerData:GetAttributeChangedSignal("Fishing"):Connect(function()OnChanged(PlayerData,"Fishing")end)
	PlayerData:GetAttributeChangedSignal("Mining"):Connect(function()OnChanged(PlayerData,"Mining")end)
	PlayerData:GetAttributeChangedSignal("Gemcrafting"):Connect(function() OnChanged(PlayerData,"Gemcrafting")end)
	PlayerData:GetAttributeChangedSignal("Crafting"):Connect(function()OnChanged(PlayerData,"Crafting")end)
	PlayerData:GetAttributeChangedSignal("Alchemy"):Connect(function()OnChanged(PlayerData,"Alchemy")end)
	PlayerData:GetAttributeChangedSignal("Enchanting"):Connect(function()OnChanged(PlayerData,"Enchanting")end)
	--PlayerData:GetAttributeChangedSignal("CraftingExp"):Connect(function() wait() GetProfessionDatas(plr,PlayerData,"Crafting") end)
	PlayerData:GetAttributeChangedSignal("CombatLevel"):Connect(function()OnLevelUp(plr,"Combat") end)
	PlayerData:GetAttributeChangedSignal("FarmingLevel"):Connect(function()OnLevelUp(plr,"Farming")end)
	PlayerData:GetAttributeChangedSignal("ForagingLevel"):Connect(function()OnLevelUp(plr,"Foraging")end)
	PlayerData:GetAttributeChangedSignal("FishingLevel"):Connect(function()OnLevelUp(plr,"Fishing")end)
	PlayerData:GetAttributeChangedSignal("MiningLevel"):Connect(function()OnLevelUp(plr,"Mining")end)
	PlayerData:GetAttributeChangedSignal("GemcraftingLevel"):Connect(function() OnLevelUp(plr,"Gemcrafting")end)
	PlayerData:GetAttributeChangedSignal("CraftingLevel"):Connect(function()OnLevelUp(plr,"Crafting")end)
	PlayerData:GetAttributeChangedSignal("AlchemyLevel"):Connect(function()OnLevelUp(plr,"Alchemy")end)
	PlayerData:GetAttributeChangedSignal("EnchantingLevel"):Connect(function()OnLevelUp(plr,"Enchanting")end)
end)