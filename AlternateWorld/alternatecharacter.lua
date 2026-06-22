-- ============================================================================
-- Alternate World - Character View Module Panel & Global Statistics
-- ============================================================================

AlternateWorldCharacterView = {}

local CharacterPanel = nil
local Portrait = nil
local CharacterHeadingText = nil
local DividerLine = nil     
local AccountTotalsHeading = nil

-- Separate FontStrings for Top Section to ensure perfect vertical column alignment
local TopLabelsText = nil
local TopValuesText = nil

-- Separate FontStrings for Bottom Section to maintain the exact same column grid
local BottomLabelsText = nil
local BottomValuesText = nil

-- Internal Helper: Calculates dynamic totals over all cached DB entries
local function UpdateGlobalAccountStats()
    if not AlternateWorldDB then return end

    local allianceGold, hordeGold = 0, 0
    local allianceChars, hordeChars = 0, 0
    local allianceLvl60, hordeLvl60 = 0, 0

    for _, data in pairs(AlternateWorldDB) do
        local gold = tonumber(data.money) or 0
        local lvl = tonumber(data.level) or 1
        local fact = data.faction or "Unknown"

        if fact == "Alliance" then
            allianceGold = allianceGold + gold
            allianceChars = allianceChars + 1
            if lvl == 60 then allianceLvl60 = allianceLvl60 + 1 end
        elseif fact == "Horde" then
            hordeGold = hordeGold + gold
            hordeChars = hordeChars + 1
            if lvl == 60 then hordeLvl60 = hordeLvl60 + 1 end
        end
    end

    local totalCombinedGold = allianceGold + hordeGold
    local totalGoldStr = GetMoneyString(totalCombinedGold, true)
    local allyGoldStr = GetMoneyString(allianceGold, true)
    local hordeGoldStr = GetMoneyString(hordeGold, true)

    local totalChars = allianceChars + hordeChars
    local totalLvl60s = allianceLvl60 + hordeLvl60

    -- All labels systematically formatted with uniform prefix rules
    local labelsString = 
        "Gold, |cFF0070DDAlliance:|r\n" ..
        "Gold, |cFFC41F3BHorde:|r\n" ..
        "Gold, total:\n\n" ..
        "Characters, |cFF0070DDAlliance:|r\n" ..
        "Characters, |cFFC41F3BHorde:|r\n" ..
        "Characters, total:"

    -- FIXED: Switched "Level 60:" color encoding to matching golden yellow inside the value column matrix
    local valuesString = string.format(
        "%s\n" ..
        "%s\n" ..
        "%s\n\n" ..
        "|cFFFFD700%d|r\n" ..
        "|cFFFFD700%d|r\n" ..
        "|cFFFFD700%d|r  (|cFFFFD700Level 60:|r |cFFFFD700%d|r)",
        allyGoldStr, hordeGoldStr, totalGoldStr,
        allianceChars, hordeChars, totalChars, totalLvl60s
    )

    BottomLabelsText:SetText(labelsString)
    BottomValuesText:SetText(valuesString)
end

function AlternateWorldCharacterView.CreatePanel(parentWindow)
    if CharacterPanel then return CharacterPanel end

    CharacterPanel = CreateFrame("Frame", nil, parentWindow)
    CharacterPanel:SetAllPoints(parentWindow)
    CharacterPanel:Hide() 

    Portrait = CharacterPanel:CreateTexture(nil, "ARTWORK")
    Portrait:SetSize(70, 70)
    Portrait:SetPoint("TOPLEFT", CharacterPanel, "TOPLEFT", 20, -20)

    LastUpdatedText = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    LastUpdatedText:SetPoint("TOPLEFT", Portrait, "TOPRIGHT", 15, 10)
    LastUpdatedText:SetJustifyH("LEFT")
    LastUpdatedText:SetTextColor(0.65, 0.65, 0.65)

    -- Character Header (Name-Realm)
    CharacterHeadingText = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    CharacterHeadingText:SetPoint("TOPLEFT", Portrait, "TOPRIGHT", 15, -5)
    CharacterHeadingText:SetJustifyH("LEFT")

    -- ========================================================================
    -- TOP SECTION GRAPHICS GRID
    -- ========================================================================
    
    TopLabelsText = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    TopLabelsText:SetPoint("TOPLEFT", CharacterPanel, "TOPLEFT", 105, -52)
    TopLabelsText:SetJustifyH("LEFT")
    TopLabelsText:SetTextColor(1, 1, 1)

    TopValuesText = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    TopValuesText:SetPoint("TOPLEFT", TopLabelsText, "TOPLEFT", 140, 0)
    TopValuesText:SetJustifyH("LEFT")

    -- Visual Separator line texture
    DividerLine = CharacterPanel:CreateTexture(nil, "ARTWORK")
    DividerLine:SetSize(parentWindow:GetWidth() - 40, 1)
    DividerLine:SetPoint("BOTTOMLEFT", CharacterPanel, "BOTTOMLEFT", 20, 165)
    DividerLine:SetColorTexture(0.5, 0.5, 0.5, 0.3) 

    -- ========================================================================
    -- BOTTOM SECTION GRAPHICS GRID (Account Totals)
    -- ========================================================================
    
    AccountTotalsHeading = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    AccountTotalsHeading:SetPoint("TOPLEFT", CharacterPanel, "TOPLEFT", 105, -240)
    AccountTotalsHeading:SetJustifyH("LEFT")
    AccountTotalsHeading:SetTextColor(1, 1, 1) 
    AccountTotalsHeading:SetText("Account Totals")

    BottomLabelsText = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    BottomLabelsText:SetPoint("TOPLEFT", AccountTotalsHeading, "BOTTOMLEFT", 0, -8)
    BottomLabelsText:SetJustifyH("LEFT")
    BottomLabelsText:SetTextColor(1, 1, 1) 

    BottomValuesText = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    BottomValuesText:SetPoint("TOPLEFT", BottomLabelsText, "TOPLEFT", 140, 0)
    BottomValuesText:SetJustifyH("LEFT")

    return CharacterPanel
end

function AlternateWorldCharacterView.ShowData(selectedCharacterKey)
    if not CharacterPanel or not AlternateWorldDB or not selectedCharacterKey then return end
    
    local data = AlternateWorldDB[selectedCharacterKey]
    if not data then return end
    
    local charLvl = data.level or 1
    CharacterHeadingText:SetText("|cFFFFFFFF" .. data.name .. " (Lvl " .. charLvl .. ") - " .. data.realm .. "|r")
    
    local timestamp = data.bagsUpdated or "Never"
    LastUpdatedText:SetText("Last updated: " .. timestamp)
    
    local classIconInline = AlternateWorldConfig.GetInlineClassIcon(data.classToken)
    local specIconInline = "|T" .. (data.specIcon or "Interface\\Icons\\Spell_Nature_Invisibilty") .. ":14:14:0:0|t "
    local goldText = GetMoneyString(data.money, true)
    
    local gearScoreEstimate = math.floor(data.itemLevel * 4.8)
    local highestGearScoreEstimate = math.floor(data.maxItemLevel * 4.8)

    local displaySpecText = data.specText or "Loading..."
    local displaySpecIcon = data.specIcon or "Interface\\Icons\\Spell_Nature_Invisibilty"
    
    if displaySpecText == "Loading..." then
        for key, savedData in pairs(AlternateWorldDB) do
            if key == selectedCharacterKey and savedData.specText and savedData.specText ~= "Loading..." then
                displaySpecText = savedData.specText
                displaySpecIcon = savedData.specIcon or displaySpecIcon
                break
            end
        end
    end
    specIconInline = "|T" .. displaySpecIcon .. ":14:14:0:0|t "

    local coloredFaction = "|cFFFFD700Unknown|r"
    if data.faction == "Alliance" then
        coloredFaction = "|cFF0070DDAlliance|r"
    elseif data.faction == "Horde" then
        coloredFaction = "|cFFC41F3BHorde|r"
    end

    TopLabelsText:SetText(
        "Class:\n" ..
        "Spec:\n" ..
        "Race:\n" ..
        "Faction:\n\n" .. 
        "Location:\n" ..
        "Money:\n" ..
        "Item Level:\n" ..
        "Gearscore (Est.):"
    )

    TopValuesText:SetText(
        classIconInline .. "|cFFFFD700" .. data.classNameLocal .. "|r\n" ..
        specIconInline .. "|cFFFFD700" .. displaySpecText .. "|r\n" ..
        "|cFFFFD700" .. data.race .. "|r\n" ..
        coloredFaction .. "\n\n" .. 
        "|cFFFFD700" .. (data.zone or "Unknown") .. "|r\n" ..
        goldText .. "\n" ..
        "|cFFFFD700" .. data.itemLevel .. " (Max: " .. data.maxItemLevel .. ")|r\n" ..
        "|cFFFFD700" .. gearScoreEstimate .. " (Max: " .. highestGearScoreEstimate .. ")|r"
    )
    
    local currentLocalKey = UnitName("player") .. " - " .. GetRealmName()
    if selectedCharacterKey == currentLocalKey then
        SetPortraitTexture(Portrait, "player")
        Portrait:SetTexCoord(0, 1, 0, 1) 
    else
        local raceToken = data.race or "Human"
        if raceToken == "Night Elf" then raceToken = "NightElf" end
        if raceToken == "Undead" then raceToken = "Scourge" end 
        
        local genderString = "Male"
        if data.gender == "Female" then genderString = "Female" end
        
        local fallbackPortraitPath = "Interface\\CharacterFrame\\TemporaryPortrait-" .. genderString .. "-" .. raceToken
        
        Portrait:SetTexture(fallbackPortraitPath)
        Portrait:SetTexCoord(0, 1, 0, 1) 
    end
    
    UpdateGlobalAccountStats()
    CharacterPanel:Show()
end

function AlternateWorldCharacterView.HidePanel()
    if CharacterPanel then CharacterPanel:Hide() end
end

function AlternateWorldCharacterView.IsShown()
    return CharacterPanel and CharacterPanel:IsShown()
end
