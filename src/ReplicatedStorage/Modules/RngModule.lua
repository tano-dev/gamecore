--APIs
--[[
	RNG(Mode,StartNumber,EndNumber)
	Mode:
	1,Number1, return Bool
	> will roll from 1 to Number1
	2,Number1 and Number2, return RngNumber
	> will roll from Number1 to Number2
]]
local RngNoThanksMyLuckSus = {}
local RNG = Random.new()
local function ConvertNumber(Number)
	local LastNumber = nil
	for i = 1,10 do
		if LastNumber == nil then
			if Number < 1 and Number >= 1/10^i then
				return 10^(i+2)
			end
			LastNumber = 10^i
		else
			if Number < LastNumber and Number >= 1/10^i then
				return 10^(i+2)
			end
			LastNumber = 10^i
		end
	end
end
local function Round(n, decimals)
	decimals = decimals or 0
	return math.floor(n * 10^decimals) / 10^decimals
end
function RngNoThanksMyLuckSus.RNG(Mode,Number1,Number2)
	if Mode == 1 then
		if Number1 == 1 then
			return true
		else
			local NewRange = ConvertNumber(Number1)
			local NewNumber = Round(Number1*NewRange)
			print(NewRange)
			print(NewNumber)
			local CastRngResult = RNG:NextInteger(1,NewRange)
			if CastRngResult <= NewNumber then
				return true
			else
				return false
			end
		end
	elseif Mode == 2  then
		if Number1 == Number2 then return Number1 or Number2 end
		local CastRngResult = RNG:NextInteger(Number1,Number2)
		return CastRngResult
	end
end
return RngNoThanksMyLuckSus
