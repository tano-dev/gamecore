--[[
	ej0w @ September 2024
	Zones
	
	Handles all zone logic, including sound & lighting.
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

--> Player
local Player = Players.LocalPlayer

local PlayerGui = Player:WaitForChild("PlayerGui")
local Alerts = PlayerGui:WaitForChild("Alerts")

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")
local Modules = ReplicatedStorage.Modules

local Assets = ReplicatedStorage.Assets
local LightingAssets = Assets.Lighting

--> Dependencies
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)
local SFX = require(Modules.Shared.SFX)

--> Variables
local PlayingZoneObject = nil

local ZoneClock = os.clock()
local ZoneTransitionTime = 0.5

local Sound = Instance.new("Sound")
Sound.Parent = SoundService
Sound.Volume = 0.5
Sound.SoundId = ""

--------------------------------------------------------------------------------

local DefaultLighting = {
	Ambient = Lighting.Ambient,
	OutdoorAmbient = Lighting.OutdoorAmbient,
	
	ColorShift_Bottom = Lighting.ColorShift_Bottom,
	ColorShift_Top = Lighting.ColorShift_Top,
	EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale,
	EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale,
	
	GlobalShadows = Lighting.GlobalShadows,
	ShadowSoftness = Lighting.ShadowSoftness,
	ClockTime = Lighting.ClockTime,
	GeographicLatitude = Lighting.GeographicLatitude,
	
	Brightness = Lighting.Brightness,
	ExposureCompensation = Lighting.ExposureCompensation,
	
	FogColor = Lighting.FogColor,
	FogEnd = Lighting.FogEnd,
	FogStart = Lighting.FogStart,
}

local DefaultLightingObjects = {}
task.defer(function()
	for _, Object in Lighting:GetChildren() do
		DefaultLightingObjects[Object.ClassName] = Object:Clone()
	end
end)

local function ApplyObjects(Default, Folder)
	local NewFolder = (Default and DefaultLightingObjects) or Folder:GetChildren()
	
	local Given = {}
	for _, Object in NewFolder do
		Given[Object.ClassName] = Object
	end
	
	for _, Object in Lighting:GetChildren() do
		if not DefaultLightingObjects[Object.ClassName] then
			Object:Destroy()
		end
	end
	
	-- Yes, this looks atrocious. I'm sorry, nothing I can do about it
	local function ApplyToFolder(Folder)
		local OriginalParameters = {}
		if Folder.Atmosphere then
			OriginalParameters.Atmosphere = {
				Density = Folder.Atmosphere.Density,
				Offset = Folder.Atmosphere.Offset,
				Color = Folder.Atmosphere.Color,
				Decay = Folder.Atmosphere.Decay,
				Glare = Folder.Atmosphere.Glare,
				Haze = Folder.Atmosphere.Haze,
			}
		end
		
		if Folder.DepthOfFieldEffect then
			OriginalParameters.DepthOfFieldEffect = {
				FarIntensity = Folder.DepthOfFieldEffect.FarIntensity,
				FocusDistance = Folder.DepthOfFieldEffect.FocusDistance,
				InFocusRadius = Folder.DepthOfFieldEffect.InFocusRadius,
				NearIntensity = Folder.DepthOfFieldEffect.NearIntensity,
			}
		end
		
		if Folder.SunRaysEffect then
			OriginalParameters.SunRaysEffect = {
				Intensity = Folder.SunRaysEffect.Intensity,
				Spread = Folder.SunRaysEffect.Spread,
			}
		end
		
		if Folder.ColorCorrectionEffect then
			OriginalParameters.ColorCorrectionEffect = {
				Brightness = Folder.ColorCorrectionEffect.Brightness,
				Contrast = Folder.ColorCorrectionEffect.Contrast,
				Saturation = Folder.ColorCorrectionEffect.Saturation,
				TintColor = Folder.ColorCorrectionEffect.TintColor,
			}
		end
		
		if Folder.BlurEffect then
			OriginalParameters.BlurEffect = {
				Size = Folder.BlurEffect.Size,
			}
		end
		
		if Folder.BloomEffect then
			OriginalParameters.BloomEffect = {
				Intensity = Folder.BloomEffect.Intensity,
				Size = Folder.BloomEffect.Size,
				Threshold = Folder.BloomEffect.Threshold,
			}
		end
		
		return OriginalParameters
	end
	
	local function SingularApplyObject(Object, Parameters)
		if not Parameters then
			return
		end
		
		local ClassName = Object.ClassName
		
		local OldObject = Lighting:FindFirstChildWhichIsA(ClassName) 
			or Object:Clone() 
			or Instance.new(ClassName)
		
		OldObject.Parent = Lighting
		Tween:Play(OldObject, {ZoneTransitionTime}, Parameters)
	end
	
	local OriginalParameters = ApplyToFolder(DefaultLightingObjects)
	for ClassName, Object in DefaultLightingObjects do
		if Given[ClassName] then
			continue
		end
		
		if ClassName == "Sky" then
			local OldSky = Lighting:FindFirstChildWhichIsA("Sky")
			if OldSky then
				OldSky:Destroy()
			end
			Object:Clone().Parent = Lighting
		else
			SingularApplyObject(Object, OriginalParameters[ClassName])
		end
	end
	
	local GivenParameters = ApplyToFolder(Given)
	for ClassName, Object in Given do
		if ClassName == "Sky" then
			local OldSky = Lighting:FindFirstChildWhichIsA("Sky")
			if OldSky then
				OldSky:Destroy()
			end
			Object:Clone().Parent = Lighting
		else
			SingularApplyObject(Object, GivenParameters[ClassName])
		end
	end
end

local function ApplyProperties(Properties)
	for Name, Value in Properties do
		local IsTweenable = typeof(Value) ~= "boolean" and typeof(Value) ~= "string"
		if IsTweenable then
			local Goal = {}
			Goal[Name] = Value
			Tween:Play(Lighting, {ZoneTransitionTime}, Goal)
		elseif not IsTweenable then
			Properties[Name] = Value
		end
	end
end

--------------------------------------------------------------------------------

local Zone = {}
Zone.__index = Zone

function Zone.new(ZoneObject)
	local self = setmetatable({}, Zone)
	self.ZoneObject = ZoneObject
	self.Config = require(ZoneObject:FindFirstChild("ZoneConfig"))
	self.LastEntered = 0
	
	local function ZoneChildAdded(Hitbox)
		if Hitbox:IsA("BasePart") then
			Hitbox.Touched:Connect(function(Hit)
				local _Player = Players:GetPlayerFromCharacter(Hit.Parent)
				if _Player == Player and PlayingZoneObject ~= self then
					if os.clock() - ZoneClock < ZoneTransitionTime then
						return
					end

					local Clock = os.clock()
					ZoneClock = Clock

					PlayingZoneObject = self
					
					self:ApplyAreaAlert()
					self:ApplyLighting(Clock)
					self:ApplySFX(Clock)
				end
			end)

			Hitbox.Transparency = 1
		end
	end
	
	for _, Hitbox in ZoneObject:GetChildren() do
		ZoneChildAdded(Hitbox)
	end
	ZoneObject.ChildAdded:Connect(ZoneChildAdded)
	
	return self
end

function Zone:ApplyAreaAlert()
	local LastEntered = self.LastEntered
	
	local AreaName = self.Config.Area
	if not AreaName or os.clock() - LastEntered < 10 then
		return
	end
	
	self.LastEntered = os.clock()
	
	-- Already has boss UI enabled (dont override)
	if PlayerGui.Entity.Enabled and PlayerGui.Entity.Boss.GroupTransparency == 0 then
		return
	end
	
	-- Create UI
	local AreaAlert = Alerts:WaitForChild("Area"):WaitForChild("AreaAlert"):Clone()
	AreaAlert.Name = AreaName
	
	AreaAlert.Title.Display.Text = AreaName
	AreaAlert.Title.Display.TextColor3 = self.Config.AreaColor or Color3.fromRGB(255, 255, 255)
	
	AreaAlert.GroupTransparency = 1
	AreaAlert.UIPadding.PaddingTop = UDim.new(0, -10)
	
	AreaAlert.Parent = Alerts.Area
	AreaAlert.Visible = true
	
	-- Fade UI
	Tween:Play(AreaAlert.UIPadding, {0.5, "Back", "Out"}, {PaddingTop =  UDim.new(0, 10)})
	Tween:Play(AreaAlert, {0.5, "Circular"}, {GroupTransparency = 0})
	task.delay(2, function()
		Tween:Play(AreaAlert.UIPadding, {0.5, "Circular"}, {PaddingTop =  UDim.new(0, -10)})
		Tween:Play(AreaAlert, {0.5, "Circular"}, {GroupTransparency = 1})
	end)
	
	Debris:AddItem(AreaAlert, 2.5)
end

function Zone:ApplySFX(Clock)
	local SoundConfig = self.Config.SFX
	if SoundConfig then
		task.delay(ZoneTransitionTime, function()
			if ZoneClock ~= Clock then
				return
			end
			
			while ZoneClock == Clock do
				local ChosenSoundID = typeof(SoundConfig[1]) == "table" and SoundConfig[math.random(1, #SoundConfig)] or SoundConfig
				Tween:Play(Sound, {0.25}, {Volume = ChosenSoundID.Volume or ChosenSoundID[2]})
				
				local Id = ChosenSoundID.SoundID or ChosenSoundID[1]
				if tonumber(Id) then
					Id = "rbxassetid://" .. Id
				end

				Sound.SoundId = Id
				Sound.TimePosition = 0
				
				Sound:Play()
				Sound.Ended:Wait()
			end
		end)
		
		Tween:Play(Sound, {ZoneTransitionTime}, {Volume = 0})
	elseif not SoundConfig then
		task.delay(ZoneTransitionTime, function()
			if ZoneClock ~= Clock then
				return
			end
			Sound:Stop()
		end)
		
		Tween:Play(Sound, {ZoneTransitionTime}, {Volume = 0})
	end
end

function Zone:ApplyLighting()
	local LightingConfig = self.Config.Lighting
	if LightingConfig then
		local Template = LightingAssets:FindFirstChild(LightingConfig.TemplateName)
		local ObjectAssets = Template or DefaultLightingObjects
		ApplyObjects(not Template, ObjectAssets)
		
		-- Fit the properties to align with default lighting properties
		local NewProperties = {}
		for Name, Value in LightingConfig.Properties or {} do
			if not DefaultLighting[Name] then 
				continue 
			end
			
			NewProperties[Name] = Value
		end
		
		for Name, Value in DefaultLighting do
			if NewProperties[Name] then 
				continue 
			end
			
			NewProperties[Name] = Value
		end
		
		ApplyProperties(NewProperties)
	elseif not LightingConfig then
		ApplyObjects(true)
		ApplyProperties(DefaultLighting)
	end
end

for _, Model in CollectionService:GetTagged("Zone") do
	task.spawn(Zone.new, Model)
end
CollectionService:GetInstanceAddedSignal("Zone"):Connect(Zone.new)

return {}