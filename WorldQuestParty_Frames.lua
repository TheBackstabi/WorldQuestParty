WQPFrame.JoinFrame = CreateFrame("Frame", "WQPJoinFrame", WQPFrame)
WQPFrame.HeaderFrame = CreateFrame("Frame", "WQPHeaderFrame", WQPFrame)
FrameLoc = {
	point = "BOTTOMLEFT",
	relativeTo = "WQPFrame",
	relativePoint = "BOTTOMLEFT",
	x = 150,
	y = 150
}

local function SetBorder(frame)
	frame.Backdrop = frame.Backdrop or CreateFrame("Frame", frame:GetName().."Border", frame)
	frame.Backdrop:ClearAllPoints()
	frame.Backdrop:SetWidth(frame:GetWidth() + 2)
	frame.Backdrop:SetHeight(frame:GetHeight() + 2)
	frame.Backdrop:SetPoint("CENTER", frame, "CENTER")
	frame.Backdrop:SetBackdrop( {
		bgFile = nil,
		edgeFile = "Interface\\AddOns\\WorldQuestParty\\Media\\Button-Normal.blp",
		tile = false,
		tileSize = 0,
		edgeSize = 2,
		insets = {left = -1, right = -1, top = -1, bottom = -1}
	} )
	frame:SetBackdropBorderColor(.5, .5, .5, 1)
	frame.Backdrop:SetFrameStrata(frame:GetFrameStrata())
	frame.Backdrop:SetFrameLevel(frame:GetFrameLevel() - 1)
end

function SetFrameAnchors()
	WQPFrame:SetAllPoints()
	WQPFrame:SetSize(UIParent:GetSize())
	local frame = WQPFrame.HeaderFrame
	frame:ClearAllPoints()
	--if FrameLoc then
		frame:SetPoint(FrameLoc.point, FrameLoc.relativeTo, FrameLoc.relativePoint, FrameLoc.x, FrameLoc.y)
	--else
	--	frame:SetPoint("LEFT", WQPFrame, "LEFT", 200, 0)
	--end
	frame:SetWidth(250)
	frame:SetHeight(30)
	local ntex = frame:CreateTexture()
	--ntex:SetTexture("Interface/DialogFrame/UI-DialogBox-Background")
	ntex:SetColorTexture(0, 0, 0, .35)
	ntex:SetAllPoints()
	SetBorder(frame)

	local frame = WQPFrame.JoinFrame
	frame:SetPoint("TOP", WQPFrame.HeaderFrame, "BOTTOM", 0, 0)
	frame:SetWidth(250)
	frame:SetHeight(125)
	local ntex = frame:CreateTexture()
	--ntex:SetTexture("Interface/DialogFrame/UI-DialogBox-Background")
	ntex:SetColorTexture(0, 0, 0, .35)
	ntex:SetAllPoints()
	SetBorder(frame)
end

function SetupButtonFrame(frame)
	--SetBorder(frame)
	local ntex = frame:CreateTexture()
	--ntex:SetTexture("Interface/Buttons/UI-Panel-Button-Up")
	ntex:SetTexture("Interface\\AddOns\\WorldQuestParty\\Media\\Button-Normal.blp")
	ntex:SetAllPoints()	
	frame:SetNormalTexture(ntex)
	
	local htex = frame:CreateTexture()
	--htex:SetTexture("Interface/Buttons/UI-Panel-Button-Highlight")
	htex:SetTexture("Interface\\AddOns\\WorldQuestParty\\Media\\Button-Pressed.blp")
	htex:SetAllPoints()
	frame:SetHighlightTexture(htex)
	
	local ptex = frame:CreateTexture()
	--ptex:SetTexture("Interface/Buttons/UI-Panel-Button-Down")
	ptex:SetTexture("Interface\\AddOns\\WorldQuestParty\\Media\\Button-Pressed.blp")
	ptex:SetAllPoints()
	frame:SetPushedTexture(ptex)
	
	local dtex = frame:CreateTexture()
	--dtex:SetTexture("Interface/Buttons/UI-Panel-Button-Disabled")
	dtex:SetTexture("Interface\\AddOns\\WorldQuestParty\\Media\\Button-Normal.blp")
	dtex:SetAllPoints()
	frame:SetDisabledTexture(dtex)
	
	frame:SetDisabledFontObject("GameFontDisable")
end

function JoinFrame_JoinButton()
	WQPFrame.JoinFrame.JoinButton = CreateFrame("Button", "WQPJoinButton1", WQPFrame.JoinFrame)
	WQPFrame.JoinFrame.JoinButton:SetPoint("TOP", WQPFrame.JoinFrame, "TOP", 0, -10)
	WQPFrame.JoinFrame.JoinButton:SetWidth(200)
	WQPFrame.JoinFrame.JoinButton:SetHeight(50)
	SetupButtonFrame(WQPFrame.JoinFrame.JoinButton)
end

function HeaderFrame_CloseButton()
	WQPFrame.HeaderFrame.CloseButton = CreateFrame("Button", "WQPJoinClose", WQPFrame.HeaderFrame)
	WQPFrame.HeaderFrame.CloseButton:SetPoint("TOPRIGHT", WQPFrame.HeaderFrame, "TOPRIGHT", 0, 0)
	WQPFrame.HeaderFrame.CloseButton:SetWidth(30)
	WQPFrame.HeaderFrame.CloseButton:SetHeight(30)
	WQPFrame.HeaderFrame.CloseButton:SetText("X")
	WQPFrame.HeaderFrame.CloseButton:SetNormalFontObject("GameFontNormal")
	SetupButtonFrame(WQPFrame.HeaderFrame.CloseButton)
	SetBorder(WQPFrame.HeaderFrame.CloseButton)
end

function JoinFrame_CreateParty()
	WQPFrame.JoinFrame.NewParty = CreateFrame("Button", "WQPNewParty", WQPFrame.JoinFrame)
	WQPFrame.JoinFrame.NewParty:SetPoint("TOP", WQPFrame.JoinFrame, "TOP", 0, -65)
	WQPFrame.JoinFrame.NewParty:SetWidth(200)
	WQPFrame.JoinFrame.NewParty:SetHeight(50)
	WQPFrame.JoinFrame.NewParty:SetText("Create Party")
	WQPFrame.JoinFrame.NewParty:SetNormalFontObject("GameFontNormal")
	SetupButtonFrame(WQPFrame.JoinFrame.NewParty)
end

function JoinFrame_ListButton()
	WQPFrame.JoinFrame.ListButton = CreateFrame("Button", "WQPListParty", WQPFrame.JoinFrame)
	WQPFrame.JoinFrame.ListButton:SetPoint("TOP", WQPFrame.JoinFrame, "TOP", 0, -5)
	WQPFrame.JoinFrame.ListButton:SetWidth(200)
	WQPFrame.JoinFrame.ListButton:SetHeight(50)
	
	WQPFrame.JoinFrame.ListButton:SetText("Enlist Party")
	WQPFrame.JoinFrame.ListButton:SetNormalFontObject("GameFontNormal")
	SetupButtonFrame(WQPFrame.JoinFrame.ListButton)
end

function JoinFrame_GeneralCallout()
	WQPFrame.JoinFrame.CalloutButton = CreateFrame("Button", "WQPCallout", WQPFrame.JoinFrame)
	WQPFrame.JoinFrame.CalloutButton:SetPoint("TOP", WQPFrame.JoinFrame, "TOP", 0, -65)
	WQPFrame.JoinFrame.CalloutButton:SetWidth(200)
	WQPFrame.JoinFrame.CalloutButton:SetHeight(50)
	
	WQPFrame.JoinFrame.CalloutButton:SetText("Post LFM")
	WQPFrame.JoinFrame.CalloutButton:SetNormalFontObject("GameFontNormal")
	SetupButtonFrame(WQPFrame.JoinFrame.CalloutButton)
end

function HeaderFrame_MinimizeButton()
	WQPFrame.HeaderFrame.MinimizeButton = CreateFrame("Button", "WQPMinButton", WQPFrame.HeaderFrame)
	WQPFrame.HeaderFrame.MinimizeButton:SetPoint("TOPRIGHT", WQPFrame.HeaderFrame, "TOPRIGHT", -31, 0)
	WQPFrame.HeaderFrame.MinimizeButton:SetWidth(30)
	WQPFrame.HeaderFrame.MinimizeButton:SetHeight(30)
	
	WQPFrame.HeaderFrame.MinimizeButton:SetText("_")
	WQPFrame.HeaderFrame.MinimizeButton:SetNormalFontObject("GameFontNormal")
	SetupButtonFrame(WQPFrame.HeaderFrame.MinimizeButton)
	SetBorder(WQPFrame.HeaderFrame.MinimizeButton)
end

function JoinFrame_LeaveParty()
	WQPFrame.JoinFrame.LeaveButton = CreateFrame("Button", "WQPLeave", WQPFrame.JoinFrame)
	WQPFrame.JoinFrame.LeaveButton:SetPoint("TOP", WQPFrame.JoinFrame, "TOP", 0, -65)
	WQPFrame.JoinFrame.LeaveButton:SetWidth(200)
	WQPFrame.JoinFrame.LeaveButton:SetHeight(50)
	
	WQPFrame.JoinFrame.LeaveButton:SetText("Leave Party")
	WQPFrame.JoinFrame.LeaveButton:SetNormalFontObject("GameFontNormal")
	SetupButtonFrame(WQPFrame.JoinFrame.LeaveButton)
end

function WQPFrame.CreateSubFrames()
	DebugPrint("Creating Frames...")
	SetFrameAnchors()
	WQPFrame.HeaderFrame.Text = WQPFrame.HeaderFrame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	WQPFrame.HeaderFrame.Text:SetPoint("LEFT", WQPFrame.HeaderFrame, "LEFT", 10, 0)
	WQPFrame.HeaderFrame.Text:SetJustifyH("LEFT")
	WQPFrame.HeaderFrame.Text:SetTextColor(.9, .8, 0, 1)
	
	WQPFrame.HeaderFrame:SetMovable(true)
	WQPFrame.HeaderFrame:EnableMouse(true)
	WQPFrame.HeaderFrame:RegisterForDrag("LeftButton")
	WQPFrame.HeaderFrame:SetScript("OnDragStart", WQPFrame.HeaderFrame.StartMoving)
	WQPFrame.HeaderFrame:SetScript("OnDragStop", function()
		WQPFrame.HeaderFrame:StopMovingOrSizing()
		FrameLoc.point, FrameLoc.relativeTo, FrameLoc.relativePoint, FrameLoc.x, FrameLoc.y = WQPFrame.HeaderFrame:GetPoint(1)
	end)
	
	JoinFrame_JoinButton()
	JoinFrame_ListButton()
	HeaderFrame_CloseButton()
	JoinFrame_CreateParty()
	JoinFrame_GeneralCallout()
	HeaderFrame_MinimizeButton()
	JoinFrame_LeaveParty()
	WQPFrame:Hide()
end