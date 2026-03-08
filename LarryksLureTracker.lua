local mainFrame = CreateFrame("Frame", "MyAddonMainFrame", UIParent, "BasicFrameTemplateWithInset")
mainFrame:SetSize(220, 200)
mainFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 50, -50)
mainFrame.TitleBg:SetHeight(30)
mainFrame.title = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
mainFrame.title:SetPoint("TOPLEFT", mainFrame.TitleBg, "TOPLEFT", 5, -3)
mainFrame.title:SetText("LarryksLureTracker")
mainFrame:Hide()
mainFrame:EnableMouse(true)
mainFrame:SetMovable(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", function(self)
	self:StartMoving()
end)
mainFrame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
end)

mainFrame:SetScript("OnShow", function()
        PlaySound(808)
end)

mainFrame:SetScript("OnHide", function()
        PlaySound(808)
end)

SLASH_MYADDON1 = "/llt"
SLASH_MYADDON2 = "/lures"
SlashCmdList["MYADDON"] = function()
    if mainFrame:IsShown() then
        mainFrame:Hide()
    else
        mainFrame:Show()
    end
end
table.insert(UISpecialFrames, "MyAddonMainFrame")



local eventListenerFrame = CreateFrame("Frame", "MyAddonEventListenerFrame", UIParent)

local function eventHandler(self, event, ...)
    if event == "PLAYER_LOGIN" then
        print("Debugging: You have logged in!")
    end
end

eventListenerFrame:SetScript("OnEvent", eventHandler)
eventListenerFrame:RegisterEvent("PLAYER_LOGIN")
eventListenerFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")

-- Quest names and IDs
local questNames = {"Eversong", "Zul'Aman", "Harandar", "Voidstorm", "Grand Beast"}
local questIDs = {88545, 88526, 88531, 88532, 88524}

local questLabels = {}
local tomtomButtons = {}
local labelYOffset = -40
local tomtomData = {
    {way = "/way #2395 41.95 80.05 Eversong (Ghostclaw Elder)"},
    {way = "/way #2437 47.69 53.25 Zul'Aman (Silverscale)"},
    {way = "/way #2413 66.28 47.91 Harandar (Lumenfin)"},
    {way = "/way #2405 54.60 65.80 Voidstorm (Umbrafang)"},
    {way = "/way #2405 43.25 82.75 Voidstorm - Grand Beast Lure (Netherscythe)"},
}
for i, name in ipairs(questNames) do
    local rowY = labelYOffset - (i-1)*30
    -- Quest name label (left column)
    local label = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 30, rowY)
    label:SetText(name)
    questLabels[i] = label

    -- TomTom button (right column)
    local btn = CreateFrame("Button", nil, mainFrame, "UIPanelButtonTemplate")
    btn:SetSize(70, 22)
    btn:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -30, rowY + 4)
    btn:SetText("TomTom")
    btn:SetScript("OnClick", function()
        ChatFrame1EditBox:SetText(tomtomData[i].way)
        ChatEdit_SendText(ChatFrame1EditBox, 0)
    end)
    tomtomButtons[i] = btn
end

-- Function to update quest completion colors

local function PlayerHasSkinning()
    local prof1, prof2 = GetProfessions()
    if prof1 then
        local _, _, _, _, _, _, skillLine = GetProfessionInfo(prof1)
        if skillLine == 393 then return true end
    end
    if prof2 then
        local _, _, _, _, _, _, skillLine = GetProfessionInfo(prof2)
        if skillLine == 393 then return true end
    end
    return false
end

local function UpdateQuestLabels()
    if not PlayerHasSkinning() then
        for i = 1, #questLabels do
            questLabels[i]:SetTextColor(0.5, 0.5, 0.5) -- gray out if not skinner
        end
        return
    end
    for i, questID in ipairs(questIDs) do
        local completed = C_QuestLog.IsQuestFlaggedCompleted(questID)
        if completed then
            questLabels[i]:SetTextColor(0, 1, 0) -- green
        else
            questLabels[i]:SetTextColor(1, 0, 0) -- red
        end
    end
end

eventListenerFrame:SetScript("OnEvent", function(self, event, ...)
    if not PlayerHasSkinning() then
        UpdateQuestLabels()
        return
    end
    if event == "PLAYER_LOGIN" then
        UpdateQuestLabels()
        -- Check for missing quests and print if any (delay by 0.5s)
        C_Timer.After(3, function()
            local missing = {}
            for i, questID in ipairs(questIDs) do
                if not C_QuestLog.IsQuestFlaggedCompleted(questID) then
                    table.insert(missing, questNames[i])
                end
            end
            if #missing > 0 then
                -- Mint green: |cff3effd7
                DEFAULT_CHAT_FRAME:AddMessage("|cff3effd7[LLT] Missing Renowned Beasts:|r")
                -- Red: |cffff2020
                for _, name in ipairs(missing) do
                    DEFAULT_CHAT_FRAME:AddMessage("|cffff2020" .. name .. "|r")
                end
            end
        end)
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unit, _, spellID = ...
        if unit == "player" and spellID == 8613 then
            -- Delay update to ensure quest state is refreshed
            C_Timer.After(0.2, function()
                UpdateQuestLabels()
            end)
        end
    end
end)
