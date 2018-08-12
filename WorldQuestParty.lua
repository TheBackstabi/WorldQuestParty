local DEBUG = false 
local AddonMessageChannel = "WQPartyFinder"
local _L = {}
WQPFrame = CreateFrame("Frame", "WorldQuestPartyFrame", UIParent)
local activeWQ = nil
local recentWQ = {}
local WQchannel = nil
local channelNum = nil
local parties = {}
local isRegistered = false
local joinButtonTimer = nil
local isAwaitingInvite = false

function WQPFrame.DebugPrint(msg)
	if (DEBUG) then
		print(msg)
	end
end

local RegEvents = {}
WQPFrame:SetScript("OnEvent", function(self, event, ...)
	if (RegEvents[event]) then
		return RegEvents[event](self, event, ...)
	end
end)
	
function RegEvents:PLAYER_LOGIN(event)
	_L = WQPLocale.BuildLocaleTable(GetLocale())
	StaticPopupDialogs["WQP_LEAVEPARTY"] = {
		text = _L["PROMPT"],
		button1 = _L["YES"],
		button2 = _L["NO"],
		OnAccept = function()
			LeaveParty()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = false,
		preferredIndex = 11,
	}
	WQPFrame.CreateSubFrames(_L)
	WQPFrame.HookEvents()
end

local function CancelTimer(timer)
	timer.Countdown:Cancel()
	timer:Cancel()
end

local function GetUnitGroupIndex(name)
	local index = name:find("-")
	if index and index > 0 then
		name = string.sub(name, 1, index-1)
		for i=1,4 do
			if UnitName("party"..i) == name then
				return "party"..i
			end
		end
		for i=1,40 do
			if UnitName("raid"..i) == name then
				return "raid"..i
			end
		end
	end
	return false
end

function RegEvents:CHAT_MSG_ADDON(self, prefix, msg, channel, sender, senderNoRealm)
	WQPFrame.DebugPrint(string.format("Message received from %s on %s - \"%s\"", sender, channel, msg))
	if DEBUG or not string.find(sender, UnitName("player")) then
		if msg == ">" and isRegistered then
			WQPFrame.DebugPrint(string.format("%s entered the WQ, sending party info...", sender))
			C_ChatInfo.SendAddonMessage(AddonMessageChannel, "<", "WHISPER", sender)
		elseif msg == "<" then
			WQPFrame.DebugPrint(string.format("Received group info from %s", sender))
			if not isRegistered and not UnitInParty("player") then
				parties[sender] = false
				if (joinButtonTimer) then
					CancelTimer(joinButtonTimer)
				end
				CreateJoinButton()
			else
				local index = GetUnitGroupIndex(senderNoRealm)
				if index and UnitIsGroupLeader(index) then
					WQPFrame.DebugPrint("Your party was listed by the party leader")
					WQPFrame.JoinFrame.ListButton:SetText(_L["LISTED"]) --"Party Listed..."
				end
			end
		elseif msg == "!" and isRegistered then
			InviteUnit(sender)
			WQPFrame.DebugPrint(string.format("%s requested an invite, sending...", sender))
		elseif msg == "?" then
			if not isRegistered and not UnitInParty("player") then
				WQPFrame.DebugPrint("Removing "..sender.."'s party from table")
				parties[sender] = nil
			else
				local index = GetUnitGroupIndex(senderNoRealm)
				if index and UnitIsGroupLeader(index) then
					WQPFrame.DebugPrint("Your party was delisted by the party leader")
					WQPFrame.JoinFrame.ListButton:SetText(_L["UNLISTED"]) --"Party Not Listed..."
					isRegistered = false
				end
			end
		elseif msg == "@" and UnitIsGroupLeader("player") then
			WQPFrame.DebugPrint(sender.." in party requested list status")
			if isRegistered then
				C_ChatInfo.SendAddonMessage(AddonMessageChannel, "<", "PARTY")
			else
				C_ChatInfo.SendAddonMessage(AddonMessageChannel, "?", "PARTY")
			end
		end
	end
end

function RegEvents:CHAT_MSG_WHISPER(event, msg, sender)
	local msg = string.lower(msg)
	if isRegistered and (msg:find("wq") > 0 or msg:find("inv") > 0 or msg == "\"wq\"") then
		WQPFrame.DebugPrint("Inviting "..sender)
		InviteUnit(sender)
	end
end

function RegEvents:CHAT_MSG_CHANNEL_JOIN(_, player, _, channel)
	if (string.lower(channel):match("wqp") and isRegistered) then
		C_ChatInfo.SendAddonMessage(AddonMessageChannel, "<", "WHISPER", player)
	end
end

function RegEvents:GROUP_ROSTER_UPDATE(self)
	if activeWQ and UnitInParty("player") then
		if UnitIsGroupLeader("player") then
			WQPFrame.SetAsParty(true)
			local maxPartySize = 5
			if (IsInRaid("player")) then
				maxPartySize = 40
			end
			if (GetNumGroupMembers() == maxPartySize) then
				C_ChatInfo.SendAddonMessage(AddonMessageChannel, "?", "CHANNEL", channelNum)
				WQPFrame.JoinFrame.ListButton:SetText(_L["FULL"])
				WQPFrame.JoinFrame.ListButton:Disable()
				isRegistered = false
			else
				C_ChatInfo.SendAddonMessage(AddonMessageChannel, "<", "CHANNEL", channelNum)
				WQPFrame.JoinFrame.ListButton:SetText(_L["DELIST"])
				WQPFrame.JoinFrame.ListButton:Enable()
				isRegistered = true
			end
		else
			isRegistered = false
			C_ChatInfo.SendAddonMessage(AddonMessageChannel, "@", "PARTY")
			WQPFrame.SetAsParty(false)
		end
	elseif activeWQ and not isRegistered then
		WQPFrame.SetAsIndividual()
	end
end

function RegEvents:QUEST_TURNED_IN(event, questID, experience, money)
	if activeWQ and questID == activeWQ then
		if UnitInParty("player") or UnitIsGroupLeader("player") then
			local questLink = GetQuestLink(activeWQ)
			SendChatMessage(string.format(_L["COMPLETE"], questLink), "PARTY")
			StaticPopup_Show("WQP_LEAVEPARTY")
		end
		WQPFrame.ExitWQ()
	end
end

function RegEvents:PARTY_INVITE_REQUEST()
	if isAwaitingInvite then
		WQPFrame.DebugPrint("Auto-accepting invite")
		AcceptGroup()
		isAwaitingInvite = false
		WQPFrame.JoinFrame.ListButton:SetText(_L["WAITING"])
		ButtonThrottle(WQPFrame.JoinFrame.ListButton, 3, function(self)
			C_ChatInfo.SendAddonMessage(AddonMessageChannel, "@", "PARTY")
		end, true)
	end
end

local function CheckIfCurrentLocIsWQ()
	local uiMapId = C_Map.GetBestMapForUnit("player")
	if uiMapId then
		local WQs = C_TaskQuest.GetQuestsForPlayerByMapID(uiMapId)
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
	WQPFrame.ExitWQ()
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
	local text = button:GetText()
	button:Disable()
	local timer = C_Timer.NewTimer(duration, function()
		if not dontEnable then
			button:Enable()
		end
		if callback then callback() end
	end)
	timer.Countdown = TimerCountdown(button, text, duration)
	return timer
end

local function IsRecentWQ(questID)
	for i=1,#recentWQ do
		if recentWQ[i] == questID then
			return true
		end
	end
	return false
end

local function CreateJoinButton()
	local currentSize = 0
	for k, v in pairs(parties) do if not v then currentSize = currentSize+1 end end
	if (currentSize == 0) then
		WQPFrame.JoinFrame.JoinButton:SetText(_L["NO_PARTIES"])
		WQPFrame.JoinFrame.JoinButton:Disable()
	else
		CancelTimer(joinButtonTimer)
		WQPFrame.JoinFrame.JoinButton:Enable()
		WQPFrame.JoinFrame.JoinButton:SetText(_L["JOIN"].." ("..currentSize..")")
	end
	WQPFrame.JoinFrame.JoinButton:SetNormalFontObject("GameFontNormal")
	WQPFrame.JoinFrame.JoinButton:Show()
end

function WQPFrame.HookEvents()
	C_ChatInfo.RegisterAddonMessagePrefix("WQPartyFinder")
	hooksecurefunc("ObjectiveTracker_Update", function(reason, questID)
		if (UnitIsDeadOrGhost("player") == false and isRegistered == false and activeWQ ~= questID and reason == OBJECTIVE_TRACKER_UPDATE_WORLD_QUEST_ADDED) then
			if (activeWQ) then
				WQPFrame.ExitWQ()
			end
			WQPFrame.DebugPrint(string.format("Entering WQ zone for %s", questID))
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
		WQPFrame.DebugPrint("Join button clicked")
		for sender, hasRequested in pairs(parties) do
			if not hasRequested then
				parties[sender] = true
				WQPFrame.DebugPrint(string.format("Requesting invite from %s", sender))
				isAwaitingInvite = true
				C_ChatInfo.SendAddonMessage(AddonMessageChannel, "!", "WHISPER", sender)
				self:SetText(_L["JOINING"])
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
		-- TODO: Config for enabling this
		--WQPFrame.JoinFrame.CalloutButton:Click()
	end)
	
	WQPFrame.HeaderFrame.CloseButton:SetScript("OnClick", function(self)
		WQPFrame.DebugPrint("Close button clicked")
		WQPFrame.ExitWQ()
	end)
	
	WQPFrame.JoinFrame.ListButton:SetScript("OnClick", function(self)
		if isRegistered then
			WQPFrame.DebugPrint("Removing group from listing")
			isRegistered = false
			C_ChatInfo.SendAddonMessage(AddonMessageChannel, "?", "CHANNEL", channelNum)
			self:SetText(_L["ENLIST"])
			ButtonThrottle(self, 3, function()
				self:SetText(_L["ENLIST"])
			end)
			if not UnitInParty("player") then
				WQPFrame.SetAsIndividual()
				ButtonThrottle(WQPFrame.JoinFrame.NewParty, 3, function()
					WQPFrame.JoinFrame.NewParty:SetText(_L["NEW"])
				end)
			end
		else
			WQPFrame.DebugPrint("Adding group to listing")
			isRegistered = true
			C_ChatInfo.SendAddonMessage(AddonMessageChannel, "<", "CHANNEL", channelNum)
			self:SetText(_L["DELIST"])
			ButtonThrottle(self, 3, function()
				self:SetText(_L["DELIST"])
			end)
		end
	end)
	
	WQPFrame.JoinFrame.CalloutButton:SetScript("OnClick", function(self)
		if isRegistered then
			local questName = C_TaskQuest.GetQuestInfoByQuestID(activeWQ)
			local questLink = GetQuestLink(activeWQ)
			local msg = string.format(_L["LFM"], questLink)
			local generalChannelNum = GetChannelName("General - "..GetZoneText())
			if not DEBUG then
				SendChatMessage(msg, "CHANNEL", nil, generalChannelNum)
			else
				SendChatMessage(msg, "WHISPER", nil, UnitName("player"))
				SendChatMessage("wq", "WHISPER", nil, UnitName("player"))
			end
			ButtonThrottle(WQPFrame.JoinFrame.CalloutButton, 30, function()
				WQPFrame.JoinFrame.CalloutButton:SetText(_L["POST"])
			end)
		end
	end)
	
	WQPFrame.HeaderFrame.MinimizeButton:SetScript("OnClick", function(self)
		WQPFrame.DebugPrint("Minimize Button clicked")
		if (WQPFrame.JoinFrame:IsShown()) then
			WQPFrame.JoinFrame:Hide()
		else
			WQPFrame.JoinFrame:Show()
		end
	end)
	
	WQPFrame.JoinFrame.LeaveButton:SetScript("OnClick", function(self)
		WQPFrame.DebugPrint("Leaving the party")
		LeaveParty()
		WQPFrame.SetAsIndividual()
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
		WQPFrame.JoinFrame.ListButton:SetText(_L["WAITING"])
	end
end

function WQPFrame.SetAsIndividual()
	isRegistered = false
	WQPFrame.JoinFrame.JoinButton:Show()
	WQPFrame.JoinFrame.ListButton:Hide()
	WQPFrame.JoinFrame.NewParty:Show()
	WQPFrame.JoinFrame.CalloutButton:Hide()
	WQPFrame.JoinFrame.LeaveButton:Hide()
	
	C_ChatInfo.SendAddonMessage(AddonMessageChannel, ">", "CHANNEL", channelNum)
	WQPFrame.JoinFrame.JoinButton:SetText(_L["SEARCHING"])
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

function WQPFrame.EnterWQ(questID)
	if not IsRecentWQ(questID) then
		WQPFrame:Show()
		activeWQ = questID
		local WQname = C_TaskQuest.GetQuestInfoByQuestID(activeWQ)
		if (string.len(WQname) > 25) then
			WQPFrame.HeaderFrame.Text:SetText(string.sub(WQname, 1, 25).."...")
		else
			WQPFrame.HeaderFrame.Text:SetText(WQname)
		end
		WQPFrame.DebugPrint(string.format("Joining channel for %s", questID))
		GetChannelNumber(WQchannel)
		if UnitIsGroupLeader("player") then
			WQPFrame.DebugPrint("Registering as a party leader")
			WQPFrame.SetAsParty(true)
			WQPFrame:Show()
		elseif DEBUG or UnitInParty("player") then
			WQPFrame.DebugPrint("Registering as a party member")
			WQPFrame.SetAsParty(false)
			WQPFrame:Show()
		else
			WQPFrame.DebugPrint("Registering as an individual")
			WQPFrame.SetAsIndividual()
		end
	end
end

local function ResetButtons()
	WQPFrame.SetAsIndividual()
	WQPFrame.JoinFrame.ListButton:SetText(_L["ENLIST"])
	if (joinButtonTimer) then
		CancelTimer(joinButtonTimer)
	end
end

function WQPFrame.ExitWQ()
	if (activeWQ ~= nil) then
		WQPFrame.DebugPrint(string.format("Exiting WQ %s", activeWQ))
		C_ChatInfo.SendAddonMessage(AddonMessageChannel, "?", "CHANNEL", channelNum)
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

SLASH_WQP1 = "/wq"
SLASH_WQP2 = "/wqp"
SLASH_WQP3 = "/wqpf"
SlashCmdList["WQP"] = function(msg)
	msg = string.lower(msg)
	if (msg == "leave" or msg == "exit" or msg == "e") then
		WQPFrame.ExitWQ()
	elseif (msg == "flush" or msg == "f" or msg == "r" or msg == "reset") then
		WQPFrame.ExitWQ()
		recentWQ = {}
		CheckIfCurrentLocIsWQ()
		print(_L["RESET"])
	--elseif (msg == "debug") then
	--	DEBUG = true
	else
		print(_L["SLASH"])
	end
end 