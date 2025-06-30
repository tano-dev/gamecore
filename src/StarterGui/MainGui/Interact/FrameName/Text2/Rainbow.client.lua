local button = script.Parent
local gradient = button.Awakened
local ts = game:GetService("TweenService")
local ti = TweenInfo.new(0.25, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local offset = {Offset = Vector2.new(1, 0)}
local create = ts:Create(gradient, ti, offset)
local startingPos = Vector2.new(-1, 0)
local list = {}
local s, kpt = ColorSequence.new, ColorSequenceKeypoint.new
local counter = 0
local status = "down"

gradient.Offset = startingPos

local function rainbowColors()
	
	local sat, val = 255, 255
	
	for i = 1, 15 do
		
		local hue = i * 17
		table.insert(list, Color3.fromHSV(hue / 255, sat / 255, val / 255))
		
	end
	
end

rainbowColors()

gradient.Color = s({

	kpt(0, list[#list]),
	kpt(0.5, list[#list - 1]),
	kpt(1, list[#list - 2])

})

counter = #list

local function animate()
	
	create:Play()
	create.Completed:Wait()
	gradient.Offset = startingPos
	gradient.Rotation = 180
	
	if counter == #list - 1 and status == "down" then
		
		gradient.Color = s({
	
			kpt(0, gradient.Color.Keypoints[1].Value),
			kpt(0.5, list[#list]),
			kpt(1, list[1])
	
		})
		
		counter = 1
		status = "up"
		
	elseif counter == #list and status == "down" then
		
		gradient.Color = s({
	
			kpt(0, gradient.Color.Keypoints[1].Value),
			kpt(0.5, list[1]),
			kpt(1, list[2])
	
		})
	
		counter = 2
		status = "up"
		
	elseif counter <= #list - 2 and status == "down" then 
		
		gradient.Color = s({
	
			kpt(0, gradient.Color.Keypoints[1].Value),
			kpt(0.5, list[counter + 1]),
			kpt(1, list[counter + 2])
	
		})
		
		counter = counter + 2
		status = "up"
	
	end
	
	create:Play()
	create.Completed:Wait()
	gradient.Offset = startingPos
	gradient.Rotation = 0
	
	if counter == #list - 1 and status == "up" then
		
		gradient.Color = s({
		
			kpt(0, list[1]),
			kpt(0.5, list[#list]),
			kpt(1, gradient.Color.Keypoints[3].Value)
				
		})
		
		counter = 1
		status = "down"
		
	 elseif counter == #list and status == "up" then
		
		gradient.Color = s({
		
			kpt(0, list[2]),
			kpt(0.5, list[1]),
			kpt(1, gradient.Color.Keypoints[3].Value)
				
		})
		
		counter = 2
		status = "down"
	
	elseif counter <= #list - 2 and status == "up" then
		
		gradient.Color = s({
		
			kpt(0, list[counter + 2]),
			kpt(0.5, list[counter + 1]),
			kpt(1, gradient.Color.Keypoints[3].Value)
				
		})
		
		counter = counter + 2
		status = "down"
	
	end
	
	animate()
	
end

animate()