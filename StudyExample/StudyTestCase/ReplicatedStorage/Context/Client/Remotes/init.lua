--[[
	ej0w @ September 2024
	RemoteHandler
	
	I noticed that remotes tended to become very messy, very quickly. 
	I introduced this to handle these miscellaneous remotes better than the kit had originally.
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--> Dependencies
local EventModule = require(ReplicatedStorage.Modules.Shared.Event)
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)

--------------------------------------------------------------------------------

for _, Module in script:GetChildren() do
	if Module:IsA("ModuleScript") and not Module:GetAttribute("Required") then
		local Required = require(Module)
		
		local Remote = EventModule:GetRemote(Module.Name)
		if not Remote then 
			continue 
		end

		if Remote:IsA("RemoteEvent") or Remote:IsA("UnreliableRemoteEvent") then
			Remote.OnClientEvent:Connect(function(...)
				Required:OnEvent(...)
			end)
		elseif Remote:IsA("RemoteFunction") then
			Remote.OnClientInvoke = function(...)
				return Required:OnEvent(...)
			end
		end

		Module:SetAttribute("Required", true)
	end
end

return {}