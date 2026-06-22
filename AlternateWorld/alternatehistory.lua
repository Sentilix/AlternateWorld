-- ============================================================================
-- Alternate World - History & Log Module Panel
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

    -- Create Scrollable Area for long log lists
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

    HistoryHeadingText:SetText("|cFFFFFFFF" .. data.name .. "'s History Log|r")

    -- Hide old strings to redraw cleanly
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
        -- Draw logs backwards to show the newest events at the top of the screen
        local count = 0
        for i = #historyLog, 1, -1 do
            count = count + 1
            local entry = historyLog[i]
            local fs = LogFontStrings[count]
            
            if not fs then
                fs = ScrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                fs:SetJustifyH("LEFT")
                LogFontStrings[count] = fs
            end

            if not previousAnchor then
                fs:SetPoint("TOPLEFT", ScrollContent, "TOPLEFT", 10, -10)
            else
                fs:SetPoint("TOPLEFT", previousAnchor, "BOTTOMLEFT", 0, -8)
            end

            -- Format: [Timestamp] in White with seconds included, Event details in original layout colors
            fs:SetText("|cFFFFFFFF[" .. (entry.date or "2026-01-01 00:00:00") .. "]|r  " .. entry.text)
            fs:Show()
            
            previousAnchor = fs
            totalHeight = totalHeight + fs:GetStringHeight() + 8
        end
        ScrollContent:SetHeight(totalHeight)
    end

    HistoryPanel:Show()
end

-- Database Helper: Injects raw formatted lines safely into character profiles logs
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

function AlternateWorldHistoryView.HidePanel()
    if HistoryPanel then 
        HistoryPanel:Hide() 
    end
end

-- FIXED: Renamed from AlternateWorldCharacterView back to AlternateWorldHistoryView to block layout leaks!
function AlternateWorldHistoryView.IsShown()
    return HistoryPanel and HistoryPanel:IsShown()
end
