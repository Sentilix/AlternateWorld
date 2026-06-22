-- ============================================================================
-- Alternate World - Character View Module Panel
-- ============================================================================

AlternateWorldCharacterView = {}

local CharacterPanel = nil
local Portrait = nil
local CharacterHeadingText = nil
local CharacterInfoText = nil
local LastUpdatedText = nil 

function AlternateWorldCharacterView.CreatePanel(parentWindow)
    if CharacterPanel then return CharacterPanel end

    CharacterPanel = CreateFrame("Frame", nil, parentWindow)
    CharacterPanel:SetAllPoints(parentWindow)
    CharacterPanel:Hide() 

    Portrait = CharacterPanel:CreateTexture(nil, "ARTWORK")
    Portrait:SetSize(70, 70)
    Portrait:SetPoint("TOPLEFT", CharacterPanel, "TOPLEFT", 20, -20)

    -- FIXED: LastUpdatedText positioned strictly ABOVE the character heading, colored slate gray
    LastUpdatedText = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    LastUpdatedText:SetPoint("TOPLEFT", Portrait, "TOPRIGHT", 15, 10)
    LastUpdatedText:SetJustifyH("LEFT")
    LastUpdatedText:SetTextColor(0.65, 0.65, 0.65) -- Medium/Slate Gray tint to prevent text collisions

    CharacterHeadingText = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    CharacterHeadingText:SetPoint("TOPLEFT", Portrait, "TOPRIGHT", 15, -5)
    CharacterHeadingText:SetJustifyH("LEFT")

    CharacterInfoText = CharacterPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    CharacterInfoText:SetPoint("TOPLEFT", CharacterHeadingText, "BOTTOMLEFT", 0, -10)
    CharacterInfoText:SetJustifyH("LEFT")

    return CharacterPanel
end

function AlternateWorldCharacterView.ShowData(selectedCharacterKey)
    if not CharacterPanel or not AlternateWorldDB or not selectedCharacterKey then return end
    
    local data = AlternateWorldDB[selectedCharacterKey]
    if not data then return end
    
    CharacterHeadingText:SetText("|cFFFFFFFF" .. data.name .. " - " .. data.realm .. "|r")
    
    -- Read bag-update parameter as base proxy for profile snapshot state
    local timestamp = data.bagsUpdated or "Never"
    LastUpdatedText:SetText("Last updated: " .. timestamp)
    
    local classIconInline = AlternateWorldConfig.GetInlineClassIcon(data.classToken)
    local specIconInline = "|T" .. (data.specIcon or "Interface\\Icons\\Spell_Nature_Invisibilty") .. ":14:14:0:0|t "
    local goldText = GetMoneyString(data.money, true)
    
    local gearScoreEstimate = math.floor(data.itemLevel * 4.8)
    local highestGearScoreEstimate = math.floor(data.maxItemLevel * 4.8)

    CharacterInfoText:SetText(
        "|cFFFFFFFFClass:|r " .. classIconInline .. data.classNameLocal .. "\n" ..
        "|cFFFFFFFFSpec:|r " .. specIconInline .. data.specText .. "\n" ..
        "|cFFFFFFFFRace:|r " .. data.race .. "\n\n" ..
        "|cFFCA1A1ALocation:|r |cFFFFFFFF" .. (data.zone or "Unknown") .. "|r\n" ..
        "|cFFFFD700Money:|r " .. goldText .. "\n" ..
        "|cFF00CCFFItem Level:|r |cFFFFFFFF" .. data.itemLevel .. " (Max: " .. data.maxItemLevel .. ")|r\n" ..
        "|cFFBF00FFGearscore (Est.):|r |cFFFFFFFF" .. gearScoreEstimate .. " (Max: " .. highestGearScoreEstimate .. ")|r"
    )
    
    local currentLocalKey = UnitName("player") .. " - " .. GetRealmName()
    if selectedCharacterKey == currentLocalKey then
        SetPortraitTexture(Portrait, "player")
        Portrait:SetTexCoord(0, 1, 0, 1)
    else
        local raceToken = data.race or "Human"
        if raceToken == "Night Elf" then raceToken = "NightElf" end
        if raceToken == "Scourge" then raceToken = "Undead" end
        
        local genderString = data.gender or "Male"
        local fallbackPortraitPath = "Interface\\CharacterFrame\\TemporaryPortrait-" .. genderString .. "-" .. raceToken
        
        Portrait:SetTexture(fallbackPortraitPath)
        Portrait:SetTexCoord(0, 1, 0, 1)
    end
    
    CharacterPanel:Show()
end

function AlternateWorldCharacterView.HidePanel()
    if CharacterPanel then CharacterPanel:Hide() end
end

function AlternateWorldCharacterView.IsShown()
    return CharacterPanel and CharacterPanel:IsShown()
end
