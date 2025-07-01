-- [SERVER]

--> References
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--> Dependencies
local RequestStunMob = require(ServerStorage.Modules.Server.requestStunMob)
local Knockback = require(ServerStorage.Modules.Server.Knockback)

local Damage = require(ServerStorage.Modules.Libraries.Damage)
local MobList = require(ServerStorage.Modules.Libraries.Mob.MobList)

--> Variables
local Keybind = {}

--------------------------------------------------------------------------------

-- Ran when activated
function Keybind:OnActivated(Player)
	
end

function Keybind:OnLetGo(Player)
	local Character = Player.Character

	local Position = Character 
		and Character:FindFirstChild("Torso")
		and Character.Torso.Position

	if not Position then 
		return
	end

	task.delay(1.35, function()
		for _, MobInstance in CollectionService:GetTagged("Mob") do
			local Torso = MobInstance:FindFirstChild("Torso")
			if Torso and (Torso.Position - Position).Magnitude < 15 then
				task.spawn(function()
					RequestStunMob(MobInstance, 2)

					Knockback:Activate(Torso, 5, Position, Torso.Position)
					Damage:DamageMob(Player, MobList[MobInstance], {Ignore = true, Damage = 25})

					pcall(function()
						Torso:SetNetworkOwner(Player)
					end)
				end)
			end
		end
	end)
end

return Keybind
