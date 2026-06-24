-- ============================================================================
-- Alternate World - Global Rested XP Real-Time Time-Calculated Panel (v0.3.0)
-- ============================================================================

AlternateWorldRestedXPView = {}

local RestedXPPanel = nil
local MainTitleText = nil
local SubTitleText = nil
local ScrollFrame = nil
local ScrollContent = nil

local AW_RestedRowsPool = {}
local ROW_HEIGHT = 28

-- Helper function: Converts stored ISO date strings ("YYYY-MM-DD HH:MM") safely into raw Unix seconds
local function ParseISOStringToSeconds(dateStr)
    if not dateStr or dateStr == "Never" or dateStr == "Unknown" then return nil end
    local y, m, d, h, min = string.match(dateStr, "(%d+)-(%d+)-(%d+)%s+(%d+):(%d+)")
    if not y then return nil end
    return time({year=tonumber(y), month=tonumber(m), day=tonumber(d), hour=tonumber(h), min=tonumber(min)})
end

function AlternateWorldRestedXPView.CreatePanel(parentWindow)
    if RestedXPPanel then return RestedXPPanel end

    RestedXPPanel = CreateFrame("Frame", "AWRestedXPPanelGlobal", parentWindow)
    RestedXPPanel:SetAllPoints(parentWindow)
    RestedXPPanel:Hide()

    MainTitleText = RestedXPPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    MainTitleText:SetPoint("TOPLEFT", RestedXPPanel, "TOPLEFT", 20, -10)
    MainTitleText:SetText("|cFFFFFFFFGlobal Rested XP Ledger|r")

    SubTitleText = RestedXPPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    SubTitleText:SetPoint("TOPLEFT", MainTitleText, "BOTTOMLEFT", 0, -2)
    SubTitleText:SetText("Active leveling alts (LvL 10-59) sorted by Favourites > Live Predicted Rested XP %")

    ScrollFrame = CreateFrame("ScrollFrame", "AW_RestedScrollFrameInstance", RestedXPPanel, "UIPanelScrollFrameTemplate")
    ScrollFrame:SetPoint("TOPLEFT", SubTitleText, "BOTTOMLEFT", 0, -15)
    ScrollFrame:SetPoint("BOTTOMRIGHT", RestedXPPanel, "BOTTOMRIGHT", -30, 15)

    ScrollContent = CreateFrame("Frame", nil, ScrollFrame)
    ScrollContent:SetSize(RestedXPPanel:GetWidth() - 40, 1)
    ScrollFrame:SetScrollChild(ScrollContent)

    return RestedXPPanel
end

function AlternateWorldRestedXPView.ShowData(selectedCharacterKey)
    if not RestedXPPanel or not AlternateWorldDB then return end
    RestedXPPanel:Show()

    for _, row in ipairs(AW_RestedRowsPool) do row:Hide() if row.Bar then row.Bar:Hide() end if row.FavBtn then row.FavBtn:Hide() end end

    local leaderboard = {}
    local nowSeconds = time()

    for dbKey, c in pairs(AlternateWorldDB) do
        local currentLevel = c.level or 1
        if c.name and currentLevel >= 10 and currentLevel <= 59 then
            local rXP = c.restedXP or 0
            local mXP = c.maxXP or 1
            local basePct = (rXP / mXP) * 100
            
            -- Step 1: Compute real-time offline time differences mathematically
            local liveComputedPct = basePct
            local scanTimeSeconds = ParseISOStringToSeconds(c.bagsUpdated)
            
            if scanTimeSeconds and nowSeconds > scanTimeSeconds then
                local secondsOffline = nowSeconds - scanTimeSeconds
                
                -- Step 2: Apply vanilla rest calculation formulas tick rates coefficients
                local percentPerSecond = 0.00004340277 -- Vildmark rate (1.25% per 8 hours)
                if c.isResting then
                    percentPerSecond = 0.00017361111 -- Kro rate (5% per 8 hours)
                end
                
                local accumulatedBonus = secondsOffline * percentPerSecond
                liveComputedPct = basePct + accumulatedBonus
            end
            
            -- Step 3: Enforce native Blizzard 150.0% capping threshold rules
            if liveComputedPct > 150 then liveComputedPct = 150 end
            liveComputedPct = math.floor(liveComputedPct * 10 + 0.5) / 10

            table.insert(leaderboard, {
                key = dbKey,
                name = c.name,
                realm = c.realm or "Unknown",
                level = currentLevel,
                class = c.classToken or "WARRIOR",
                faction = c.faction or "Alliance",
                restedPct = liveComputedPct,
                isResting = c.isResting or false,
                isFavourite = c.isFavourite or false
            })
        end
    end
    
    table.sort(leaderboard, function(a, b)
        if a.isFavourite ~= b.isFavourite then return a.isFavourite and not b.isFavourite
        elseif a.restedPct ~= b.restedPct then return a.restedPct > b.restedPct
        else return a.level > b.level end
    end)

    local currentYOffset, count = -5, 0
    for i, alt in ipairs(leaderboard) do
        count = count + 1
        local row = AW_RestedRowsPool[count]
        if not row then
            row = CreateFrame("Frame", nil, ScrollContent)
            row:SetSize(ScrollContent:GetWidth(), ROW_HEIGHT)
            
            row.Text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            row.Text:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -8)
            row.Text:SetJustifyH("LEFT")
            
            row.Bar = CreateFrame("StatusBar", nil, row)
            row.Bar:SetSize(180, 12)
            
            local barTex = row.Bar:CreateTexture(nil, "BACKGROUND")
            barTex:SetAllPoints(row.Bar)
            barTex:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
            row.Bar:SetStatusBarTexture(barTex)
            row.Bar:SetStatusBarColor(0.0, 0.39, 0.88, 1.0)
            
            local bgTex = row.Bar:CreateTexture(nil, "BORDER")
            bgTex:SetAllPoints(row.Bar)
            bgTex:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
            bgTex:SetVertexColor(0.0, 0.1, 0.3, 0.6)
            
            row.Bar.PctText = row.Bar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmallOutline")
            row.Bar.PctText:SetPoint("CENTER", row.Bar, "CENTER", 0, 0)

            row.FavBtn = CreateFrame("Button", nil, row)
            row.FavBtn:SetSize(14, 14)
            row.FavBtn:SetPoint("LEFT", row.Bar, "RIGHT", 8, 0)
            
            row.FavBtn.Icon = row.FavBtn:CreateTexture(nil, "OVERLAY")
            row.FavBtn.Icon:SetAllPoints(row.FavBtn)
            row.FavBtn:SetNormalTexture(row.FavBtn.Icon)
            
            row.FavBtn:SetScript("OnEnter", function(self)
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetText("Mark as favourite", 1, 1, 1)
                GameTooltip:Show()
            end)
            row.FavBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

            AW_RestedRowsPool[count] = row
        end

        if count == 1 then row:SetPoint("TOPLEFT", ScrollContent, "TOPLEFT", 0, -5)
        else row:SetPoint("TOPLEFT", AW_RestedRowsPool[count - 1], "BOTTOMLEFT", 0, -6) end

        row.Bar:ClearAllPoints()
        row.Bar:SetPoint("LEFT", row.Text, "LEFT", 175, 0)

        local shortenedRealm = ""
        if alt.realm and alt.realm ~= "Unknown" then
            local cleanRealm = string.gsub(alt.realm, "%s+", "")
            shortenedRealm = "-|cFF888888" .. string.sub(cleanRealm, 1, 3) .. "|r"
        end

        local factIcon = alt.faction == "Horde" and "|TInterface\\TargetingFrame\\UI-PVP-Horde:14:14:0:0:64:64:0:38:0:38|t " or "|TInterface\\TargetingFrame\\UI-PVP-Alliance:14:14:0:0:64:64:0:38:0:38|t "
        local hex = "|cFFFFFFFF"
        if alt.class and RAID_CLASS_COLORS[alt.class] then
            local c = RAID_CLASS_COLORS[alt.class]
            hex = string.format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
        end

        local innStamp = alt.isResting and " |cFF1EFF00[Zzz]|r" or ""
        row.Text:SetText(string.format("%s%s%s%s|r  |cFFFFFFFF(%d)|r%s", factIcon, hex, alt.name, shortenedRealm, alt.level, innStamp))

        row.Bar:SetMinMaxValues(0, 150)
        row.Bar:SetValue(alt.restedPct)
        row.Bar:Show()

        if alt.restedPct >= 150 then row.Bar.PctText:SetText(string.format("|cFF00FFFF%.1f%%|r", alt.restedPct))
        else row.Bar.PctText:SetText(string.format("%.1f%%", alt.restedPct)) end

        if alt.isFavourite then
            row.FavBtn.Icon:SetTexture("Interface\\Icons\\inv_misc_coin_17")
        else
            row.FavBtn.Icon:SetTexture("Interface\\Icons\\inv_misc_coin_18")
        end

        row.FavBtn:SetScript("OnClick", function()
            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
            if AlternateWorldDB[alt.key] then
                AlternateWorldDB[alt.key].isFavourite = not AlternateWorldDB[alt.key].isFavourite
                GameTooltip:Hide()
                AlternateWorldRestedXPView.ShowData(selectedCharacterKey)
            end
        end)
        
        row.FavBtn:Show()
        row:Show()
        currentYOffset = currentYOffset - ROW_HEIGHT - 6
    end

    ScrollContent:SetHeight(math.abs(currentYOffset) + ROW_HEIGHT)
end

function AlternateWorldRestedXPView.HidePanel() if RestedXPPanel then RestedXPPanel:Hide() end end
function AlternateWorldRestedXPView.IsShown() return RestedXPPanel and RestedXPPanel:IsShown() end

-- End of [alternaterestedxp.lua]
