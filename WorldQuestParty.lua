WQPartyVars = {
	channel = 1,
	sendPartyMessage = true,
	customPartyMessage = "",
	automaticLFM = false,
	LFMchannel = 1,
	leavePartyPrompt = true
}
--WQPAce = LibStub("AceAddon-3.0"):NewAddon("WorldQuestParty", "AceConfig-3.0")
local DEBUG = false 
local AddonMessageChannel = "WQPartyFinder"
local _L = {}
WQPFrame = CreateFrame("Frame", "WorldQuestPartyFrame", UIParent)
local activeWQ = nil
local recentWQ = {}
local WQchannel = nil
local WQchannelNum = nil
local parties = {}
local isRegistered = false
local joinButtonTimer = nil
local isAwaitingInvite = false
local IgnoreWQ = { -- Ignored WQ IDs (Can probably lift this into a SavedVar once config is done...?)
	-- Supplies Needed (BFA)
	51024, 51038, 51027, 51041, 51032, 51048, 51040, 51026, 52378, 52385, 51037, 51023,
	51043, 51031, 51047, 51034, 51050, 52384, 52377, 51025, 51039, 51017, 51042, 52379,
	51036, 51022, 52376, 52383, 51028, 51044, 51045, 51029, 51030, 51046, 51051, 52380, 
	52375, 52382, 52388, 52381, 51049, 51033, 52387, 52386, 51021, 51035
}
local function IsQuestIgnored(questID)
	for i,v in ipairs(IgnoreWQ) do
		if (v == questID) then
			return true
		end
	end
	return false
end

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
	end
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

function RegEvents:CHAT_MSG_ADDON(self, prefix, msg, channel, sender)
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
				local index = GetUnitGroupIndex(sender)
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
				local index = GetUnitGroupIndex(sender)
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
	if isRegistered and (msg:find("wq") or msg:find("inv") or msg == "\"wq\"") then
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
		if UnitIsGroupLeader("player") and isRegistered then
			WQPFrame.SetAsParty(true)
			local maxPartySize = 5
			if (IsInRaid("player")) then
				maxPartySize = 40
			end
			if (GetNumGroupMembers() == maxPartySize) then
				C_ChatInfo.SendAddonMessage(AddonMessageChannel, "?", "CHANNEL", WQchannelNum)
				WQPFrame.JoinFrame.ListButton:SetText(_L["FULL"])
				WQPFrame.JoinFrame.ListButton:Disable()
				isRegistered = false
			else
				C_ChatInfo.SendAddonMessage(AddonMessageChannel, "<", "CHANNEL", WQchannelNum)
				WQPFrame.JoinFrame.ListButton:SetText(_L["DELIST"])
				WQPFrame.JoinFrame.ListButton:Enable()
				isRegistered = true
			end
		elseif UnitIsGroupLeader("player") then
			WQPFrame.JoinFrame.ListButton:SetText(_L["ENLIST"])
			WQPFrame.SetAsParty(true)
		else
			if isRegistered then
				C_ChatInfo.SendAddonMessage(AddonMessageChannel, "?", "CHANNEL", WQchannelNum)
			end
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
			if (WQPartyVars.sendPartyMessage) then
				local questLink = GetQuestLink(activeWQ)
				local message = _L["COMPLETE"]
				if (WQPartyVars.customPartyMessage ~= "") then
					message = WQPartyVars.customPartyMessage
				end
				SendChatMessage(string.format(message, questLink), "PARTY")
			end
			if (WQPartyVars.leavePartyPrompt) then
				StaticPopup_Show("WQP_LEAVEPARTY")
			end
		end
		WQPFrame.ExitWQ()
	end
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

function RegEvents:PARTY_INVITE_REQUEST()
	if isAwaitingInvite then
		WQPFrame.DebugPrint("Auto-accepting invite")
		AcceptGroup()
		isAwaitingInvite = false
		--WQPFrame.JoinFrame.ListButton:SetText(_L["WAITING"])
		--ButtonThrottle(WQPFrame.JoinFrame.ListButton, 3, function(self)
		--	C_ChatInfo.SendAddonMessage(AddonMessageChannel, "@", "PARTY")
		--end, true)
	end
end

local function IsQuestFiltered(questID)
	local wqName, wqFaction = C_TaskQuest.GetQuestInfoByQuestID(questID)
	local wqDesc = GetQuestObjectiveInfo(questID, 1, true)
	local wqType = select(3, GetQuestTagInfo(questID))
	if wqFaction == 2163 or wqType == LE_QUEST_TAG_TYPE_PROFESSION or wqType == LE_QUEST_TAG_TYPE_PET_BATTLE or wqType == LE_QUEST_TAG_TYPE_DUNGEON then
		return true
	end
	return IsQuestIgnored(questID)
end

local function CheckIfCurrentLocIsWQ()
	local uiMapId = C_Map.GetBestMapForUnit("player")
	if uiMapId then
		local WQs = C_TaskQuest.GetQuestsForPlayerByMapID(uiMapId)
		for k in pairs(WQs) do
			local questID = WQs[k]["questId"]
			if (C_QuestLog.IsOnQuest(questID) and not IsQuestFiltered(questID)) then
				WQchannel = "WQP"..WQs[k]["questId"]
				if C_PvP.IsWarModeActive() then
					WQchannel = WQchannel.."PVP"
				end
				JoinChannelByName(WQchannel)
				C_Timer.NewTimer(1, function()
					WQPFrame.EnterWQ(WQs[k]["questId"])
				end)
				return 1
			end
		end
	end
end

local function RemoveAllWQPChannels()
	for i=1,GetNumDisplayChannels() do
		local chName = GetChannelDisplayInfo(i)
		local index = chName:find("WQP")
		if index and index > 0 then
			LeaveChannelByName(chName)
		end
	end
end

function RegEvents:PLAYER_ENTERING_WORLD(self, isInitialLogin, isReloadingUi)
	RemoveAllWQPChannels()
	WQPFrame.ExitWQ()
	RegEvents.isInitialLogin = isInitialLogin
	WQPFrame:RegisterEvent("CHANNEL_UI_UPDATE");
	if not isInitialLogin and isReloadingUi then
		WQPOptionsPane.Setup()
	end
end

function RegEvents:CHANNEL_UI_UPDATE()
	if (RegEvents.isInitialLogin == true) then
		C_Timer.After(1, function()
			WQPOptionsPane.Setup()
		end)
	end
	C_Timer.After(5, function()
		CheckIfCurrentLocIsWQ()
	end)
	WQPFrame:UnregisterEvent("CHANNEL_UI_UPDATE");
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
			WQPFrame.ExitWQ()
			WQPFrame.DebugPrint(string.format("Entering WQ zone for %s", questID))
			if not IsRecentWQ(questID) and not IsQuestFiltered(questID) then
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
		if (WQPartyVars.automaticLFM) then
			WQPFrame.JoinFrame.CalloutButton:Click()
		end
	end)
	
	WQPFrame.HeaderFrame.CloseButton:SetScript("OnClick", function(self)
		WQPFrame.DebugPrint("Close button clicked")
		WQPFrame.ExitWQ()
	end)
	
	WQPFrame.JoinFrame.ListButton:SetScript("OnClick", function(self)
		if isRegistered then
			WQPFrame.DebugPrint("Removing group from listing")
			isRegistered = false
			C_ChatInfo.SendAddonMessage(AddonMessageChannel, "?", "CHANNEL", WQchannelNum)
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
			C_ChatInfo.SendAddonMessage(AddonMessageChannel, "<", "CHANNEL", WQchannelNum)
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
			if not DEBUG then
				if (WQPartyVars.LFMchannel == -1) then
					SendChatMessage(msg, "SAY")
				elseif (WQPartyVars.LFMchannel == 0) then
					SendChatMessage(msg, "YELL")
				else
					SendChatMessage(msg, "CHANNEL", nil, WQPartyVars.LFMchannel)
				end
			else
				SendChatMessage(msg, "WHISPER", nil, UnitName("player"))
				SendChatMessage("wq", "WHISPER", nil, UnitName("player"))
			end
			ButtonThrottle(WQPFrame.JoinFrame.CalloutButton, 60, function()
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
		C_ChatInfo.SendAddonMessage(AddonMessageChannel, "@", "PARTY")
	end
end

function WQPFrame.SetAsIndividual()
	isRegistered = false
	WQPFrame.JoinFrame.JoinButton:Show()
	WQPFrame.JoinFrame.ListButton:Hide()
	WQPFrame.JoinFrame.NewParty:Show()
	WQPFrame.JoinFrame.CalloutButton:Hide()
	WQPFrame.JoinFrame.LeaveButton:Hide()
	
	C_ChatInfo.SendAddonMessage(AddonMessageChannel, ">", "CHANNEL", WQchannelNum)
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
	WQchannelNum = GetChannelName(channelName)
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
		C_ChatInfo.SendAddonMessage(AddonMessageChannel, "?", "CHANNEL", WQchannelNum)
		RemoveAllWQPChannels()
		LeaveChannelByName(WQchannel)
		table.insert(recentWQ, activeWQ)
		activeWQ = nil
		WQchannel = nil
		WQchannelNum = nil
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
		C_Timer.NewTimer(1, function()
			CheckIfCurrentLocIsWQ()
		end)
		print(_L["RESET"])
	elseif (msg == "config") then
		InterfaceOptionsFrame_OpenToCategory("World Quest Party")
		InterfaceOptionsFrame_OpenToCategory("World Quest Party") -- Run twice because WoW is weird.
	else
		print(_L["SLASH"])
	end
end 
