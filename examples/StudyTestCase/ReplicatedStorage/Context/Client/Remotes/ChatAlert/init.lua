--[[
	ej0w @ October 2024
	ChatAlert
	
	Sends a notification in chat depending on parameters
]]

--> Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local StarterGui = game:GetService("StarterGui")

--> References
local LegacyChatVersion = TextChatService.ChatVersion == Enum.ChatVersion.LegacyChatService

local TextChannels, RBXGeneral
if not LegacyChatVersion then
	TextChannels = TextChatService:WaitForChild("TextChannels")
	RBXGeneral = TextChannels:WaitForChild("RBXGeneral") :: TextChannel
end

--> Dependencies
local RichText = require(script.RichText)

--> Variables
local Remotes = {}

--------------------------------------------------------------------------------

-- Modify this function in order to change remote callback
function Remotes:OnEvent(Color, Text)
	if LegacyChatVersion then
		local Font = Enum.Font.SourceSansBold
		local FontSize = Enum.FontSize.Size18
		StarterGui:SetCore("ChatMakeSystemMessage", {Text = Text, Color = Color, Font = Font, FontSize = FontSize})
	elseif not LegacyChatVersion then
		local ModifiedText = string.format("<font color='%s'>%s</font>", RichText.toHex(Color), RichText.stringEscapeRichText(Text))
		RBXGeneral:DisplaySystemMessage(ModifiedText)
	end
end

return Remotes