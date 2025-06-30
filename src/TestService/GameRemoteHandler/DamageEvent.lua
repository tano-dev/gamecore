_Module = {}

function CreateTag(plr,enemy)
	if enemy ~= nil then
		if (enemy:FindFirstChild("Player_Tag")) then return end
		local tag = Instance.new("ObjectValue", enemy)
		tag.Name = "Player_Tag"
		tag.Value = plr
	end
end

function DestroyTag(enemy)
	if enemy ~= nil then
		local tag = enemy:FindFirstChild("Player_Tag")
		if tag ~= nil then tag:Destroy() end
	end
end

local function CheckDistance(plr,tor,dist)
	if (not tor) or (not tor.Parent) or (not tor.Parent:FindFirstChild("MobConfig")) then return end
	if plr:DistanceFromCharacter(Vector3.new(tor.Position.X,tor.Position.Y,tor.Position.Z)) < require(tor.Parent.MobConfig).FollowDistance then
		return true else return false
	end
end

function F(str)
	return #str % 3 == 0 and str:reverse():gsub("(%d%d%d)", "%1,"):reverse():sub(2) or str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
end

local function CreateObject(hit,dmg)
		local ObjModel = Instance.new("Model", workspace.DebrisHolder)
		local Obj = Instance.new("Part", ObjModel)
		-- Appearance
		Obj.BrickColor = BrickColor.new("Bright red")
		Obj.Material = Enum.Material.Neon
		Obj.Transparency = 1
		-- Data
		Obj.Position = hit.Parent:FindFirstChild("Head").Position + Vector3.new(math.random(-1.6,1.6),2,math.random(-1.6,1.6))
		-- Behavior
		Obj.Anchored = true
		Obj.CanCollide = false
		Obj.Locked = true
		-- Part
		Obj.Shape = Enum.PartType.Ball
		Obj.Size = Vector3.new(0.75,0.75,0.75)
		-- Billboard Gui
		local Gui = script.BillboardGui:Clone()
		Gui.Adornee = ObjModel:FindFirstChild("Part")
		Gui.TextLabel.Text = addComas(tostring(dmg)).." damage"
		Gui.Parent = ObjModel
		
		local ObjPos = Instance.new("BodyPosition", Obj)
		ObjPos.Position = Vector3.new(0,7.85,0)
		for i = 1,0,-0.1 do
			Obj.Transparency = i
			Gui.TextLabel.TextTransparency = i
			Gui.TextLabel.TextStrokeTransparency = i
			wait()
		end
		wait(0.50)
		for i = 0,1,0.1 do
			Obj.Transparency = i
			Gui.TextLabel.TextTransparency = i
			Gui.TextLabel.TextStrokeTransparency = i
			wait()
		end
		return ObjModel
	end

function _Module.Damage(plr,hit,enemy)
	local chr = plr.Character or plr.CharacterAdded:Wait()
	local tool = chr:FindFirstChildOfClass("Tool")
	if (not enemy) or (not hit) or (not tool) then return end
	local tor = hit.Parent:FindFirstChild("Torso")
	if (not hit.Parent) or (not tor) then return end
	if (game.Players:GetPlayerFromCharacter(enemy.Parent)) then return end
	if (not CheckDistance(plr,hit.Parent:FindFirstChild("Torso"))) then return end
	local dmg = math.random(require(tool.WeaponConfig).MinDamage,require(tool.WeaponConfig).MaxDamage)
	if (plr:FindFirstChild("leaderstats")) then
		if plr:FindFirstChild("Level") then
			dmg = dmg + (plr.leaderstats.Level.Value - 1)
		end
	end
	CreateTag(plr,enemy)
	enemy:TakeDamage(dmg)
	local ObjModel = CreateObject(hit,dmg)
	ObjModel:Destroy()
	DestroyTag(ObjModel)
end

return _Module

-- By Evercyan (https://www.roblox.com/users/111334263/profile)