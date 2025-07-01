--[[
	ej0w @ October 2024
	ReturnTooltipInfo
	
	Used for SetTooltipListener, configure tooltips through here
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Dependencies
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local GameConfig = require(ReplicatedStorage.GameConfig)

--------------------------------------------------------------------------------

local function GetLength(t)
	local v = 0
	for _ in t do
		v += 1
	end
	return v
end

-- Configure the information that the tooltip displays here
-- Generally, \n means that the string starts ad a new line, ..= adds onto previous string
-- <xxx> and other richtext markups just modify the string within the case, escaping with </xxx>
return function(ItemInstance, ItemConfig, Info, ItemType, Type, Level)
	local function CreateBreakline()
		Info ..= `\n------------------------------`
	end
	
	if ItemConfig and ItemConfig.Tip then
		Info ..= `\n"{ItemConfig.Tip}"`
	end
	
	if ItemInstance:IsA("Tool") and ItemInstance.ToolTip ~= "" then
		Info ..= `\n"{ItemInstance.ToolTip}"`
	end
	
	if ItemConfig and ItemType == "Tool" and ItemInstance:IsA("Tool") then
		CreateBreakline()
		
		if ItemConfig.ManaCost ~= nil then
			Info ..= `\n<b>-{FormatNumber(ItemConfig.ManaCost, "Suffix")}</b> MP`
		end
		
		if ItemConfig.Damage ~= nil then
			if typeof(ItemConfig.Damage) == "table" then
				Info ..= `<b>\n{FormatNumber(ItemConfig.Damage[1], "Suffix")}-{FormatNumber(ItemConfig.Damage[2], "Suffix")}</b> Damage`
			else
				Info ..= `<b>\n{FormatNumber(ItemConfig.Damage, "Suffix")}</b> Damage`
			end

			local AverageDamage = (typeof(ItemConfig.Damage) == "table" and (ItemConfig.Damage[1] + ItemConfig.Damage[2])/2) or ItemConfig.Damage
			AverageDamage = (ItemConfig.Cooldown and AverageDamage/ItemConfig.Cooldown) or AverageDamage
			Info ..= ` <font size="12" transparency="0.2">[{FormatNumber(math.round(AverageDamage*10)/10, "Suffix")} DPS]</font>`
		end


		if ItemConfig.Cooldown ~= nil then
			Info ..= `\n<b>{ItemConfig.Cooldown}s</b> Cooldown`
		end

		if ItemConfig.DefensePenetration ~= nil and ItemConfig.DefensePenetration[1] > 0 then
			local DefenseSuffix = ""
			if ItemConfig.DefensePenetration[2] then
				DefenseSuffix = `<b>+{FormatNumber(ItemConfig.DefensePenetration[1], "Suffix")}</b> Piercing`
			else
				DefenseSuffix = `<b>{math.round(math.clamp(ItemConfig.DefensePenetration[1] * 100, 0, 100) * 10) / 10}%</b> Piercing`
			end
			
			Info ..= `\n{DefenseSuffix}`
		end

		if ItemConfig.CriticalChance ~= nil and ItemConfig.CriticalChance[2] and ItemConfig.CriticalChance[2] ~= GameConfig.CriticalChance[2] then
			local CriticalPercentage = math.round(math.clamp((1 / ItemConfig.CriticalChance[2]) * 100, 0, 100) * 10) / 10
			Info ..= `\n<b>{CriticalPercentage}%</b> Critical chance`
		end

		if ItemConfig.Tier ~= nil then
			Info ..= `\nTier <b>{FormatNumber(ItemConfig.Tier, "Suffix")}</b>`
		end

		if ItemConfig.Pierce ~= nil and ItemConfig.Pierce > 1 then
			Info ..= `\n<b>Can pierce</b>`
		end
	elseif Type == "Armor" then
		CreateBreakline()
		
		if ItemConfig.Health and ItemConfig.Health ~= 0 then
			Info ..= `\n<b>+{FormatNumber(ItemConfig.Health, "Suffix")}</b> Health Points`
		end
		
		if ItemConfig.WalkSpeed and ItemConfig.WalkSpeed ~= 0 then
			Info ..= `\n<b>+{FormatNumber(ItemConfig.WalkSpeed, "Suffix")}</b> WalkSpeed`
		end
		
		if ItemConfig.JumpPower and ItemConfig.JumpPower ~= 0 then
			Info ..= `\n<b>+{FormatNumber(ItemConfig.JumpPower, "Suffix")}</b> JumpPower`
		end
		
		if ItemConfig.Mana and ItemConfig.Mana ~= 0 then
			Info ..= `\n<b>+{FormatNumber(ItemConfig.Mana, "Suffix")}</b> Mana Points`
		end

		if ItemConfig.Defense and ItemConfig.Defense[1] > 0 then
			local DefenseSuffix = ""
			if ItemConfig.Defense[2] then
				DefenseSuffix = `<b>+{FormatNumber(ItemConfig.Defense[1], "Suffix")}</b> Defense`
			else
				DefenseSuffix = `<b>{math.round(math.clamp(ItemConfig.Defense[1] * 100, 0, 100) * 10) / 10}%</b> Defense`
			end
			
			Info ..= `\n{DefenseSuffix}`
		end

		if ItemConfig.DamageClass then
			local SuffixType = ItemConfig.DamagePoints[2] and "+" or "x"
			Info ..= `\n<b>{SuffixType}{FormatNumber(ItemConfig.DamagePoints[1], "Suffix")}</b> Class boost to <b>{ItemConfig.DamageClass}</b>`
		end
	elseif Type == "Food" or Type == "Spell" then
		local ItemSuite = ItemConfig.Suite and ItemConfig.Suite[2]
		local SuiteName = ItemConfig.Suite and ItemConfig.Suite[1]
		
		CreateBreakline()
		
		-- Spell tooltips
		if ItemConfig.ManaCost then
			Info ..= `\n<b>-{FormatNumber(ItemConfig.ManaCost, "Suffix")}</b> MP`
		end

		if ItemSuite and string.find(SuiteName, "Heal") and Type == "Spell" then
			if ItemSuite.Percentage then
				Info ..= `\n<b>+{math.round(ItemSuite.Percentage * 100)}%</b> HP`
			end
			if ItemSuite.Additive and ItemSuite.Duration then
				Info ..= ` <font size="12" transparency="0.2">[<b>+{math.round(ItemSuite.Additive * 100)}%</b> MaxHealth for {ItemSuite.Duration}s]</font>`
			end
		end

		if ItemSuite and ItemSuite.Damage then
			if ItemSuite.Proportionate then
				Info ..= `\n<b>x{FormatNumber(ItemSuite.Damage, "Suffix")} Best item</b> Tick damage`
			else
				Info ..= `\n<b>{FormatNumber(ItemSuite.Damage, "Suffix")}</b> Tick damage`
			end
		end

		if ItemConfig.Cooldown then
			Info ..= `\n<b>{ItemConfig.Cooldown}s</b> Cooldown`
		else
			Info ..= ` font size="12" transparency="0.2">[Single use]</font>`
		end

		if ItemSuite and ItemSuite.Delay and ItemSuite.Ticks then
			Info ..= `\n<b>{ItemSuite.Delay * ItemSuite.Ticks}s</b> Duration <font size="12" transparency="0.2">[{ItemSuite.Ticks} Ticks]</font>`
		end

		if ItemConfig.Throwable then
			Info ..= `\n<b>Throwable</b>`
		end
		
		-- Potion & food tooltipa
		if ItemSuite.Duration and not ItemConfig.ManaCost then
			if ItemSuite.Multiplier then
				Info ..= `\nGain <b>+{math.round((ItemSuite.Multiplier - 1) * 100)}% {SuiteName}</b> for {ItemSuite.Duration} seconds.`
			end

			if ItemSuite.Percentage then
				Info ..= `\nGain <b>+{math.round(ItemSuite.Percentage * 100)}% {SuiteName}</b> for {ItemSuite.Duration} seconds.`
			end

			if ItemSuite.Addition then
				Info ..= `\nGain <b>+{FormatNumber(ItemSuite.Addition, "Suffix")} {SuiteName}</b> for {ItemSuite.Duration} seconds.`
			end

			if ItemSuite.Boost then
				Info ..= `\nBoost <b>x{FormatNumber(ItemSuite.Boost, "Suffix")} {SuiteName}</b> for {ItemSuite.Duration} seconds.`
			end
		end

		if ItemSuite.Health then
			Info ..= `\nHeals <b>+{FormatNumber(ItemSuite.Health, "Suffix")} Health</b> on usage.`
		end
	elseif Type == "Accessory" then
		CreateBreakline()
		
		if ItemConfig.Health and ItemConfig.Health ~= 0 then
			Info ..= `\n<b>+{FormatNumber(ItemConfig.Health, "Suffix")}</b> Health Points`
		end
		
		if ItemConfig.WalkSpeed and ItemConfig.WalkSpeed ~= 0 then
			Info ..= `\n<b>+{FormatNumber(ItemConfig.WalkSpeed, "Suffix")}</b> WalkSpeed`
		end
		
		if ItemConfig.JumpPower and ItemConfig.JumpPower ~= 0 then
			Info ..= `\n<b>+{FormatNumber(ItemConfig.JumpPower, "Suffix")}</b> JumpPower`
		end
		
		if ItemConfig.Mana and ItemConfig.Mana ~= 0 then
			Info ..= `\n<b>+{FormatNumber(ItemConfig.Mana, "Suffix")}</b> Mana Points`
		end
	end
	
	if ItemConfig then
		local MadeScalingBreakline = false
		
		for _Name, Value in ItemConfig do
			if string.find(_Name, "Scaling") and GetLength(Value) > 0 then
				local Header = string.gsub(_Name, "Scaling", "")
				
				if not MadeScalingBreakline then
					CreateBreakline()
					
					MadeScalingBreakline = true
				end
				
				for Name, Data in Value do
					local BonusText = ""
					if Data.Multiplier and Data.Multiplier ~= 0 then
						BonusText ..= `<b>x{1 + Data.Multiplier}</b>`
					end
					if Data.Additive and Data.Additive ~= 0 then
						BonusText ..= `{BonusText ~= "" and " & " or ""}<b>+{Data.Additive}</b>`
					end
					
					Info ..= `\nScales {Header:lower()} with <b>{Name}</b>, {BonusText} per`
				end
			end
		end
		
		if ItemConfig.DamageTypes then
			for _, Type in ItemConfig.DamageTypes do
				if Type[2] ~= 1 then
					CreateBreakline()
					break
				end
			end

			for _, Type in ItemConfig.DamageTypes do
				if Type[2] == 1 then
					continue
				end
				Info ..= `\nDeals x{FormatNumber(Type[2], "Suffix")} damage to <b>{Type[1]}</b> mobs`
			end
		end
		
		if ItemConfig.Keybinds then
			for Key, Data in ItemConfig.Keybinds do
				CreateBreakline()
				break
			end

			for Key, Data in ItemConfig.Keybinds do
				Info ..= `\n<b>[{Key}]</b> {Data[1]}`
			end
		end
		
		if ItemConfig.CustomBackground then
			CreateBreakline()

			Info ..= `\n<b>{ItemConfig.CustomBackground}</b>`
		end
	end
	
	return Info
end
