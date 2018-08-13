WQPLocale = {}
function WQPLocale.BuildLocaleTable(locale)
	local Locales = {
		enUS = {
			SEARCHING = "Searching...",
			JOIN = "Join Party",
			JOINING = "Requesting Invite…",
			NO_PARTIES = "No parties found yet…",
			NEW = "Create Party",
			ENLIST = "Enlist Party",
			DELIST = "Delist Party",
			POST = "Post LFM",
			LISTED = "Party Listed",
			UNLISTED = "Party Delisted",
			FULL = "Party Full",
			WAITING = "Waiting for party status...",
			LFM = "LFM %s WQ - whisper me \"wq\" for an invite! (World Quest Party)",
			COMPLETE = "I’ve completed the %s WQ. Thanks for your help! (World Quest Party)",
			LEAVE = "Leave Party",
			PROMPT = "Leave party?",
			YES = "Yes",
			NO = "No",
			SLASH = "If you run into any issues, please reach out for support!\n\nWQP Commands:\nreset - clear and reset addon data.",
			RESET = "WQP: All set, addon has been reset!"
		}
	}
	local loadedLoc = Locales[locale]
	if not loadedLoc then
		print("WQP: This locale is not translated! Loading enUS...")
		return Locales["enUS"]
	end
	return loadedLoc
end