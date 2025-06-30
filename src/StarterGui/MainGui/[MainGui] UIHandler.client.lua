game.StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
local UserInputService = game:GetService("UserInputService")
local RemoteFunc = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("RemoteFunc"))
local RomanNumberConverter = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("RomanNumberConverter"))
local LevelingCalculator = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("LevelingCalculator"))
local CollectionService = game:GetService("CollectionService")
local PlayerMouse = game.Players.LocalPlayer:GetMouse()
local Player = game.Players.LocalPlayer
local StringConverterPattern = "(%a+)%s?_%s?(%d+)"
--
local UILibrary = game:GetService("ReplicatedStorage"):WaitForChild("Format"):WaitForChild("UILibrary")
local UILibrary_DropNotify = UILibrary:WaitForChild("DropNotify")
local UILibrary_StatsFrame = UILibrary:WaitForChild("StatsFrame")
local UILibrary_ItemGradient = UILibrary:WaitForChild("ItemGradient")
local UILibrary_ItemGradient_Main = UILibrary_ItemGradient:WaitForChild("MainItemGradient")
local UILibrary_ItemGradient_Secondary = UILibrary_ItemGradient:WaitForChild("SecondItemGradient")
local UILibrary_ItemGradient_Upgrade = UILibrary_ItemGradient:WaitForChild("UpgradeGradient")
local UILibrary_Interact = UILibrary:WaitForChild("Interact")

--
local MainGui = script.Parent
local Backpack = MainGui.Backpack
local Buttons = MainGui.Buttons
local Settings = MainGui.Settings
local PlayerList = MainGui.PlayerList
local Buttons = MainGui.Buttons
local StatsFrame = MainGui.StatsFrame
local ServerNotify = MainGui.ServerNotify
local Interact = MainGui.Interact
local OnInteract = MainGui.OnInteract
--Backpack Materials
local InfoFrame = Backpack.InfoFrame
local InfoFrame_Accessory = InfoFrame.Accessory
local InfoFrame_MainWeaponFrame = InfoFrame.Item
local InfoFrame_StatsFrame = InfoFrame.StatsFrame
local InfoFrame_ButtonBar = InfoFrame.ButtonBar
local InfoFrame_StatsFrame_NameTag = InfoFrame_StatsFrame.ScrollingFrame["0"].NameTag
local InfoFrame_ButtonBar_Equipments = InfoFrame_ButtonBar.Equipment.Button
local InfoFrame_ButtonBar_Accessory = InfoFrame_ButtonBar.Accessory.Button
local InfoFrame_ButtonBar_Stats = InfoFrame_ButtonBar.Stats.Button
local InfoFrame_ButtonBar_Stats_Show = InfoFrame_StatsFrame.ButtonBar.Mode.Button 
local InfoFrame_ButtonBar_Stats_Mode = InfoFrame_StatsFrame.ButtonBar.Advanced.Button 
--Interact
local SelectedItem
local Interact_PercentChanged = 1
local IsOnInteract = false
local IsInOnInteract = false
local CurrentInv 
local Interact_Name =  Interact.FrameName
local Interact_Stats =  Interact.Stats
local AdvInteractOption = false
local SelectedString
--OnInteract
local OnInteract_Frame = OnInteract.Frame
--Inventory
local Inventory = Backpack.Inventory
local Inventory_Item = Inventory.ItemInventory
local Inventory_Consumable = Inventory.ConsumableInventory
local Inventory_Material = Inventory.MaterialInventory
local Inventory_Money = Inventory.MoneyFrame
local Inventory_ButtonBar = Inventory.ButtonBar
local Inventory_ButtonBar_Equipment = Inventory_ButtonBar.Item.TextButton
local Inventory_ButtonBar_Consumables = Inventory_ButtonBar.Consumable.TextButton
local Inventory_ButtonBar_Materials = Inventory_ButtonBar.Material.TextButton
local Inventory_ButtonBar_Close = Inventory_ButtonBar.Close.TextButton
--PlayerList
local PlayerList_Button = PlayerList.Frame.ButtonBar
local PlayerList_Button_Party = PlayerList_Button.Party.TextButton
local PlayerList_Button_Guild = PlayerList_Button.Guild.TextButton
local PlayerList_Button_ServerList = PlayerList_Button.Server.TextButton
local PlayerList_Button_Close = PlayerList_Button.Close.TextButton
local PlayerList_Party = PlayerList.Frame.HolderFrame.Party
local PlayerList_Party_List = PlayerList_Party.PartyList
local PlayerList_Party_Create = PlayerList_Party.NewParty
local PlayerList_Party_Create_Create = PlayerList_Party_Create.Create.TextButton
local PlayerList_Party_Create_Buff = PlayerList_Party_Create.Buff.Buff.TextButton
local PlayerList_Party_Create_Type = PlayerList_Party_Create.Type.Type.TextButton
local PlayerList_Party_Create_SizeText = PlayerList_Party_Create.SizeFrame.SizeText
local PlayerList_Party_Create_SizePlus = PlayerList_Party_Create.SizeFrame["+"].TextButton
local PlayerList_Party_Create_SizeMinus = PlayerList_Party_Create.SizeFrame["-"].TextButton
local PlayerList_Party_MyParty = PlayerList_Party.MyParty
local PlayerList_Party_MyParty_Leave = PlayerList_Party_MyParty.Leave.TextButton
local PlayerList_Party_CreateButton = PlayerList_Party.ButtonBar.CreateParty.TextButton
local PlayerList_Party_ListButton = PlayerList_Party.ButtonBar.PartyList.TextButton
local PlayerList_Guild = PlayerList.Frame.HolderFrame.Guild
local PlayerList_Server = PlayerList.Frame.HolderFrame.Server
local IsPartied = false
local PartySize = 2
local PartySizeMin = 2
local PartySizeMax = 5
local PartyType = 0 -- 0 Public, 1 Private
local PartyBuff = 0 -- 0 coins, 1 exp
--NotifyFrame
local Notify = MainGui.Notify
-->>StatsFrame
--Profession
local ProfessionList = StatsFrame.ProfessionList
local ProfessionDisplay = StatsFrame.ProfessionDisplay

--Combat
local CombatList = StatsFrame.CombatList
local CombatDisplay = StatsFrame.CombatDisplay
local CombatBack = CombatDisplay.Back.TextButton
local IsCombatOn = false
--Class
local ClassList = StatsFrame.ClassList
local ClassListList = StatsFrame.ClassList.Classes.ScrollingFrame
local ClassDisplay = StatsFrame.ClassDisplay
--Spell
local SpellList = StatsFrame.SpellList
local SpellDisplay = StatsFrame.SpellDisplay
--Statbuttons
local StatsFrame_Profession = StatsFrame.ButtonFrame.ButtonFrame.Profession.TextButton
local StatsFrame_Class = StatsFrame.ButtonFrame.ButtonFrame.Class.TextButton
local StatsFrame_Spell = StatsFrame.ButtonFrame.ButtonFrame.Spell.TextButton
local StatsFrame_Close = StatsFrame.ButtonFrame.ButtonFrame.Close.TextButton
--Settings
local Settings_Keybinds_Button = Settings.Frame.ButtonBar.Keybinds.TextButton
local Settings_Gameplay_Button = Settings.Frame.ButtonBar.Gameplay.TextButton
local Settings_Misc_Button = Settings.Frame.ButtonBar.Misc.TextButton
local Settings_Close_Button = Settings.Frame.ButtonBar.Close.TextButton
local Settings_Keybinds_Frame = Settings.Frame.HolderFrame.Keybinds
local Settings_Gameplay_Frame = Settings.Frame.HolderFrame.Gameplay
local Settings_Misc_Frame = Settings.Frame.HolderFrame.Misc
--Main Button
local Buttons_Inventory = Buttons.Inventory
local Buttons_Stats = Buttons.Stats
local Buttons_Players = Buttons.Players
local Buttons_Settings = Buttons.Settings
--ServerNotify
local ServerNotifyButton = ServerNotify.ButtonFrame
local ServerNotifyMessageType = ServerNotifyButton.MessageType
local ServerNotifyMessage = ServerNotifyButton.Message
local ServerNotifyCount = 0 -- initial count, should always be 0
local ServerNotifyThreshHold = 2 -- you can set this to even 3 of 4 to get triple and quadriple clicks!
local ServerNotifyClickTime = 0.3 -- the time within the clicks should be clicked
--TweenInfo
local Buttons_Inventory_Color = Color3.fromRGB(255, 237, 166)
local Buttons_Stats_Color = Color3.fromRGB(157, 255, 209)
local Buttons_Players_Color = Color3.fromRGB(157, 159, 255)
local Buttons_Settings_Color = Color3.fromRGB(255, 174, 231)
local Buttons_Color = Color3.fromRGB(175, 175, 175)
local TweenService = game:GetService("TweenService")
local TweenButtonInfo = TweenInfo.new(0.2,0,0,0,false,0)
local TweenButtonInfoClose = TweenInfo.new(0.1,0,0,0,false,0)
--InfoStatState
local InfoStatState = 0 -- Combat
local IsAdvanced = 0 -- False
local State0 = {"Health","Defense","Damage","CritChance","CritDamage","Mana","Strength","Intelligence","Dexterity","Vitality","Looting","Proficiency","AttackSpeed","Speed","Jump","Luck","Coins"}
local State1 = {"Combat","Farming","Foraging","Fishing","Mining","Gemcrafting","Crafting","Alchemy","Enchanting"}
--
local IsOnBlurEffect = false
--
InfoFrame_StatsFrame_NameTag.Text = Player.Name.." 's stats:"
--Local Func 
local function Round(n, decimals)
	decimals = decimals or 0
	return math.floor(n * 10^decimals) / 10^decimals
end
local function PositionAtMouse(box)
	--local frameSize = box.AbsoluteSize

	--//positions at left corner of mouse
	box.Position = UDim2.fromOffset(PlayerMouse.X+Interact_PercentChanged*15, PlayerMouse.Y+Interact_Name.AbsoluteSize.Y*1.05)
end
--Sound
local function SoundPlaying(SoundLocation)
	local NewSound = SoundLocation:Clone()
	NewSound.Parent = script.SoundHolder
	NewSound:Play()
	NewSound.Ended:Wait()
	NewSound:Destroy()
end

local function BlurEffect(boolean)
	if game.Lighting:FindFirstChild("UIBlur") then
		game.Lighting:FindFirstChild("UIBlur").Enabled = boolean
	end
end

local function CheckSpareSlot(item)
	local CatagoryInventory = item.Parent.Parent
	local CheckTable = item:GetAttributes()
	local ItemLibrary =  game:GetService("ReplicatedStorage"):FindFirstChild("GameItems"):FindFirstChild(item.Parent.Parent.Name)
	local ServerItemData = require(ItemLibrary:FindFirstChild(item.Name)) 
	CheckTable.Amounts = nil
	CheckTable.CurrentSlot = nil
	local ItemSearch = {}
	for i,v in pairs(CatagoryInventory:GetChildren()) do -- get existed items
		if v:FindFirstChildOfClass("NumberValue") then
			local itemlookup = v:FindFirstChildOfClass("NumberValue") 
			if itemlookup.Value == item.Value then
				--if type(CustomCondition) == "table" then
				local returnvalue = true
				for a,b in pairs(CheckTable) do
					if item:GetAttribute(a) ~= b then
						returnvalue = false
					end
				end
				if returnvalue then
					if item:GetAttribute("Amounts") ~= ServerItemData.StackSize then
						local slotinform = v.Name:split("_")
						print(slotinform)
						ItemSearch[#ItemSearch+1] = tonumber(item:GetAttribute("Amounts"))
					end
				end
			end
		end
	end
	if #ItemSearch > 1 then return true else return false
	end
end

local function GetSlotString(item)

	if item.Parent:IsA("StringValue") then

		local _,numb = string.match(item.Parent.Name,StringConverterPattern)
		return item.Parent.Parent.Name.."_"..numb
	elseif item.Parent:IsA("BoolValue") then
		if item.Parent.Parent.Name == "Main" then
			return item.Parent.Name
		elseif item.Parent.Parent.Name == "Accessory" then
			local _,numb = string.match(item.Parent.Name,StringConverterPattern)
			return "Accessory_"..numb
		elseif item.Parent.Parent.Name == "Fishing" then
			local _,numb = string.match(item.Parent.Name,StringConverterPattern)
			return "Fishing_"..numb
		elseif item.Parent.Parent.Name == "Bow" then
			local _,numb = string.match(item.Parent.Name,StringConverterPattern)
			return "Bow_"..numb
		end
	end
end
local function SettingButtonInventoryState(boolvalue:boolean)
	for i,v in Inventory_Item:GetChildren() do
		if v:IsA("Frame") and v:FindFirstChildOfClass("TextButton") then
			v:FindFirstChildOfClass("TextButton").Active = boolvalue
			v:FindFirstChildOfClass("TextButton").AutoButtonColor = boolvalue
		end
	end
	for i,v in Inventory_Consumable:GetChildren() do
		if v:IsA("Frame") and v:FindFirstChildOfClass("TextButton") then
			v:FindFirstChildOfClass("TextButton").Active = boolvalue
			v:FindFirstChildOfClass("TextButton").AutoButtonColor = boolvalue
		end
	end
	for i,v in Inventory_Material:GetChildren() do
		if v:IsA("Frame") and v:FindFirstChildOfClass("TextButton") then
			v:FindFirstChildOfClass("TextButton").Active = boolvalue
			v:FindFirstChildOfClass("TextButton").AutoButtonColor = boolvalue
		end
	end
	for i,v in InfoFrame_MainWeaponFrame:GetChildren() do
		if v:IsA("Frame") then
			for a,b in v:GetChildren() do
				if b:FindFirstChildOfClass("TextButton") then
					b:FindFirstChildOfClass("TextButton").Active = boolvalue
					b:FindFirstChildOfClass("TextButton").AutoButtonColor = boolvalue
				end
			end
		end
	end
end
--

--[[local function CreateItemUI(PlayerItemData,ItemLib,UIForm,Type,IsEquipped)
--	local ServerItemData = require(ItemLib:FindFirstChild(PlayerItemData.Name)) 
--	local _,SlotNumber = string.match(v.Name,StringConverterPattern)
--	local SlotLookUp = UIInv:FindFirstChild(SlotNumber)
--	local MainGradient = UILibrary_ItemGradient_Main:FindFirstChild(ServerItemData.Rarity):Clone()
--	local SecondGradient = UILibrary_ItemGradient_Secondary:FindFirstChild(ServerItemData.Rarity):Clone()
--	local UIFormatClone =  UIFormat:Clone()


--	local EventConnect1
--	local EventConnect2
--	local EventConnect3
--	MainGradient.Parent = UIFormatClone
--	SecondGradient.Parent = UIFormatClone:FindFirstChild("EffectFrame")
--			--[[Icon
--			UIFormat:FindFirstChild("ItemIcon").Image = robloxid
--			]] 

--	if (Type == 2 or Type == 3)	and ServerItemData.Stackable == true then
--		UIFormatClone:FindFirstChildOfClass("Frame").Visible  = true
--		UIFormatClone:FindFirstChildOfClass("Frame"):FindFirstChildOfClass("TextLabel").Text = ItemData:GetAttribute("Amounts")
--	end
--	UIFormatClone.Parent = SlotLookUp
--	EventConnect1 = UIFormatClone.MouseMoved:Connect(function()
--		--Loading Stats
--		--ItemName
--		if IsOnInteract == false then
--			local NameText
--			for i,v in Interact_Name.Text1:GetChildren() do
--				if v:IsA("UIGradient") then v:Destroy() end
--			end
--			for i,v in Interact_Name.Text2:GetChildren() do
--				if v:IsA("UIGradient") then v:Destroy() end
--			end
--			Interact_Name.Text1.Visible = false
--			Interact_Name.Text2.Visible = false
--			Interact_Name.Upgrade.Visible = false
--			if Type == 2 or Type == 3 then
--				NameText = Interact_Name.Text2
--				NameText.Visible = true
--				NameText.Text = ItemData.Name
--				local BorderGradient = UILibrary_Interact:FindFirstChild("BorderGradient"):FindFirstChild(ServerItemData.Rarity):Clone()
--				local NameGradient = UILibrary_Interact:FindFirstChild("NameGradient"):FindFirstChild(ServerItemData.Rarity):Clone()
--				--Cleaning up UIGradient
--				for i,v in Interact_Name.UIStroke:GetChildren() do
--					if v:IsA("UIGradient") then v:Destroy() end
--				end

--				--
--				BorderGradient.Parent = Interact_Name.UIStroke
--				NameGradient.Parent = NameText
--			elseif Type == 1 then

--				--checking item is upgraded or not
--				if ItemData:GetAttribute("UpgradeAttempts") == ServerItemData.UpgradeAttempts and ItemData:FindFirstChild("Upgrades").Value == 0 and ItemData:GetAttribute("UpgradeAttemptSuccessed") == 0 then
--					NameText = Interact_Name.Text2
--				else
--					NameText = Interact_Name.Text1
--					Interact_Name.Upgrade.Visible = true
--					--UpgradeScoreCalc
--				end
--				--
--				NameText.Visible = true
--				NameText.Text = ItemData.Name
--				local BorderGradient = UILibrary_Interact:FindFirstChild("BorderGradient"):FindFirstChild(ServerItemData.Rarity):Clone()
--				local NameGradient = UILibrary_Interact:FindFirstChild("NameGradient"):FindFirstChild(ServerItemData.Rarity):Clone()
--				--Cleaning up UIGradient
--				for i,v in Interact_Name.UIStroke:GetChildren() do
--					if v:IsA("UIGradient") then v:Destroy() end
--				end

--				--
--				BorderGradient.Parent = Interact_Name.UIStroke
--				NameGradient.Parent = NameText
--			end
--			--Stats
--			for i,v in Interact_Stats:GetChildren() do if v:IsA("TextLabel") then v:Destroy() end end

--			local Rarity = UILibrary_Interact.InteractStats.Item.Item_Rarity:Clone()
--			local RarityGradient = UILibrary_Interact.ItemRarity:FindFirstChild(ServerItemData.Rarity):Clone()
--			RarityGradient.Parent = Rarity
--			Rarity.Text = ServerItemData.Rarity.." "..ServerItemData.SubType
--			Rarity.Parent = Interact_Stats
--			if Type == 2 or Type == 3 then
--				local Desc = UILibrary_Interact.InteractStats.Item.Item_Description:Clone()
--				Desc.Text = ServerItemData.Description
--				Desc.Parent = Interact_Stats
--			elseif Type == 1 then
--				local StatsTable = {}
--				for index,value in ServerItemData.BaseStats do
--					StatsTable[index] = value
--				end
--				for name,value in ItemData:FindFirstChild("Upgrades"):GetAttributes() do
--					if StatsTable[name] then
--						StatsTable[name] += value
--					else
--						StatsTable[name] = value
--					end

--				end
--				--Gem,Reforge in future


--				for i,v in StatsTable do
--					local StatLookUp = UILibrary_Interact.InteractStats.Stats:FindFirstChild(i):Clone()
--					StatLookUp.Text = StatLookUp.Text..' <font color="rgb(230, 230, 230)">+'..v..'</font>'
--					StatLookUp.Parent = Interact_Stats
--				end
--				for i,v in ItemData:FindFirstChild("Upgrades"):GetAttributes() do
--					local StatLookUp = Interact_Stats:FindFirstChild(i)
--					StatLookUp.Text = StatLookUp.Text..' <font color="rgb(210, 210, 210)">(+'..v..')</font>'
--					StatLookUp.Parent = Interact_Stats
--				end
--			end

--			Interact.Visible = true
--			PositionAtMouse(Interact)
--		end
--	end)
--	EventConnect2 = UIFormatClone.MouseLeave:Connect(function()
--		Interact.Visible = false
--	end)
--	EventConnect3 = UIFormatClone.MouseButton1Click:Connect(function()
--		print("clicked")
--		if UIFormatClone.Active == true then
--			task.spawn(SoundPlaying,script.OpenSound2)
--			print("clicked with con")
--			for i,v in UIInv:GetChildren() do
--				CurrentInv = UIInv
--				if v:IsA("Frame") and v:FindFirstChildOfClass("TextButton") then
--					v:FindFirstChildOfClass("TextButton").Active = false
--					v:FindFirstChildOfClass("TextButton").AutoButtonColor = false
--				end
--			end
--			SelectedItem = ItemData
--			Interact.Visible = false
--			OnInteract.Visible = true
--			IsOnInteract = true
--			PositionAtMouse(OnInteract)
--			LoadingOnInteract(SelectedItem)
--			SelectedString = GetSlotString(SelectedItem)
--			print(SelectedString)
--		end
--	end)
--	UIFormatClone.Destroying:Connect(function()
--		EventConnect1:Disconnect()
--		EventConnect2:Disconnect()
--	end)
--end
--end

--CombatStatsGradientColor
--local STRmain = Color3.fromHex("ff6c23")
--local INTmain = Color3.fromHex("00ffff")
--local DEXmain = Color3.fromHex("ff73ff")
--local VITmain = Color3.fromHex("ff878b")
--local LUCKmain = Color3.fromHex("c5ff50")
--local PROFmain = Color3.fromHex("b469ff")

--local STRsecondary
--local INTsecondary
--local DEXsecondary
--local VITsecondary
--local LUCKsecondary
--local PROFsecondary

--local STRcolorSequence = ColorSequence.new{
--	ColorSequenceKeypoint.new(0, STRmain),
--	ColorSequenceKeypoint.new(1, Color3.fromHSV(20/360,50/255,1))
--}
--local INTcolorSequence = ColorSequence.new{
--	ColorSequenceKeypoint.new(0,INTmain),
--	ColorSequenceKeypoint.new(1, Color3.fromHSV(225/360,50/255,1))
--}
--local DEXcolorSequence = ColorSequence.new{
--	ColorSequenceKeypoint.new(0, DEXmain),
--	ColorSequenceKeypoint.new(1, Color3.fromHSV(300/360,50/255,1))
--}
--local VITcolorSequence = ColorSequence.new{
--	ColorSequenceKeypoint.new(0,VITmain),
--	ColorSequenceKeypoint.new(1, Color3.fromHSV(330/360,50/255,1))
--}
--local LUCKcolorSequence = ColorSequence.new{
--	ColorSequenceKeypoint.new(0, LUCKmain),
--	ColorSequenceKeypoint.new(1, Color3.fromHSV(120/360,50/255,1))
--}
--local PROFcolorSequence = ColorSequence.new{
--	ColorSequenceKeypoint.new(0, PROFmain),
--	ColorSequenceKeypoint.new(1, Color3.fromHSV(280/360,50/255,1))
--}
--]]
--Preloading
local function LoadingProfessionExp(Profession)
	if Profession == "Combat" then
		local UnassignedPoint = Player:FindFirstChild("PlayerData"):GetAttribute("CombatStatPoints")
		local PointStats = ProfessionList:FindFirstChild("Combat"):FindFirstChild("Notify")
		PointStats.Text = UnassignedPoint
		--CombatList
	else
		local LevelCap = LevelingCalculator.LevelCap
		local ExpHolderLookUp = UILibrary_StatsFrame:WaitForChild("LevelHolder"):WaitForChild(Profession)
		local ProfDisplay = ProfessionDisplay:FindFirstChild(Profession)
		local CurrentExp = Player:FindFirstChild("PlayerData"):GetAttribute(Profession.."ExpLeft")
		local Level = Player:FindFirstChild("PlayerData"):GetAttribute(Profession.."Level")
		local NextLevelExp = Player:FindFirstChild("PlayerData"):GetAttribute(Profession.."NextLevelExp")
		for i,v in ProfDisplay:FindFirstChildOfClass("ScrollingFrame"):GetChildren() do
			if v:IsA("Frame") then
				v:Destroy()
			end
		end
		for i=0,LevelCap do
			print(i)
			local ExpFrame
			if i == 0 then
				ExpFrame = ExpHolderLookUp:FindFirstChild("Main"):Clone()
				ExpFrame:FindFirstChild("LevelFrame"):FindFirstChildOfClass("TextLabel").Text = ""
			elseif i == LevelCap then
				ExpFrame = ExpHolderLookUp:FindFirstChild("End"):Clone()
				ExpFrame:FindFirstChild("LevelFrame"):FindFirstChildOfClass("TextLabel").Text = RomanNumberConverter.NumberToRoman(i)
			elseif i%5 == 0 then
				ExpFrame = ExpHolderLookUp:FindFirstChild("Main"):Clone()
				ExpFrame:FindFirstChild("LevelFrame"):FindFirstChildOfClass("TextLabel").Text = RomanNumberConverter.NumberToRoman(i)
			else 
				ExpFrame = ExpHolderLookUp:FindFirstChild("Secondary"):Clone()
				ExpFrame:FindFirstChild("LevelFrame"):FindFirstChildOfClass("TextLabel").Text = RomanNumberConverter.NumberToRoman(i)
			end
			if i < Level then
				ExpFrame:FindFirstChild("ProgressDisplay"):FindFirstChild("Frame").Size = UDim2.fromScale(1,1)
			elseif i == LevelCap and Level == LevelCap then ExpFrame:FindFirstChild("LevelFrame").BackgroundColor3 = ExpHolderLookUp:FindFirstChild("Main"):FindFirstChild("LevelFrame").BackgroundColor3
			elseif i == Level then
				ExpFrame:FindFirstChild("ProgressDisplay"):FindFirstChild("Frame").Size = UDim2.fromScale(CurrentExp/NextLevelExp,1)
			elseif i > Level then
				ExpFrame:FindFirstChild("LevelFrame").BackgroundColor3 = Color3.fromRGB(135, 135, 135)
				if i ~= LevelCap then
					ExpFrame:FindFirstChild("ProgressDisplay"):FindFirstChild("Frame").Size = UDim2.fromScale(0,1)
				end
			end
			ExpFrame.Name = i
			ExpFrame.LayoutOrder = i
			ExpFrame.Parent = ProfDisplay:FindFirstChildOfClass("ScrollingFrame")
		end
		local ScalePosition = math.round(ProfDisplay:FindFirstChildOfClass("ScrollingFrame"):FindFirstChild("0").AbsoluteSize.X*0.99)*Level
		print(ScalePosition)
		ProfDisplay:FindFirstChildOfClass("ScrollingFrame").CanvasPosition = Vector2.new(ScalePosition,0)

	end
end
local function LoadingProfession()
	for i,v in ProfessionList:GetChildren() do
		if v:IsA("TextButton") then
			local Exp = Player:FindFirstChild("PlayerData"):GetAttribute(v.Name)
			local CurrentExp = Player:FindFirstChild("PlayerData"):GetAttribute(v.Name.."ExpLeft")
			local Level = Player:FindFirstChild("PlayerData"):GetAttribute(v.Name.."Level")
			local NextLevelExp = Player:FindFirstChild("PlayerData"):GetAttribute(v.Name.."NextLevelExp")
			local ProfDisplay = ProfessionDisplay:FindFirstChild(v.Name)
			if  v.Name == "Combat"  then
				LoadingProfessionExp("Combat")
			elseif ProfDisplay.Visible and v.Name ~= "Combat" then LoadingProfessionExp(v.Name)
			end
			if LevelingCalculator.LevelCap <= Level then
				v:FindFirstChildOfClass("TextLabel").Text = v.Name..": "..RomanNumberConverter.NumberToRoman(LevelingCalculator.LevelCap)
				v:FindFirstChild("ExpFrame"):FindFirstChildOfClass("TextLabel").Text = "LEVEL MAX!"
				v:FindFirstChild("ExpFrame"):FindFirstChild("EffectFrame"):FindFirstChildOfClass("Frame").Size = UDim2.fromScale(1,1)
			else
				v:FindFirstChildOfClass("TextLabel").Text = v.Name..": "..RomanNumberConverter.NumberToRoman(Level)
				v:FindFirstChild("ExpFrame"):FindFirstChildOfClass("TextLabel").Text = CurrentExp.."/"..NextLevelExp
				v:FindFirstChild("ExpFrame"):FindFirstChild("EffectFrame"):FindFirstChildOfClass("Frame").Size = UDim2.fromScale(CurrentExp/NextLevelExp,1)
			end

		end
	end
end
local function LoadingCombatGradient(CombatStat)
	local Combat = Player:FindFirstChild("PlayerData"):GetAttribute("Combat")
	local UnassignedPoint = Player:FindFirstChild("PlayerData"):GetAttribute("CombatStatPoints") 
	local Strength = Player:FindFirstChild("PlayerData"):GetAttribute("Strength")
	local Intelligence = Player:FindFirstChild("PlayerData"):GetAttribute("Intelligence")
	local Dexterity = Player:FindFirstChild("PlayerData"):GetAttribute("Dexterity")
	local Vitality = Player:FindFirstChild("PlayerData"):GetAttribute("Vitality")
	local Looting = Player:FindFirstChild("PlayerData"):GetAttribute("Looting")
	local Proficiency = Player:FindFirstChild("PlayerData"):GetAttribute("Proficiency")
	if Combat == "All" then

	end
end
local function LoadingOnInteract(Item,IsEquippedInv)
	local IsEquippedInv = IsEquippedInv or false
	print(IsEquippedInv)
	if OnInteract.Visible and IsOnInteract == true and Item ~= nil then
		print(Item)
		print(IsEquippedInv)
		print("con1")
		local ItemLibLookUp
		if IsEquippedInv then
			ItemLibLookUp = "Equipments"
		else
			
			ItemLibLookUp = Item.Parent.Parent.Name
		end
		local ItemLibrary =  game:GetService("ReplicatedStorage"):FindFirstChild("GameItems"):FindFirstChild(ItemLibLookUp)
		local ServerItemData = require(ItemLibrary:FindFirstChild(Item.Name)) 
		for i,v in OnInteract_Frame.Buttons:GetChildren() do
			if v:IsA("TextButton") and v.Name ~= "Cancel" then v.Visible = false end
		end
		if ServerItemData.ItemType == 1 then
			if IsEquippedInv then
				OnInteract_Frame.Buttons.Unequip.Visible = true
				if AdvInteractOption then
					OnInteract_Frame.Buttons.Lock.Visible = true
				end
			else
				OnInteract_Frame.Buttons.Equip.Visible = true
				OnInteract_Frame.Buttons.Equip.Text = '<font color="rgb(165, 165, 165)">Equip</font> [%s]'
				OnInteract_Frame.Buttons.Equip.Text = string.format(OnInteract_Frame.Buttons.Equip.Text,ServerItemData.SubType)
				if AdvInteractOption then
					OnInteract_Frame.Buttons.Lock.Visible = true
					OnInteract_Frame.Buttons.Move.Visible = true
					OnInteract_Frame.Buttons.Drop.Visible = true
				end
			end
		elseif ServerItemData.ItemType == 2 then
			if ServerItemData.SubType == "Consumable" then OnInteract_Frame.Buttons.Use.Visible = true
			elseif ServerItemData.SubType == "Arrow" or ServerItemData.SubType == "Bait" then
				OnInteract_Frame.Buttons.Equip.Visible = true
				OnInteract_Frame.Buttons.Equip.Text = '<font color="rgb(165, 165, 165)">Equip</font> [%s]'
				OnInteract_Frame.Buttons.Equip.Text = string.format(OnInteract_Frame.Buttons.Equip.Text,ServerItemData.SubType)
			else OnInteract_Frame.Buttons.Move.Visible = true
			end
			if AdvInteractOption then
				if ServerItemData.Stackable == true then 
					if Item:GetAttribute("Amounts") > 1 then OnInteract_Frame.Buttons.Split.Visible = true  end
					if CheckSpareSlot(Item) then OnInteract_Frame.Buttons.Combine.Visible = true  end
				end
				OnInteract_Frame.Buttons.Drop.Visible = true
				OnInteract_Frame.Buttons.Move.Visible = true
			end
		elseif ServerItemData.ItemType == 3 then
			OnInteract_Frame.Buttons.Move.Visible = true
			if AdvInteractOption then
				if ServerItemData.Stackable == true then 
					if Item:GetAttribute("Amounts") > 1 then OnInteract_Frame.Buttons.Split.Visible = true  end
					if CheckSpareSlot(Item) then OnInteract_Frame.Buttons.Combine.Visible = true  end
				end
				OnInteract_Frame.Buttons.Drop.Visible = true
			end
		end
		--elseif OnInteract.Visible and IsOnInteract == false and Item ~= nil and IsEquippedInv == true then
		--	print(Item)
		--	print("con2")
		--	local ItemLibrary =  game:GetService("ReplicatedStorage"):FindFirstChild("GameItems"):FindFirstChild("Equipments")
		--	local ServerItemData = require(ItemLibrary:FindFirstChild(Item.Name)) 
		--	for i,v in OnInteract_Frame.Buttons:GetChildren() do
		--		if v:IsA("TextButton") and v.Name ~= "Cancel" then v.Visible = false end
		--	end
		--	OnInteract_Frame.Buttons.Unequip.Visible = true
	end
end
local function LoadEquipped(Type)
	local UIInv 
	local PlayerDataInv 
	local UIFormat
	local ItemLibrary
	if Type == 1 then -- 1.Weapons/Armor 2.Accessory
		UIInv = InfoFrame_MainWeaponFrame
		PlayerDataInv = Player:FindFirstChild("Inventory"):FindFirstChild("Equipped"):FindFirstChild("Main")
		UIFormat = UILibrary:FindFirstChild("Inventory"):FindFirstChild("Item")
		ItemLibrary = game:GetService("ReplicatedStorage"):FindFirstChild("GameItems"):FindFirstChild("Equipments")
		local function LoadingEquipped(valuelookup)
			print("a")
			for i,v in UIInv:FindFirstChild(valuelookup):GetChildren() do
				if v:IsA("Frame") and PlayerDataInv:FindFirstChild(v.Name):FindFirstChildOfClass("NumberValue") then
					print("b")
					local ItemData = PlayerDataInv:FindFirstChild(v.Name):FindFirstChildOfClass("NumberValue")
					local ServerItemData = require(ItemLibrary:FindFirstChild(ItemData.Name)) 
					local MainGradient = UILibrary_ItemGradient_Main:FindFirstChild(ServerItemData.Rarity):Clone()
					local SecondGradient = UILibrary_ItemGradient_Secondary:FindFirstChild(ServerItemData.Rarity):Clone()
					local UIFormatClone =  UIFormat:Clone()
					local EventConnect1
					local EventConnect2
					local EventConnect3
					v.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
					v:FindFirstChildOfClass("Frame").Visible = false
					MainGradient.Parent = UIFormatClone
					SecondGradient.Parent = UIFormatClone:FindFirstChild("EffectFrame")
			--[[Icon
			UIFormat:FindFirstChild("ItemIcon").Image = robloxid
			]] 
					UIFormatClone.Parent = v
					EventConnect1 = UIFormatClone.MouseMoved:Connect(function()
						--Loading Stats
						--ItemName
						if IsOnInteract == false then
							local NameText
							for i,v in Interact_Name.Text1:GetChildren() do
								if v:IsA("UIGradient") then v:Destroy() end
							end
							for i,v in Interact_Name.Text2:GetChildren() do
								if v:IsA("UIGradient") then v:Destroy() end
							end
							Interact_Name.Text1.Visible = false
							Interact_Name.Text2.Visible = false
							Interact_Name.Upgrade.Visible = false
							--checking item is upgraded or not
							if ItemData:GetAttribute("UpgradeAttempts") == ServerItemData.UpgradeAttempts and ItemData:FindFirstChild("Upgrades").Value == 0 and ItemData:GetAttribute("UpgradeAttemptSuccessed") == 0 then
								NameText = Interact_Name.Text2
							else
								NameText = Interact_Name.Text1
								Interact_Name.Upgrade.Visible = true
								--UpgradeScoreCalc
							end
							--
							NameText.Visible = true
							NameText.Text = ItemData.Name
							local BorderGradient = UILibrary_Interact:FindFirstChild("BorderGradient"):FindFirstChild(ServerItemData.Rarity):Clone()
							local NameGradient = UILibrary_Interact:FindFirstChild("NameGradient"):FindFirstChild(ServerItemData.Rarity):Clone()
							--Cleaning up UIGradient
							for i,v in Interact_Name.UIStroke:GetChildren() do
								if v:IsA("UIGradient") then v:Destroy() end
							end

							--
							BorderGradient.Parent = Interact_Name.UIStroke
							NameGradient.Parent = NameText

							--Stats
							for i,v in Interact_Stats:GetChildren() do if v:IsA("TextLabel") then v:Destroy() end end

							local Rarity = UILibrary_Interact.InteractStats.Item.Item_Rarity:Clone()
							local RarityGradient = UILibrary_Interact.ItemRarity:FindFirstChild(ServerItemData.Rarity):Clone()
							RarityGradient.Parent = Rarity
							Rarity.Text = ServerItemData.Rarity.." "..ServerItemData.SubType
							Rarity.Parent = Interact_Stats
							local StatsTable = {}
							for index,value in ServerItemData.BaseStats do
								StatsTable[index] = value
							end
							for name,value in ItemData:FindFirstChild("Upgrades"):GetAttributes() do
								if StatsTable[name] then
									StatsTable[name] += value
								else
									StatsTable[name] = value
								end

							end
							--Gem,Reforge in future


							for i,v in StatsTable do
								local StatLookUp = UILibrary_Interact.InteractStats.Stats:FindFirstChild(i):Clone()
								StatLookUp.Text = StatLookUp.Text..' <font color="rgb(230, 230, 230)">+'..v..'</font>'
								StatLookUp.Parent = Interact_Stats
							end
							for i,v in ItemData:FindFirstChild("Upgrades"):GetAttributes() do
								local StatLookUp = Interact_Stats:FindFirstChild(i)
								StatLookUp.Text = StatLookUp.Text..' <font color="rgb(210, 210, 210)">(+'..v..')</font>'
								StatLookUp.Parent = Interact_Stats
							end
							Interact.Visible = true
							PositionAtMouse(Interact)
						end
					end)
					EventConnect2 = UIFormatClone.MouseLeave:Connect(function()
						Interact.Visible = false
					end)
					EventConnect3 = UIFormatClone.MouseButton1Click:Connect(function()
						print("clicked")
						if UIFormatClone.Active == true then
							task.spawn(SoundPlaying,script.OpenSound2)
							print("clicked with con2")
							CurrentInv = UIInv
							SettingButtonInventoryState(false)
							--for i,v in UIInv:GetChildren() do
							--	CurrentInv = UIInv
							--	if v:IsA("Frame") and v:FindFirstChildOfClass("TextButton") then
							--		v:FindFirstChildOfClass("TextButton").Active = false
							--		v:FindFirstChildOfClass("TextButton").AutoButtonColor = false
							--	end
							--end
							--for i,v in InfoFrame_MainWeaponFrame:GetChildren() do
							--	if v:IsA("Frame") then
							--		for a,b in v:GetChildren() do
							--			if b:FindFirstChildOfClass("TextButton") then
							--				b:FindFirstChildOfClass("TextButton").Active = false
							--				b:FindFirstChildOfClass("TextButton").AutoButtonColor = false
							--			end
							--		end
							--	end
							--end
							SelectedItem = ItemData
							Interact.Visible = false
							OnInteract.Visible = true
							IsOnInteract = true
							PositionAtMouse(OnInteract)
							LoadingOnInteract(SelectedItem,true)
							SelectedString = GetSlotString(SelectedItem)
							print(SelectedString)
						end
					end)
					UIFormatClone.Destroying:Connect(function()
						EventConnect1:Disconnect()
						EventConnect2:Disconnect()
					end)
				end
			end
		end
		LoadingEquipped("First")
		LoadingEquipped("Second")
	end
end
local function LoadInventory(Type) -- 1.Item 2.Consumable 3.Material
	local UIInv 
	local PlayerDataInv 
	local UIFormat
	local ItemLibrary
	if Type == 1 then
		UIInv = Inventory_Item
		PlayerDataInv = Player:FindFirstChild("Inventory"):FindFirstChild("Equipments")
		UIFormat = UILibrary:FindFirstChild("Inventory"):FindFirstChild("Item")
		ItemLibrary = game:GetService("ReplicatedStorage"):FindFirstChild("GameItems"):FindFirstChild("Equipments")
		for i,v in UIInv:GetChildren() do
			if v:IsA("Frame") and v:FindFirstChildOfClass("TextButton") then
				v:FindFirstChildOfClass("TextButton"):Destroy()
			end
		end
	elseif Type == 2 then
		UIInv = Inventory_Consumable
		PlayerDataInv = Player:FindFirstChild("Inventory"):FindFirstChild("Consumables")
		UIFormat = UILibrary:FindFirstChild("Inventory"):FindFirstChild("Consumable_Material")
		ItemLibrary = game:GetService("ReplicatedStorage"):FindFirstChild("GameItems"):FindFirstChild("Consumables")
		for i,v in UIInv:GetChildren() do
			if v:IsA("Frame") and v:FindFirstChildOfClass("TextButton") then
				v:FindFirstChildOfClass("TextButton"):Destroy()
			end
		end
	elseif Type == 3 then
		UIInv = Inventory_Material
		PlayerDataInv = Player:FindFirstChild("Inventory"):FindFirstChild("Materials")
		UIFormat = UILibrary:FindFirstChild("Inventory"):FindFirstChild("Consumable_Material")
		ItemLibrary = game:GetService("ReplicatedStorage"):FindFirstChild("GameItems"):FindFirstChild("Materials")
		for i,v in UIInv:GetChildren() do
			if v:IsA("Frame") and v:FindFirstChildOfClass("TextButton") then
				v:FindFirstChildOfClass("TextButton"):Destroy()
			end
		end
		--elseif Type == 4 then
		--	UIInv = Inventory_Material
		--	PlayerDataInv = Player:FindFirstChild("Inventory"):FindFirstChild("Materials")
		--	UIFormat = UILibrary:FindFirstChild("Inventory"):FindFirstChild("Consumable_Material")
		--	ItemLibrary = game:GetService("ReplicatedStorage"):FindFirstChild("GameItems"):FindFirstChild("Materials")
		--	for i,v in UIInv:GetChildren() do
		--		if v:IsA("Frame") and v:FindFirstChildOfClass("TextButton") then
		--			v:FindFirstChildOfClass("TextButton"):Destroy()
		--		end
		--	end
	end
	for i,v in PlayerDataInv:GetChildren() do
		if v:FindFirstChildOfClass("NumberValue") then
			local ItemData = v:FindFirstChildOfClass("NumberValue")
			local ServerItemData = require(ItemLibrary:FindFirstChild(ItemData.Name)) 
			local _,SlotNumber = string.match(v.Name,StringConverterPattern)
			local SlotLookUp = UIInv:FindFirstChild(SlotNumber)
			local MainGradient = UILibrary_ItemGradient_Main:FindFirstChild(ServerItemData.Rarity):Clone()
			local SecondGradient = UILibrary_ItemGradient_Secondary:FindFirstChild(ServerItemData.Rarity):Clone()
			local UIFormatClone =  UIFormat:Clone()
			--
			local function CreateItemUI(PlayerItemData,ItemLib,UIForm,IsEquipped)

			end
			local EventConnect1
			local EventConnect2
			local EventConnect3
			MainGradient.Parent = UIFormatClone
			SecondGradient.Parent = UIFormatClone:FindFirstChild("EffectFrame")
			--[[Icon
			UIFormat:FindFirstChild("ItemIcon").Image = robloxid
			]] 

			if (Type == 2 or Type == 3)	and ServerItemData.Stackable == true then
				UIFormatClone:FindFirstChildOfClass("Frame").Visible  = true
				UIFormatClone:FindFirstChildOfClass("Frame"):FindFirstChildOfClass("TextLabel").Text = ItemData:GetAttribute("Amounts")
			end
			UIFormatClone.Parent = SlotLookUp
			EventConnect1 = UIFormatClone.MouseMoved:Connect(function()
				--Loading Stats
				--ItemName
				if IsOnInteract == false then
					local NameText
					for i,v in Interact_Name.Text1:GetChildren() do
						if v:IsA("UIGradient") then v:Destroy() end
					end
					for i,v in Interact_Name.Text2:GetChildren() do
						if v:IsA("UIGradient") then v:Destroy() end
					end
					Interact_Name.Text1.Visible = false
					Interact_Name.Text2.Visible = false
					Interact_Name.Upgrade.Visible = false
					if Type == 2 or Type == 3 then
						NameText = Interact_Name.Text2
						NameText.Visible = true
						NameText.Text = ItemData.Name
						local BorderGradient = UILibrary_Interact:FindFirstChild("BorderGradient"):FindFirstChild(ServerItemData.Rarity):Clone()
						local NameGradient = UILibrary_Interact:FindFirstChild("NameGradient"):FindFirstChild(ServerItemData.Rarity):Clone()
						--Cleaning up UIGradient
						for i,v in Interact_Name.UIStroke:GetChildren() do
							if v:IsA("UIGradient") then v:Destroy() end
						end

						--
						BorderGradient.Parent = Interact_Name.UIStroke
						NameGradient.Parent = NameText
					elseif Type == 1 then

						--checking item is upgraded or not
						if ItemData:GetAttribute("UpgradeAttempts") == ServerItemData.UpgradeAttempts and ItemData:FindFirstChild("Upgrades").Value == 0 and ItemData:GetAttribute("UpgradeAttemptSuccessed") == 0 then
							NameText = Interact_Name.Text2
						else
							NameText = Interact_Name.Text1
							Interact_Name.Upgrade.Visible = true
							--UpgradeScoreCalc
						end
						--
						NameText.Visible = true
						NameText.Text = ItemData.Name
						local BorderGradient = UILibrary_Interact:FindFirstChild("BorderGradient"):FindFirstChild(ServerItemData.Rarity):Clone()
						local NameGradient = UILibrary_Interact:FindFirstChild("NameGradient"):FindFirstChild(ServerItemData.Rarity):Clone()
						--Cleaning up UIGradient
						for i,v in Interact_Name.UIStroke:GetChildren() do
							if v:IsA("UIGradient") then v:Destroy() end
						end

						--
						BorderGradient.Parent = Interact_Name.UIStroke
						NameGradient.Parent = NameText
					end
					--Stats
					for i,v in Interact_Stats:GetChildren() do if v:IsA("TextLabel") then v:Destroy() end end

					local Rarity = UILibrary_Interact.InteractStats.Item.Item_Rarity:Clone()
					local RarityGradient = UILibrary_Interact.ItemRarity:FindFirstChild(ServerItemData.Rarity):Clone()
					RarityGradient.Parent = Rarity
					if ServerItemData.SubType == "Reel" or ServerItemData.SubType == "Float" or ServerItemData.SubType == "Bait" then
						Rarity.Text = ServerItemData.Rarity.." Fishing "..ServerItemData.SubType
					else
						Rarity.Text = ServerItemData.Rarity.." "..ServerItemData.SubType
					end
					Rarity.Parent = Interact_Stats
					if Type == 2 or Type == 3 then
						local Desc = UILibrary_Interact.InteractStats.Item.Item_Description:Clone()
						Desc.Text = ServerItemData.Description
						Desc.Parent = Interact_Stats
					elseif Type == 1 then
						local StatsTable = {}
						for index,value in ServerItemData.BaseStats do
							StatsTable[index] = value
						end
						for name,value in ItemData:FindFirstChild("Upgrades"):GetAttributes() do
							if StatsTable[name] then
								StatsTable[name] += value
							else
								StatsTable[name] = value
							end

						end
						--Gem,Reforge in future


						for i,v in StatsTable do
							local StatLookUp = UILibrary_Interact.InteractStats.Stats:FindFirstChild(i):Clone()
							StatLookUp.Text = StatLookUp.Text..' <font color="rgb(230, 230, 230)">+'..v..'</font>'
							StatLookUp.Parent = Interact_Stats
						end
						for i,v in ItemData:FindFirstChild("Upgrades"):GetAttributes() do
							local StatLookUp = Interact_Stats:FindFirstChild(i)
							StatLookUp.Text = StatLookUp.Text..' <font color="rgb(210, 210, 210)">(+'..v..')</font>'
							StatLookUp.Parent = Interact_Stats
						end
					end

					Interact.Visible = true
					PositionAtMouse(Interact)
				end
			end)
			EventConnect2 = UIFormatClone.MouseLeave:Connect(function()
				Interact.Visible = false
			end)
			EventConnect3 = UIFormatClone.MouseButton1Click:Connect(function()
				print("clicked")
				if UIFormatClone.Active == true then
					task.spawn(SoundPlaying,script.OpenSound2)
					print("clicked with con")
					CurrentInv = UIInv
					--for i,v in UIInv:GetChildren() do

					--	if v:IsA("Frame") and v:FindFirstChildOfClass("TextButton") then
					--		v:FindFirstChildOfClass("TextButton").Active = false
					--		v:FindFirstChildOfClass("TextButton").AutoButtonColor = false
					--	end
					--end
					SettingButtonInventoryState(false)
					SelectedItem = ItemData
					Interact.Visible = false
					OnInteract.Visible = true
					IsOnInteract = true
					PositionAtMouse(OnInteract)
					LoadingOnInteract(SelectedItem,false)
					SelectedString = GetSlotString(SelectedItem)
					print(SelectedString)
				end
			end)
			UIFormatClone.Destroying:Connect(function()
				EventConnect1:Disconnect()
				EventConnect2:Disconnect()
			end)
		end
	end
end
--Button fuctioning 
--Main Buttons
Buttons_Inventory.MouseEnter:Connect(function()
	local tween1 = TweenService:Create(Buttons_Inventory:WaitForChild("ColorFrame"), TweenButtonInfo, {BackgroundColor3 = Buttons_Inventory_Color})
	local tween2 = TweenService:Create(Buttons_Inventory:WaitForChild("ColorFrame"), TweenButtonInfoClose, {BackgroundColor3 = Buttons_Color})
	tween1:Play()
	Buttons_Inventory.MouseLeave:Connect(function()
		tween1:Cancel()
		tween2:Play()
	end)
end)
Buttons_Stats.MouseEnter:Connect(function()
	local tween1 = TweenService:Create(Buttons_Stats:WaitForChild("ColorFrame"), TweenButtonInfo, {BackgroundColor3 = Buttons_Stats_Color})
	local tween2 = TweenService:Create(Buttons_Stats:WaitForChild("ColorFrame"), TweenButtonInfoClose, {BackgroundColor3 = Buttons_Color})
	tween1:Play()
	Buttons_Stats.MouseLeave:Connect(function()
		tween1:Cancel()
		tween2:Play()
	end)
end)
Buttons_Players.MouseEnter:Connect(function()
	local tween1 = TweenService:Create(Buttons_Players:WaitForChild("ColorFrame"), TweenButtonInfo, {BackgroundColor3 = Buttons_Players_Color})
	local tween2 = TweenService:Create(Buttons_Players:WaitForChild("ColorFrame"), TweenButtonInfoClose, {BackgroundColor3 = Buttons_Color})
	tween1:Play()
	Buttons_Players.MouseLeave:Connect(function()
		tween1:Cancel()
		tween2:Play()
	end)
end)
Buttons_Settings.MouseEnter:Connect(function()
	local tween1 = TweenService:Create(Buttons_Settings:WaitForChild("ColorFrame"), TweenButtonInfo, {BackgroundColor3 = Buttons_Settings_Color})
	local tween2 = TweenService:Create(Buttons_Settings:WaitForChild("ColorFrame"), TweenButtonInfoClose, {BackgroundColor3 = Buttons_Color})
	tween1:Play()
	Buttons_Settings.MouseLeave:Connect(function()
		tween1:Cancel()
		tween2:Play()
	end)
end)
--MainButton
Buttons_Inventory.MouseButton1Click:Connect(function()
	BlurEffect(not Backpack.Visible)
	Backpack.Visible = not Backpack.Visible
	StatsFrame.Visible = false
	PlayerList.Visible = false
	Settings.Visible = false
	if Backpack.Visible then
		SoundPlaying(script.OpenSound)
	else
		SoundPlaying(script.CloseSound)
	end
end)
Buttons_Stats.MouseButton1Click:Connect(function()
	BlurEffect(not StatsFrame.Visible)
	Backpack.Visible = false
	StatsFrame.Visible = not StatsFrame.Visible
	PlayerList.Visible = false
	Settings.Visible = false
	LoadingProfession()
	if StatsFrame.Visible then
		SoundPlaying(script.OpenSound)
	else
		SoundPlaying(script.CloseSound)
	end
end)
Buttons_Players.MouseButton1Click:Connect(function()
	BlurEffect(not PlayerList.Visible)
	Backpack.Visible = false
	StatsFrame.Visible = false
	PlayerList.Visible = not PlayerList.Visible
	Settings.Visible = false
	if PlayerList.Visible then
		SoundPlaying(script.OpenSound)
	else
		SoundPlaying(script.CloseSound)
	end
end)
Buttons_Settings.MouseButton1Click:Connect(function()
	BlurEffect(not Settings.Visible)
	Backpack.Visible = false
	StatsFrame.Visible = false
	PlayerList.Visible = false
	Settings.Visible = not Settings.Visible
	if Settings.Visible then
		SoundPlaying(script.OpenSound)
	else
		SoundPlaying(script.CloseSound)
	end
end)
--Inventory
Inventory_ButtonBar_Close.MouseButton1Click:Connect(function()
	Backpack.Visible = false
	BlurEffect(false)
	SoundPlaying(script.CloseSound)
end)
Inventory_ButtonBar_Equipment.MouseButton1Click:Connect(function()
	Inventory_Item.Visible = true
	Inventory_Consumable.Visible = false
	Inventory_Material.Visible = false
	SoundPlaying(script.SoftClick)
end)
Inventory_ButtonBar_Consumables.MouseButton1Click:Connect(function()
	Inventory_Item.Visible = false
	Inventory_Consumable.Visible = true
	Inventory_Material.Visible = false
	SoundPlaying(script.SoftClick)
end)
Inventory_ButtonBar_Materials.MouseButton1Click:Connect(function()
	Inventory_Item.Visible = false
	Inventory_Consumable.Visible = false
	Inventory_Material.Visible = true
	SoundPlaying(script.SoftClick)
end)

InfoFrame_ButtonBar_Equipments.MouseButton1Click:Connect(function()
	InfoFrame_MainWeaponFrame.Visible = true
	InfoFrame_Accessory.Visible = false
	InfoFrame_StatsFrame.Visible = false
	SoundPlaying(script.SoftClick)
end)
InfoFrame_ButtonBar_Accessory.MouseButton1Click:Connect(function()
	InfoFrame_MainWeaponFrame.Visible = false
	InfoFrame_Accessory.Visible = true
	InfoFrame_StatsFrame.Visible = false
	SoundPlaying(script.SoftClick)
end)
InfoFrame_ButtonBar_Stats.MouseButton1Click:Connect(function()
	InfoFrame_MainWeaponFrame.Visible = false
	InfoFrame_Accessory.Visible = false
	InfoFrame_StatsFrame.Visible = true
	SoundPlaying(script.SoftClick)
end)
local function InfoStateSorter()
	if InfoStatState == 0 then
		if IsAdvanced then
			for i,v in pairs(InfoFrame_StatsFrame:WaitForChild("ScrollingFrame"):WaitForChild("UIListLayout"):GetChildren()) do
				if v:IsA("TextLabel") then
					v.Parent = InfoFrame_StatsFrame:WaitForChild("ScrollingFrame")
				end
			end
		else
			for i,v in pairs(InfoFrame_StatsFrame:WaitForChild("ScrollingFrame"):GetChildren()) do
				if v:IsA("TextLabel") then
					if not table.find(State0,v.Name) and not table.find(State1,v.Name) then
						v.Parent = InfoFrame_StatsFrame:WaitForChild("ScrollingFrame"):WaitForChild("UIListLayout")
					end
				end
			end
			for i,v in pairs(InfoFrame_StatsFrame:WaitForChild("ScrollingFrame"):WaitForChild("UIListLayout"):GetChildren()) do
				if v:IsA("TextLabel") then
					if table.find(State0,v.Name) or table.find(State1,v.Name) then
						v.Parent = InfoFrame_StatsFrame:WaitForChild("ScrollingFrame")
					end
				end
			end
		end
	elseif InfoStatState == 1 then
		if IsAdvanced then
			for i,v in pairs(InfoFrame_StatsFrame:WaitForChild("ScrollingFrame"):GetChildren()) do
				if v:IsA("TextLabel") then
					if table.find(State1,v.Name) then
						v.Parent = InfoFrame_StatsFrame:WaitForChild("ScrollingFrame"):WaitForChild("UIListLayout")
					end
				end
			end
			for i,v in pairs(InfoFrame_StatsFrame:WaitForChild("ScrollingFrame"):WaitForChild("UIListLayout"):GetChildren()) do
				if v:IsA("TextLabel") then
					if not table.find(State1,v.Name) then
						v.Parent = InfoFrame_StatsFrame:WaitForChild("ScrollingFrame")
					end
				end
			end
		else
			for i,v in pairs(InfoFrame_StatsFrame:WaitForChild("ScrollingFrame"):GetChildren()) do
				if v:IsA("TextLabel") then
					if not table.find(State0,v.Name) then
						v.Parent = InfoFrame_StatsFrame:WaitForChild("ScrollingFrame"):WaitForChild("UIListLayout")
					end
				end
			end
			for i,v in pairs(InfoFrame_StatsFrame:WaitForChild("ScrollingFrame"):WaitForChild("UIListLayout"):GetChildren()) do
				if v:IsA("TextLabel") then
					if table.find(State0,v.Name) then
						v.Parent = InfoFrame_StatsFrame:WaitForChild("ScrollingFrame")
					end
				end
			end
		end
	elseif InfoStatState == 2 then
		for i,v in pairs(InfoFrame_StatsFrame:WaitForChild("ScrollingFrame"):GetChildren()) do
			if v:IsA("TextLabel") then
				if not table.find(State1,v.Name) then
					v.Parent = InfoFrame_StatsFrame:WaitForChild("ScrollingFrame"):WaitForChild("UIListLayout")
				end
			end
		end
		for i,v in pairs(InfoFrame_StatsFrame:WaitForChild("ScrollingFrame"):WaitForChild("UIListLayout"):GetChildren()) do
			if v:IsA("TextLabel") then
				if table.find(State1,v.Name) then
					v.Parent = InfoFrame_StatsFrame:WaitForChild("ScrollingFrame")
				end
			end
		end
	end
end
InfoFrame_ButtonBar_Stats_Show.MouseButton1Click:Connect(function()
	if InfoStatState >= 2 then
		InfoStatState = 0
		InfoFrame_ButtonBar_Stats_Show.Text = "Show: 📊"
	elseif InfoStatState == 1 then
		InfoFrame_ButtonBar_Stats_Show.Text = "Show: ⚒"
		InfoStatState = InfoStatState + 1
	elseif InfoStatState == 0 then
		InfoFrame_ButtonBar_Stats_Show.Text = "Show: ⚔️"
		InfoStatState = InfoStatState + 1
	end
	InfoStateSorter()
	SoundPlaying(script.MidPitchClick)
end)
InfoFrame_ButtonBar_Stats_Mode.MouseButton1Click:Connect(function()
	if IsAdvanced == true then
		IsAdvanced = false
		InfoFrame_ButtonBar_Stats_Mode.Text = "Advanced: ❌"
		InfoStateSorter()
	else 
		IsAdvanced = true
		InfoFrame_ButtonBar_Stats_Mode.Text = "Advanced: ✅"
		InfoStateSorter()
	end
	SoundPlaying(script.MidPitchClick)
end)
--PlayerList
PlayerList_Button_Party.MouseButton1Click:Connect(function()
	PlayerList_Party.Visible = true
	PlayerList_Guild.Visible = false
	PlayerList_Server.Visible = false
	SoundPlaying(script.SoftClick)
end)
PlayerList_Button_Guild.MouseButton1Click:Connect(function()
	PlayerList_Party.Visible = false
	PlayerList_Guild.Visible = true
	PlayerList_Server.Visible = false
	SoundPlaying(script.SoftClick)
end)
PlayerList_Button_ServerList.MouseButton1Click:Connect(function()
	PlayerList_Party.Visible = false
	PlayerList_Guild.Visible = false
	PlayerList_Server.Visible = true
	SoundPlaying(script.SoftClick)
end)
PlayerList_Button_Close.MouseButton1Click:Connect(function()
	PlayerList.Visible = false
	BlurEffect(false)
	SoundPlaying(script.CloseSound)
end)
PlayerList_Party_ListButton.MouseButton1Click:Connect(function()
	PlayerList_Party_List.Visible = true
	PlayerList_Party_MyParty.Visible = false
	PlayerList_Party_Create.Visible = false
end)
PlayerList_Party_CreateButton.MouseButton1Click:Connect(function()
	if IsPartied then
		PlayerList_Party_List.Visible = false
		PlayerList_Party_MyParty.Visible = true
		PlayerList_Party_Create.Visible = false
	else
		PlayerList_Party_List.Visible = false
		PlayerList_Party_MyParty.Visible = false
		PlayerList_Party_Create.Visible = true
	end
end)
PlayerList_Party_Create_Type.MouseButton1Click:Connect(function()
	if PartyType == 0 then
		PartyType = 1 
		PlayerList_Party_Create_Type.Text = "Private"
		PlayerList_Party_Create_Type.TextColor3 = Color3.fromRGB(255, 70, 70)
	elseif PartyType == 1 then
		PartyType = 0
		PlayerList_Party_Create_Type.Text = "Public"
		PlayerList_Party_Create_Type.TextColor3 = Color3.fromRGB(0, 255, 127)
	end
end)
PlayerList_Party_Create_Buff.MouseButton1Click:Connect(function()
	if PartyBuff == 0 then
		PartyBuff = 1
		PlayerList_Party_Create_Buff.Text = "ƺ Exp"
		PlayerList_Party_Create_Buff.TextColor3 = Color3.fromRGB(0, 255, 255)
	elseif PartyBuff == 1 then
		PartyBuff = 0
		PlayerList_Party_Create_Buff.Text = "ѻ Coins"
		PlayerList_Party_Create_Buff.TextColor3 = Color3.fromRGB(255, 255, 127)
	end
end)
PlayerList_Party_Create_SizePlus.MouseButton1Click:Connect(function()
	if PartySize < PartySizeMax then
		PartySize += 1
		PlayerList_Party_Create_SizeText.Text = 'Size: <font color="rgb(85, 255, 255)">'..PartySize.."</font>"
	end
end)
PlayerList_Party_Create_SizeMinus.MouseButton1Click:Connect(function()
	if PartySize > PartySizeMin then
		PartySize -= 1
		PlayerList_Party_Create_SizeText.Text = 'Size: <font color="rgb(85, 255, 255)">'..PartySize.."</font>"
	end
end)
PlayerList_Party_Create_Create.MouseButton1Click:Connect(function()
	IsPartied = true
	PlayerList_Party_List.Visible = false
	PlayerList_Party_MyParty.Visible = true
	PlayerList_Party_Create.Visible = false
end)
PlayerList_Party_MyParty_Leave.MouseButton1Click:Connect(function()
	IsPartied = false
	PlayerList_Party_List.Visible = false
	PlayerList_Party_MyParty.Visible = false
	PlayerList_Party_Create.Visible = true
end)
--Settings
Settings_Close_Button.MouseButton1Click:Connect(function()
	Settings.Visible = false
	BlurEffect(false)
	SoundPlaying(script.CloseSound)
end)
Settings_Misc_Button.MouseButton1Click:Connect(function()
	Settings_Keybinds_Frame.Visible = false
	Settings_Gameplay_Frame.Visible = false
	Settings_Misc_Frame.Visible = true
	SoundPlaying(script.SoftClick)
end)
Settings_Gameplay_Button.MouseButton1Click:Connect(function()
	Settings_Keybinds_Frame.Visible = false
	Settings_Gameplay_Frame.Visible = true
	Settings_Misc_Frame.Visible = false
	SoundPlaying(script.SoftClick)
end)
Settings_Keybinds_Button.MouseButton1Click:Connect(function()
	Settings_Keybinds_Frame.Visible = true
	Settings_Gameplay_Frame.Visible = false
	Settings_Misc_Frame.Visible = false
	SoundPlaying(script.SoftClick)
end)
--ServerNotify
ServerNotifyButton.MouseButton1Click:Connect(function() 
	ServerNotifyCount += 1
	if ServerNotifyCount % ServerNotifyThreshHold == 0 then
		--{0.823, 0},{0.67, 0} old pos
		ServerNotify:TweenPosition(UDim2.new(1, 0,0.67, 0),0,0,0.3,true)
		wait(0.3)
		ServerNotify.Visible = false
	end
	wait(ServerNotifyClickTime) -- just wait to invalidate the click
	ServerNotifyCount -= 1
end)
-->>StatsFrame
--Profession
for i,v in pairs(ProfessionList:GetChildren()) do
	if v:IsA("TextButton") then
		if v.Name ~= "Combat" then
			v.MouseButton1Click:Connect(function()
				for a,b in pairs(ProfessionDisplay:GetChildren()) do
					if b.Name == v.Name then
						b.Visible = true
					else
						if b:IsA("Frame") then
							b.Visible = false
						end
					end
				end
				LoadingProfessionExp(v.Name)
				SoundPlaying(script.OpenSound)

			end)
		else
			v.MouseButton1Click:Connect(function()
				IsCombatOn = true
				ProfessionList.Visible = false
				ProfessionDisplay.Visible = false
				CombatList.Visible = true
				CombatDisplay.Visible = true
				SoundPlaying(script.OpenSound)
			end)
		end
	end
end
--Combat
for i,v in pairs(CombatList:GetChildren()) do
	if v:IsA("TextButton") then
		v.MouseButton1Click:Connect(function()
			for a,b in pairs(CombatDisplay:GetChildren()) do
				if b:IsA("Frame") and b.Name ~= "Back" then
					if b.Name == v.Name then
						b.Visible = true
					else
						b.Visible = false
					end
				end
			end
			SoundPlaying(script.OpenSound)
		end)
	end
end
--Class
for i,v in pairs(ClassListList:GetChildren()) do
	if v:IsA("TextButton") then
		v.MouseButton1Click:Connect(function()
			local IsFound = false
			for a,b in pairs(ClassDisplay:GetChildren()) do
				if b:IsA("Frame") then
					if b.Name == v.Name then
						b.Visible = true
						IsFound = true
					else
						b.Visible = false
					end
				end
				if not IsFound then
					ClassDisplay:WaitForChild("Locked").Visible = true
				end
			end
			SoundPlaying(script.SoftClick)
		end)
	end
end
CombatBack.MouseButton1Click:Connect(function()
	IsCombatOn = false
	ProfessionList.Visible = true
	ProfessionDisplay.Visible = true
	CombatList.Visible = false
	CombatDisplay.Visible = false
	SoundPlaying(script.CloseSound)
end)
StatsFrame_Profession.MouseButton1Click:Connect(function()
	if not IsCombatOn then
		ProfessionList.Visible = true
		ProfessionDisplay.Visible = true
	else
		CombatList.Visible = true
		CombatDisplay.Visible = true
	end
	ClassList.Visible = false
	ClassDisplay.Visible = false
	SpellList.Visible = false
	SpellDisplay.Visible = false
	SoundPlaying(script.SoftClick)
end)
StatsFrame_Class.MouseButton1Click:Connect(function()
	ProfessionList.Visible = false
	ProfessionDisplay.Visible = false
	CombatList.Visible = false
	CombatDisplay.Visible = false
	ClassList.Visible = true
	ClassDisplay.Visible = true
	SpellList.Visible = false
	SpellDisplay.Visible = false
	SoundPlaying(script.SoftClick)
end)
StatsFrame_Spell.MouseButton1Click:Connect(function()
	ProfessionList.Visible = false
	ProfessionDisplay.Visible = false
	CombatList.Visible = false
	CombatDisplay.Visible = false
	ClassList.Visible = false
	ClassDisplay.Visible = false
	SpellList.Visible = true
	SpellDisplay.Visible = true
	SoundPlaying(script.SoftClick)
end)
StatsFrame_Close.MouseButton1Click:Connect(function()
	StatsFrame.Visible = false
	BlurEffect(false)
	SoundPlaying(script.CloseSound)
end)
--OnInteract
OnInteract_Frame.MouseEnter:Connect(function() IsInOnInteract = true end)
OnInteract_Frame.MouseLeave:Connect(function() IsInOnInteract = false end)
UserInputService.InputBegan:Connect(function(input)
	if OnInteract.Visible and not IsInOnInteract and IsOnInteract and input.UserInputType == Enum.UserInputType.MouseButton1 then
		print("Unselect")


		IsOnInteract = false
		OnInteract.Visible = false
		SelectedItem = nil
		task.spawn(SoundPlaying,script.CloseSound2)
		task.wait(0.2)
		if CurrentInv then
			--for i,v in CurrentInv:GetChildren() do
			--	for i,v in CurrentInv:GetChildren() do
			--		if v:IsA("Frame") and v:FindFirstChildOfClass("TextButton") then
			--			v:FindFirstChildOfClass("TextButton").Active = true
			--			v:FindFirstChildOfClass("TextButton").AutoButtonColor = true
			--		end
			--	end
			--end
			--for i,v in Inventory_Item:GetChildren() do
			--	if v:IsA("Frame") and v:FindFirstChildOfClass("TextButton") then
			--		v:FindFirstChildOfClass("TextButton").Active = true
			--		v:FindFirstChildOfClass("TextButton").AutoButtonColor = true
			--	end
			--end
			--for i,v in Inventory_Consumable:GetChildren() do
			--	if v:IsA("Frame") and v:FindFirstChildOfClass("TextButton") then
			--		v:FindFirstChildOfClass("TextButton").Active = true
			--		v:FindFirstChildOfClass("TextButton").AutoButtonColor = true
			--	end
			--end
			--for i,v in Inventory_Material:GetChildren() do
			--	if v:IsA("Frame") and v:FindFirstChildOfClass("TextButton") then
			--		v:FindFirstChildOfClass("TextButton").Active = true
			--		v:FindFirstChildOfClass("TextButton").AutoButtonColor = true
			--	end
			--end
			--for i,v in InfoFrame_MainWeaponFrame:GetChildren() do
			--	if v:IsA("Frame") then
			--		for a,b in v:GetChildren() do
			--			if b:FindFirstChildOfClass("TextButton") then
			--				b:FindFirstChildOfClass("TextButton").Active = true
			--				b:FindFirstChildOfClass("TextButton").AutoButtonColor = true
			--			end
			--		end
			--	end
			--end
			SettingButtonInventoryState(true)
		end
	elseif  (input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl) and OnInteract.Visible == true then
		AdvInteractOption = not AdvInteractOption
		print(AdvInteractOption)
		if AdvInteractOption then
			OnInteract_Frame.Buttons.Note.Text = 'Press <font color="rgb(225, 225, 225)">[Ctrl]</font> to show <font color="rgb(255, 90, 90)">less</font> options'
		else
			OnInteract_Frame.Buttons.Note.Text = 'Press <font color="rgb(225, 225, 225)">[Ctrl]</font> to show <font color="rgb(85, 255, 127)">more</font> options'
		end
		print(SelectedItem)
		if SelectedItem.Parent.Parent.Name ~= "Equipments" and SelectedItem.Parent.Parent.Name ~= "Consumables" and SelectedItem.Parent.Parent.Name ~= "Materials" then
			LoadingOnInteract(SelectedItem,true)
		else
			LoadingOnInteract(SelectedItem)
		end
	end

end)
--local Function
local function CreateDropEffect(Type,DataTable) -- 1. Item, 2. Material/Consumable, 3. LevelUp 4.Exp
	for i,v in pairs(Notify:GetChildren()) do
		if v:IsA("Frame") then
			v.LayoutOrder -= 1
		end
	end
	if Type == 1 then
		local NewItem = UILibrary_DropNotify:FindFirstChild("Item"):Clone()
		local FrameGradient = UILibrary_DropNotify:FindFirstChild("ItemGradient"):FindFirstChild(DataTable[2]):Clone()
		local TextGradient = UILibrary_DropNotify:FindFirstChild("ItemGradient"):FindFirstChild("NameGradient"):FindFirstChild(DataTable[2]):Clone()
		local MainItemGradient = UILibrary_ItemGradient_Main:FindFirstChild(DataTable[2]):Clone()
		local SecondItemGradient = UILibrary_ItemGradient_Secondary:FindFirstChild(DataTable[2]):Clone()
		FrameGradient.Parent = NewItem
		TextGradient.Parent = NewItem.ItemName
		MainItemGradient.Parent = NewItem.ItemIcon:FindFirstChildOfClass("ImageLabel")
		SecondItemGradient.Parent = NewItem.ItemIcon:FindFirstChildOfClass("ImageLabel"):FindFirstChild("EffectFrame")
		NewItem.ItemName.Text = DataTable[1]
		DataTable[3].Value = NewItem
		NewItem.Parent = Notify
		local Sound 
		local RarityMod 
		if DataTable[2] == "Common" or DataTable[2] == "Uncommon" then
			RarityMod = 0.1
			Sound = script.Pickup1
		elseif DataTable[2] == "Rare" or DataTable[2] == "Epic" then
			RarityMod = 0.15
			Sound =script.Pickup2
		elseif DataTable[2] == "Legendary" then
			RarityMod = 0.175
			Sound =script.Pickup3
		elseif DataTable[2] == "Mythic" then
			RarityMod = 0.25
			Sound =script.Pickup5
		elseif DataTable[2] == "Soulbound" or DataTable[2] == "Special" then
			RarityMod = 0.15
			Sound =script.Pickup4
		end
		NewItem.Size = UDim2.fromScale(0.5+RarityMod+string.len(DataTable[1])*0.01,0.143)
		NewItem:TweenSize(UDim2.new(0, 0, 0.143, 0),Enum.EasingDirection.In,Enum.EasingStyle.Back,0.5,true)
		SoundPlaying(Sound)
	elseif Type == 3 then
		local NewItem = UILibrary_DropNotify:FindFirstChild("ProfessionLevelUp"):Clone()
		local FrameGradient = UILibrary_DropNotify:FindFirstChild("Profession"):FindFirstChild(DataTable[1]):FindFirstChildOfClass("UIGradient"):Clone()
		local TextColor = UILibrary_DropNotify:FindFirstChild("Profession"):FindFirstChild(DataTable[1]).Value
		local RomanLevel = RomanNumberConverter.NumberToRoman(DataTable[2])
		FrameGradient.Parent = NewItem
		NewItem:FindFirstChild("Text").TextColor3 = TextColor
		NewItem:FindFirstChild("Text").Text = "[Level Up!] "..FrameGradient.Name.." "..DataTable[1]..' <font family="rbxasset://fonts/families/RobotoMono.json">'..RomanLevel.."</font>"
		DataTable[3].Value = NewItem
		NewItem.Parent = Notify
		NewItem.Size = UDim2.fromScale(0.8,0.08)
		NewItem:TweenSize(UDim2.new(0, 0, 0.08, 0),Enum.EasingDirection.In,Enum.EasingStyle.Quad,0.6,true)
		SoundPlaying(script.LevelUp)
	end
end
local connections = {}
local function onInstanceAdded(object)
	connections[object] = object:GetAttributeChangedSignal("Timer"):Connect(function()
		if object:GetAttribute("Timer") == 0.5 then
			local NotifiedItem = object.Value
			for i= 0,1,0.1 do
				task.wait(0.025)
				NotifiedItem.BackgroundTransparency = i 
				NotifiedItem:FindFirstChildOfClass("TextLabel").TextTransparency = i
				if object:GetAttribute("Type") == 1 then
					NotifiedItem:FindFirstChild("ItemIcon").BackgroundTransparency = i
					NotifiedItem:FindFirstChild("ItemIcon"):FindFirstChildOfClass("ImageLabel").BackgroundTransparency = i
					NotifiedItem:FindFirstChild("ItemIcon"):FindFirstChildOfClass("ImageLabel"):FindFirstChild("Icon").ImageTransparency = i
					NotifiedItem:FindFirstChild("ItemIcon"):FindFirstChildOfClass("ImageLabel"):FindFirstChild("EffectFrame").ImageTransparency = i
				end
			end
			task.wait(0.25)
			NotifiedItem:Destroy()
		end
	end)
end
local function onInstanceRemoved(object)
	-- If we made a connection on this object, disconnect it (prevent memory leaks)
	if connections[object] then
		connections[object]:Disconnect()
		connections[object] = nil
	end
end
--RemoteEvent
--local LevelUp = RemoteFunc.new("OnLevelUp")
--LevelUp.Event = function(Profession, ProfessionLevel)
--	print(Profession,ProfessionLevel)
--	local NewRomanNumber = RomanNumberConverter.NumberToRoman(ProfessionLevel)
--	print(NewRomanNumber)
--	return NewRomanNumber
--end
local OnNotifyEvent = RemoteFunc.new("OnNotify")
--local ItemHandleEvent = RemoteFunc.new("ItemHandleEvent")
OnNotifyEvent.Event = function(Type,...)
	local DataPassed = {...}
	print(DataPassed)
	CreateDropEffect(Type,DataPassed)
	return "Notified"
end
CollectionService:GetInstanceAddedSignal("Notify"):Connect(onInstanceAdded)
--Event
--Player.ChildAdded:Connect(function(Obj)
--	if Obj:IsA("BoolValue") then
--		LoadInventory(1) LoadInventory(2) LoadInventory(3) LoadEquipped(1)
--		local Plr_Inv = Player:WaitForChild("Inventory")
--		for i,v in Plr_Inv:FindFirstChild("Equipments"):GetChildren() do
--			v.ChildAdded:Connect(function() LoadInventory(1) OnInteract.Visible = false IsOnInteract = false SelectedString = nil end)
--			v.ChildRemoved:Connect(function() LoadInventory(1) OnInteract.Visible = false IsOnInteract = false SelectedString = nil end)
--		end
--		for i,v in Plr_Inv:FindFirstChild("Consumables"):GetChildren() do
--			v.ChildAdded:Connect(function() LoadInventory(2) OnInteract.Visible = false IsOnInteract = false SelectedString = nil end)
--			v.ChildRemoved:Connect(function() LoadInventory(2) OnInteract.Visible = false IsOnInteract = false SelectedString = nil end)
--			if v:FindFirstChildOfClass("NumberValue") then
--				local LinkEvent1 
--				LinkEvent1 = v:FindFirstChildOfClass("NumberValue").AttributeChanged:Connect(function()
--					LoadInventory(2) OnInteract.Visible = false IsOnInteract = false SelectedString = nil
--				end)
--				v:FindFirstChildOfClass("NumberValue").Destroying:Connect(function()
--					LinkEvent1:Disconnect()
--				end)
--			end
--		end
--		for i,v in Plr_Inv:FindFirstChild("Materials"):GetChildren() do
--			v.ChildAdded:Connect(function() LoadInventory(3) OnInteract.Visible = false IsOnInteract = false SelectedString = nil end)
--			v.ChildRemoved:Connect(function() LoadInventory(3) OnInteract.Visible = false IsOnInteract = false SelectedString = nil end)
--			if v:FindFirstChildOfClass("NumberValue") then
--				local LinkEvent1 
--				LinkEvent1 = v:FindFirstChildOfClass("NumberValue").AttributeChanged:Connect(function()
--					LoadInventory(3) OnInteract.Visible = false IsOnInteract = false SelectedString = nil
--				end)
--				v:FindFirstChildOfClass("NumberValue").Destroying:Connect(function()
--					LinkEvent1:Disconnect()
--				end)
--			end
--		end
--	end

--end)
Interact_Name:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	local Interact_PercentChanged = Interact_Name.AbsoluteSize.Y/27
	print(Interact_PercentChanged)
	for i,v in pairs(Interact_Stats:GetChildren())do
		if v:IsA("TextLabel") then
			local NewTextSize = 19*Interact_PercentChanged
			if Round(NewTextSize) > v:FindFirstChildWhichIsA("UITextSizeConstraint").MinTextSize then
				v:FindFirstChildWhichIsA("UITextSizeConstraint").MaxTextSize = Round(NewTextSize)
			end
		end
	end
end)
--
local function LoadPlayerInventory()
	while true do
		task.wait()
		if Player:FindFirstChild("DataLoaded") then
			LoadInventory(1) LoadInventory(2) LoadInventory(3) LoadEquipped(1)
			local Plr_Inv = Player:WaitForChild("Inventory")
			for i,v in Plr_Inv:FindFirstChild("Equipments"):GetChildren() do
				v.ChildAdded:Connect(function() LoadInventory(1) OnInteract.Visible = false IsOnInteract = false SelectedString = nil end)
				v.ChildRemoved:Connect(function() LoadInventory(1) OnInteract.Visible = false IsOnInteract = false SelectedString = nil end)
			end
			for i,v in Plr_Inv:FindFirstChild("Consumables"):GetChildren() do
				v.ChildAdded:Connect(function() LoadInventory(2) OnInteract.Visible = false IsOnInteract = false SelectedString = nil end)
				v.ChildRemoved:Connect(function() LoadInventory(2) OnInteract.Visible = false IsOnInteract = false SelectedString = nil end)
				if v:FindFirstChildOfClass("NumberValue") then
					local LinkEvent1 
					LinkEvent1 = v:FindFirstChildOfClass("NumberValue").AttributeChanged:Connect(function()
						LoadInventory(2) OnInteract.Visible = false IsOnInteract = false SelectedString = nil
					end)
					v:FindFirstChildOfClass("NumberValue").Destroying:Connect(function()
						LinkEvent1:Disconnect()
					end)
				end
			end
			for i,v in Plr_Inv:FindFirstChild("Materials"):GetChildren() do
				v.ChildAdded:Connect(function() LoadInventory(3) OnInteract.Visible = false IsOnInteract = false SelectedString = nil end)
				v.ChildRemoved:Connect(function() LoadInventory(3) OnInteract.Visible = false IsOnInteract = false SelectedString = nil end)
				if v:FindFirstChildOfClass("NumberValue") then
					local LinkEvent1 
					LinkEvent1 = v:FindFirstChildOfClass("NumberValue").AttributeChanged:Connect(function()
						LoadInventory(3) OnInteract.Visible = false IsOnInteract = false SelectedString = nil
					end)
					v:FindFirstChildOfClass("NumberValue").Destroying:Connect(function()
						LinkEvent1:Disconnect()
					end)
				end
			end
			break
		end
	end
end
local taskCoro = coroutine.create(LoadPlayerInventory)
local yieldresult = coroutine.resume(taskCoro)
print(yieldresult)