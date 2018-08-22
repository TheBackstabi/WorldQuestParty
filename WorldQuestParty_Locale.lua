WQPLocale = {}
function WQPLocale.BuildLocaleTable(locale)
	local Locales = {
		enUS = {
			SEARCHING = "Searching...",
			JOIN = "Join Party",
			JOINING = "Requesting Invite…",
			NO_PARTIES = "No parties found yet…",
			NEW = "Create Party",
			ENLIST = "List Party",
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
		},
		koKR = {
			COMPLETE = "%s 퀘스트 완료. 도와 줘서 고마워! (세계 퀘스트 그룹)",
			DELIST = "목록에서 그룹 삭제",
			ENLIST = "목록 그룹",
			FULL = "그룹이 가득 찼다",
			JOIN = "그룹에 가입",
			JOINING = "초대장 요청",
			LEAVE = "그룹을 떠나다",
			LFM = "LFM %s WQ - 메시지 나 \"wq\" 초대장을받는 방법 (세계 퀘스트 그룹)",
			LISTED = "그룹에 열거 된",
			NEW = "그룹을 만들자",
			NO = "아니",
			NO_PARTIES = "그룹 없음",
			POST = "채팅에 게시",
			PROMPT = "확실합니까?",
			RESET = "WQP: 재설정 완료",
			SEARCHING = "수색중",
			SLASH = "문제가있는 경우 저에게 연락주세요. \n\nWQP 명령: \nreset - 날을 다시 끼우다",
			UNLISTED = "목록에서 그룹을 삭제했습니다",
			WAITING = "그룹 상태 찾기",
			YES = "네"
		}
	}
	local loadedLoc = Locales[locale]
	if loadedLoc == nil then
		print("WQP: This locale is not translated! Loading enUS...")
		return Locales["enUS"]
	end
	return loadedLoc
end
