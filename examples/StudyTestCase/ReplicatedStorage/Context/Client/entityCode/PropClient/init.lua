--[[
	ej0w @ October 2024
	PropClient
	
	Clientside interperetation for prop healthbars & hit effect
]]

--> Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

--> Player
local Player = Players.LocalPlayer

--> References
local _Assets = ReplicatedStorage.Assets

--> Dependencies
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)
local Format = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)

local _PropEffects = require(ReplicatedStorage.Modules.Libraries.PropEffects)

local TweenModel = require(ReplicatedStorage.Modules.Client.tweenModel)
local SafeWait = require(ReplicatedStorage.Modules.Client.safeWait)

local PropClientList = require(script.PropClientList)

local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local Props = {}
Props.__index = Props

--> Configuration
local HEALTH_CHANGE_STOP = 2

--------------------------------------------------------------------------------

if not GameConfig.EnabledFeatures.Props then
	return {}
end

-- Creates and returns the overhead gui instance for mobs
local function SetupOverheadGui(PropInstance: Model, Root: BasePart, PropConfig): BillboardGui
	local OverrideGui = PropInstance:FindFirstChild("BillboardGui")
	if OverrideGui then
		return OverrideGui
	end
		
	local Gui = script:WaitForChild("BillboardGui"):Clone()
	
	local OreDisplay = `<b>{PropConfig.Name}</b>`
	if PropConfig.Tier and PropConfig.Tier >= 1 then
		OreDisplay ..= ` <font size='16' color="rgb(245,245,245)">[Tier {Format(PropConfig.Tier, "Suffix")}]</font>`
	end
	if PropConfig.Level and PropConfig.Level[1] > 1 then
		OreDisplay ..= ` <font size='16' color="rgb(245,245,245)">[Level {Format(PropConfig.Level[1], "Suffix")}]</font>`
	end
	
	Gui.Canvas.OreName.Text = OreDisplay
	task.defer(function()
		Gui.Canvas.HealthBar.Size = UDim2.fromOffset(Gui.Canvas.OreName.AbsoluteSize.X * 0.6, 12)
	end)
	
	Gui.Adornee = Root
	Gui.StudsOffsetWorldSpace = Vector3.new(0, Root.Size.Y / 2, 0)
	Gui.Enabled = true
	
	Gui.Canvas.GroupTransparency = 1
	Tween:Play(Gui.Canvas, {0.25, "Circular"}, {GroupTransparency = 0})
	return Gui
end

function Props.new(PropInstance: Model)
	if PropInstance:GetAttribute("Loaded") then
		return
	end
	
	PropInstance:SetAttribute("Loaded", true)

	local PropConfig = require(SafeWait(PropInstance, "PropConfig"))

	local Prop = setmetatable({}, Props)
	Prop.Config = PropConfig
	Prop.Instance = PropInstance
	Prop.isDead = false

	-- Overhead GUI ------------------------------------------------------

	local Hitbox = SafeWait(PropInstance, "Hitbox")

	local Gui = SetupOverheadGui(PropInstance, Hitbox, PropConfig)
	Gui.Parent = PropInstance
	
	local Fill = Gui.Canvas.HealthBar.Fill
	local Meter = Gui.Canvas.HealthBar.Meter
	
	local PreviousHealth = PropConfig.Health
	local CurrentTime = os.clock()

	local function OnHealthChanged()
		local Ore = {
			Health = AttributeModule:GetAttribute(PropInstance, "Health"), 
			MaxHealth = AttributeModule:GetAttribute(PropInstance, "MaxHealth")
		}
		
		local Percent = math.clamp(Ore.Health / Ore.MaxHealth, 0, 1)
		Tween:Play(Fill, {0.5, "Circular"}, {Size = UDim2.new(Percent, 0, 1, 0)})

		local Health = math.floor(Ore.Health * 10) / 10
		local MaxHealth = math.floor(Ore.MaxHealth * 10) / 10
		Gui.Canvas.HealthBar.Display.Text = `{Format(Health, "Suffix")} / {Format(MaxHealth, "Suffix")}`
		
		-- Meter frame (damage residual)
		local Alpha = Ore.Health / Ore.MaxHealth
		if Ore.Health > PreviousHealth then
			Meter.Size = UDim2.fromScale(Alpha, 1)
		else
			local Clock = os.clock()
			CurrentTime = Clock

			task.delay(HEALTH_CHANGE_STOP, function()
				if CurrentTime == Clock then
					local NewAlpha = Ore.Health / Ore.MaxHealth
					Tween:Play(Meter, {0.5, "Circular"}, {Size = UDim2.fromScale(Alpha, 1)})
				end
			end)
		end
		
		-- Hide/show ore UI
		if GameConfig.HideMobHUDIfHeal then
			local IsFullyHealed = Ore.Health == Ore.MaxHealth
			if IsFullyHealed then
				Gui.Canvas.HealthBar.GroupTransparency = 1
			else
				Tween:Play(Gui.Canvas.HealthBar, {0.5, "Circular"}, {GroupTransparency = 0})
			end

			Gui.Canvas.HealthBar.Visible = not IsFullyHealed
		end
		
		-- Death effect
		local isDead = Ore.Health <= 0
		if isDead then
			if not Prop.isDead then
				Prop:RequestEffect("OnDeath")
			end
			
			Prop.isDead = true
			Tween:Play(Gui.Canvas, {0.5, "Circular"}, {GroupTransparency = 1})
		end
		
		-- Hit effect
		if Ore.Health < PreviousHealth then
			Prop:RequestEffect("OnHit")
		end

		-- Health bar color
		local Alpha = Health / MaxHealth
		local Goal = PropConfig.HealthBarColor
			or (Alpha > 0.66 and GameConfig.PercentageColors.High)
			or (Alpha > 0.33 and GameConfig.PercentageColors.Medium) 
			or GameConfig.PercentageColors.Low

		Tween:Play(Fill, {0.5, "Circular"}, {BackgroundColor3 = Goal})
		Tween:Play(Meter, {0.5, "Circular"}, {BackgroundColor3 = Goal})
		
		PreviousHealth = Ore.Health
	end

	Gui.Canvas.HealthBar.Fill.Size = UDim2.new(0, 0, 1, 0)
	
	AttributeModule:GetAttributeChanged(PropInstance, "Health"):Connect(OnHealthChanged)
	OnHealthChanged()

	-- Textlabel color
	local Color = PropConfig.Color or (PropInstance:FindFirstChild("Material") and PropInstance.Material.Color)
	if Color then
		Gui.Canvas.OreName.TextColor3 = Color
	end
	
	PropClientList[PropInstance] = Prop
	return Prop
end

function Props:RequestEffect(Name)
	return _PropEffects:RequestEffect(self, Name)
end

for _, PropInstance in CollectionService:GetTagged("Prop") do
	task.spawn(Props.new, PropInstance)
end
CollectionService:GetInstanceAddedSignal("Prop"):Connect(Props.new)

return {}