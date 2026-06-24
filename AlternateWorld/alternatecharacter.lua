-- ============================================================================
-- Alternate World - Character Profile Data Engine (v0.3.0 - GLOBAL REALMS)
-- ============================================================================

AlternateWorldCharacterEngine = {}

function AlternateWorldCharacterEngine.FormatMoneyString(copperCoins)
    local gold = math.floor(copperCoins / 10000)
    local silver = math.floor((copperCoins % 10000) / 100)
    local copper = copperCoins % 100
    return string.format("|cFFFFD700%dg|r |cFFC0C0C0%ds|r |cFFB87333%dc|r", gold, silver, copper)
end

function AlternateWorldCharacterEngine.CalculateAccountTotals()
    local totals = { allyGold = 0, hordeGold = 0, allyChars = 0, hordeChars = 0, ally60s = 0, horde60s = 0 }
    if not AlternateWorldDB then return totals end
    
    -- FIXED: Bypassed the realm restriction constraint to calculate a true account-wide ledger
    for _, loopChar in pairs(AlternateWorldDB) do
        if loopChar.faction == "Alliance" then
            totals.allyGold = totals.allyGold + (loopChar.money or 0)
            totals.allyChars = totals.allyChars + 1
            if loopChar.level == 60 then totals.ally60s = totals.ally60s + 1 end
        elseif loopChar.faction == "Horde" then
            totals.hordeGold = totals.hordeGold + (loopChar.money or 0)
            totals.hordeChars = totals.hordeChars + 1
            if loopChar.level == 60 then totals.horde60s = totals.horde60s + 1 end
        end
    end
    return totals
end

function AlternateWorldCharacterEngine.ProcessShowData(selectedCharacterKey, elements, pool)
    if not AlternateWorldDB or not selectedCharacterKey or not elements then return end
    local data = AlternateWorldDB[selectedCharacterKey]
    if not data then return end

    if elements.LastUpdateText then
        elements.LastUpdateText:SetText("Last Update: |cFF888888" .. (data.bagsUpdated or "Unknown") .. "|r")
    end

    if elements.DefaultPortrait2D then
        elements.DefaultPortrait2D:SetTexture("Interface\\CharacterFrame\\TemporaryPortrait")
        if data.name == UnitName("player") then SetPortraitTexture(elements.DefaultPortrait2D, "player") end
    end

    local classColorHex = "|cFFFFFFFF"
    if data.classToken and RAID_CLASS_COLORS[data.classToken] then
        local c = RAID_CLASS_COLORS[data.classToken]
        classColorHex = string.format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
    end

    if elements.DetailLine1 then
        elements.DetailLine1:SetText(classColorHex .. data.name .. "|r  |cFF888888-|r  |cFFFFFFFF" .. (data.realm or "Unknown") .. "|r")
    end

    if elements.ClassIconTexture and data.classToken and AlternateWorldConstants and AlternateWorldConstants.CLASS_COORDS[data.classToken] then
        local coords = AlternateWorldConstants.CLASS_COORDS[data.classToken]
        elements.ClassIconTexture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
        elements.ClassIconTexture:SetTexCoord(coords, coords, coords, coords)
        elements.ClassIconTexture:Show()
    else
        if elements.ClassIconTexture then elements.ClassIconTexture:Hide() end
    end

    if elements.DetailLine2 then
        local factionColored = data.faction == "Alliance" and "|cFF0070DDAlliance|r" or "|cFFFF0000Horde|r"
        elements.DetailLine2:SetText((data.race or "Unknown") .. " " .. (data.gender or "Female") .. " " .. classColorHex .. (data.classNameLocal or "Character") .. "|r of the " .. factionColored .. "  |cFFFFFFFF(Level " .. (data.level or 60) .. ")|r")
    end

    if data.specIcon and elements.SpecIconTexture and elements.SpecTextString then
        elements.SpecIconTexture:SetTexture(data.specIcon)
        elements.SpecIconTexture:Show()
        elements.SpecTextString:SetText(string.format("|cFFFFFFFF%s|r", data.specText or "Fury (0/51/0)"))
    elseif elements.SpecIconTexture and elements.SpecTextString then
        elements.SpecIconTexture:Hide()
        elements.SpecTextString:SetText("|cFF888888No Specialization Allocations|r")
    end

    local currentIlvl = data.itemLevel or 0
    local maxIlvl = data.maxItemLevel or 0
    local formattedMoney = AlternateWorldCharacterEngine.FormatMoneyString(data.money or 0)
    if elements.InfoTextLeft then
        elements.InfoTextLeft:SetText(string.format("Gold: %s\n\nItem Level: |cFFFFFFFF%.1f|r  |cFF888888(Max: %.1f)|r\n\nZone: |cFFFFFFFF%s|r", formattedMoney, currentIlvl, maxIlvl, data.zone or "Unknown"))
    end

    -- FIXED: Removed the realm filter reference parameter from the master calculation call
    local t = AlternateWorldCharacterEngine.CalculateAccountTotals()
    if elements.AccountTotalsLeft and elements.AccountTotalsRight then
        elements.AccountTotalsLeft:SetText(string.format("Gold, Alliance: %s\nGold, Horde: %s\nGold, Total: %s", AlternateWorldCharacterEngine.FormatMoneyString(t.allyGold), AlternateWorldCharacterEngine.FormatMoneyString(t.hordeGold), AlternateWorldCharacterEngine.FormatMoneyString(t.allyGold + t.hordeGold)))
        elements.AccountTotalsRight:SetText(string.format("Chars, Alliance: |cFFFFFFFF%d|r  |cFF888888(lvl 60: %d)|r\nChars, Horde: |cFFFFFFFF%d|r  |cFF888888(lvl 60: %d)|r\nChars, Total: |cFFFFFFFF%d|r  |cFF888888(lvl 60: %d)|r", t.allyChars, t.ally60s, t.hordeChars, t.horde60s, t.allyChars + t.hordeChars, t.ally60s + t.horde60s))
    end

    if elements.DeleteCharButton then
        if data.name == UnitName("player") then elements.DeleteCharButton:Disable()
        else
            elements.DeleteCharButton:Enable()
            elements.DeleteCharButton:SetScript("OnClick", function()
                StaticPopup_Show("AW_CONFIRM_DELETE_PROFILE", nil, nil, { targetKey = selectedCharacterKey })
            end)
        end
    end

    for _, line in ipairs(pool) do line:Hide() line.Icon:Hide() line.Text:SetText("") end
    local foundProfessions = {}
    if data.professions then
        for profName, profData in pairs(data.professions) do
            table.insert(foundProfessions, { name = profName, level = profData.level or 0, maxLevel = profData.maxLevel or 0 })
        end
    end
    table.sort(foundProfessions, function(a, b) return a.name < b.name end)

    for i, profObj in ipairs(foundProfessions) do
        local lineFrame = pool[i]
        if not lineFrame and elements.Panel then
            lineFrame = CreateFrame("Frame", nil, elements.Panel)
            lineFrame:SetSize(220, 16)
            if i == 1 then lineFrame:SetPoint("TOPLEFT", elements.Panel, "TOPLEFT", 240, -115)
            else lineFrame:SetPoint("TOPLEFT", pool[i - 1], "BOTTOMLEFT", 0, -8) end
            
            lineFrame.Icon = lineFrame:CreateTexture(nil, "OVERLAY")
            lineFrame.Icon:SetSize(14, 14)
            lineFrame.Icon:SetPoint("LEFT", lineFrame, "LEFT", 0, 0)
            
            lineFrame.Text = lineFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lineFrame.Text:SetPoint("LEFT", lineFrame.Icon, "RIGHT", 6, 0)
            lineFrame.Text:SetJustifyH("LEFT")
            pool[i] = lineFrame
        end
        if lineFrame then
            if AlternateWorldProfEngine then lineFrame.Icon:SetTexture(AlternateWorldProfEngine.GetProfessionIconTexture(profObj.name)) lineFrame.Icon:Show() end
            lineFrame.Text:SetText(string.format("%s: |cFFFFFFFF%d/%d|r", profObj.name, profObj.level, profObj.maxLevel))
            lineFrame:Show()
        end
    end
end

-- End of [alternatecharacter.lua]
