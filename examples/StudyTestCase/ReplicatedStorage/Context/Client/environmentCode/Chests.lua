--[[
	ej0w @ September 2024
	Chests
	
	Handles clientside chest logic, e.g. open animation and cooldown timer
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")
local pData = PlayerData:WaitForChild(Player.UserId)

--> Dependencies
local TweenCFrame = require(ReplicatedStorage.Modules.Client.tweenCFrame)
local SafeWait = require(ReplicatedStorage.Modules.Client.safeWait)

--> Variables
local Info = TweenInfo.new(0.5, Enum.EasingStyle.Circular)

--------------------------------------------------------------------------------

local Chest = {}
Chest.__index = Chest

function Chest.new(ChestInstance: Model)
	local Config = require(SafeWait(ChestInstance, "Config"))
	local Top = SafeWait(ChestInstance, "Top")
	local Hinge = SafeWait(Top, "Hinge")
	
	local self = setmetatable({}, Chest)
	self.Config = Config
	self.Name = Config.Name
	
	self.Instane = ChestInstance
	self.Hinge = Hinge
	self.HingeOrigin = Hinge.CFrame.Rotation
	
	self.ProximityPrompt = ChestInstance:FindFirstChildWhichIsA("ProximityPrompt", true)
	self.BillboardGui = ChestInstance:FindFirstChildWhichIsA("BillboardGui", true)
	
	local ChestValue = pData:WaitForChild("Chests"):FindFirstChild(self.Name)
	self.Value = ChestValue
	self.PreviousValue = nil
	
	ChestValue.Changed:Connect(function()
		self:OnUpdated()
	end)
	self:OnUpdated()
end

function Chest:OnClosed()
	self.BillboardGui.Enabled = false
	self.ProximityPrompt.Enabled = true
	
	local Goal = CFrame.new(self.Hinge.Position) * self.HingeOrigin
	TweenCFrame(self.Hinge, Info, Goal)
end

function Chest:OnOpened()
	self.BillboardGui.Enabled = true
	self.ProximityPrompt.Enabled = false
	
	local Goal = self.Hinge.CFrame * CFrame.Angles(math.rad(-135), 0, 0)
	TweenCFrame(self.Hinge, Info, Goal)
end

function Chest:RequestChanged()
	local Duration = math.round(self.Value.Value)
	
	local IsPermanent = Duration >= 1e9
	if IsPermanent then
		self.BillboardGui.Enabled = false
	elseif not IsPermanent then
		local Seconds = Duration % 60
		local Minutes = math.floor(Duration / 60) % 60
		local Hours = math.floor(Duration / 3600) % 24
		local Days = math.floor(Duration / 86400)

		local TimeText = ""
		if Days > 0 then
			TimeText ..= ` {Days}d`
		end
		if Hours > 0 then
			TimeText ..= ` {Hours}h`
		end
		if Minutes > 0 then
			TimeText ..= ` {Minutes}m`
		end
		TimeText ..= ` {Seconds}s `

		self.BillboardGui.Cooldown.Text = TimeText
	end
end

function Chest:OnUpdated()
	local PreviousValue = self.PreviousValue
	self:RequestChanged()
	
	-- Check new, changed values
	if PreviousValue then
		local IsClosed = self.Value.Value <= 0 and PreviousValue > 0
		if IsClosed then
			self:OnClosed()
		end
		
		local IsOpened = self.Value.Value > 0 and PreviousValue<= 0
		if IsOpened then
			self:OnOpened()
		end
		
	-- Check based on the original values
	elseif not PreviousValue then
		local IsClosed = self.Value.Value == 0
		if IsClosed then
			self:OnClosed()
		elseif not IsClosed then
			self:OnOpened()
		end
	end

	self.PreviousValue = self.Value.Value
end

--- Initialize

for _, Model in CollectionService:GetTagged("Chest") do
	task.spawn(Chest.new, Model)
end
CollectionService:GetInstanceAddedSignal("Chest"):Connect(Chest.new)

return {}