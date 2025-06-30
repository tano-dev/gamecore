--APIs
--[[
Main APIs:
CalculateLevelMain(Level,Superiority)
 > return ExpNeeded
CalculateLevelProfession(Level)
 > return ExpNeeded
]]--

local LevelingCalculator = {}
LevelingCalculator.LevelCap = 25
--local function Round(n, decimals)
--	decimals = decimals or 0
--	return math.floor(n * 10^decimals) / 10^decimals
--end
--function LevelingCalculator.CalculateLevelMain(Level,Superiority)
--	local ExpNeeded = Round((26*Level+51)^math.log(8) * (1+Superiority*0.1) *0.01)
--	return ExpNeeded
--end
--function LevelingCalculator.CalculateLevelProfession(Level)
--	local ExpNeeded = Round(((1.276*Level^2+20*Level+105)^math.log(6))*0.01)
--	return ExpNeeded
--end

--[[
lvl 1 - 130 exp
exp 125 + 10 = 135 --> lv 1
lvl 
vd: exp: 135 --> -130 and +1 lv

exp: 5845
]]


function LevelingCalculator.CalculateLevel(Exp)
	local TotalExp=0
	local TotalExpNextLevel=0
	local Level,NextLevelExp,TotalAccExp 
	local function func1(E) return 5*E*(E+25) end
	local function func2(E) return 35*E*(E-5)end
	local function func3(E) return 70*E*(E-13)end
	local function func4(E) return 185*E*(E-27)end
	local function func5(E) return 505*E*(E-42)end
	local function func6(E) return 1355*E*(E-66)end
	local function func7(E) return 2275*E*(E-88)end
	local function func8(E) return 6250*E*(E-134)end
	for i = 0,LevelingCalculator.LevelCap do
		local currentfunc, nextfunc
		if i <= 10 then currentfunc = func1(i) nextfunc = func1(i+1)
		elseif i <=20 then currentfunc = func2(i) nextfunc = func2(i+1)
		elseif i <=35 then currentfunc = func3(i) nextfunc = func3(i+1)
		elseif i <=50 then currentfunc = func4(i) nextfunc = func4(i+1)
		elseif i <=80 then currentfunc = func5(i) nextfunc = func5(i+1)
		elseif i <=120 then currentfunc = func6(i) nextfunc = func6(i+1)
		elseif i <=160 then currentfunc = func7(i) nextfunc = func7(i+1)
		elseif i <=200 then currentfunc = func8(i) nextfunc = func8(i+1) end
		TotalExp = TotalExp + currentfunc
		TotalExpNextLevel = TotalExpNextLevel + nextfunc
		--print("Exp needed to "..i.." : "..currentfunc)
		--print("Total exp: "..TotalExp) 
		--print("Total exp for next level: "..TotalExpNextLevel)
		if Exp >= TotalExp and Exp < TotalExpNextLevel then
			return i,(TotalExpNextLevel-Exp),nextfunc
		end
	end
	return LevelingCalculator.LevelCap,-1,-1
end
return LevelingCalculator
--local Multiplier = 1
--local CurrentLevel = 1

--for i = 1,100 do
--	CurrentLevel = i
--	local MathFuction = ((CurrentLevel + 2)*CurrentLevel + 100 + 10*CurrentLevel)^2 * Multiplier *0.01
--	print("Current Level: "..CurrentLevel.." and exp required to level up is: "..tostring(Round(MathFuction)))
--end