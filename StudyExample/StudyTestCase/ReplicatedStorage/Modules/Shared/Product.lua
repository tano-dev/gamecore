--[[
	ej0w @ May 2024
	Product
	
	In charge of handling products, such as badges, gamepasses, and etc.
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local BadgeService = game:GetService("BadgeService")
local MarketplaceService = game:GetService("MarketplaceService")

--> Dependencies
local AttributeModule = require(ReplicatedStorage.Modules.Shared.Attribute)

local GameConfig = require(ReplicatedStorage.GameConfig)

--> Variables
local ProductLib = {}

--------------------------------------------------------------------------------

local function WrapReturned(Function, Domain, UserID, ProductID)
	local Given = false
	
	local Success = nil :: boolean
	local Returns = nil :: any

	repeat
		Success, Returns = pcall(function()
			Given = Function(Domain, UserID, ProductID)
		end)
		if not Success then
			task.wait(1)
			warn(Returns)
		end
	until Success

	return Given
end

function ProductLib:PlayerHasBadge(Player: Player, ProductID)
	local Owns = AttributeModule:GetAttribute(Player, tostring(ProductID))
	if Owns ~= nil then
		return Owns
	end

	Owns = WrapReturned(BadgeService.UserHasBadgeAsync, BadgeService, Player.UserId, ProductID)
	AttributeModule:SetAttribute(Player, tostring(ProductID), Owns)
	return Owns
end

function ProductLib:PlayerHasGamepass(Player: Player, ProductID)
	local Owns = AttributeModule:GetAttribute(Player, tostring(ProductID))
	if Owns ~= nil then
		return Owns
	end
	
	Owns = WrapReturned(MarketplaceService.UserOwnsGamePassAsync, MarketplaceService, Player.UserId, ProductID)
	AttributeModule:SetAttribute(Player, tostring(ProductID), Owns)
	return Owns
end

function ProductLib:PlayerHasPremium(Player: Player)
	return Player.MembershipType == Enum.MembershipType.Premium
end

function ProductLib:PlayerIsInGroup(Player: Player, ProductID)
	local Returns = nil
	
	local Success = pcall(function()
		Returns = Player:IsInGroup(ProductID)
	end)
	
	return Returns
end

function ProductLib:PlayerHasProduct(Player: Player, ProductID, ProductType)
	local Function = nil
	
	for Name, Found in ProductLib do
		if not string.match(Name, ProductType) then
			continue
		end

		Function = Found
	end
	
	return Function(nil, Player, ProductID)
end

function ProductLib:GetProducts(Player)
	local Products = {}
	
	for _, Product in GameConfig.Products do
		local Owned = ProductLib:PlayerHasProduct(Player, Product.AssetID, Product.Type)
		
		if Owned then
			table.insert(Products, Product)
		end
	end
	
	return Products
end

return ProductLib