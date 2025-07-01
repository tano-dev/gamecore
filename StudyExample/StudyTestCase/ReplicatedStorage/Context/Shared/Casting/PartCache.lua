--[[
	Xan the Dragon // Eti the Spirit
	PartCache V4.0
	
	** Modified by Evercyan to further improve performance & for personal & kit use
	
	PartCache is used here for ranged weapons to cache projectiles which would normally be destroyed to greatly improve performance.
	For ranged weapons that fire tens or hundreds of projectiles, it is essential to cache your instances for this reason.
	
	Each template can only have one PartCacheStatic associated with it. If it's already made, it'll return it. A new one can be made when PartCacheStatic::Dispose is called
--]]

local CF_REALLY_FAR_AWAY = CFrame.new(0, 1e7, 0)

local PartCacheStatic = {}
local _PCS = {} -- All PartCacheStatics made that exist
PartCacheStatic.__index = PartCacheStatic
PartCacheStatic.__type = "PartCache" -- For compatibility with TypeMarshaller

export type PartCache = {
	Open: {[number]: BasePart},
	InUse: {[number]: BasePart},
	CacheParent: Instance,
	Template: BasePart,
	ExpansionSize: number,
	GetPart: (PartCache) -> (BasePart),
	ReturnPart: (PartCache, BasePart) -> (),
	Expand: (PartCache, number) -> (),
	Dispose: (PartCache) -> ()
}		

local function quickRemove(t, i) -- I added this since it's more performant than table.remove if the order of values isn't important
	local size = #t
	t[i] = t[size]
	t[size] = nil
end

local function MakeFromTemplate(template: BasePart, currentCacheParent: Instance): BasePart
	local part: BasePart = template:Clone()
	part.CFrame = CF_REALLY_FAR_AWAY
	part.Anchored = true
	part.Parent = currentCacheParent
	
	return part
end

function PartCacheStatic.new(template: BasePart, numPrecreatedParts: number?, CacheParent: Instance?): PartCache
	if _PCS[template] then
		return _PCS[template]
	end
	
	numPrecreatedParts = numPrecreatedParts or 50
	CacheParent = CacheParent or workspace:WaitForChild("Temporary")
	local newTemplate: BasePart = template:Clone()
	
	local object: PartCache = setmetatable({
		Open = {},
		InUse = {},
		CacheParent = CacheParent,
		Template = newTemplate,
		ExpansionSize = 10,
		__OriginalTemplate = template -- DON'T TOUCH: Used only for removing the pool reference under PartCacheStatic::Dispose
	}, PartCacheStatic)
	
	object:Expand(numPrecreatedParts)
	object.Template.Parent = nil
	
	_PCS[template] = object
	
	return object
end

function PartCacheStatic:GetPart(): BasePart
	local part = self.Open[1]
	
	if not part then
		self:Expand()
		part = self.Open[1]
	end
	
	quickRemove(self.Open, 1)
	table.insert(self.InUse, part)
	
	-- Clear the Trail so it won't drag from far away
	for _, Instance in part:GetDescendants() do
		if Instance:IsA("Trail") or Instance:IsA("ParticleEmitter") then
			Instance.Enabled = true
			Instance:Clear()
		end
	end
	part:SetAttribute("Modified", nil)
	
	return part
end

function PartCacheStatic:ReturnPart(part: BasePart)
	local index = table.find(self.InUse, part)
	
	if index then
		quickRemove(self.InUse, index)
		table.insert(self.Open, part)
		part.CFrame = CF_REALLY_FAR_AWAY
		part.Anchored = true
		
		-- Clear the Trail so it won't drag to far away
		for _, Instance in part:GetDescendants() do
			if Instance:IsA("Trail") or Instance:IsA("ParticleEmitter") then
				Instance.Enabled = false
			end
		end
		part:SetAttribute("Modified", nil)
	end
end

function PartCacheStatic:Expand(numParts: number)
	numParts = numParts or self.ExpansionSize
	
	for i = 1, numParts do
		local BasePart = MakeFromTemplate(self.Template, self.CacheParent)
		BasePart.CanCollide = false
		BasePart.CanQuery = false
		BasePart.CanTouch = false
		table.insert(self.Open, BasePart)
	end
end

function PartCacheStatic:Dispose()
	for _, Part in self.Open do
		Part:Destroy()
	end
	for _, Part in self.InUse do
		Part:Destroy()
	end
	_PCS[self.__OriginalTemplate] = nil
	self.Template:Destroy()
	self.Open = {}
	self.InUse = {}
	self.CacheParent = nil
end

return PartCacheStatic