-- ============================================================================
-- Alternate World - Character Profile & Account Totals View Panel (v0.2.0)
-- ============================================================================

AlternateWorldCharacterView = {}

local CharacterPanel = nil
local MainTitleText = nil
local LastUpdateText = nil
local DefaultPortrait2D = nil

local DetailLine1 = nil
local DetailLine2 = nil
local SpecIconTexture = nil
local SpecTextString = nil
local ClassIconTexture = nil

local InfoTextLeft = nil
local AccountTotalsHeadingText = nil
local AccountTotalsLeft = nil
local AccountTotalsRight = nil

local ProfLineFramesPool = {}

local function FormatMoneyString(copperCoins)
    local gold = math.floor(copperCoins / 10000)
    local silver = math.floor((copperCoins % 10000) / 100)
    local copper = copperCoins % 100
    return string.format("|cFFFFD700%dg|r |cFFC0C0C0%ds|r |cFFB87333%dc|r", gold, silver, copper)
end

function AlternateWorldCharacterView.CreatePanel(parentWindow)
    if CharacterPanel then return CharacterPanel end

    CharacterPanel = CreateFrame("Frame", "AWCharacterPanelGlobal", parentWindow)
    CharacterPanel:SetAllPoints(parentWindow)
    CharacterPanel:Hide()

    MainTitleText = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    MainTitleText:SetPoint("TOPLEFT", CharacterPanel, "TOPLEFT", 20, -10)
    MainTitleText:SetText("|cFFFFFFFFCharacter Profile Overview|r")

    LastUpdateText = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    LastUpdateText:SetPoint("TOPLEFT", MainTitleText, "BOTTOMLEFT", 0, -2)

    DefaultPortrait2D = CharacterPanel:CreateTexture(nil, "OVERLAY")
    DefaultPortrait2D:SetSize(50, 50)
    DefaultPortrait2D:SetPoint("TOPLEFT", LastUpdateText, "BOTTOMLEFT", 0, -10)

    DetailLine1 = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    DetailLine1:SetPoint("TOPLEFT", DefaultPortrait2D, "TOPRIGHT", 15, -2)
    DetailLine1:SetJustifyH("LEFT")

    ClassIconTexture = CharacterPanel:CreateTexture(nil, "OVERLAY")
    ClassIconTexture:SetSize(14, 14)
    ClassIconTexture:SetPoint("TOPLEFT", DetailLine1, "BOTTOMLEFT", 0, -4)
    ClassIconTexture:Hide()

    DetailLine2 = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    DetailLine2:SetPoint("LEFT", ClassIconTexture, "RIGHT", 5, 0)
    DetailLine2:SetJustifyH("LEFT")

    SpecIconTexture = CharacterPanel:CreateTexture(nil, "OVERLAY")
    SpecIconTexture:SetSize(14, 14)
    SpecIconTexture:SetPoint("TOPLEFT", ClassIconTexture, "BOTTOMLEFT", 0, -5)
    SpecIconTexture:Hide()

    SpecTextString = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    SpecTextString:SetPoint("LEFT", SpecIconTexture, "RIGHT", 6, 0)
    SpecTextString:SetJustifyH("LEFT")

    InfoTextLeft = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    InfoTextLeft:SetPoint("TOPLEFT", DefaultPortrait2D, "BOTTOMLEFT", 0, -32)
    InfoTextLeft:SetJustifyH("LEFT")

    AccountTotalsHeadingText = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    AccountTotalsHeadingText:SetPoint("TOPLEFT", CharacterPanel, "TOPLEFT", 20, -255)
    AccountTotalsHeadingText:SetText("|cFFFFFFFFAccount Totals Overview|r")

    AccountTotalsLeft = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    AccountTotalsLeft:SetPoint("TOPLEFT", AccountTotalsHeadingText, "BOTTOMLEFT", 0, -10)
    AccountTotalsLeft:SetJustifyH("LEFT")

    AccountTotalsRight = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    AccountTotalsRight:SetPoint("TOPLEFT", AccountTotalsHeadingText, "BOTTOMLEFT", 220, -10)
    AccountTotalsRight:SetJustifyH("LEFT")

    return CharacterPanel
end

function AlternateWorldCharacterView.ShowData(selectedCharacterKey)
    if not CharacterPanel or not AlternateWorldDB or not selectedCharacterKey then return end
    local data = AlternateWorldDB[selectedCharacterKey]
    if not data then return end

    LastUpdateText:SetText("Last Update: |cFF888888" .. (data.bagsUpdated or "Unknown") .. "|r")

    if DefaultPortrait2D then
        DefaultPortrait2D:SetTexture("Interface\\CharacterFrame\\TemporaryPortrait")
        if data.name == UnitName("player") then SetPortraitTexture(DefaultPortrait2D, "player") end
    end

    local classColorHex = "|cFFFFFFFF"
    if data.classToken and RAID_CLASS_COLORS[data.classToken] then
        local c = RAID_CLASS_COLORS[data.classToken]
        classColorHex = string.format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
    end

    DetailLine1:SetText(classColorHex .. data.name .. "|r  |cFF888888-|r  |cFFFFFFFF" .. (data.realm or "Unknown") .. "|r")

    -- FIXED LOCAL REFERENCE: Pull coords from the newly setup AlternateWorldConstants module
    if ClassIconTexture and data.classToken and AlternateWorldConstants and AlternateWorldConstants.CLASS_COORDS[data.classToken] then
        local coords = AlternateWorldConstants.CLASS_COORDS[data.classToken]
        ClassIconTexture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
        ClassIconTexture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        ClassIconTexture:Show()
    else
        if ClassIconTexture then ClassIconTexture:Hide() end
    end

    local factionColored = data.faction == "Alliance" and "|cFF0070DDAlliance|r" or "|cFFFF0000Horde|r"
    DetailLine2:SetText((data.race or "Human") .. " " .. (data.gender or "Female") .. " " .. classColorHex .. (data.classNameLocal or "Character") .. "|r of the " .. factionColored .. "  |cFFFFFFFF(Level " .. (data.level or 60) .. ")|r")

    if data.specIcon then
        SpecIconTexture:SetTexture(data.specIcon)
        SpecIconTexture:Show()
        SpecTextString:SetText(string.format("|cFFFFFFFF%s|r", data.specText or "Fury (0/51/0)"))
    else
        SpecIconTexture:Hide()
        SpecTextString:SetText("|cFF888888No Specialization Allocations|r")
    end

    local currentIlvl = data.itemLevel or 0
    local maxIlvl = data.maxItemLevel or 0
    InfoTextLeft:SetText(string.format("Gold: %s\n\nItem Level: |cFFFFFFFF%.1f|r  |cFF888888(Max: %.1f)|r\n\nZone: |cFFFFFFFF%s|r", FormatMoneyString(data.money or 0), currentIlvl, maxIlvl, data.zone or "Unknown"))

    local currentRealm = data.realm or GetRealmName()
    local allyGold, hordeGold, allyChars, hordeChars, ally60s, horde60s = 0, 0, 0, 0, 0, 0
    
    for _, loopChar in pairs(AlternateWorldDB) do
        if loopChar.realm == currentRealm then
            if loopChar.faction == "Alliance" then
                allyGold = allyGold + (loopChar.money or 0)
                allyChars = allyChars + 1
                if loopChar.level == 60 then ally60s = ally60s + 1 end
            elseif loopChar.faction == "Horde" then
                hordeGold = hordeGold + (loopChar.money or 0)
                hordeChars = hordeChars + 1
                if loopChar.level == 60 then horde60s = horde60s + 1 end
            end
        end
    end

    AccountTotalsLeft:SetText(string.format("Gold, Alliance: %s\nGold, Horde: %s\nGold, Total: %s", FormatMoneyString(allyGold), FormatMoneyString(hordeGold), FormatMoneyString(allyGold + hordeGold)))
    AccountTotalsRight:SetText(string.format("Chars, Alliance: |cFFFFFFFF%d|r  |cFF888888(level 60: %d)|r\nChars, Horde: |cFFFFFFFF%d|r  |cFF888888(level 60: %d)|r\nChars, Total: |cFFFFFFFF%d|r  |cFF888888(level 60: %d)|r", allyChars, ally60s, hordeChars, horde60s, allyChars + hordeChars, ally60s + horde60s))

    for _, line in ipairs(ProfLineFramesPool) do line:Hide() line.Icon:Hide() line.Text:SetText("") end
    local foundProfessions = {}
    if data.professions then
        for profName, profData in pairs(data.professions) do
            table.insert(foundProfessions, { name = profName, level = profData.level or 0, maxLevel = profData.maxLevel or 0 })
        end
    end
    table.sort(foundProfessions, function(a, b) return a.name < b.name end)

    for i, profObj in ipairs(foundProfessions) do
        local lineFrame = ProfLineFramesPool[i]
        if not lineFrame then
            lineFrame = CreateFrame("Frame", nil, CharacterPanel)
            lineFrame:SetSize(220, 16)
            if i == 1 then lineFrame:SetPoint("TOPLEFT", CharacterPanel, "TOPLEFT", 240, -115)
            else lineFrame:SetPoint("TOPLEFT", ProfLineFramesPool[i - 1], "BOTTOMLEFT", 0, -8) end
            
            lineFrame.Icon = lineFrame:CreateTexture(nil, "OVERLAY")
            lineFrame.Icon:SetSize(14, 14)
            lineFrame.Icon:SetPoint("LEFT", lineFrame, "LEFT", 0, 0)
            
            lineFrame.Text = lineFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lineFrame.Text:SetPoint("LEFT", lineFrame.Icon, "RIGHT", 6, 0)
            lineFrame.Text:SetJustifyH("LEFT")
            ProfLineFramesPool[i] = lineFrame
        end
        if AlternateWorldProfEngine then lineFrame.Icon:SetTexture(AlternateWorldProfEngine.GetProfessionIconTexture(profObj.name)) lineFrame.Icon:Show() end
        lineFrame.Text:SetText(string.format("%s: |cFFFFFFFF%d/%d|r", profObj.name, profObj.level, profObj.maxLevel))
        lineFrame:Show()
    end

    CharacterPanel:Show()
end

function AlternateWorldCharacterView.HidePanel() if CharacterPanel then CharacterPanel:Hide() end end
function AlternateWorldCharacterView.IsShown() return CharacterPanel and CharacterPanel:IsShown() end

-- End of [alternatecharacter.lua]
