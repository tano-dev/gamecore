--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--> Player
local Player = Players.LocalPlayer

--> References
local Modules = ReplicatedStorage.Modules

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

local _Animation = require(Modules.Client.Animation)

local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)
local ToolSystem = require(ReplicatedStorage.Modules.Client.ToolSystem)
local SFX = require(ReplicatedStorage.Modules.Shared.SFX)

--> Variables
shared.FoodCooldown = {}

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return function(Tool)
	local Handle = Tool:WaitForChild("Handle")
	local ItemConfig = require(Tool:WaitForChild("ItemConfig"))
	
	local ActiveAnimation
	local Debounce = false
	
	local toolSystem = ToolSystem.new(Tool)
	
	-- Character
	local Character = Player.Character or Player.CharacterAdded:Wait()

	local Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
	local Animator = Humanoid:WaitForChild("Animator") :: Animator
	
	--------------------------------------------------------------------------------

	local function DefaultConsumeAnimation(Cooldown)
		local DefaultGripForward = Tool.GripForward
		local DefaultGripPos = Tool.GripPos
		local DefaultGripRight = Tool.GripRight
		local DefaultGripUp = Tool.GripUp
		
		Tool.GripForward = Vector3.new(0,-.759,-.651)
		Tool.GripPos = Vector3.new(1.5,-.5,.3)
		Tool.GripRight = Vector3.new(1,0,0)
		Tool.GripUp = Vector3.new(0,.651,-.759)
		
		task.delay(math.min(0.5, Cooldown), function()
			if ItemConfig.Reusable then
				Tool.GripForward = DefaultGripForward
				Tool.GripPos = DefaultGripPos
				Tool.GripRight = DefaultGripRight
				Tool.GripUp = DefaultGripUp
			elseif not ItemConfig.IsPotion then
				for _, Part in Tool:GetDescendants() do
					if Part:IsA("BasePart") then
						Part:Destroy()
					end
				end
			end
		end)
	end
	
	--------------------------------------------------------------------------------
	
	local function RequestActivate()
		if ItemConfig.Autofire and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			if Tool:IsDescendantOf(workspace) then
				Tool:Activate()
			end
		end
	end
	
	-- Connections
	Tool.Activated:Connect(function()
		local Cooldown = ItemConfig.Cooldown or 1
		
		local GlobalDebounce = shared.FoodCooldown[Tool.Name]
		if GlobalDebounce and os.clock() - GlobalDebounce < Cooldown or Humanoid.Health <= 0 or not Tool.Enabled then
			return
		end
		
		-- Assign variables
		Tool.Enabled = false
		shared.FoodCooldown[Tool.Name] = os.clock()
		
		---- Animation & SFX
		
		toolSystem:Activated()
		
		local Animation = toolSystem:PlayAnimation("Activate")
		if not Animation then
			DefaultConsumeAnimation(Cooldown)
		end
		
		---- Callback & activated

		task.delay(ItemConfig.ConsumeDelay, function()
			if Character.Parent == nil then
				return
			end
			
			EventModule:FireServer("PlayerConsumedItem", Tool)
		end)

		EventModule:Fire("PlayerUsedWeapon", Cooldown, Tool.Name)

		if ItemConfig.Reusable then
			task.delay(Cooldown, function()
				Tool.Enabled = true
				RequestActivate()
			end)
		end
	end)
	
	Tool.Equipped:Connect(function()
		toolSystem:Equipped()
	end)

	Tool.Unequipped:Connect(function()
		toolSystem:Unequipped()
	end)
end
