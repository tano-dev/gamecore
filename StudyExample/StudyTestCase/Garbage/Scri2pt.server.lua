local RNG = Random.new()
local attempts = 0 
while wait() do
	attempts = attempts + 1
	local FinalRNG = RNG:NextInteger(1,10)
	print(FinalRNG)
	if FinalRNG == 1 then
		print("Took "..attempts.." attempt(s) to get 1%")
		break
	end
end