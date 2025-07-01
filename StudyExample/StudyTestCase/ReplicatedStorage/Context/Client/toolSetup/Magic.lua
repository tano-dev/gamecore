--> Services
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer

--> References
local Modules = ReplicatedStorage.Modules

--> Dependencies
local GameConfig = require(ReplicatedStorage.GameConfig)

local RbxUtility = require(Modules.Shared.RbxUtility)
local _Animation = require(Modules.Client.Animation)
local SFX = require(Modules.Shared.SFX)

local ToolSystem = require(ReplicatedStorage.Modules.Client.ToolSystem)
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)

--> Variables
local LastEquippedTool = 0
local RequestSwing = 0

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

return function(Tool)
	local Handle = Tool:WaitForChild("Handle")
	local ItemConfig = require(Tool:WaitForChild("ItemConfig"))
	
	local ActiveSlashTrack
	local Debounce = {}
	
	local toolSystem = ToolSystem.new(Tool, true)
	
	-- Character
	local Character = Player.Character or Player.CharacterAdded:Wait()

	local Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
	local Animator = Humanoid:WaitForChild("Animator") :: Animator

	--------------------------------------------------------------------------------

	-- Utilities
	local function GetMouseHit(): Vector3
		local RaycastParams = RaycastParams.new()
		RaycastParams.FilterType = Enum.RaycastFilterType.Exclude
		RaycastParams.FilterDescendantsInstances = {
			workspace:WaitForChild("Temporary"), workspace:WaitForChild("Characters"),
			workspace.Zones, workspace.Teleports
		}
		RaycastParams.RespectCanCollide = true

		local MouseLocation = UserInputService:GetMouseLocation()
		local ViewportRay = workspace.CurrentCamera:ViewportPointToRay(MouseLocation.X, MouseLocation.Y)
		local RaycastResult = workspace:Raycast(ViewportRay.Origin, ViewportRay.Direction * 1e3, RaycastParams)

		return RaycastResult and RaycastResult.Position or (ViewportRay.Origin + ViewportRay.Direction.Unit * 1e3)
	end
	
	local function RequestActivate()
		if ItemConfig.Autofire and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
			if Tool:IsDescendantOf(workspace) then
				Tool:Activate()
			end
		end
	end
	
	Tool.Activated:Connect(function()
		if not Tool.Enabled or Humanoid.Health <= 0 then
			return
		end
		
		local TimeLeftDisabled = os.clock() - toolSystem.LastDisable 

		local Clock = os.clock()
		RequestSwing = Clock

		local IsDisabled = TimeLeftDisabled < 0
		if IsDisabled then
			task.delay(TimeLeftDisabled + 0.03, function()
				if Clock == RequestSwing then
					RequestActivate()
				end
			end)

			return
		end

		---- Hit miscellaneous & activated
		
		toolSystem:Activated()
		
		task.spawn(function()
			local MousePosition = GetMouseHit()
			EventModule:InvokeServer("PlayerCalledMagic", MousePosition)
		end)

		toolSystem:RequestUpdateTrail(true)
		
		EventModule:Fire("PlayerUsedWeapon", ItemConfig.Cooldown, Tool.Name)
		toolSystem.LastSwing = os.clock()
		
		Tool.Enabled = false
		
		---- Callback
		
		task.delay(ItemConfig.Cooldown, function()
			Tool.Enabled = true
			RequestActivate()
		end)
	end)

	Tool.Equipped:Connect(function()
		toolSystem:Equipped()
	end)

	Tool.Unequipped:Connect(function()
		toolSystem:Unequipped()
	end)
end
