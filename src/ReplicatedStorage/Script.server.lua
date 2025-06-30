local Modification = {
	Conditions = nil,
	AcceptType = {"All"},
	UpgradeRng = false,
	UpgradeRange = 10,
	SuccessRate = 1,
	OnFailRange = 1,
	UpgradeCount = 1,
	Weight = "1:1",
	Upgrade = {
		OnEquipments = {
			["1:1"] = {
				Damage = {["1:1"] = {Weight = 1,Value = 1}},
			},
		},
		Successed = {
			["1:1"] = {
				SetPurity = 1,
				Message = "Your equipment successfully absorped the power of the crystal.",
				MessageColor = Color3.fromRGB(0, 255, 255),
			},
		},
	},
	OnFail = {},
}
for i,v in pairs(Modification) do
	print(i,v)
end