--[[
	Evercyan @ March 2023
	Transportation
	
	Transportation handles all level door & portal logic, including the teleport transition.
]]

--> Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")
local pData = PlayerData:WaitForChild(Player.UserId)

--> Dependencies
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)
local ColorModule = require(ReplicatedStorage.Modules.Shared.Color)
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)

local SafeWait = require(ReplicatedStorage.Modules.Client.safeWait)

--> Configuration
local OWNED_TRANSPARENCY = 0.4
local NOT_OWNED_TRANSPARENCY = 0
local TELEPORT_UP = 4

--------------------------------------------------------------------------------

local function CreateGui(Class): BillboardGui
	local Gui = script:WaitForChild("BillboardGui"):Clone()
	Gui.Canvas.Destination.Text = Class.Config.Name
	
	local LevelSuffix = (Class.Config.Level and `Level <b>{FormatNumber(Class.Config.Level, "Suffix")}+</b>`)
	local HasNoRequirements = not Class.Config.Level and not Class.Config.Tool
	
	for _, Item in Class.Config.Items or {} do
		local ItemSuffix = `{Item[1]} <b>'{Item[2]}'</b> <font transparency="0.2">(x{FormatNumber(Item[3], "Suffix")})</font>`
		
		local Frame = Gui.Canvas.ItemReq:Clone()
		Frame.Text = ItemSuffix
		
		Frame.Visible = true
		Frame.Parent = Gui.Canvas
		
		local function CheckIfVisible()
			local FoundItem = pData.Items[Item[1]]:FindFirstChild(Item[2])
			local isOwned = FoundItem and FoundItem.Value >= Item[3]
			Frame.TextTransparency = isOwned and OWNED_TRANSPARENCY or NOT_OWNED_TRANSPARENCY
		end
		
		pData.Items.DescendantAdded:Connect(function(Child)
			if Child.Parent.Name == Item[1] and Child.Name == Item[2] then
				Child.Changed:Connect(CheckIfVisible)
				CheckIfVisible()
			end
		end)
		
		pData.Items.DescendantRemoving:Connect(function()
			task.defer(CheckIfVisible)
		end)
		
		CheckIfVisible()
	end
	
	local NewColor = ColorModule:ConvertToRawHSV(Class.Color)
	Gui.Canvas.Destination.TextColor3 = NewColor

	if LevelSuffix then
		local function CheckIfLevelVisible()
			local isOwned = pData.Stats.Level.Value >= Class.Config.Level
			Gui.Canvas.LevelReq.TextTransparency = isOwned and OWNED_TRANSPARENCY or NOT_OWNED_TRANSPARENCY
		end
	
		pData.Stats.Level.Changed:Connect(CheckIfLevelVisible)
		CheckIfLevelVisible()
		
		Gui.Canvas.LevelReq.Text = LevelSuffix
	end
	
	Gui.Canvas.LevelReq.Visible = LevelSuffix and true or false
	
	Gui.Enabled = true
	return Gui
end

local function CanPlayerAccess(Player: Player, Class): boolean
	if Class.Config.Level and (pData.Stats.Level.Value < Class.Config.Level) then
		return false
	end
	
	for _, Item in Class.Config.Items or {} do
		local FoundItem = Item and pData.Items[Item[1]]:FindFirstChild(Item[2])
		if Item and (not FoundItem or (FoundItem and FoundItem:IsA("NumberValue") and FoundItem.Value < Item[3])) then
			return false
		end
	end
	
	return true
end

---- LEVEL DOORS ---------------------------------------------------------------

local LevelDoor = {}
LevelDoor.__index = LevelDoor

LevelDoor.Items = {}

-- Level Doors require a "Hitbox" part. Any included instance is automatically hidden when opened.
function LevelDoor.new(Model: Model)
	if Model:FindFirstChild("Loaded") then
		return
	end
	
	local Configuration = Instance.new("Configuration")
	Configuration.Name = "Loaded"
	Configuration.Parent = Model
	
	local Base = SafeWait(Model, "Base") :: BasePart
	local Hitbox = SafeWait(Model, "Hitbox") :: BasePart
	local Config = require(SafeWait(Model, "Config"))
	
	local self = setmetatable({}, LevelDoor)
	self.Instance = Model
	self.Config = Config
	self.Color = Config.Color or Base.Color
	
	local Gui = CreateGui(self)
	Gui.Adornee = Base
	Gui.Parent = Model
	
	Hitbox.Touched:Connect(function(HitPart)
		local plr = Players:GetPlayerFromCharacter(HitPart.Parent)
		if Player == plr and CanPlayerAccess(Player, self) then
			self:Open()
		end
	end)
	
	table.insert(LevelDoor.Items, self)
end

function LevelDoor:Open()
	if not self.Opened then
		self.Opened = true
		
		for _, Instance in self.Instance:GetDescendants() do
			if Instance:IsA("BasePart") and Instance.Name ~= "Hitbox" then
				Tween:Play(Instance, {1, "Circular"}, {Transparency = 1})
				Instance.CanCollide = false
			elseif Instance:IsA("CanvasGroup") then
				Tween:Play(Instance, {1, "Circular"}, {GroupTransparency = 1})
			end
		end
	end
end

for _, Model in CollectionService:GetTagged("Level Door") do
	task.spawn(LevelDoor.new, Model)
end
CollectionService:GetInstanceAddedSignal("Level Door"):Connect(LevelDoor.new)

---- PORTALS -------------------------------------------------------------------

local TeleportScreen = script:WaitForChild("TeleportScreen")
TeleportScreen:WaitForChild("Canvas"):WaitForChild("Foreground").GroupTransparency = 1
TeleportScreen.Enabled = true
TeleportScreen.Parent = Player:WaitForChild("PlayerGui")

local FadeScreen = script:WaitForChild("FadeScreen")
FadeScreen.Enabled = true
FadeScreen.Parent = Player:WaitForChild("PlayerGui")

local TpCooldown = false

local Portal = {}
Portal.__index = Portal

Portal.Items = {}

-- Portals require a "Base" part.
function Portal.new(Model: Model)
	if Model:FindFirstChild("Loaded") then
		return
	end

	local Configuration = Instance.new("Configuration")
	Configuration.Name = "Loaded"
	Configuration.Parent = Model
	
	local Base = SafeWait(Model, "Base") :: BasePart
	local Hitbox = SafeWait(Model, "Hitbox") :: BasePart
	local Config = require(SafeWait(Model, "Config"))
	
	local self = setmetatable({}, Portal)
	self.Instance = Model
	self.Config = Config
	self.Color = Config.Color or Base.Color
	
	local Gui = CreateGui(self)
	Gui.Adornee = Hitbox
	Gui.Parent = Model
	
	Hitbox.Touched:Connect(function(HitPart)
		local plr = Players:GetPlayerFromCharacter(HitPart.Parent)
		if Player == plr and CanPlayerAccess(Player, self) then
			self:Teleport(Player)
		end
	end)
	
	table.insert(Portal.Items, self)
end

---- Teleport UI

local function PushTeleportScreen(Portal)
	local Canvas = TeleportScreen:WaitForChild("Canvas")
	local Background = Canvas:WaitForChild("Background")

	local Foreground = Canvas:WaitForChild("Foreground")
	if Foreground.GroupTransparency ~= 1 then return end

	Foreground.DestinationName.Text = Portal.Config.Name
	Background.BackgroundColor3 = Portal.Color

	for _, Section in Foreground.Ring:GetChildren() do
		Section.UIGradient.Rotation = 90
	end
	Background.Rotation = 0

	task.spawn(function()
		Tween:Play(Background, {2}, {Rotation = 360})
		Tween:Play(Background, {1, "Quint", "Out"}, {Size = UDim2.fromScale(2,3)})
		task.wait(1)
		Tween:Play(Background, {1, "Quint", "Out"}, {Size = UDim2.fromScale(0,0)})
	end)

	Tween:Play(Foreground, {1, "Circular"}, {GroupTransparency = 0})

	task.defer(function()
		for _, SectionName in {"TopRight", "TopLeft", "BottomLeft", "BottomRight"} do
			local Section = Foreground.Ring[SectionName]
			Tween:Play(Section.UIGradient, {0.3, "Linear"}, {Rotation = -1}).Completed:Wait()
		end

		Tween:Play(Foreground, {1, "Circular"}, {GroupTransparency = 1})
	end)

	task.wait(0.6)
	return true
end

local function PushFadeScreen()
	local Canvas = FadeScreen:WaitForChild("Canvas")
	
	local Background = Canvas:WaitForChild("Background")
	local Foreground = Canvas:WaitForChild("Foreground")
	if Background.BackgroundTransparency ~= 1 then return end

	Tween:Play(Background, {0.3, "Quad", "InOut"}, {BackgroundTransparency = 0})
	task.delay(0.7, function()
		Tween:Play(Background, {0.3, "Quad", "InOut"}, {BackgroundTransparency = 1})
	end)
	
	for _, Section in Foreground.Ring:GetChildren() do
		Section.UIGradient.Rotation = 90
	end
	Background.Rotation = 0
	
	Tween:Play(Foreground, {1, "Circular"}, {GroupTransparency = 0})

	task.defer(function()
		for _, SectionName in {"TopRight", "TopLeft", "BottomLeft", "BottomRight"} do
			local Section = Foreground.Ring[SectionName]
			Tween:Play(Section.UIGradient, {0.15, "Linear"}, {Rotation = -1}).Completed:Wait()
		end

		Tween:Play(Foreground, {1, "Circular"}, {GroupTransparency = 1})
	end)
	
	task.wait(0.3)
	return true
end

local function RequestTeleport(Position, _PushFadeScreen)
	local Character = Player.Character
	if Character then
		if _PushFadeScreen then
			local Success = PushFadeScreen()
			if not Success then return end
		end
		
		if workspace.StreamingEnabled then
			Player:RequestStreamAroundAsync(Position, 5)
		end

		local CharacterPivot = Character:GetPivot()
		Character:PivotTo((CFrame.new(Position) * CharacterPivot.Rotation) + (Vector3.yAxis * TELEPORT_UP))
	end
end

EventModule:GetOnClientEvent("RequestTeleport"):Connect(RequestTeleport)
EventModule:GetOnEvent("ClientRequestTeleport"):Connect(RequestTeleport)

function Portal:Teleport()
	if TpCooldown then
		return
	end
	TpCooldown = true
	
	local Character = Player.Character
	if Character then
		local Success = PushTeleportScreen(self)
		if Success then
			RequestTeleport(self.Config.TP)
		end
	end
	
	TpCooldown = false
end

for _, Model in CollectionService:GetTagged("Portal") do
	task.spawn(Portal.new, Model)
end
CollectionService:GetInstanceAddedSignal("Portal"):Connect(Portal.new)

return {LevelDoors = LevelDoor.Items, Portals = Portal.Items}