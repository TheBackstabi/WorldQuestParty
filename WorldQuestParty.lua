local DEBUG = false 
	local DEBUG_AS_LEAD = false
	local DEBUG_AS_MEMBER = false

WQPFrame = CreateFrame("Frame", "WorldQuestPartyFrame", UIParent)
local activeWQ = nil
local recentWQ = {}
local WQchannel = nil
local channelNum = nil
local parties = {}
local isRegistered = false
local joinButtonTimer = nil
local isAwaitingInvite = false
StaticPopupDialogs["WQP_LEAVEPARTY"] = {
	text = "Leave party?",
	button1 = "Yes",
	button2 = "No",
	OnAccept = function()
		LeaveParty()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = false,
	preferredIndex = 11,
}

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

local function CancelTimer(timer)
	timer.Countdown:Cancel()
	timer:Cancel()
end

local function GetUnitGroupIndex(name)
	for i=1,4 do
		if (UnitName("party"..i) == name) then return "party"..i end
	end
	for i=1,40 do
		if (UnitName("raid"..i) == name) then return "raid"..i end
	end
	return false
end

function RegEvents:CHAT_MSG_ADDON(self, prefix, msg, _, sender, channel)
	DebugPrint(string.format("Message received from %s on %s - \"%s\"", sender, channel, msg))
	if DEBUG or string.find(sender, UnitName("player")) == nil then
		if msg == ">" and (isRegistered or DEBUG) then
			DebugPrint(string.format("%s entered the WQ, sending party info...", sender))
			C_ChatInfo.SendAddonMessage("WQPartyFinder", "<", "WHISPER", sender)
		elseif msg == "<" then
			DebugPrint(string.format("Received group info from %s", sender))
			if not isRegistered and not (UnitInParty("player") or DEBUG_AS_MEMBER) then
				parties[sender] = false
				if (joinButtonTimer) then
					CancelTimer(joinButtonTimer)
				end
				CreateJoinButton()
			else
				index = GetUnitGroupIndex(sender)
				if (index and UnitIsGroupLeader(index)) or DEBUG_AS_MEMBER then
					DebugPrint("Your party was listed by the party leader")
					WQPFrame.JoinFrame.ListButton:SetText("Party Listed...")
					isRegistered = true
				end
			end
		elseif (msg == "!" and isRegistered) then
			InviteUnit(sender)
			DebugPrint(string.format("%s requested an invite, sending...", sender))
		elseif msg == "?" then
			if not isRegistered and (UnitInParty("player") == false or DEBUG_AS_MEMBER == true) and not DEBUG then
				DebugPrint("Removing "..sender.."'s party from table")
				parties[sender] = nil
			else
				index = GetUnitGroupIndex(sender)
				if (index and UnitIsGroupLeader(index)) or DEBUG_AS_MEMBER then
					DebugPrint("Your party was delisted by the party leader")
					WQPFrame.JoinFrame.ListButton:SetText("Party Not Listed...")
					isRegistered = false
				end
			end
		elseif msg == "@" then
			DebugPrint(sender.." in party requested list status")
			if isRegistered then
				C_ChatInfo.SendAddonMessage("WQPartyFinder", "<", "PARTY")
			else
				C_ChatInfo.SendAddonMessage("WQPartyFinder", "?", "PARTY")
			end
		end
	end
end

function RegEvents:CHAT_MSG_WHISPER(event, msg, sender)
	msg = string.lower(msg)
	if isRegistered and (msg:find("wq") > 0 or msg:find("inv") > 0 or msg == "\"wq\"" or msg:match("inv")) then
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
	if activeWQ and UnitInParty("player") then
		if (UnitIsGroupLeader("player") and not DEBUG_AS_MEMBER) then
			WQPFrame.SetAsParty(true)
			maxPartySize = 5
			if (IsInRaid("player")) then
				maxPartySize = 40
			end
			if (GetNumGroupMembers() == maxPartySize) then
				C_ChatInfo.SendAddonMessage("WQPartyFinder", "?", "CHANNEL", channelNum)
				--C_ChatInfo.SendAddonMessage("WQPartyFinder", "?", "PARTY")
			else
				C_ChatInfo.SendAddonMessage("WQPartyFinder", "<", "CHANNEL", channelNum)
				--C_ChatInfo.SendAddonMessage("WQPartyFinder", "<", "PARTY")
			end
		else
			WQPFrame.SetAsParty(false)
		end
	elseif activeWQ and not isRegistered then
		WQPFrame.SetAsIndividual()
	end
end

function RegEvents:QUEST_TURNED_IN(event, questID, experience, money)
	if activeWQ and questID == activeWQ then
		if UnitInParty("player") or UnitIsGroupLeader("player") then
			questLink = GetQuestLink(activeWQ)
			SendChatMessage("I’ve completed the "..questLink.." WQ. Thanks for your help! (World Quest Party)", "PARTY")
			StaticPopup_Show("WQP_LEAVEPARTY")
		end
		WQPFrame.ExitWQ()
	end
end

function RegEvents:PARTY_INVITE_REQUEST()
	if isAwaitingInvite then
		DebugPrint("Auto-accepting invite")
		AcceptGroup()
		isAwaitingInvite = false
	end
end

local function CheckIfCurrentLocIsWQ()
	uiMapId = C_Map.GetBestMapForUnit("player")
	if uiMapId then
		WQs = C_TaskQuest.GetQuestsForPlayerByMapID(uiMapId)
		for k in pairs(WQs) do
			if (C_QuestLog.IsOnQuest(WQs[k]["questId"])) then
				WQchannel = "WQP"..WQs[k]["questId"]
				if C_PvP.IsWarModeActive() then
					WQchannel = WQchannel.."PVP"
				end
				JoinChannelByName(WQchannel)
				C_Timer.NewTimer(1, function()
					WQPFrame.EnterWQ(WQs[k]["questId"])
				end)
			end
		end
	end
end

function RegEvents:PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)
	CheckIfCurrentLocIsWQ()
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
		if (UnitIsDeadOrGhost("player") == false and isRegistered == false and activeWQ ~= questID and reason == OBJECTIVE_TRACKER_UPDATE_WORLD_QUEST_ADDED) then
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
	local function FilterByChannelName(_, _, _, _, _, channel)
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
				isAwaitingInvite = true
				C_ChatInfo.SendAddonMessage("WQPartyFinder", "!", "WHISPER", sender)
				self:SetText("Requesting Invite...")
				joinButtonTimer = ButtonThrottle(self, 3, function()
					if not UnitInParty("player") then
						CreateJoinButton()
					end
				end, true)
				break
			end
		end
	end)

	WQPFrame.JoinFrame.NewParty:SetScript("OnClick", function(self)
		if joinButtonTimer then CancelTimer(joinButtonTimer) end
		WQPFrame.SetAsParty(true)
		WQPFrame.JoinFrame.ListButton:Click()
		WQPFrame.JoinFrame.CalloutButton:Click()
	end)
	
	WQPFrame.HeaderFrame.CloseButton:SetScript("OnClick", function(self)
		DebugPrint("Close button clicked")
		WQPFrame.ExitWQ()
	end)
	
	WQPFrame.JoinFrame.ListButton:SetScript("OnClick", function(self)
		if isRegistered then
			DebugPrint("Removing group from listing")
			C_ChatInfo.SendAddonMessage("WQPartyFinder", "?", "CHANNEL", channelNum)
			self:SetText("Enlist Party")
			ButtonThrottle(self, 3, function()
				self:SetText("Enlist Party")
			end)
			isRegistered = false
			if not UnitInParty("player") then
				WQPFrame.SetAsIndividual()
				ButtonThrottle(WQPFrame.JoinFrame.NewParty, 3, function()
					WQPFrame.JoinFrame.NewParty:SetText("Create Party")
				end)
			end
		else
			RegisterGroup(self)
			self:SetText("Delist Party")
			ButtonThrottle(self, 3, function()
				self:SetText("Delist Party")
			end)
		end
	end)
	
	WQPFrame.JoinFrame.CalloutButton:SetScript("OnClick", function(self)
		if isRegistered then
			questName = C_TaskQuest.GetQuestInfoByQuestID(activeWQ)
			questLink = GetQuestLink(activeWQ)
			msg = "LFM "..questLink.." WQ - whisper me \"wq\" for an invite! (World Quest Party)"
			generalChannelNum = GetChannelName("General - "..GetZoneText())
			if not DEBUG then
				SendChatMessage(msg, "CHANNEL", nil, generalChannelNum)
			else
				SendChatMessage(msg, "WHISPER", nil, UnitName("player"))
				SendChatMessage("wq", "WHISPER", nil, UnitName("player"))
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
	
	WQPFrame.JoinFrame.LeaveButton:SetScript("OnClick", function(self)
		DebugPrint("Leaving the party")
		LeaveParty()
		WQPFrame.SetAsIndividual()
		C_ChatInfo.SendAddonMessage("WQPartyFinder", ">", "CHANNEL", channelNum)
		WQPFrame.JoinFrame.JoinButton:SetText("Searching...")
		WQPFrame.JoinFrame.JoinButton:SetNormalFontObject("GameFontNormal")
		joinButtonTimer = ButtonThrottle(WQPFrame.JoinFrame.JoinButton, 3, function(self)
			CreateJoinButton()
		end)
	end)
	
	SetupRecentWQFlush()
end

function WQPFrame.SetAsParty(isLeader)
	if (joinButtonTimer) then
		CancelTimer(joinButtonTimer)
	end
	WQPFrame.JoinFrame.JoinButton:Hide()
	WQPFrame.JoinFrame.ListButton:Show()
	WQPFrame.JoinFrame.NewParty:Hide()
	if isLeader then
		WQPFrame.JoinFrame.CalloutButton:Show()
		WQPFrame.JoinFrame.LeaveButton:Hide()
		WQPFrame.JoinFrame.ListButton:Enable()
	else
		WQPFrame.JoinFrame.CalloutButton:Hide()
		WQPFrame.JoinFrame.LeaveButton:Show()
		WQPFrame.JoinFrame.ListButton:Disable()
		WQPFrame.JoinFrame.ListButton:SetText("Waiting...")
		ButtonThrottle(WQPFrame.JoinFrame.ListButton, 1, function(self)
			C_ChatInfo.SendAddonMessage("WQPartyFinder", "@", "PARTY")
		end, true)
	end
end

function WQPFrame.SetAsIndividual()
	isRegistered = false
	WQPFrame.JoinFrame.JoinButton:Show()
	WQPFrame.JoinFrame.ListButton:Hide()
	WQPFrame.JoinFrame.NewParty:Show()
	WQPFrame.JoinFrame.CalloutButton:Hide()
	WQPFrame.JoinFrame.LeaveButton:Hide()
	
	C_ChatInfo.SendAddonMessage("WQPartyFinder", ">", "CHANNEL", channelNum)
	WQPFrame.JoinFrame.JoinButton:SetText("Searching...")
	WQPFrame.JoinFrame.JoinButton:SetNormalFontObject("GameFontNormal")
	if joinButtonTimer then
		CancelTimer(joinButtonTimer)
	end
	joinButtonTimer = ButtonThrottle(WQPFrame.JoinFrame.JoinButton, 3, function(self)
		CreateJoinButton()
	end)
end

local function GetChannelNumber(channelName)
	channelNum = GetChannelName(channelName)
end

local function BuildPartyMemberTest(isListed)
	if isListed == nil then
		isListed = false
	end
	if not isListed then
		C_ChatInfo.SendAddonMessage("WQPartyFinder", "<", "WHISPER", UnitName("player"))
		isListed = true
	else
		C_ChatInfo.SendAddonMessage("WQPartyFinder", "?", "WHISPER", UnitName("player"))
		isListed = false
	end
	joinButtonTimer = C_Timer.NewTimer(3, function()
		BuildPartyMemberTest(isListed)
	end)
end

function WQPFrame.EnterWQ(questID)
	if not IsRecentWQ(questID) then
		WQPFrame:Show()
		activeWQ = questID
		WQname = C_TaskQuest.GetQuestInfoByQuestID(activeWQ)
		if (string.len(WQname) > 25) then
			WQPFrame.HeaderFrame.Text:SetText(string.sub(WQname, 1, 25).."...")
		else
			WQPFrame.HeaderFrame.Text:SetText(WQname)
		end
		DebugPrint(string.format("Joining channel for %s", questID))
		GetChannelNumber(WQchannel)
		if not UnitIsGroupLeader("player") and not UnitInParty("player") and not DEBUG_AS_LEAD and not DEBUG_AS_MEMBER then
			DebugPrint("Registering as an individual")
			WQPFrame.SetAsIndividual()
		elseif UnitIsGroupLeader("player") or DEBUG_AS_LEAD then
			DebugPrint("Registering as a party leader")
			WQPFrame.SetAsParty(true)
			WQPFrame:Show()
		elseif UnitInParty("player") or DEBUG_AS_MEMBER then
			DebugPrint("Registering as a party member")
			WQPFrame.SetAsParty(false)
			WQPFrame:Show()
			BuildPartyMemberTest()
		end
	end
end

local function ResetButtons()
	WQPFrame.SetAsIndividual()
	WQPFrame.JoinFrame.ListButton:SetText("Enlist Party")
	if (joinButtonTimer) then
		CancelTimer(joinButtonTimer)
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
		if joinButtonTimer then
			CancelTimer(joinButtonTimer)
		end
		ResetButtons()
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
		WQPFrame.JoinFrame.JoinButton:SetText("No Parties Found")
		WQPFrame.JoinFrame.JoinButton:Disable()
	elseif (currentSize == 1) then
		CancelTimer(joinButtonTimer)
		WQPFrame.JoinFrame.JoinButton:Enable()
		WQPFrame.JoinFrame.JoinButton:SetText("Join Party ("..currentSize..")")
	else
		CancelTimer(joinButtonTimer)
		WQPFrame.JoinFrame.JoinButton:Enable()
		WQPFrame.JoinFrame.JoinButton:SetText("Join Party ("..currentSize..")")
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
	elseif (msg == "flush" or msg == "f" or msg == "r" or msg == "reset") then
		recentWQ = {}
		CheckIfCurrentLocIsWQ()
		print("WQP: All set, addon has been reset!")
	elseif (msg == "debug") then
		DEBUG = true
	else
		print("WQP Commands:\nreset - clear and reset addon data.")
	end
end 