repeat wait() until game:GetService("Players").LocalPlayer.Character-- wait for character loaded or sometimes you will get sus lines
UserInputService = game:GetService("UserInputService")
--https://developer.roblox.com/en-us/api-reference/class/UserInputService
print("aaaa")
local CoolDown = 0.69 --Change cooldown here
local DeBouncer = true --Debounce incase spamming
--Get Player
local Player = game.Players.LocalPlayer -- available from local script
local Amogus = Player.Character -- get character

--some advanced stuff but not really it is
local HitboxEffect = true -- change this to false if u want to see it

local OffSet = Vector3.new(0,0,-3)
--https://developer.roblox.com/en-us/articles/Debounce
local function onInputBegan(input, gameProcessed)
	if DeBouncer == false then return end -- End the function if caller pressed anykey when DeBouncer = false
	print(input.KeyCode)
	if input.KeyCode == Enum.KeyCode.E then
		DeBouncer = false
		print("E")
		--create hitbox
		local HumanoidRootPart = Amogus:FindFirstChild("HumanoidRootPart")
		local NewCFrame = HumanoidRootPart.CFrame*CFrame.new(OffSet)
		--CFrame kinda hard to understand so yeah imma not explain it, also i dont get it at all so yeah ;>
		local SusBox = script.Hitbox:Clone()
		SusBox.Parent = workspace.Terrain
		SusBox.CFrame = NewCFrame
		-- if you want the part rotate then
		--SusBox.Orientation = Vector3.New(x,y,z)
		game.Lighting.DamageEvent:FireServer(NewCFrame,SusBox.Size)
		if HitboxEffect == true then
			SusBox.OutlineEffect.Visible = true
		end
		game.Debris:AddItem(SusBox,3) -- yoink the hitbox after 5s
		--https://developer.roblox.com/en-us/api-reference/class/Debris
	
		
		wait(CoolDown)
		DeBouncer = true
	end
	
end

UserInputService.InputBegan:Connect(onInputBegan)