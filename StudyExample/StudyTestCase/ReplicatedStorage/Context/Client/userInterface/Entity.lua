--[[
	ej0w @ October 2024
	Entity
	
	Handles miscellaneous entity UIs like boss HUDs.
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer

--> Dependencies
local SetCanvasGroupVisibility = require(ReplicatedStorage.Modules.Client.setCanvasGroupVisibility)

local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)

local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local MobRankColors = GameConfig.MobRankColors

-- vv i was planning to make this cross script but i got too lazy
-- can still be used cross clients though, so I'll keep
shared.Boss = {Name = nil, Instance = nil} 

--> Configuration
local HEALTH_CHANGE_STOP = 2

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return function(Gui)
	if not GameConfig.EnabledFeatures.BuyShop then
		return
	end
	
	--> References
	local BossFrame = Gui:WaitForChild("Boss")
	
	local Title = BossFrame:WaitForChild("Title"):WaitForChild("Display")
	local Health = BossFrame:WaitForChild("Health")
	
	local HealthBar = BossFrame:WaitForChild("Bar"):WaitForChild("Background"):WaitForChild("HealthBar")
	local Fill = HealthBar:WaitForChild("Fill")
	local Meter = HealthBar:WaitForChild("Meter")
	
	--> Variables
	local BillboardGui = nil
	
	--------------------------------------------------------------------------------
	
	local Functions = {} -- Wrapped because I can't use global functions in another function
	local Connections = {}
	
	local function ClearConnections()
		for _, Connection in Connections do
			Connection:Disconnect()
			Connection = nil
		end
		Connections = {}
	end
	
	local function CloseHUD()
		shared.Boss.Name = nil
		shared.Boss.Instance = nil
		
		if BillboardGui then
			BillboardGui.Canvas.Center.SideInfo.Boss.Visible = false
			BillboardGui = nil
		end
		
		ClearConnections()
		SetCanvasGroupVisibility(BossFrame, false)
		
		Tween:Play(Gui.Padding, {0.2, "Back", "In"}, {PaddingTop = UDim.new(0, 50)})
	end
	
	local function OpenHUD(MobInstance: Model)
		local Enemy = MobInstance:FindFirstChildWhichIsA("Humanoid")
		if not Enemy or Enemy.Health <= 0 then 
			Functions.EndBossHUD(MobInstance)
			return 
		end
		
		local Config = require(MobInstance.MobConfig)
		local Color = Config.BossData and Config.BossData.Color
		
		Title.Text = Config.Name
		Title.TextColor3 = Config.Color or Color3.fromRGB(255, 255, 255)
		
		Fill.Size = UDim2.fromScale(0, 1)
		Meter.Size = UDim2.fromScale(0, 1)
		
		Fill.BackgroundColor3 = Color or GameConfig.PercentageColors.High
		Meter.BackgroundColor3 = Color or GameConfig.PercentageColors.High
		
		BillboardGui = MobInstance:FindFirstChildWhichIsA("BillboardGui")
		
		local _BossFrame = BillboardGui.Canvas.Center.SideInfo.Boss
		_BossFrame.Visible = true
		_BossFrame.GroupColor3 = Color or GameConfig.PercentageColors.High
		
		ClearConnections()
		
		Connections[#Connections + 1] = Enemy.Died:Once(function()
			task.delay(0.5, function()
				Functions.EndBossHUD()
			end)
		end)
		
		Connections[#Connections + 1] = Enemy.AncestryChanged:Connect(function(Child, Parent)
			if Parent == nil then
				Functions.EndBossHUD()
			end
		end)
		
		local PreviousHealth = 0
		local CurrentTime = os.clock()

		local function RequestHealthChanged()
			Health.Text = FormatNumber(Enemy.Health, "Suffix")
			
			-- Meter frame (damage residual)
			local Alpha = Enemy.Health / Enemy.MaxHealth
			if Enemy.Health > PreviousHealth then
				Meter.Size = UDim2.fromScale(Alpha, 1)
			else
				local Clock = os.clock()
				CurrentTime = Clock

				task.delay(HEALTH_CHANGE_STOP, function()
					if CurrentTime == Clock then
						local NewAlpha = Enemy.Health / Enemy.MaxHealth
						Tween:Play(Meter, {0.5, "Circular"}, {Size = UDim2.fromScale(Alpha, 1)})
					end
				end)
			end
			
			-- Health bar color
			if Color == nil then
				local Goal = (Alpha > 0.66 and GameConfig.PercentageColors.High)
					or (Alpha > 0.33 and GameConfig.PercentageColors.Medium) 
					or GameConfig.PercentageColors.Low
				
				Tween:Play(Fill, {0.5, "Circular"}, {BackgroundColor3 = Goal})
				Tween:Play(Meter, {0.5, "Circular"}, {BackgroundColor3 = Goal})
				Tween:Play(_BossFrame, {0.5, "Circular"}, {GroupColor3 = Goal})
			end
			
			Tween:Play(Fill, {0.5, "Circular"}, {Size = UDim2.fromScale(Alpha, 1)})
			PreviousHealth = Enemy.Health
		end
		
		Connections[#Connections + 1] = Enemy.HealthChanged:Connect(RequestHealthChanged)
		RequestHealthChanged()
		
		Gui.Enabled = true
		Gui.Padding.PaddingTop = UDim.new(0, 50)

		SetCanvasGroupVisibility(BossFrame, true)
		
		Tween:Play(Gui.Padding, {0.3, "Back", "Out"}, {PaddingTop = UDim.new()})
	end
	
	---- Logic to end/start boss HUDs
	
	function Functions.EndBossHUD(MobInstance)
		local Boss = shared.Boss
		
		if MobInstance then
			local MobConfig = require(MobInstance.MobConfig)
			if Boss.Name == MobConfig.Name then
				CloseHUD()
			end
		elseif not MobInstance then
			CloseHUD()
		end
	end
	
	function Functions.StartBossHUD(MobInstance)
		local MobConfig = require(MobInstance.MobConfig)
		local Boss = shared.Boss
		
		if Boss.Name == MobConfig.Name then
			return
		elseif Boss.Name ~= nil then
			Functions.EndBossHUD(Boss.Instance)
			RunService.Heartbeat:Wait()
		end
		
		OpenHUD(MobInstance)
		
		shared.Boss.Name = MobConfig.Name
		shared.Boss.Instance = MobInstance
	end
	
	---- Boss hud event handling
	
	EventModule:GetOnEvent("RequestBossHUD"):Connect(function(Verdict, MobInstance)
		local IsResetting = MobInstance == nil
		if Verdict == false and IsResetting then
			Functions.EndBossHUD()
		elseif not IsResetting then
			if Verdict then
				Functions.StartBossHUD(MobInstance)
			elseif not Verdict then
				Functions.EndBossHUD(MobInstance)
			end
		end
	end)
	
	---- Character added & removed
	
	local function OnCharacterAdded(Character)
		local Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
		Humanoid.Died:Connect(function()
			EventModule:Fire("RequestBossHUD", false)
		end)
	end
	
	if Player.Character then
		OnCharacterAdded(Player.Character)
	end
	Player.CharacterAdded:Connect(OnCharacterAdded)
	
	-------------------------------
	
	Gui:WaitForChild("Padding")
	Functions.EndBossHUD()
end