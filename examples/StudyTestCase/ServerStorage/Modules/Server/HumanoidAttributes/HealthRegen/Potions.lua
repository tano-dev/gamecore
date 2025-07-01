return function(self, DeltaHealth)
	local Statuses = self.Player:WaitForChild("Statuses", 1)
	if Statuses then 
		local Effect = Statuses:WaitForChild("Health")
		DeltaHealth *= Effect:GetAttribute("Boost") 
	end
	
	return DeltaHealth
end