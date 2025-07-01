--[[
	UpdatePopupInfo
	Used for shop & pawn shop, updates the information displayed on a popup
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Dependencies
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)

--------------------------------------------------------------------------------

return function(Item, Content)
	if Item.Type == "Tool" and Item.Config.WeaponType ~= nil then
		local Damage = Item.Config.Damage
		local Cooldown = Item.Config.Cooldown
		
		Content.ItemStat1.Text = `<b>Damage</b> {typeof(Damage) == "table" and `{FormatNumber(Damage[1], "Suffix")}-{FormatNumber(Damage[2], "Suffix")}` or `{FormatNumber(Damage, "Suffix")}`}`
		Content.ItemStat2.Text = `<b>Cooldown</b> {FormatNumber(Cooldown, "Suffix")}`
		Content.ItemStat3.Text = `<b>DPS</b> {FormatNumber(math.floor((typeof(Damage) == "table" and ((Damage[1]+Damage[2])/2) or Damage)/Cooldown), "Suffix")}`
		
		for i = 1, 3 do
			Content["ItemStat".. i].Visible = i <= 3 and true or false
		end
	elseif Item.Type == "Armor" or Item.Type == "Accessory" then
		Content.ItemStat1.Text = `<b>HP</b> +{FormatNumber(Item.Config.Health, "Suffix")}`
		Content.ItemStat2.Text = `<b>WS</b> +{FormatNumber(Item.Config.WalkSpeed, "Suffix")}`
		Content.ItemStat3.Text = `<b>JP</b> +{FormatNumber(Item.Config.JumpPower, "Suffix")}`
		
		for i = 1, 3 do
			Content["ItemStat".. i].Visible = i <= 3 and true or false
		end
	elseif Item.Type == "Spell" then
		Content.ItemStat1.Text = `<b>Mana</b> {FormatNumber(Item.Config.ManaCost, "Suffix")}`
		Content.ItemStat2.Text = `<b>Cooldown</b> {FormatNumber(Item.Config.Cooldown, "Suffix")}`
		Content.ItemStat3.Text = `<b>Throwable</b> {Item.Config.Throwable and "True" or "False"}`

		for i = 1, 3 do
			Content["ItemStat".. i].Visible = i <= 3 and true or false
		end
	elseif Item.Type == "Consumable" then
		Content.ItemStat1.Text = `<b>Cooldown</b> {FormatNumber(Item.Config.Cooldown, "Suffix")}`
		Content.ItemStat2.Text = `<b>Reusable</b> {Item.Config.Reusable and "True" or "False"}`
		
		for i = 1, 3 do
			Content["ItemStat".. i].Visible = i <= 2 and true or false
		end
	else
		for i = 1, 3 do
			Content["ItemStat".. i].Visible = false
		end
	end
end
