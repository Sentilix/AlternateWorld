-- ============================================================================
-- Alternate World - History & Log Module Panel (v0.2.0 - MASTER GENOPRETTET)
-- ============================================================================

AlternateWorldHistoryView = {}

local HistoryPanel = nil
local ScrollFrame = nil
local ScrollContent = nil
local HistoryHeadingText = nil
local LogFontStrings = {}

function AlternateWorldHistoryView.CreatePanel(parentWindow)
    if HistoryPanel then return HistoryPanel end

    HistoryPanel = CreateFrame("Frame", nil, parentWindow)
    HistoryPanel:SetAllPoints(parentWindow)
    HistoryPanel:Hide()

    HistoryHeadingText = HistoryPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    HistoryHeadingText:SetPoint("TOPLEFT", HistoryPanel, "TOPLEFT", 20, -10)

    ScrollFrame = CreateFrame("ScrollFrame", "AlternateWorldHistoryScrollFrame", HistoryPanel, "UIPanelScrollFrameTemplate")
    ScrollFrame:SetPoint("TOPLEFT", HistoryPanel, "TOPLEFT", 10, -35)
    ScrollFrame:SetPoint("BOTTOMRIGHT", HistoryPanel, "BOTTOMRIGHT", -30, 10)

    ScrollContent = CreateFrame("Frame", nil, ScrollFrame)
    ScrollContent:SetSize(parentWindow:GetWidth() - 40, 1)
    ScrollFrame:SetScrollChild(ScrollContent)

    return HistoryPanel
end

function AlternateWorldHistoryView.ShowData(selectedCharacterKey)
    if not HistoryPanel or not AlternateWorldDB or not selectedCharacterKey then return end
    local data = AlternateWorldDB[selectedCharacterKey]
    if not data then return end

    -- FIXED LOGIC: Handles native language grammar apostrophe formatting rules cleanly
    local charName = data.name or "Character"
    local genitiveName = charName .. "'s"
    if string.sub(charName, -1) == "s" or string.sub(charName, -1) == "S" then genitiveName = charName .. "'" end
    HistoryHeadingText:SetText("|cFFFFFFFF" .. genitiveName .. " History Log|r")

    for _, fs in ipairs(LogFontStrings) do fs:Hide() end

    local historyLog = data.historyLog or {}
    local previousAnchor = nil
    
    if #historyLog == 0 then
        local emptyFS = LogFontStrings[1] or ScrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        emptyFS:SetPoint("TOPLEFT", ScrollContent, "TOPLEFT", 10, -10)
        emptyFS:SetText("|cFFFFFFFFNo historical events recorded yet for this character.|r")
        emptyFS:Show()
        LogFontStrings[1] = emptyFS
        ScrollContent:SetHeight(30)
    else
        local totalHeight = 10
        local count = 0
        -- FIXED v0.6.0 DYNAMIC WIDTH CALCULATION: Enforces standard safe margins clear of scrollbars
        local targetWidth = ScrollContent:GetWidth() - 20
        
        for i = #historyLog, 1, -1 do
            count = count + 1
            local entry = historyLog[i]
            local fs = LogFontStrings[count]
            
            if not fs then
                fs = ScrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                fs:SetJustifyH("LEFT")
                -- FIXED v0.6.0 LINEBREAK ENFORCEMENT: Locks the boundaries to wrap text strings cleanly
                fs:SetWidth(targetWidth)
                fs:SetWordWrap(true)
                fs:SetNonSpaceWrap(true)
                LogFontStrings[count] = fs
            end

            -- Safely refresh the width matrix calculation dynamically in case UI scales are altered
            fs:SetWidth(targetWidth)

            if not previousAnchor then fs:SetPoint("TOPLEFT", ScrollContent, "TOPLEFT", 10, -10)
            else fs:SetPoint("TOPLEFT", previousAnchor, "BOTTOMLEFT", 0, -8) end

            local finalTimestamp = "2026-01-01 00:00:00"
            local finalEventText = ""
            
            if type(entry) == "table" then
                finalTimestamp = entry.date or finalTimestamp
                finalEventText = entry.text or "Unknown Loot Event Data"
            else
                finalEventText = tostring(entry)
            end

            fs:SetText("|cFFFFFFFF[" .. finalTimestamp .. "]|r  " .. finalEventText)
            fs:Show()
            
            previousAnchor = fs
            totalHeight = totalHeight + fs:GetStringHeight() + 8
        end
        ScrollContent:SetHeight(totalHeight)
    end

    HistoryPanel:Show()
end

function AlternateWorldHistoryView.LogEvent(eventText)
    local charName = UnitName("player")
    local realmName = GetRealmName()
    if not charName or not realmName or not AlternateWorldDB then return end
    local myKey = charName .. " - " .. realmName

    if not AlternateWorldDB[myKey] then return end
    if not AlternateWorldDB[myKey].historyLog then AlternateWorldDB[myKey].historyLog = {} end

    table.insert(AlternateWorldDB[myKey].historyLog, {
        date = date("%Y-%m-%d %H:%M:%S"),
        text = eventText
    })
end

function AlternateWorldHistoryView.HidePanel() if HistoryPanel then HistoryPanel:Hide() end end
function AlternateWorldHistoryView.IsShown() return HistoryPanel and HistoryPanel:IsShown() end

-- End of [alternatehistory.lua]
