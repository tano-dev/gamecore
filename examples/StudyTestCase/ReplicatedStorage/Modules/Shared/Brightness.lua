local Brightness = {} do
	function Brightness:CheckBrightness(Color: Color3)
		local R	 = Color.R * 255
		local G	 = Color.G * 255
		local B = Color.B * 255
		return R < 100 and G < 100 and B < 100
	end

	function Brightness:AddBrightness(Color: Color3, Multiply)
		return Color3.new(Color.R * Multiply, Color.G * Multiply, Color.B * Multiply)
	end
	
	function Brightness:AdjustColor(Color1, Color2)
		local Color = Brightness:AddBrightness(Color1, 1.3)
		
		if Brightness:CheckBrightness(Color) then
			Color = Brightness:AddBrightness(Color2, 1.3)
		end
		
		if Brightness:CheckBrightness(Color) then
			Color = Color3.fromRGB(223, 223, 223)
		end
		
		return Color
	end
	
	return Brightness
end