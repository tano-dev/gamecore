local lastnumb=0
for i = 0,200 do
	local func1 = 5*i*(i+25)
	local func2 = 35*i*(i-5)
	local func3 = 70*i*(i-13)
	local func4 = 185*i*(i-27)
	local func5 = 505*i*(i-42)
	local func6 = 1355*i*(i-66)
	local func7 = 2275*i*(i-88)
	local func8 = 6250*i*(i-134)
	local currentfunc
	if i <= 10 then currentfunc = func1
	elseif i <=20 then currentfunc = func2
	elseif i <=35 then currentfunc = func3
	elseif i <=50 then currentfunc = func4
	elseif i <=80 then currentfunc = func5
	elseif i <=120 then currentfunc = func6
	elseif i <=160 then currentfunc = func7
	else currentfunc = func8 end
	lastnumb = lastnumb + currentfunc
	print("Exp needed to "..i.." : "..currentfunc)
	print("Total exp: "..lastnumb)
end