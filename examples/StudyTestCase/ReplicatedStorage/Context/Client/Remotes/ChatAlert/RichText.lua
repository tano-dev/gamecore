--[[
	ej0w @ July 2021
	RichText Module (imported)
]]

local RichText = {} do
	function RichText.toInteger(color)
		return math.floor(color.r*255)*256^2+math.floor(color.g*255)*256+math.floor(color.b*255)
	end

	function RichText.toHex(color)
		local int = RichText.toInteger(color)

		local current = int
		local final = ""

		local hexChar = {
			"A", "B", "C", "D", "E", "F"
		}

		repeat local remainder = current % 16
			local char = tostring(remainder)

			if remainder >= 10 then
				char = hexChar[1 + remainder - 10]
			end

			current = math.floor(current/16)
			final = final..char
		until current <= 0

		return "#"..string.reverse(final)
	end
	
	function RichText.stringEscapeRichText(s)
		s = string.gsub(s, "&",  "&amp;") -- (must do & first)
		s = string.gsub(s, "<",  "&lt;")
		s = string.gsub(s, ">",  "&gt;")
		s = string.gsub(s, "\"", "&quot;")
		s = string.gsub(s, "'",  "&apos;")
		return s
	end
end

return RichText