-- CLIENTSIDE

--[[
	ej0w @ October 2024
	ToolSetup
	
	Requires the scripts under this module to a tool when it is introduced to the player
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--> Player
local Player = Players.LocalPlayer
local StarterGear = Player.StarterGear

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")
local Modules = ReplicatedStorage.Modules

--> Dependencies
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local KeybindSystem = require(ReplicatedStorage.Modules.Libraries.Keybinds)

--------------------------------------------------------------------------------

local function ToolAdded(Tool)
	if not Tool:GetAttribute("LoadedClient") and Tool.Parent ~= nil then
		Tool:SetAttribute("LoadedClient", true)
		
		local ItemConfig = Tool:FindFirstChild("ItemConfig") or Tool:WaitForChild("ItemConfig", 1)
		if not ItemConfig or ItemConfig.Parent == nil then return end
		
		ItemConfig = ItemConfig and require(ItemConfig)
		
		local WeaponType = ItemConfig and (ItemConfig.WeaponType or ItemConfig.Type)
		if not ItemConfig or not WeaponType then return end
		
		local Keybinds = ItemConfig.Keybinds or {}
		
		local function LoadModule(Module)
			local Callback = require(Module)
			local Thread = task.spawn(Callback, Tool)

			-- Garbagecollect required modules :3
			local function RequestGarbageCollectThread(Child, Parent)
				if Parent == nil then
					task.cancel(Thread)
				end
			end

			Tool.AncestryChanged:Connect(RequestGarbageCollectThread)
		end
		
		local function FireClientCallback(Name)
			EventModule:Fire("ClientToClientCallback", Player, Tool.Name, Name, {Tool})
			EventModule:FireServer("ClientToServerCallback", Tool.Name, Name, {Tool})
		end

		local NewModule = script:FindFirstChild(WeaponType)
		if NewModule then
			local Connection = nil :: RBXScriptConnection
			
			local function RequestUpdateKeybinds(Verdict)
				for Key, Data in Keybinds do
					KeybindSystem:UpdateKeybind(Key, Data[1], Verdict, Data[2], Data[3], Data[4], {
						Type = ItemConfig.Type, Name = Tool.Name
					})
				end
			end
			
			local function OnUnequipped()
				if Connection and Connection.Connected then
					Connection:Disconnect()
				end

				RequestUpdateKeybinds(false)
				FireClientCallback("OnUnequipped")
			end
			
			local function OnEquipped()
				Connection = Tool.AncestryChanged:Once(OnUnequipped)

				RequestUpdateKeybinds(true)
				FireClientCallback("OnEquipped")
			end
			
			Tool.Equipped:Connect(OnEquipped)
			Tool.Unequipped:Connect(OnUnequipped)

			LoadModule(NewModule)
		else
			warn(`ToolSetup: No valid module for {WeaponType}.`)
		end
	end
end

local function BackpackAdded(Backpack)
	if Backpack:IsA("Backpack") then
		for _, Tool in Backpack:GetChildren() do
			task.spawn(ToolAdded, Tool)
		end
		Backpack.ChildAdded:Connect(ToolAdded)
	end
end

if Player:FindFirstChild("Backpack") then
	BackpackAdded(Player.Backpack)
end
Player.ChildAdded:Connect(BackpackAdded)

return {}