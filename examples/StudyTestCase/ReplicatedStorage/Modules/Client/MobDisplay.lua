--[[
	ej0w @ September 2024
	MobDisplay
	
	Ported from ClientMain
]]

--> Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Player
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local Main = PlayerGui:WaitForChild("Main")
local BottomLeft = Main:WaitForChild("BottomLeft")

local Mobs = BottomLeft:WaitForChild("Mobs")
local Canvas = Mobs:WaitForChild("Canvas")

--> Dependencies
local Maid = require(ReplicatedStorage.Modules.Shared.Maid)
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)
local Brightness = require(ReplicatedStorage.Modules.Shared.Brightness)
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)

local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local MobDisplay = {}
local Shares = {}

local Random = Random.new()

--> Configuration
local CONFIG_MAX_DISPLAY = 4

--------------------------------------------------------------------------------

local function CountMobFrameVisible()
	local TotalVisible = 0
	
	for _, Frame in Mobs:GetChildren() do
		if Frame:IsA("CanvasGroup") and Frame.Visible then
			TotalVisible += 1
		end
	end

	return TotalVisible
end

function MobDisplay:CreateShare(EntityInstance: Model)
	local HumanoidRootPart = EntityInstance:FindFirstChild("HumanoidRootPart")
	if HumanoidRootPart and HumanoidRootPart.Size.Y <= 2 and GameConfig.MobHUDStyle == "OnlyOnBosses" then return end
	
	local Config = (EntityInstance:FindFirstChild("MobConfig") and require(EntityInstance.MobConfig))
		or (EntityInstance:FindFirstChild("PropConfig") and require(EntityInstance.PropConfig))
	
	if not Config then return end
	
	local Humanoid = EntityInstance:FindFirstChildWhichIsA("Humanoid")
	
	for Index, Share in Shares do
		local NewMobInstance = Share.MobInstance
		local BindableEvent = Share.BindableEvent
		
		if NewMobInstance == EntityInstance then
			return 	-- Cancel the entire function
		end	
		
		if Index == CONFIG_MAX_DISPLAY and #Shares == Index then
			table.remove(Shares, Index)
			BindableEvent:Fire()
		end
	end
	
	---- Create new display
	
	local Display = Canvas:Clone()
	Display.Name = Config.Name
	
	local Frame = Display:WaitForChild("HealthBar")
	local Fill = Frame:WaitForChild("Fill")
	
	local totalVisible = CountMobFrameVisible()
	if totalVisible <= 0 then
		Mobs.UIScale.Scale = 0.8
		Tween:Play(Mobs.UIScale, {0.5, "Circular"}, {Scale = 1})
	end
	
	local LevelText = (Config.Level and Config.Level[1] > 0 and `[{FormatNumber(Config.Level[1], "Suffix")}]`) or ""
	local TierText = (Config.Tier and `[T{FormatNumber(Config.Tier, "Suffix")}]`) or ""
	Display.MobName.Text = `<b>{Config.Name}</b> <font size='16' color="rgb(255,255,255)">{TierText}{TierText ~= "" and LevelText ~= "" and " " or ""}{LevelText}</font>`

	local Color = Config.Color or Brightness:AdjustColor(EntityInstance.Head.Color, EntityInstance.Torso.Color)
	Display.MobName.TextColor3 = Color
	Fill.BackgroundColor3 = Brightness:AddBrightness(Color, 0.7)
	Frame.StatName.TextColor3 = Brightness:AddBrightness(Color, 1)
	Frame.BackgroundColor3 = Brightness:AddBrightness(Color, 0.4)
	
	Display.Parent = Mobs
	Display.Visible = true
	
	---- Changed & connections
	
	local HealthClock = os.clock()
	local HealthConnection = nil
	
	local Share = {MobInstance = EntityInstance, BindableEvent = Instance.new("BindableEvent")}
	Share.BindableEvent.Event:Once(function()
		local Find = table.find(Shares, Share)
		if Find then
			table.remove(Shares, Find)
		end
		
		if HealthConnection then
			HealthConnection:Disconnect()
		end

		if Display then
			Display:Destroy()
		end
		Share.BindableEvent:Destroy()
	end)
	
	table.insert(Shares, Share)
	
	local function RequestHealthUpdate()
		local Humanoid = Humanoid or {
			Health = AttributeModule:GetAttribute(EntityInstance, "Health"), 
			MaxHealth = AttributeModule:GetAttribute(EntityInstance, "MaxHealth")
		}
		
		Frame:WaitForChild("Percent").Text = math.clamp(math.floor(Humanoid.Health / Humanoid.MaxHealth * 100), 0, 100) .."%"
		Tween:Play(Fill, {0.5, "Circular"}, {
			Size = UDim2.fromScale(Humanoid.Health / Humanoid.MaxHealth, 1)
		})
		
		Mobs.Visible = true
		
		local IsDead = Humanoid.Health <= 0
		if not IsDead then
			local Clock = os.clock()
			HealthClock = Clock

			task.delay(4, function()
				if HealthClock == Clock then
					Share.BindableEvent:Fire()
				end
			end)
		elseif IsDead then
			task.delay(1, function()
				Share.BindableEvent:Fire()
			end)
		end
	end

	HealthConnection = (Humanoid and Humanoid.HealthChanged:Connect(RequestHealthUpdate))
		or AttributeModule:GetAttributeChanged(EntityInstance, "Health"):Connect(RequestHealthUpdate)
	
	RequestHealthUpdate()
end

return MobDisplay