local DEBUG = false
	local DEBUG_AS_LEAD = false

WQPFrame = CreateFrame("Frame", "WorldQuestPartyFrame", UIParent)
local activeWQ = nil
local recentWQ = {}
local WQchannel = nil
local channelNum = nil
local parties = {}
local isRegistered = false
local joinButtonTimer = nil
local RegEvents = {}
WQPFrame:SetScript("OnEvent", function(self, event, ...)
		if (RegEvents[event]) then
			return RegEvents[event](self, event, ...)
		end
	end)
	
function RegEvents:PLAYER_LOGIN(event)
	WQPFrame.CreateSubFrames()
	WQPFrame.HookEvents()
end

function RegEvents:CHAT_MSG_ADDON(self, prefix, msg, _, sender, channel)
	DebugPrint(string.format("Message recieved from %s on %s - \"%s\"", sender, channel, msg))
	if DEBUG or string.find(sender, UnitName("player")) == nil then
		if msg == ">" and (isRegistered or DEBUG) then
			DebugPrint(string.format("%s entered the WQ, sending party info...", sender))
			C_ChatInfo.SendAddonMessage("WQPartyFinder", "<", "WHISPER", sender)
		elseif (msg == "<" and not isRegistered) then
			DebugPrint(string.format("Recieved group info from %s", sender))
			parties[sender] = false
			CreateJoinButton()
		elseif (msg == "!" and isRegistered) then
			InviteUnit(sender)
			DebugPrint(string.format("%s requested an invite, sending...", sender))
		elseif msg == "?" and not isRegistered and not UnitInParty("player") and not DEBUG then
			if parties[sender] then
				parties[sender] = nil
			end
		end
	end
end

function RegEvents:CHAT_MSG_WHISPER(event, msg, sender)
	DebugPrint("Whisper recieved")
	if isRegistered and (msg == "!" or msg == "\"!\"") then
		DebugPrint("Inviting "..sender)
		InviteUnit(sender)
	end
end

function RegEvents:CHAT_MSG_CHANNEL_JOIN(_, player, _, channel)
	if (string.lower(channel):match("wqp") and isRegistered) then
		C_ChatInfo.SendAddonMessage("WQPartyFinder", "<", "WHISPER", player)
	end
end

function RegEvents:GROUP_ROSTER_UPDATE(self)
	if (activeWQ) then
		if (UnitIsGroupLeader("player")) then
			maxPartySize = 5
			if (IsInRaid("player")) then
				maxPartySize = 40
			end
			if (GetNumGroupMembers() == maxPartySize) then
				C_ChatInfo.SendAddonMessage("WQPartyFinder", "?", "CHANNEL", channelNum)
			else
				C_ChatInfo.SendAddonMessage("WQPartyFinder", "<", "CHANNEL", channelNum)
			end
		else
			WQPFrame:Hide()
		end
	end
end

for k, v in pairs(RegEvents) do
	WQPFrame:RegisterEvent(k)
end

local function SetupRecentWQFlush()
	C_Timer.NewTimer(300, function()
		recentWQ = {}
		SetupRecentWQFlush()
	end)
end

local function TimerCountdown(button, text, timeRemaining)
	button:SetText(text.." ("..timeRemaining.."s)")
	button:SetNormalFontObject("GameFontNormal")
	return C_Timer.NewTimer(1, function()
		timeRemaining = timeRemaining - 1
		if timeRemaining > 0 then
			TimerCountdown(button, text, timeRemaining)
		end
	end)
end

local function ButtonThrottle(button, duration, callback, dontEnable)
	text = button:GetText()
	button:Disable()
	timer = C_Timer.NewTimer(duration, function()
		if not dontEnable then
			button:Enable()
		end
		if callback then callback() end
	end)
	timer.Countdown = TimerCountdown(button, text, duration)
	return timer
end

local function CancelTimer(timer)
	timer.Countdown:Cancel()
	timer:Cancel()
end

local function RegisterGroup(self)
	DebugPrint("Registering party for "..activeWQ)
	C_ChatInfo.SendAddonMessage("WQPartyFinder", "<", "CHANNEL", channelNum)
	isRegistered = true
end

local function IsRecentWQ(questID)
	for i=1,#recentWQ do
		if recentWQ[i] == questID then
			return true
		end
	end
	return false
end

function WQPFrame.HookEvents()
	C_ChatInfo.RegisterAddonMessagePrefix("WQPartyFinder")
	hooksecurefunc("ObjectiveTracker_Update", function(reason, questID)
		if (activeWQ ~= questID and reason == OBJECTIVE_TRACKER_UPDATE_WORLD_QUEST_ADDED) then
			if (activeWQ) then
				WQPFrame.ExitWQ()
			end
			DebugPrint(string.format("Entering WQ zone for %s", questID))
			if not IsRecentWQ(questID) then
				WQchannel = "WQP"..questID
				if C_PvP.IsWarModeActive() then
					WQchannel = WQchannel.."PVP"
				end
				JoinChannelByName(WQchannel)
				C_Timer.NewTimer(1, function()
					WQPFrame.EnterWQ(questID)
				end)
			end
		end
	end)
	
	-- Remove addon chat channels from view
	local function FilterByChannelName(_, _, _, _, _, channel, _, _, test)
		return not string.find(string.lower(channel), ("wqp")) == nil
	end
	ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL", FilterByChannelName)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_NOTICE", FilterByChannelName)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_JOIN", FilterByChannelName)
	ChatFrame_AddMessageEventFilter("CHAT_MSG_CHANNEL_LEAVE", FilterByChannelName)
	
	WQPFrame.JoinFrame.JoinButton:SetScript("OnClick", function(self)
		DebugPrint("Join button clicked")
		for sender, hasRequested in pairs(parties) do
			if not hasRequested then
				parties[sender] = true
				DebugPrint(string.format("Requesting invite from %s", sender))
				C_ChatInfo.SendAddonMessage("WQPartyFinder", "!", "WHISPER", sender)
				self:SetText("Requesting invite...")
				joinButtonTimer = ButtonThrottle(self, 3, function()
					self:SetText("Join failed")
					C_Timer.NewTimer(2, function()
						if not UnitInParty("player") then
							CreateJoinButton()
						end
					end)
				end, true)
				
				break
			end
		end
	end)

	WQPFrame.JoinFrame.NewParty:SetScript("OnClick", function(self)
		WQPFrame.SetAsParty()
		WQPFrame.JoinFrame.ListButton:Click()
		if joinButtonTimer then CancelTimer(joinButtonTimer) end
	end)
	
	WQPFrame.HeaderFrame.CloseButton:SetScript("OnClick", function(self)
		DebugPrint("Close button clicked")
		WQPFrame.ExitWQ()
	end)
	
	WQPFrame.JoinFrame.ListButton:SetScript("OnClick", function(self)
		if isRegistered then
			DebugPrint("Removing group from listing")
			C_ChatInfo.SendAddonMessage("WQPartyFinder", "?", "CHANNEL", channelNum)
			self:SetText("List Group")
			ButtonThrottle(self, 3, function()
				self:SetText("List Group")
			end)
			isRegistered = false
			if not UnitInParty("player") then
				C_ChatInfo.SendAddonMessage("WQPartyFinder", ">", "CHANNEL", channelNum)
				WQPFrame.SetAsIndividual()
				WQPFrame.JoinFrame.JoinButton:SetText("Searching...")
				WQPFrame.JoinFrame.JoinButton:SetNormalFontObject("GameFontNormal")
				joinButtonTimer = ButtonThrottle(WQPFrame.JoinFrame.JoinButton, 3, function()
					CreateJoinButton()
				end)
			end
		else
			RegisterGroup(self)
			self:SetText("Unlist Group")
			ButtonThrottle(self, 3, function()
				self:SetText("Unlist Group")
			end)
		end
	end)
	
	WQPFrame.JoinFrame.CalloutButton:SetScript("OnClick", function(self)
		if isRegistered then
			questName = C_TaskQuest.GetQuestInfoByQuestID(activeWQ)
			msg = "WorldQuestParty - Whisper me \"!\" for invite to World Quest \""..questName.."\""
			if not DEBUG then
				SendChatMessage(msg, "CHANNEL", nil, 1)
			else
				DebugPrint("MSG: "..msg)
				SendChatMessage("!", "WHISPER", nil, UnitName("player"))
			end
			ButtonThrottle(WQPFrame.JoinFrame.CalloutButton, 30, function()
				WQPFrame.JoinFrame.CalloutButton:SetText("Post LFM")
			end)
		end
	end)
	
	WQPFrame.HeaderFrame.MinimizeButton:SetScript("OnClick", function(self)
		DebugPrint("Minimize Button clicked")
		if (WQPFrame.JoinFrame:IsShown()) then
			WQPFrame.JoinFrame:Hide()
		else
			WQPFrame.JoinFrame:Show()
		end
	end)
	
	SetupRecentWQFlush()
end

function WQPFrame.SetAsParty()
	WQPFrame.JoinFrame.JoinButton:Hide()
	WQPFrame.JoinFrame.ListButton:Show()
	WQPFrame.JoinFrame.NewParty:Hide()
	WQPFrame.JoinFrame.CalloutButton:Show()
end

function WQPFrame.SetAsIndividual()
	WQPFrame.JoinFrame.JoinButton:Show()
	WQPFrame.JoinFrame.ListButton:Hide()
	WQPFrame.JoinFrame.NewParty:Show()
	WQPFrame.JoinFrame.CalloutButton:Hide()
end

local function GetChannelNumber(channelName)
	channelNum = GetChannelName(channelName)
end

function WQPFrame.EnterWQ(questID)
	if not IsRecentWQ(questID) then
		WQPFrame:Show()
		activeWQ = questID
		WQPFrame.HeaderFrame.Text:SetText(string.sub(C_TaskQuest.GetQuestInfoByQuestID(activeWQ), 1, 30))
		if DEBUG then
			WQPFrame.HeaderFrame.Text:SetText(string.sub("THIS IS A SUPER LONG QUEST TITLE AAAAAAAAAAAAAAAAA", 1, 20).."...")
		end
		DebugPrint(string.format("Joining channel for %s", questID))
		GetChannelNumber(WQchannel)
		if not UnitIsGroupLeader("player") and not UnitInParty("player") and not DEBUG_AS_LEAD then
			DebugPrint("Registering as an individual")
			WQPFrame.SetAsIndividual()
			C_ChatInfo.SendAddonMessage("WQPartyFinder", ">", "CHANNEL", channelNum)
			WQPFrame.JoinFrame.JoinButton:SetText("Searching...")
			WQPFrame.JoinFrame.JoinButton:SetNormalFontObject("GameFontNormal")
			joinButtonTimer = ButtonThrottle(WQPFrame.JoinFrame.JoinButton, 3, function(self)
				CreateJoinButton()
			end)
		elseif UnitIsGroupLeader("player") or DEBUG_AS_LEAD then
			DebugPrint("Registering as a party")
			WQPFrame.SetAsParty()
			WQPFrame:Show()
		end
	end
end

function WQPFrame.ExitWQ()
	if (activeWQ ~= nil) then
		DebugPrint(string.format("Exiting WQ %s", activeWQ))
		C_ChatInfo.SendAddonMessage("WQPartyFinder", "?", "CHANNEL", channelNum)
		LeaveChannelByName(WQchannel)
		table.insert(recentWQ, activeWQ)
		activeWQ = nil
		WQchannel = nil
		channelNum = nil
		parties = {}
		isRegistered = false
		WQPFrame:Hide()
	end
end

function DebugPrint(msg)
	if (DEBUG) then
		print(msg)
	end
end

function CreateJoinButton()
	currentSize = 0
	for k, v in pairs(parties) do if not v then currentSize = currentSize+1 end end
	if (currentSize == 0) then
		WQPFrame.JoinFrame.JoinButton:SetText("No parties found yet")
		WQPFrame.JoinFrame.JoinButton:Disable()
	elseif (currentSize == 1) then
		CancelTimer(joinButtonTimer)
		WQPFrame.JoinFrame.JoinButton:Enable()
		WQPFrame.JoinFrame.JoinButton:SetText("Join\n"..currentSize.." party found")
	else
		CancelTimer(joinButtonTimer)
		WQPFrame.JoinFrame.JoinButton:Enable()
		WQPFrame.JoinFrame.JoinButton:SetText("Join\n"..currentSize.." parties found")
	end
	WQPFrame.JoinFrame.JoinButton:SetNormalFontObject("GameFontNormal")
	WQPFrame.JoinFrame.JoinButton:Show()
end

SLASH_WQP1 = "/wq"
SLASH_WQP2 = "/wqp"
SLASH_WQP3 = "/wqpf"
SlashCmdList["WQP"] = function(msg)
	msg = string.lower(msg)
	if (msg == "leave" or msg == "exit" or msg == "e") then
		WQPFrame.ExitWQ()
	elseif (msg == "flush" or msg == "f") then
		recentWQ = {}
		print("WQP: Flushed all recent world quests!")
	elseif (msg == "debug") then
		DEBUG = true
	end
end 