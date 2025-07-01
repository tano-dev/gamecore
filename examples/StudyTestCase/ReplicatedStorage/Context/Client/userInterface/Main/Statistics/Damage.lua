--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local Main = PlayerGui:WaitForChild("Main")
local BottomRight = Main:WaitForChild("BottomRight")
local StatisticsFrame = BottomRight:WaitForChild("Statistics")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")
local pData = PlayerData:WaitForChild(Player.UserId)

local Attributes = pData:WaitForChild("Attributes")

--> Dependencies
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local ProductLib = require(ReplicatedStorage.Modules.Shared.Product)
local GetValueScaling = require(ReplicatedStorage.Modules.Shared.getValueScaling)

local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local STREN_DAMAGE_BOOST = GameConfig.Attributes.Strength.Boost[2]
local STREN_DAMAGE_ADD = GameConfig.Attributes.Strength.Boost[1]

local MethodOfGain = GameConfig.Attributes.Strength.MethodOfGain
local StrengthAmplifier = GameConfig.Attributes.Strength.Amplifier

--------------------------------------------------------------------------------

return function(Character, Tool)
	local Humanoid = Character:FindFirstChild("Humanoid")
	local ItemConfig = Tool and Tool:FindFirstChild("ItemConfig")
	ItemConfig = ItemConfig and require(ItemConfig)
	
	local Damage = ItemConfig and (ItemConfig.Damage or (ItemConfig.Suite and ItemConfig.Suite[2].Damage))
	if Damage then
		local ApproximateDamage = (typeof(Damage) == "table" and (Damage[1] + Damage[2]) / 2) or Damage
		local NewDamage = ApproximateDamage

		-- Armor
		local Boosts = Humanoid and Humanoid:FindFirstChild("Boosts")
		local ClassBoost = (ItemConfig.WeaponType and Boosts:FindFirstChild(ItemConfig.WeaponType)) or Boosts.Magic
		if Boosts and ClassBoost then
			for Name, Value in ClassBoost:GetAttributes() do
				local AddInstead = string.find(Name, "Additive")
				NewDamage = (AddInstead and NewDamage + Value) or Value * NewDamage
			end
		end
		for Name, Value in Boosts.All:GetAttributes() do
			local AddInstead = string.find(Name, "Additive")
			NewDamage = (AddInstead and NewDamage + Value) or Value * NewDamage
		end

		-- Potions
		local Statuses = Player:FindFirstChild("Statuses")
		if Statuses then
			local Potion = Statuses.Strength
			NewDamage = NewDamage * Potion:GetAttribute("Boost")
		end
		
		-- Strength
		local Points = Attributes.Strength.Value
		if MethodOfGain == "Add" then
			NewDamage += STREN_DAMAGE_ADD * Points * StrengthAmplifier
		elseif MethodOfGain == "Multiply" then
			NewDamage *= 1 + (STREN_DAMAGE_BOOST * Points * StrengthAmplifier)
		end
		
		-- Products
		local Products = ProductLib:GetProducts(Player)
		local ProductMultiplier = 0
		for _, Product in Products do
			local Buffs = Product.Buffs
			if not Buffs or not Buffs.Damage then
				continue 
			end
			ProductMultiplier += Buffs.Damage
		end
		NewDamage *= (ProductMultiplier + 1)
		
		-- Damage scaling
		NewDamage = GetValueScaling(NewDamage, "Damage", ItemConfig)
		
		-- Finalize
		NewDamage = math.round(NewDamage - ApproximateDamage)
		if NewDamage > 0 then
			StatisticsFrame.Damage.Text = `<b>+{FormatNumber(NewDamage, "Suffix")}</b> Damage`
		end
		StatisticsFrame.Damage.Visible = NewDamage > 0 
	elseif not ItemConfig then
		StatisticsFrame.Damage.Visible = false
	end
end