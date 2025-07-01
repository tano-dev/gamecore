--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

local Server = ServerStorage.Modules.Server
local Libraries = ServerStorage.Modules.Libraries

--> Dependencies
local HumanoidAttributes = require(Server.HumanoidAttributes)
local PlayerLeveling = require(Server.PlayerLeveling)
local BoostFunctions = require(Server.BoostFunctions)
local ActivateRagdoll = require(Server.activateRagdoll)
local PlayerUtils = require(Server.PlayerUtils)

local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)
local ProductLib = require(ReplicatedStorage.Modules.Shared.Product)
local GameConfig = require(ReplicatedStorage.GameConfig)
local ContentLibrary = require(ReplicatedStorage.Modules.Shared.ContentLibrary)

local itemLibrary = require(Libraries["items [Subcategories]"])

--> Configuration
local RESPAWN_TIME = 1.5
local ADMIN_ITEMS = {
	--[0] = {{"Tool", "Iron Sword"}}, -- [Player ID] = {{Type, Name}, ...},
}

Players.CharacterAutoLoads = false

--------------------------------------------------------------------------------

local function GiveTemporaryItem(Player, pData, ContentItem)
	local Module = itemLibrary(ContentItem[1])

	if not pData.Items[ContentItem[1]]:FindFirstChild(ContentItem[2]) then
		Module:Give(Player, ContentLibrary[ContentItem[1]][ContentItem[2]], true)
	end
end

local function OnPlayerAdded(Player: Player)
	Player:LoadCharacter()

	local pData = PlayerData:WaitForChild(Player.UserId)
	local Level = pData.Stats.Level
	local XP = pData.Stats.XP
	
	AttributeModule:CreateAttributeFolder(Player)

	-- Character addded
	local function OnCharacterAdded(Character: Model)
		local Humanoid = Character:WaitForChild("Humanoid") :: Humanoid

		AttributeModule:CreateAttributeFolder(Character)
		local ClassBoosts, Statistics, ManaAttributes = PlayerUtils:CreateHumanoidStats(Humanoid)

		-- Humanoid attributes & product handling
		local HumanoidAttributes = HumanoidAttributes.new(Humanoid)

		local GivenMana = 0
		local GivenStats = {
			["Health"] = 0,
			["WalkSpeed"] = 0,
			["JumpPower"] = 0,
		}

		local Products = ProductLib:GetProducts(Player)
		for _, Product in Products do
			for Name: string, Value: number in Product.Attributes do
				if GivenStats[Name] then
					GivenStats[Name] += Value
				elseif Name == "Mana" then
					GivenMana += Value
				end
			end
		end

		for _, Attribute in HumanoidAttributes.Instance:GetChildren() do
			Attribute:SetAttribute("Product", GivenStats[Attribute.Name])
		end
		HumanoidAttributes.Instance.Health:SetAttribute("Level", Level.Value * GameConfig.HealthPerLevel)

		-- Handle mana resetting on player death
		local Mana = ManaAttributes.Mana
		local MaxMana = ManaAttributes.MaxMana

		local function GetMaxMana()
			local MaxManaAmount = 0
			for Name, Value in MaxMana:GetAttributes() do
				if Value ~= Value then Value = 0 end
				MaxManaAmount += Value
			end
			
			return MaxManaAmount
		end
		
		local function ClampMana()
			local MaxMana = GetMaxMana()
			
			if Mana:GetAttribute("Default") > MaxMana then
				Mana:SetAttribute("Default", MaxMana)
			end
		end

		MaxMana:SetAttribute("Product", GivenMana)
		MaxMana:SetAttribute("Level", Level.Value * GameConfig.ManaPerLevel)
		MaxMana.AttributeChanged:Connect(ClampMana)
		
		Mana:SetAttribute("Default", GetMaxMana())
		Mana.AttributeChanged:Connect(ClampMana)

		-- Ragdoll on death
		Humanoid.Died:Connect(function()
			task.delay(RESPAWN_TIME, function()
				pcall(function()
					if Player.Character then
						Player.Character:Destroy()
						Player.Character = nil
					end
					Player:LoadCharacter()
				end)
			end)

			Mana:SetAttribute("Default", 0)
			ActivateRagdoll(Character)
		end)
		
		Humanoid.BreakJointsOnDeath = false

		-- Destroy health regen
		task.defer(function()
			local HealthScript = Character:WaitForChild("Health", 1)
			if HealthScript then
				HealthScript:Destroy()
			end
		end)
		
		-- Parent a forcefield to the torso (prevents weird bugs)
		task.defer(function()
			local Forcefield = Character:WaitForChild("ForceField", 1)
			if Forcefield and Character:WaitForChild("Torso", 0.5) then
				task.wait(0.5)
				Forcefield.Parent = Character.Torso
			end
		end)

		-- Force the character into the correct folder
		task.defer(function()
			Character.Parent = workspace.Characters
		end)
	end
	
	-- Connect on character added
	if Player.Character then
		task.spawn(OnCharacterAdded, Player.Character)
	end
	Player.CharacterAdded:Connect(OnCharacterAdded)
	
	---- Connect player to the rest of stuff!
	
	pData:WaitForChild("Hotbar")
	
	local Logged = PlayerUtils:CheckIfLogged(Player)
	
	-- Player leveling
	task.defer(function()
		PlayerLeveling:TryLevelUp(Player, Level, XP)
		XP.Changed:Connect(function()
			PlayerLeveling:TryLevelUp(Player, Level, XP)
		end)
	end)
	
	PlayerUtils:SetUpChestsLoop(Player, pData:WaitForChild("Chests"))
	PlayerUtils:SetUpManaLoop(Player, Level)
	PlayerUtils:SetUpPlayerStats(Player)
	
	-- Give items (starter, admin items, & prodyct)
	for _, StarterItem in GameConfig.StarterItems do
		GiveTemporaryItem(Player, pData, StarterItem)
	end
	
	local GivenUserID = ADMIN_ITEMS[Player.UserId]
	for _, StarterItem in GivenUserID or {} do
		GiveTemporaryItem(Player, pData, StarterItem)
	end
	
	local Products = ProductLib:GetProducts(Player)
	for _, Product in Products do
		for _, Item: {[number]: string} in Product.Items do
			GiveTemporaryItem(Player, pData, Item)
		end
	end
	
	-- If the hotbar is completely empty, fill it with starter items
	local isEmpty = true
	for _, ValueObject in pData.Hotbar:GetChildren() do
		if ValueObject.Value ~= "" then
			isEmpty = false
		end
	end
	
	if isEmpty and Logged then
		for n, StarterItem in GameConfig.StarterItems do
			if n <= 9 then
				pData.Hotbar[tostring(n)].Value = StarterItem[2]
			end
		end
	end
end

Players.PlayerAdded:Connect(OnPlayerAdded)
for _, Player in Players:GetPlayers() do
	task.spawn(OnPlayerAdded, Player)
end

return {}