--[[
	ej0w @ May 2024
	Board
	
	Handles serverside for leaderboards
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local DatastoreService = game:GetService("DataStoreService")
local UserService = game:GetService("UserService")
local CollectionService = game:GetService("CollectionService")

--> References
local FormatNumber = require(ReplicatedStorage.Modules.Shared.FormatNumber)

local GameConfig = require(ReplicatedStorage.GameConfig)

--> Init
local Leaderboards = {}
local TotalLeaderboards = {}

local Leaderboard = {}
Leaderboard.__index = Leaderboard

export type Leaderboard = {
	Datastore: OrderedDataStore,
	Boards: {any: any},
}

--------------------------------------------------------------------------------

function Leaderboard.getLeaderboards()
	return TotalLeaderboards
end

function Leaderboard.new(Board: Model, AttributeName: string): Leaderboard
	local self = setmetatable({}, Leaderboard)
	self.Datastore = DatastoreService:GetOrderedDataStore(`Statistics.{AttributeName}`)
	self.Boards = {Board}

	TotalLeaderboards[AttributeName] = self
	return self
end

function Leaderboard:GetData(Count)
	local Datastore: OrderedDataStore = self.Datastore
	local Pages = Datastore:GetSortedAsync(false, Count)
	return Pages:GetCurrentPage()
end

function Leaderboard:SetData(Userid: number, Value: number)
	local Datastore: OrderedDataStore = self.Datastore
	Datastore:SetAsync(Userid, math.floor(Value))
end

--------------------------------------------------------------------------------

local function Encode(Value)
	return Value ~= 0 and math.floor(math.log(Value) / math.log(1.0000001)) or 0
end

local function Decode(Value)
	return Value ~= 0 and (1.0000001^Value) or 0
end

local function BoardConnection(Board)
	local Config = Board:WaitForChild("BoardConfig")
	Config = Config and require(Config)
	
	local StatName: string = Config.StatName
	local TotalLeaderboards = Leaderboard.getLeaderboards()

	local FoundBoard = TotalLeaderboards[StatName]
	if FoundBoard then
		table.insert(FoundBoard.Boards, Board)
	end

	if StatName and (not FoundBoard) then
		Leaderboard.new(Board, StatName)
	end
end

local function CollectionAdded(Tag: string, Callback:(...any) -> ())
	CollectionService:GetInstanceAddedSignal(Tag):Connect(Callback)

	for _, Tagged: any in CollectionService:GetTagged(Tag) do
		Callback(Tagged)
	end
end

return function()
	CollectionAdded("Leaderboard", function(Tagged: any)
		BoardConnection(Tagged)
	end)
	
	task.defer(function()
		while true do
			local TotalLeaderboards = Leaderboard.getLeaderboards()

			for _, Leaderboard: Leaderboard in TotalLeaderboards do
				local Boards = Leaderboard.Boards

				--> Set player lb data
				for _, Player in Players:GetPlayers() do
					task.spawn(function()
						local Board = Boards[1]
						local Data = ReplicatedStorage.PlayerData:WaitForChild(Player.UserId, 1)
						if not Data then
							return
						end

						local Config = Board:WaitForChild("BoardConfig")
						Config = Config and require(Config)

						local Value = Data[Config.StatPath][Config.StatName].Value
						Leaderboard:SetData(Player.UserId, Encode(Value))
					end)
				end

				--> Load leaderboard data
				local Data = Leaderboard:GetData(50)

				--> Update boards
				for _, Board in Boards do
					local List: Part = Board.List
					local Surface: SurfaceGui = List.Surface

					local Scroller: ScrollingFrame = Surface.Scroller
					local Template: ImageLabel = Scroller.Template
					
					local Config = Board:WaitForChild("BoardConfig")
					Config = Config and require(Config)
					
					Board.Stat.Surface.Panel.Text = `Highest {Config.StatName}`

					for _, Template in Scroller:GetChildren() do
						if Template:IsA("Frame") and (Template.Name ~= "Template") then
							Template:Destroy()
						end
					end

					for Position, Key in Data do
						task.defer(function()
							local UserName = nil :: string
							local Success = nil :: boolean
							local Return = nil :: any
							
							repeat
								Success, Return = pcall(function()
									UserName = Players:GetNameFromUserIdAsync(tonumber(Key.key))
								end)
								if not Success then
									task.wait(1)
								end
							until UserName and Success
							
							local Value = Decode(Key.value)
							if UserName and (Value > 0) then
								local Display: ImageLabel = Template:Clone()
								Display.Parent = Scroller
								Display.Name = UserName
								Display.LayoutOrder = Position
								Display.Visible = true

								local Amount: Frame = Display.Amount
								local Panel: TextLabel = Amount.Panel
								local Rank: TextLabel = Amount.Rank

								Rank.Text = `#{Position}. <b>{UserName}</b>`
								Panel.Text = `{Config.StatName}: {FormatNumber(math.round(Value), "Suffix")}`
								Panel.TextColor3 = GameConfig.PrimaryColor
							end
						end)
					end
				end
			end

			task.wait(GameConfig.LeaderboardRefresh)
		end
	end)
end
