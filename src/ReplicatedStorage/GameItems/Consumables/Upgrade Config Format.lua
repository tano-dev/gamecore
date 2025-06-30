local Modification = {
	Conditions = nil,
		--[[
		'Condition' = {
        Purity, -- More purity stats = more/less success chance
        Corruption,-- More corruption stats = more/less success chance
        Rarity,-- higher item rarity = more/less success chance
        OnLessUpgradeAttempts,-- Less = more/less success chance
        OnMoreUpgradeAttempts,-- More= more/less success chance
        NotUpgraded, --ItemAlreadyUpgraded
		}
		Format = "Condition_Rate_Cap" 
		-Ex: Purity_-10_90 if it has like purity: 5 --> reduced chance = -50%, cap at -90%
		]]
	AcceptType = {"All"},
	UpgradeRng = false, 
		--[[
		if UpgradeRng == false then UpgradeRange = 1
		]] 

	UpgradeRange = 10, 
		--[[
		Will roll from 1 to UpgradeRange
		//Note: Will Apply to every rng rolls
		]] 

	SuccessRate = 1,
		--[[
		Roll from 0 to 1, if number rolled higher than
		]]
	OnFailRange = 1,
		--[[
		
		]]
	UpgradeCount = 1, -- UpgradeAttemptSuccessed increasing
	Weight = 1, -- Weight for upgrade //note: Will Apply for success/fail too
	Upgrade = {
		OnAll = {
			["1:1:1"] = { --MinRoll:MaxRoll:Type
				--If rolled 3 then it gonna be first one, if from 5 to 10 then it gonna be second one
				Insert_StatsName = {
					["1:4"] = {Weight= 1,Value="1:4"},--that means value will roll 1 to 4
				}, 
				--//NOTE!: Value can be LevelScale like this
					--[[ 
					BaseStats = {
						["1:1"] = {Weight= 1,LevelScale="7:75"}},
					},
					]]
				ApplyState = {
					["5:10"] = {Weight= 1,Value={1,2,3,4,5,6,7,8}}},
				--[[
					BaseStats = {
						["1:1"] = {Weight= 1,LevelScale="7:75"}},
					},
					Reset = {
						["1:1"] = {Weight = 1,Value = true},
					},
					ResetUpgrades = {
						["1:1"] = {Weight = 1,Value = true},
					},
					ResetUpgradeSlots = {
						["1:1"] = {Weight = 1,Value = true},
					},
					ResetPurity = {
						["1:1"] = {Weight = 1,Value = true},
					},
					ResetCorruption = {
						["1:1"] = {Weight = 1,Value = true},
					},
					ResetFailedUpgrades = {
						["1:1"] = {Weight = 1,Value = true},
					},
					ResetFailedUpgrades = {
						["1:1"] = {Weight = 1,Value = true},
					},
					ResetFailedUpgrades = {
						["1:1"] = {Weight = 1,Value = true},
					},
					ApplyState = {
						["5:10"] = {Weight= 1,Value={1,2,3,4,5,6,7,8}}l,
					},
				]]
			},
		},
	--[[
		OnAll
		OnWeapon
		OnArmor
		OnHeadgear
		OnChestplate
		OnBoots
		OnAccessory
		OnTool
	]]
		Successed = {
			["1:5"] = {
				
				Message = "The power of the scroll reached your equipment and clean all of your upgrades.",
				MessageColor = Color3.fromRGB(255, 255, 255),
			},
			["6:10"] = {
				
				Message = "The power of the scroll reached your equipment and clean all of your upgrades.",
				MessageColor = Color3.fromRGB(255, 255, 255),
			},
		},
	},

	OnFail = {
		OnAll = {},
		Failed = {
			["1:1"] = {
				Message = "The power of the crystal failed to reach your equipment.",
				MessageColor = Color3.fromRGB(255, 0, 0),
			},
		},
	},
}
return Modification