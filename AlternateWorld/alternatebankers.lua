-- ============================================================================
-- Alternate World - Bankers Data Engine Module (v0.3.0 - REBALANCED)
-- ============================================================================

AlternateWorldBankersEngine = {}

local BankersPanel = nil
local MainTitleText = nil
local SubTitleText = nil
local AllyHeaderLabel = nil
local HordeHeaderLabel = nil
local BankersScrollFrame = nil
local BankersScrollContent = nil

-- NEW v0.4.0 CLUSTER ROUTER: Determines whether to map data to a specific realm or a global cluster bucket
local function GetBankerRealmContext(realmName)
    if AlternateWorldDB and AlternateWorldDB.Settings and AlternateWorldDB.Settings.Clusters then
        local assignedCluster = AlternateWorldDB.Settings.Clusters[realmName]
        if assignedCluster then
            return assignedCluster -- Returns "cluster_1", "cluster_2", etc.
        end
    end
    return realmName -- Fallback to legacy single realm mapping if unassigned
end

function AlternateWorldBankersEngine.CleanClassColoredName(data)
    if not data or not data.name then return "Unknown" end
    local classColorHex = "|cFFFFFFFF"
    if data.classToken and RAID_CLASS_COLORS[data.classToken] then
        local c = RAID_CLASS_COLORS[data.classToken]
        classColorHex = string.format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
    end
    local serverLabel = data.realm and data.realm ~= "Unknown" and (" -|cFF888888" .. string.sub(string.gsub(data.realm, "%s+", ""), 1, 3) .. "|r") or ""
    return classColorHex .. data.name .. "|r" .. serverLabel
end

function AlternateWorldBankersEngine.GetSortedFactionKeys(targetFaction)
    local sortedKeys = {}
    if not AlternateWorldDB then return sortedKeys end
    
    -- FIXED v0.4.0 SCOPE FILTER: Resolve the active live player's cluster/realm family node first
    local currentRealm = GetRealmName()
    local liveContext = GetBankerRealmContext(currentRealm)

    for key, altData in pairs(AlternateWorldDB) do
        if key ~= "Settings" and altData and altData.name and altData.faction == targetFaction then
            -- Determine the scanned alt's cluster/realm context mapping safely
            local altRealm = altData.realm or "Unknown"
            local altContext = GetBankerRealmContext(altRealm)
            
            -- CLUSTER MATCH GUARD: Only populate the alt if it shares the exact same cluster family or identical unassigned realm
            if liveContext == altContext then
                table.insert(sortedKeys, key)
            end
        end
    end
    table.sort(sortedKeys)
    return sortedKeys
end

-- FIXED CENTRAL SETUP: Houses the clean core UI frame initialization matrix safely
function AlternateWorldBankersEngine.InitializeCorePanel(parentWindow)
    if BankersPanel then return BankersPanel, BankersScrollContent end

    BankersPanel = CreateFrame("Frame", "AWBankersPanelGlobal", parentWindow)
    BankersPanel:SetAllPoints(parentWindow)
    BankersPanel:Hide()

    MainTitleText = BankersPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    MainTitleText:SetPoint("TOPLEFT", BankersPanel, "TOPLEFT", 20, -10)
    MainTitleText:SetText("|cFFFFFFFFAccount Bankers Manager|r")

    SubTitleText = BankersPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    SubTitleText:SetPoint("TOPLEFT", MainTitleText, "BOTTOMLEFT", 0, -2)
    SubTitleText:SetText("Assign designated warehouse managers scoped per Realm for both factions")

    AllyHeaderLabel = BankersPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    AllyHeaderLabel:SetPoint("TOPLEFT", BankersPanel, "TOPLEFT", 180, -65)
    AllyHeaderLabel:SetText("|TInterface\\TargetingFrame\\UI-PVP-Alliance:12:12:0:0:64:64:0:38:0:38|t |cFF0070DDAlliance Bankers|r")

    HordeHeaderLabel = BankersPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    HordeHeaderLabel:SetPoint("TOPLEFT", BankersPanel, "TOPLEFT", 325, -65)
    HordeHeaderLabel:SetText("|TInterface\\TargetingFrame\\UI-PVP-Horde:12:12:0:0:64:64:0:38:0:38|t |cFFFF0000Horde Bankers|r")

    BankersScrollFrame = CreateFrame("ScrollFrame", "AW_BankersScrollFrameInstance", BankersPanel, "UIPanelScrollFrameTemplate")
    BankersScrollFrame:SetPoint("TOPLEFT", BankersPanel, "TOPLEFT", 0, -85)
    BankersScrollFrame:SetPoint("BOTTOMRIGHT", BankersPanel, "BOTTOMRIGHT", -30, 15)

    BankersScrollContent = CreateFrame("Frame", nil, BankersScrollFrame)
    BankersScrollContent:SetSize(BankersPanel:GetWidth() - 40, 1)
    BankersScrollFrame:SetScrollChild(BankersScrollContent)

    return BankersPanel, BankersScrollContent
end

function AlternateWorldBankersEngine.SetCategoryBanker(realmName, faction, categoryID, characterKey)
    if not AlternateWorldDB then return end
    if not AlternateWorldDB.Settings then AlternateWorldDB.Settings = {} end
    if not AlternateWorldDB.Settings.Bankers then AlternateWorldDB.Settings.Bankers = {} end

    -- FIXED v0.4.0: Context shifts instantly to cluster key if the realm belongs to a family
    local contextKey = GetBankerRealmContext(realmName)

    if not AlternateWorldDB.Settings.Bankers[contextKey] then 
        AlternateWorldDB.Settings.Bankers[contextKey] = {} 
    end
    if not AlternateWorldDB.Settings.Bankers[contextKey][faction] then 
        AlternateWorldDB.Settings.Bankers[contextKey][faction] = {} 
    end

    AlternateWorldDB.Settings.Bankers[contextKey][faction][categoryID] = characterKey
end

function AlternateWorldBankersEngine.GetCategoryBanker(realmName, faction, categoryID)
    if not AlternateWorldDB or not AlternateWorldDB.Settings or not AlternateWorldDB.Settings.Bankers then 
        return nil 
    end

    -- FIXED v0.4.0: Sweeps the global cluster bucket dynamically for sibling realms synergy
    local contextKey = GetBankerRealmContext(realmName)

    local realmData = AlternateWorldDB.Settings.Bankers[contextKey]
    local factionData = realmData and realmData[faction]
    return factionData and factionData[categoryID] or nil
end

-- End of [alternatebankers.lua]
