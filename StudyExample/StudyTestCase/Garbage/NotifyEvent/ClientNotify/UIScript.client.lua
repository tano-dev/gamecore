_C = require( game:GetService("ReplicatedStorage").GameConfig )
plr = game.Players.LocalPlayer
wait()
for _,v in ipairs(script.Parent:GetDescendants()) do
	if v.Name == "Color" then
		v.BackgroundColor3 = _C.UI_Color
	elseif v:IsA("TextButton") and v.BorderSizePixel > 0 then
		v.BorderColor3 = _C.UI_Color
	end
end
