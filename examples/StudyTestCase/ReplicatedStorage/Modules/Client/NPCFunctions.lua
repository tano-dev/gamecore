--[[
	ej0w @ October 2024
	NPCFunctions
	
	Handles NPC functions (includes animation, etc.)
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer

--> Dependencies
local WaitForDescendant = require(ReplicatedStorage.Modules.Client.waitForDescendant)

local Animation = require(ReplicatedStorage.Modules.Client.Animation)
local Tween = require(ReplicatedStorage.Modules.Shared.Tween)

local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local NPCFunctions = {}

--> Configuration
local SHOP_DIALOGUE_REFRESH = {10, 30}

--------------------------------------------------------------------------------

function NPCFunctions:AnimateNPC(Shop)
	local Config = require(Shop:WaitForChild("Config"))
	local NPC = (Shop:FindFirstChild("NPC") or Shop) :: Model
	
	for _, Part in NPC:GetDescendants() do
		if Part:IsA("BasePart") and (not Part.Anchored or Part.Name == "HumanoidRootPart") then
			Part.CollisionGroup = "Mobs"
		end
	end
	
	if NPC:FindFirstChild("Torso") and not NPC.Torso.Anchored then
		local Humanoid = NPC:WaitForChild("Humanoid")
		local Animator = Humanoid:WaitForChild("Animator") :: Animator

		local AnimationID = Config.Animations.Idle and `rbxassetid://{Config.Animations.Idle}` 
			or ReplicatedStorage.Context.Client.entityCode.MobClient.DefaultAnimations.Idle.AnimationId

		local NewAnimation = Instance.new("Animation")
		NewAnimation.AnimationId = Animation:GetAnimationID(AnimationID)

		local AnimationTrack = Animator:LoadAnimation(NewAnimation)
		AnimationTrack:Play()
	end
end

function NPCFunctions:CreateDialogue(Shop)
	local BillboardGui = Shop.Primary:FindFirstChildWhichIsA("BillboardGui", true)
	local Config = require(Shop:WaitForChild("Config"))
	
	if BillboardGui and Config.Dialogues then
		task.spawn(function()
			while Shop.Parent ~= nil do
				local ChosenDialogue = nil
				repeat
					ChosenDialogue = Config.Dialogues[math.random(1, #Config.Dialogues)]
					if ChosenDialogue == BillboardGui.Dialogue.Text then
						task.wait()
					end
				until ChosenDialogue ~= BillboardGui.Dialogue.Text

				Tween:Play(BillboardGui.Dialogue, {0.5, "Quad", "InOut"}, {TextTransparency = 1})
				Tween:Play(BillboardGui.Dialogue.UIStroke, {0.5, "Quad", "InOut"}, {Transparency = 1})
				task.delay(0.5, function()
					Tween:Play(BillboardGui.Dialogue, {0.5, "Quad", "InOut"}, {TextTransparency = 0})
					Tween:Play(BillboardGui.Dialogue.UIStroke, {0.5, "Quad", "InOut"}, {Transparency = 0.6})
					BillboardGui.Dialogue.Text = ChosenDialogue
				end)

				task.wait(math.random(table.unpack(SHOP_DIALOGUE_REFRESH)))
			end
		end)
	end
end

function NPCFunctions:CreateProximityPrompt(Shop, Check0, Connection0, Callback1, Callback2)
	if Shop:FindFirstChild("Loaded") then
		return
	end

	local Configuration = Instance.new("Configuration")
	Configuration.Name = "Loaded"
	Configuration.Parent = Shop
	
	local ProximityPrompt = WaitForDescendant(Shop, "ProximityPrompt") :: ProximityPrompt
	local ShopConfig = require(Shop:WaitForChild("Config"))

	if ProximityPrompt.ObjectText == "" then
		ProximityPrompt.ObjectText = ShopConfig.Name
	end

	ProximityPrompt.Triggered:Connect(function(p)
		if p == Player and Player.Character then
			if Check0() then
				local Success = Callback1(Shop)
				if Success then
					return
				end
			end

			Callback2(Shop, ShopConfig)

			-- Wait for either the ExitButton to be pressed, or for the player to move outside of close distance, to close the shop.
			local Connection; Connection = Connection0:Connect(function()
				Connection:Disconnect()
			end)

			local MaxDistance = ShopConfig.CloseDistance
			local ShopPosition = (Shop:FindFirstChild("Torso") :: BasePart or Shop.PrimaryPart).Position

			while Connection.Connected do
				local Character = Player.Character
				local Distance = Character and (Character:GetPivot().Position - ShopPosition).Magnitude

				if Distance == nil or Distance > MaxDistance then
					break
				end

				task.wait(0.1)
			end

			if Connection.Connected then
				Connection:Disconnect()
			end

			Callback1()
		end
	end)
end

return NPCFunctions