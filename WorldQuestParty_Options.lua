WQPOptionsPane = {}
local function BuildChannelList()
	local tab = {}
	local chanCount = GetNumDisplayChannels()
	local addCount = 0
	for i=1,chanCount do
		local channel, isHeader, _, num = GetChannelDisplayInfo(i)
		if num and not isHeader then
			tab[i] = num..". "..channel
			addCount = addCount + 1
		end
	end
	tab[-1] = "Say" --Ahh, LUA. You so weird.
	tab[0] = "Yell"
	return tab
end

function WQPOptionsPane.Setup()
	local OptionsTable = {
		type = "group",
		args = {
			sendPartyMessage = {
				order = 0,
				name = "Send Party Message",
				desc = "Should WQP send a thank you message to party chat?",
				type = "toggle",
				set = function(info, val) WQPartyVars.sendPartyMessage = val end,
				get = function(info) return WQPartyVars.sendPartyMessage end
			},
			leavePartyPrompt = {
				order = 1,
				name = "Prompt to Leave Party",
				desc = "Should WQP prompt you to leave your party when completing a WQ?",
				type = "toggle",
				set = function(info, val) WQPartyVars.leavePartyPrompt = val end,
				get = function(info) return WQPartyVars.leavePartyPrompt end
			},
			customPartyMessage = {
				order = 2,
				name = "Custom Party Message",
				desc = "Create a custom message to send to your party on WQ completion.\n\nTemplate: \"I’ve completed the %s WQ. Thanks for your help! (World Quest Party)\"\n\n%s is the chat link to your current WQ.\n\nLeave blank to send the default message.",
				type = "input",
				set = function(info, val) WQPartyVars.customPartyMessage = val end,
				get = function(info) return WQPartyVars.customPartyMessage end,
				width = "full",
				hidden = function(info) return not WQPartyVars.sendPartyMessage end
			},
			automaticLFM = {
				order = 3,
				name = "Automatically Post LFM Message",
				desc = "Should WQP automatically post a LFM message when listing a group?",
				type = "toggle",
				set = function(info, val) WQPartyVars.automaticLFM = val end,
				get = function(info) return WQPartyVars.automaticLFM end
			},
			automaticLFM = {
				order = 4,
				name = "Automatically Post LFM Message",
				desc = "Should WQP automatically post a LFM message when listing a group?",
				type = "toggle",
				set = function(info, val) WQPartyVars.automaticLFM = val end,
				get = function(info) return WQPartyVars.automaticLFM end,
				width = "full"
			},
			LFMchannel = {
				order = 5,
				name = "LFM Channel",
				desc = "What channel number to send your LFM post to.",
				type = "select",
				set = function(info, val) WQPartyVars.LFMchannel = val end,
				get = function(info) return WQPartyVars.LFMchannel end,
				values = BuildChannelList(),
				style = "dropdown"
			},
		}
	}
	LibStub("AceConfig-3.0"):RegisterOptionsTable("World Quest Party Options", OptionsTable, nil)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("World Quest Party Options", "World Quest Party", nil)
end
WQPOptionsPane.Setup()