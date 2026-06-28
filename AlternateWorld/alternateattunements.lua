-- ============================================================================
-- Alternate World - Attunements & Keys View Panel (v0.2.0 - PERFECT VERTICAL)
-- ============================================================================

AlternateWorldAttunementsView = {}

local AttunementsPanel = nil
local MainTitleText = nil
local LastUpdatedText = nil
local KeysTitleText = nil 
local UIEntries = {}

local RAID_DATA = {
    { key = "mc", name = "Molten Core", icon = "Interface\\Icons\\Spell_Fire_LavaSpawn", reqText = "Attunement to the Core (Quest)" },
    { key = "bwl", name = "Blackwing Lair", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_Black", reqText = "Attunement to Blackwing Lair (Quest)" },
    { key = "ony", name = "Onyxia's Lair", icon = "Interface\\Icons\\INV_Misc_Head_Dragon_01", reqText = "Drakefire Amulet (Necklace)" },
    { key = "naxx", name = "Naxxramas", icon = "Interface\\Icons\\INV_Jewelry_Necklace_19", reqText = "Argent Dawn Attunement (Reputation)" }
}

local DUNGEON_DATA = {
    { key = "brd", name = "Blackrock Depths", icon = "Interface\\Icons\\INV_Misc_Key_03", reqText = "Shadowforge Key" },
    { key = "scholo", name = "Scholomance", icon = "Interface\\Icons\\INV_Misc_Key_11", reqText = "The Skeleton Key" },
    { key = "strat", name = "Stratholme", icon = "Interface\\Icons\\INV_Misc_Key_14", reqText = "Key to the City" },
    { key = "ubrs", name = "UBRS (Upper Lair)", icon = "Interface\\Icons\\INV_Jewelry_Ring_01", reqText = "Seal of Ascension (Ring)" },
    { key = "mara", name = "Maraudon", icon = "Interface\\Icons\\INV_Staff_06", reqText = "Scepter of Celebras" },
    { key = "gnomer", name = "Gnomeregan", icon = "Interface\\Icons\\INV_Misc_Key_06", reqText = "Workshop Key" },
    { key = "dm", name = "Dire Maul", icon = "Interface\\Icons\\INV_Misc_Key_10", reqText = "Crescent Key" }
}

local DATA_KEY_MAP = {
    ["mc"] = "MC", ["bwl"] = "BWL", ["ony"] = "Onyxia", ["naxx"] = "Naxxramas",
    ["brd"] = "BRDKey", ["scholo"] = "ScholoKey", ["strat"] = "StratKey",
    ["ubrs"] = "UBRSKey", ["mara"] = "MaraKey", ["gnomer"] = "GnomereganKey", ["dm"] = "DMKey"
}

local function GetFormattedResetTime(expirationTimestamp)
    if not expirationTimestamp then return nil end
    local timeLeft = expirationTimestamp - time()
    if timeLeft <= 0 then return nil end
    local days = math.floor(timeLeft / 86400)
    local hours = math.floor((timeLeft % 86400) / 3600)
    if days > 0 then return string.format("%dd %dh", days, hours)
    else return string.format("%dh %dm", hours, math.floor((timeLeft % 3600) / 60)) end
end

local function BuildAttunementGrid(parentFrame, dataList, yAnchorOffset, attunementFlags, activeLockouts, isFirstSection)
    local BOX_SIZE = 74 
    local SPACING = 14
    local COLUMNS = 4 
    local lowestY = yAnchorOffset

    for i, raid in ipairs(dataList) do
        local keyID = raid.key
        local box = UIEntries[keyID]

        if not box then
            box = CreateFrame("Frame", nil, parentFrame)
            box:SetSize(BOX_SIZE, BOX_SIZE)

            box.Icon = box:CreateTexture(nil, "BACKGROUND")
            box.Icon:SetAllPoints(box)
            box.Icon:SetTexture(raid.icon)

            box.Label = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            box.Label:SetPoint("TOP", box, "BOTTOM", 0, -4)
            box.Label:SetText(raid.name)

            box.Border = box:CreateTexture(nil, "OVERLAY")
            box.Border:SetAllPoints(box)
            box.Border:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")

            box.Padlock = box:CreateTexture(nil, "OVERLAY", nil, 7)
            box.Padlock:SetSize(32, 32) 
            box.Padlock:SetPoint("CENTER", box, "CENTER", 0, 0)
            box.Padlock:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
            box.Padlock:SetTexCoord(0.50, 0.75, 0.25, 0.50) 
            box.Padlock:Hide()

            box:EnableMouse(true)
            UIEntries[keyID] = box
        end

        local row = math.floor((i - 1) / COLUMNS)
        local col = (i - 1) % COLUMNS
        
        local xPos = 20 + (col * (BOX_SIZE + SPACING))
        local startingTopMargin = isFirstSection and (yAnchorOffset - 42) or (yAnchorOffset - 25)
        local yPos = startingTopMargin - (row * (BOX_SIZE + SPACING + 15))
        
        box:ClearAllPoints()
        box:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", xPos, yPos)

        local dbToken = DATA_KEY_MAP[keyID] or keyID
        local isUnlocked = attunementFlags[dbToken] or false
        box.isAttuned = isUnlocked

        local lockoutExpiration = activeLockouts and activeLockouts[keyID]
        local lockTimeLeftStr = GetFormattedResetTime(lockoutExpiration)

        if lockTimeLeftStr then
            box.Padlock:Show()
            box.Icon:SetAlpha(1.0)
            box.Icon:SetVertexColor(0.65, 0.65, 0.65) 
            box.Icon:SetDesaturated(false)
        else
            box.Padlock:Hide()
            if isUnlocked then
                box.Icon:SetAlpha(1.0)
                box.Icon:SetVertexColor(1, 1, 1) 
                box.Icon:SetDesaturated(false) 
            else
                box.Icon:SetAlpha(0.35)
                box.Icon:SetVertexColor(0.8, 0.8, 0.8)
                box.Icon:SetDesaturated(true) 
            end
        end

        box:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(raid.name, 1, 1, 1)
            if self.isAttuned then GameTooltip:AddLine("Status: Attuned / key obtained", 0.2, 1, 0.2)
            else GameTooltip:AddLine("Status: Not attuned or no key obtained", 1, 0.2, 0.2) 
                if raid.reqText then GameTooltip:AddLine("Requires: " .. raid.reqText, 1, 0.5, 0) end
            end
            local currentLock = activeLockouts and activeLockouts[keyID]
            local liveTime = GetFormattedResetTime(currentLock)
            if liveTime then GameTooltip:AddLine("Raid Locked (ID Saved)", 1, 0.3, 0.3) GameTooltip:AddLine("Resets in: " .. liveTime, 0.6, 0.6, 1.0) end
            GameTooltip:Show()
        end)
        box:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
        
        box:Show()
        lowestY = math.min(lowestY, yPos - BOX_SIZE - 20)
    end
    return lowestY
end

function AlternateWorldAttunementsView.CreatePanel(parentWindow)
    if AttunementsPanel then return AttunementsPanel end

    AttunementsPanel = CreateFrame("Frame", "AWAttunementsPanelGlobal", parentWindow)
    AttunementsPanel:SetAllPoints(parentWindow)
    AttunementsPanel:Hide()

    MainTitleText = AttunementsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    MainTitleText:SetPoint("TOPLEFT", AttunementsPanel, "TOPLEFT", 20, -10)

    LastUpdatedText = AttunementsPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    LastUpdatedText:SetPoint("TOPLEFT", MainTitleText, "BOTTOMLEFT", 0, -2)

    KeysTitleText = AttunementsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    KeysTitleText:Hide()

    return AttunementsPanel
end

function AlternateWorldAttunementsView.ShowData(selectedCharacterKey)
    print(selectedCharacterKey or "nil");

    if not AttunementsPanel or not AlternateWorldDB or not selectedCharacterKey then return end
    local data = AlternateWorldDB[selectedCharacterKey]
    if not data then return end

    local charName = data.name or "Character"
    local genitiveName = charName .. "'s"
    if string.sub(charName, -1) == "s" or string.sub(charName, -1) == "S" then genitiveName = charName .. "'" end

    MainTitleText:SetText("|cFFFFFFFF" .. genitiveName .. " Raid Attunements|r")
    LastUpdatedText:SetText("Last updated: |cFF888888" .. (data.bagsUpdated or "Never") .. "|r")
    
    local attunementFlags = data.attunements or {}
    local activeLockouts = data.activeRaidIDs or {}

    for _, box in pairs(UIEntries) do box:Hide() end

    local raidsBottomY = BuildAttunementGrid(AttunementsPanel, RAID_DATA, -10, attunementFlags, activeLockouts, true)
    
    -- FIXED MATH SPACING: Subtracted 12px horizontally downward to drop the entire lower dungeon row group cleanly
    local correctedDungeonY = raidsBottomY - 12
    if KeysTitleText then
        KeysTitleText:SetPoint("TOPLEFT", AttunementsPanel, "TOPLEFT", 20, correctedDungeonY)
        KeysTitleText:SetText("|cFFFFFFFF" .. genitiveName .. " Dungeon Keys & Rings|r")
        KeysTitleText:Show()
    end

    BuildAttunementGrid(AttunementsPanel, DUNGEON_DATA, correctedDungeonY, attunementFlags, activeLockouts, false)

    AttunementsPanel:Show()
end

function AlternateWorldAttunementsView.OnUpdateTick(selectedCharacterKey) end
function AlternateWorldAttunementsView.HidePanel() if AttunementsPanel then AttunementsPanel:Hide() end end
function AlternateWorldAttunementsView.IsShown() return AttunementsPanel and AttunementsPanel:IsShown() end

-- End of [alternateattunements.lua]
