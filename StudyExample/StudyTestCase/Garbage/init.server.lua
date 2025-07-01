local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RemoteFolder = ReplicatedStorage:WaitForChild("GameRemotes")
local ItemFolder = ReplicatedStorage:WaitForChild("GameItems")

game.Players.PlayerAdded:Connect(function(plr)
	wait()
	local BindableEvent = Instance.new("RemoteEvent",plr)
	BindableEvent.Name = "ShopBind"
end)

RemoteFolder:WaitForChild("BuyEvent").OnServerEvent:Connect(function(plr,item)
	local lstats = plr:WaitForChild("leaderstats")
	local stat = lstats:WaitForChild("Gold")
	local BP = plr:WaitForChild("Backpack")
	local SG = plr:WaitForChild("StarterGear")
	if (plr) and (item ~= nil) then
		local LoadedGear = ItemFolder:WaitForChild(item)
		if stat.Value >= require(LoadedGear.WeaponConfig).Cost then
			if BP:FindFirstChild(item) or SG:FindFirstChild(item) then
				require(script.NotifyEvent).Notify(plr,"You already own "..item..".")
				return
			end
			require(script.BuyEvent).Purchase(plr,item,require(LoadedGear.WeaponConfig).Cost)
			require(script.NotifyEvent).Notify(plr,"You purchased the "..item.." for "..require(LoadedGear.WeaponConfig).Cost.." gold.")
		else
			require(script.NotifyEvent).Notify(plr,"You don't have enough gold for "..item..".")
		end
	end
end)

RemoteFolder:WaitForChild("SellEvent").OnServerEvent:Connect(function(plr,item)
	local lstats = plr:WaitForChild("leaderstats")
	local stat = lstats:WaitForChild("Gold")
	local BP = plr:WaitForChild("Backpack")
	local SG = plr:WaitForChild("StarterGear")
	if (plr) and (item ~= nil) then
		local BPG = BP:FindFirstChild(item)
		local SGG = SG:FindFirstChild(item)
		local LoadedGear = ItemFolder:WaitForChild(item)
		if (BPG~=nil) and (SGG~=nil) then
			require(script.SellEvent).Sell(plr,item,require(LoadedGear.WeaponConfig).Cost)
			require(script.NotifyEvent).Notify(plr,"You sold your "..item.." for "..require(LoadedGear.WeaponConfig).Cost.." gold.")
		else
			require(script.NotifyEvent).Notify(plr,"You don't own the "..item..".")
		end
	end
end)

RemoteFolder:WaitForChild("DamageEvent").OnServerEvent:Connect(function(plr,hit,enemy)
	require(script.DamageEvent).Damage(plr,hit,enemy)
end)
RemoteFolder:WaitForChild("NotifyEvent").OnServerEvent:Connect(function(plr,msg)
	require(script.NotifyEvent).Notify(plr,msg)
end)

RemoteFolder:WaitForChild("CloseGUIEvent").OnServerEvent:Connect(function(plr,gui,action)
	if action == "Visible" then gui.Visible = (not gui.Visible) end
	if action == "Destroy" then gui:Destroy() end
end)

-- By Evercyan (https://www.roblox.com/users/111334263/profile)