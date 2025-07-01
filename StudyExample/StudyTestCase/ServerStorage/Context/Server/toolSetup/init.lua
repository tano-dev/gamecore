-- SERVERSIDE

--[[
	ej0w @ October 2024
	ToolSetup
	
	Clones the scripts under this module to a tool when it is introduced to the player
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

--> Dependencies
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)

--> References
local PlayerData = ReplicatedStorage:WaitForChild("PlayerData")
local Modules = ReplicatedStorage.Modules

--------------------------------------------------------------------------------

local function PlayerAdded(Player)
	local function ToolAdded(Tool)
		if not Tool:GetAttribute("LoadedServer") and Tool.Parent ~= nil then
			Tool:SetAttribute("LoadedServer", true)

			local ItemConfig = Tool:FindFirstChild("ItemConfig") or Tool:WaitForChild("ItemConfig", 1)
			ItemConfig = ItemConfig and require(ItemConfig)
			
			AttributeModule:CreateAttributeFolder(Tool)

			local WeaponType = ItemConfig and (ItemConfig.WeaponType or ItemConfig.Type)
			if not ItemConfig or not WeaponType then
				return
			end
			
			EventModule:Fire("ServerToServerCallback", Player, Tool.Name, "OnBackpackAdded", {Tool})
			EventModule:FireAllClients("ServerToClientCallback", Player, Tool.Name, "OnBackpackAdded", {Tool})

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

			if ItemConfig.Motor6D then
				LoadModule(script.Motor6D)
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
end

for _, Player in Players:GetPlayers() do
	PlayerAdded(Player)
end
Players.PlayerAdded:Connect(PlayerAdded)

return {}