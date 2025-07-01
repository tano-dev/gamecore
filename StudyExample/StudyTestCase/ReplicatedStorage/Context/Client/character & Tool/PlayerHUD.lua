--[[
	ej0w @ November 2024
	PlayerHUD
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")

--> Dependencies
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)

local GameConfig = require(ReplicatedStorage.GameConfig)

--> Configuration
local HEALTH_CHANGE_STOP = 2

--------------------------------------------------------------------------------

if not GameConfig.EnabledFeatures.PlayerHUD then
	return {}
end

-- Creates and returns the overhead gui instance for (repurposed to) players
local function SetupOverheadGui(Player, Character: Model): BillboardGui
	local pData = PlayerData:WaitForChild(Player.UserId)
	
	local Root = Character:WaitForChild("HumanoidRootPart")
	local Gui = script:WaitForChild("BillboardGui"):Clone()

	local function UpdateOnLevelChanged()
		local PlayerName = Player.DisplayName ~= Player.Name and `<b>{Player.DisplayName} (@{Player.Name})</b>` or `<b>@{Player.DisplayName}</b>`
		PlayerName ..= ` <font size='16' color="rgb(245,245,245)">[{FormatNumber(pData.Stats.Level.Value, "Suffix")}]</font>`

		Gui.Canvas.DisplayName.Text = PlayerName
	end
	
	pData.Stats.Level.Changed:Connect(UpdateOnLevelChanged)
	UpdateOnLevelChanged()
	
	Gui.Canvas.GroupTransparency = 1

	Gui.Adornee = Root
	Gui.Enabled = true
	
	Gui.Canvas.UIPadding.PaddingBottom = UDim.new(0, 4)
	Gui.StudsOffsetWorldSpace = Vector3.new(0, Root.Size.Y * 1.3, 0)
	Tween:Play(Gui.Canvas, {0.25, "Circular"}, {GroupTransparency = 0})

	return Gui
end

local function CharacterAdded(Character)
	local Player = Players:GetPlayerFromCharacter(Character)
	
	local Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
	Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	
	local Gui = SetupOverheadGui(Player, Character)
	Gui.Parent = Character
	
	local PreviousHealth = Humanoid.Health
	local CurrentTime = os.clock()
	
	local Fill = Gui.Canvas.HealthBar.Fill
	local Meter = Gui.Canvas.HealthBar.Meter

	local function UpdateFill()
		local Percent = math.clamp(Humanoid.Health/Humanoid.MaxHealth, 0, 1)
		Tween:Play(Fill, {0.5, "Circular"}, {Size = UDim2.new(Percent, 0, 1, 0)})

		local Health = math.floor(Humanoid.Health * 10) / 10
		local MaxHealth = math.floor(Humanoid.MaxHealth * 10) / 10
		Gui.Canvas.HealthBar.Display.Text = `{FormatNumber(Health, "Suffix")} / {FormatNumber(MaxHealth, "Suffix")}`
		
		local Clock = os.clock()
		
		-- Meter frame (damage residual)
		local Alpha = Humanoid.Health / Humanoid.MaxHealth
		if Humanoid.Health > PreviousHealth and math.abs(Humanoid.Health - PreviousHealth) > (Humanoid.MaxHealth / 25) then
			Meter.Size = UDim2.fromScale(Alpha, 1)
		elseif Humanoid.Health < PreviousHealth then
			CurrentTime = Clock

			task.delay(HEALTH_CHANGE_STOP, function()
				if CurrentTime == Clock then
					local NewAlpha = Humanoid.Health / Humanoid.MaxHealth
					Tween:Play(Meter, {0.5, "Circular"}, {Size = UDim2.fromScale(Alpha, 1)})
				end
			end)
		end

		-- Hide/show player UI
		if GameConfig.HideMobHUDIfHeal then
			local IsFullyHealed = Humanoid.Health == Humanoid.MaxHealth
			if IsFullyHealed then
				task.delay(0.5, function()
					if CurrentTime == Clock then
						Gui.Canvas.HealthBar.Visible = false
						Gui.Canvas.UIPadding.PaddingBottom = UDim.new(0, 4 + Gui.Canvas.UIListLayout.Padding.Offset + Gui.Canvas.HealthBar.AbsoluteSize.Y)
					end
				end)
				
				Tween:Play(Gui.Canvas.HealthBar, {0.5, "Circular"}, {GroupTransparency = 1})
				Tween:Play(Gui.Canvas.HealthBar.UIStroke, {0.5, "Circular"}, {Transparency = 1})
			elseif not IsFullyHealed then
				Gui.Canvas.HealthBar.Visible = true
				Gui.Canvas.UIPadding.PaddingBottom = UDim.new(0, 4)

				Tween:Play(Gui.Canvas.HealthBar, {0.5, "Circular"}, {GroupTransparency = 0})
				Tween:Play(Gui.Canvas.HealthBar.UIStroke, {0.5, "Circular"}, {Transparency = 0.4})
			end
		end

		-- Health bar color
		local Alpha = Health / MaxHealth
		local Goal = (Alpha > 0.66 and GameConfig.PercentageColors.High)
			or (Alpha > 0.33 and GameConfig.PercentageColors.Medium) 
			or GameConfig.PercentageColors.Low

		Tween:Play(Fill, {0.5, "Circular"}, {BackgroundColor3 = Goal})
		Tween:Play(Meter, {0.5, "Circular"}, {BackgroundColor3 = Goal})

		PreviousHealth = Humanoid.Health
	end

	Gui.Canvas.HealthBar.Fill.Size = UDim2.new(0, 0, 1, 0)

	Humanoid.HealthChanged:Connect(UpdateFill)
	UpdateFill()
end

local function PlayerAdded(Player)
	if Player.Character then
		task.spawn(CharacterAdded, Player.Character)
	end
	
	Player.CharacterAdded:Connect(CharacterAdded)
end

for _, Player in Players:GetPlayers() do
	task.spawn(PlayerAdded, Player)
end

Players.PlayerAdded:Connect(PlayerAdded)

return {}