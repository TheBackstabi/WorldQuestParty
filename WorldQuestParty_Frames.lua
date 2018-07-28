WQPFrame.JoinFrame = CreateFrame("Frame", "WQPJoinFrame", WQPFrame)
WQPFrame.HeaderFrame = CreateFrame("Frame", "WQPHeaderFrame", WQPFrame)

function SetFrameAnchors()
	WQPFrame:SetAllPoints()
	WQPFrame:SetSize(UIParent:GetSize())
	local frame = WQPFrame.HeaderFrame
	frame:SetPoint("LEFT", WQPFrame, "LEFT", 200, 0)
	frame:SetWidth(250)
	frame:SetHeight(30)
	local ntex = frame:CreateTexture()
	ntex:SetTexture("Interface/DialogFrame/UI-DialogBox-Background")
	ntex:SetTexCoord(0, 0.625, 0, 0.625)
	ntex:SetAllPoints()

	local frame = WQPFrame.JoinFrame
	frame:SetPoint("LEFT", WQPFrame.HeaderFrame, "LEFT", 0, -83)
	frame:SetWidth(250)
	frame:SetHeight(125)
	local ntex = frame:CreateTexture()
	ntex:SetTexture("Interface/DialogFrame/UI-DialogBox-Background")
	ntex:SetTexCoord(0, 0.625, 0, 0.625)
	ntex:SetAllPoints()
end

function SetupButtonFrame(frame)
	local ntex = frame:CreateTexture()
	ntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
	ntex:SetTexCoord(0, 0.625, 0, 0.6875)
	ntex:SetAllPoints()	
	frame:SetNormalTexture(ntex)
	
	local htex = frame:CreateTexture()
	htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	htex:SetTexCoord(0, 0.625, 0, 0.6875)
	htex:SetAllPoints()
	frame:SetHighlightTexture(htex)
	
	local ptex = frame:CreateTexture()
	ptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
	ptex:SetTexCoord(0, 0.625, 0, 0.6875)
	ptex:SetAllPoints()
	frame:SetPushedTexture(ptex)
	
	local dtex = frame:CreateTexture()
	dtex:SetTexture("Interface/Buttons/UI-Panel-Button-Disabled")
	dtex:SetTexCoord(0, 0.625, 0, 0.6875)
	dtex:SetAllPoints()
	frame:SetDisabledTexture(dtex)
	return frame
end

function JoinFrame_JoinButton()
	WQPFrame.JoinFrame.JoinButton = CreateFrame("Button", "WQPJoinButton1", WQPFrame.JoinFrame)
	WQPFrame.JoinFrame.JoinButton:SetPoint("TOP", WQPFrame.JoinFrame, "TOP", 0, -5)
	WQPFrame.JoinFrame.JoinButton:SetWidth(200)
	WQPFrame.JoinFrame.JoinButton:SetHeight(50)
	SetupButtonFrame(WQPFrame.JoinFrame.JoinButton)
end

function HeaderFrame_CloseButton()
	WQPFrame.HeaderFrame.CloseButton = CreateFrame("Button", "WQPJoinClose", WQPFrame.HeaderFrame)
	WQPFrame.HeaderFrame.CloseButton:SetPoint("TOPRIGHT", WQPFrame.HeaderFrame, "TOPRIGHT", 0, 0)
	WQPFrame.HeaderFrame.CloseButton:SetWidth(30)
	WQPFrame.HeaderFrame.CloseButton:SetHeight(30)
	SetupButtonFrame(WQPFrame.HeaderFrame.CloseButton)
	WQPFrame.HeaderFrame.CloseButton:SetText("X")
	WQPFrame.HeaderFrame.CloseButton:SetNormalFontObject("GameFontNormal")
end

function JoinFrame_CreateParty()
	WQPFrame.JoinFrame.NewParty = CreateFrame("Button", "WQPNewParty", WQPFrame.JoinFrame)
	WQPFrame.JoinFrame.NewParty:SetPoint("TOP", WQPFrame.JoinFrame, "TOP", 0, -65)
	WQPFrame.JoinFrame.NewParty:SetWidth(200)
	WQPFrame.JoinFrame.NewParty:SetHeight(50)
	SetupButtonFrame(WQPFrame.JoinFrame.NewParty)
	WQPFrame.JoinFrame.NewParty:SetText("Create new party")
	WQPFrame.JoinFrame.NewParty:SetNormalFontObject("GameFontNormal")
end

function JoinFrame_ListButton()
	WQPFrame.JoinFrame.ListButton = CreateFrame("Button", "WQPListParty", WQPFrame.JoinFrame)
	WQPFrame.JoinFrame.ListButton:SetPoint("TOP", WQPFrame.JoinFrame, "TOP", 0, -5)
	WQPFrame.JoinFrame.ListButton:SetWidth(200)
	WQPFrame.JoinFrame.ListButton:SetHeight(50)
	SetupButtonFrame(WQPFrame.JoinFrame.ListButton)
	WQPFrame.JoinFrame.ListButton:SetText("List Group")
	WQPFrame.JoinFrame.ListButton:SetNormalFontObject("GameFontNormal")
end

function JoinFrame_GeneralCallout()
	WQPFrame.JoinFrame.CalloutButton = CreateFrame("Button", "WQPCallout", WQPFrame.JoinFrame)
	WQPFrame.JoinFrame.CalloutButton:SetPoint("TOP", WQPFrame.JoinFrame, "TOP", 0, -65)
	WQPFrame.JoinFrame.CalloutButton:SetWidth(200)
	WQPFrame.JoinFrame.CalloutButton:SetHeight(50)
	SetupButtonFrame(WQPFrame.JoinFrame.CalloutButton)
	WQPFrame.JoinFrame.CalloutButton:SetText("Post LFM")
	WQPFrame.JoinFrame.CalloutButton:SetNormalFontObject("GameFontNormal")
end

function HeaderFrame_MinimizeButton()
	WQPFrame.HeaderFrame.MinimizeButton = CreateFrame("Button", "WQPMinButton", WQPFrame.HeaderFrame)
	WQPFrame.HeaderFrame.MinimizeButton:SetPoint("TOPRIGHT", WQPFrame.HeaderFrame, "TOPRIGHT", -40, 0)
	WQPFrame.HeaderFrame.MinimizeButton:SetWidth(30)
	WQPFrame.HeaderFrame.MinimizeButton:SetHeight(30)
	SetupButtonFrame(WQPFrame.HeaderFrame.MinimizeButton)
	WQPFrame.HeaderFrame.MinimizeButton:SetText("_")
	WQPFrame.HeaderFrame.MinimizeButton:SetNormalFontObject("GameFontNormal")
end

function JoinFrame_LeaveParty()
	WQPFrame.JoinFrame.LeaveButton = CreateFrame("Button", "WQPLeave", WQPFrame.JoinFrame)
	WQPFrame.JoinFrame.LeaveButton:SetPoint("TOP", WQPFrame.JoinFrame, "TOP", 0, -65)
	WQPFrame.JoinFrame.LeaveButton:SetWidth(200)
	WQPFrame.JoinFrame.LeaveButton:SetHeight(50)
	SetupButtonFrame(WQPFrame.JoinFrame.LeaveButton)
	WQPFrame.JoinFrame.LeaveButton:SetText("Leave Party")
	WQPFrame.JoinFrame.LeaveButton:SetNormalFontObject("GameFontNormal")
end

function WQPFrame.CreateSubFrames()
	DebugPrint("Creating Frames...")
	SetFrameAnchors()
	WQPFrame.HeaderFrame.Text = WQPFrame.HeaderFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	WQPFrame.HeaderFrame.Text:SetPoint("LEFT", WQPFrame.HeaderFrame, "LEFT", 10, 0)
	WQPFrame.HeaderFrame.Text:SetJustifyH("LEFT")
	WQPFrame.HeaderFrame.Text:SetTextColor(1, 1, 1, 1)
	
	WQPFrame.HeaderFrame:SetMovable(true)
	WQPFrame.HeaderFrame:EnableMouse(true)
	WQPFrame.HeaderFrame:RegisterForDrag("LeftButton")
	WQPFrame.HeaderFrame:SetScript("OnDragStart", WQPFrame.HeaderFrame.StartMoving)
	WQPFrame.HeaderFrame:SetScript("OnDragStop", WQPFrame.HeaderFrame.StopMovingOrSizing)

	JoinFrame_JoinButton()
	JoinFrame_ListButton()
	HeaderFrame_CloseButton()
	JoinFrame_CreateParty()
	JoinFrame_GeneralCallout()
	HeaderFrame_MinimizeButton()
	JoinFrame_LeaveParty()
	
	WQPFrame:Hide()
end