-- ============================================================================
-- Alternate World - Bankers User Interface Layout Module (v0.4.0)
-- ============================================================================

AlternateWorldBankersView = {}

local AW_BankerRowsPool = {}
local ROW_HEIGHT = 32

local BANKER_CATEGORIES = {
    { id = "Tailoring", name = "Tailoring", icon = "interface\\icons\\trade_tailoring" },
    { id = "Mining", name = "Ores & Bars", icon = "interface\\icons\\trade_mining" },
    { id = "Gems", name = "Gems & Stones", icon = "interface\\icons\\inv_misc_gem_emerald_02" },
    { id = "Enchanting", name = "Enchanting", icon = "interface\\icons\\trade_engraving" },
    { id = "Herbalism", name = "Herbs", icon = "interface\\icons\\spell_nature_naturetouchgrow" },
    { id = "Skinning", name = "Leather & Hides", icon = "interface\\icons\\inv_misc_pelt_wolf_01" },
    { id = "MiscMats", name = "Materials", icon = "interface\\icons\\inv_summerfest_firepotion" },
    { id = "Consumables", name = "Consumables", icon = "interface\\icons\\inv_misc_food_99" },
    { id = "QuestItems", name = "Quest items", icon = "interface\\icons\\achievement_quests_completed_06" },
    { id = "Reputation", name = "Reputation", icon = "interface\\icons\\achievement_reputation_01" },
    { id = "Gear", name = "Gear", icon = "interface\\icons\\inv_sword_29" },
    { id = "Recipes", name = "Patterns", icon = "interface\\icons\\inv_scroll_06" },
    { id = "Lockboxes", name = "Lockboxes", icon = "interface\\icons\\inv_box_03" }
}

-- FIXED v0.6.0 CATEGORY DROPDOWN MATRIX: Hierarchical matrix inside dropdown, full context on the main button
local function InitializeCategoryDropdown(self, faction, categoryID, dropdownMenuFrame, contextRealm)
    if not AlternateWorldDB or not AlternateWorldBankersEngine then return end
    
    local rawAlts = {}
    local mustIsolate = AlternateWorldDB.Settings and AlternateWorldDB.Settings.IsolateSingleRealms
    local assignedCluster = AlternateWorldDB.Settings and AlternateWorldDB.Settings.Clusters and AlternateWorldDB.Settings.Clusters[contextRealm]
    
    -- 1. EXTRACT DATA STRICTLY FILTERED BY YOUR SYSTEM INTERACTION POLICIES
    if assignedCluster then
        for key, altData in pairs(AlternateWorldDB) do
            if key ~= "Settings" and altData and altData.name and altData.faction == faction then
                local altRealm = altData.realm or "Unknown"
                local altCluster = AlternateWorldDB.Settings.Clusters and AlternateWorldDB.Settings.Clusters[altRealm]
                if altCluster == assignedCluster then
                    table.insert(rawAlts, altData)
                end
            end
        end
    elseif mustIsolate then
        for key, altData in pairs(AlternateWorldDB) do
            if key ~= "Settings" and altData and altData.name and altData.faction == faction then
                if (altData.realm or "Unknown") == contextRealm then
                    table.insert(rawAlts, altData)
                end
            end
        end
    else
        for key, altData in pairs(AlternateWorldDB) do
            if key ~= "Settings" and altData and altData.name and altData.faction == faction then
                table.insert(rawAlts, altData)
            end
        end
    end

    -- 2. SORT THE COLLECTED DATA EXPLICITLY BY REALM -> CHARACTER NAME
    table.sort(rawAlts, function(a, b)
        local aRealm = a.realm or ""
        local bRealm = b.realm or ""
        if aRealm ~= bRealm then return aRealm < bRealm end
        return (a.name or "") < (b.name or "")
    end)

    -- 3. INITIALIZE DROPDOWN BASE ELEMENT
    local info = UIDropDownMenu_CreateInfo()
    info.text = "|cFF888888(None assigned)|r"
    info.value = "none"
    info.isTitle = false
    info.disabled = false
    
    local activeBanker = AlternateWorldBankersEngine.GetCategoryBanker(contextRealm, faction, categoryID)
    info.checked = (activeBanker == nil)
    info.func = function()
        AlternateWorldBankersEngine.SetCategoryBanker(contextRealm, faction, categoryID, nil)
        UIDropDownMenu_SetText(dropdownMenuFrame, "|cFF888888(None assigned)|r")
    end
    UIDropDownMenu_AddButton(info)

    local lastSeenRealm = nil

    -- 4. INJECT STRUCTURAL RENDERING ROWS WITH BLANK SPACERS AND INDENTED NAMES
    for _, altData in ipairs(rawAlts) do
        local exactRealm = altData.realm or "Unknown Realm"
        local altKey = altData.name .. " - " .. exactRealm

        -- GENERATE REALM HEADER ROW WITH INTERMITTENT BLANK SPACERS
        if exactRealm ~= lastSeenRealm then
            if lastSeenRealm ~= nil then
                info.text = " "
                info.value = nil
                info.arg1 = nil
                info.isTitle = true
                info.disabled = true
                info.checked = false
                UIDropDownMenu_AddButton(info)
            end
            
            lastSeenRealm = exactRealm
            
            info.text = "|cFFFFFFFF" .. exactRealm .. "|r"
            info.value = nil
            info.arg1 = nil
            info.isTitle = true 
            info.disabled = true
            info.checked = false
            UIDropDownMenu_AddButton(info)
        end

        -- GENERATE ACTUAL CHARACTER ROW WITH EXPLICIT HORIZONTAL TEXT INDENTATION
        local rawCharName = altData.name or "Unknown"
        local classColorHex = "|cFFFFFFFF"
        
        if altData.isVirtual then
            classColorHex = AlternateWorldConstants.VIRTUAL_BANKER_COLOR_HEX
        elseif altData.classToken and RAID_CLASS_COLORS[altData.classToken] then
            local c = RAID_CLASS_COLORS[altData.classToken]
            classColorHex = string.format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
        end
        
        -- Keeps the internal dropdown list rows clean and suffix-free under their headers
        info.text = "   " .. classColorHex .. rawCharName .. "|r"
        info.value = altKey
        info.arg1 = altKey
        info.isTitle = false
        info.disabled = false
        info.checked = (activeBanker == altKey)
        info.padding = nil 
        
        info.func = function(button)
            local targetKey = button.arg1
            AlternateWorldBankersEngine.SetCategoryBanker(contextRealm, faction, categoryID, targetKey)
            
            -- FIXED v0.6.0 DISPLAY SYMMETRY: Enforces the full engine routine to show server suffixes on the front button instantly
            local fullColoredEngineName = AlternateWorldBankersEngine.CleanClassColoredName(altData)
            UIDropDownMenu_SetText(dropdownMenuFrame, fullColoredEngineName)
        end
        
        UIDropDownMenu_AddButton(info)
    end
end

function AlternateWorldBankersView.ShowData(selectedCharacterKey)
    local parentWindow = AlternateWorldMainContentWindow
    if not parentWindow or not AlternateWorldBankersEngine then return end

    local panel, scrollContent = AlternateWorldBankersEngine.InitializeCorePanel(parentWindow)
    if not panel or not scrollContent then return end

    local contextRealm = selectedCharacterKey and string.match(selectedCharacterKey, "%s*-%s*(.+)") or GetRealmName()
    panel.activeContextRealmCache = contextRealm

    local mustIsolate = AlternateWorldDB.Settings and AlternateWorldDB.Settings.IsolateSingleRealms
    local assignedCluster = AlternateWorldDB.Settings.Clusters and AlternateWorldDB.Settings.Clusters[contextRealm]

    -- 1. Create Checkbox first to establish the anchor root safely
    local IsolateCB = _G["AW_BankersIsolateCheckbox"]
    if not IsolateCB then
        IsolateCB = CreateFrame("CheckButton", "AW_BankersIsolateCheckbox", panel, "InterfaceOptionsCheckButtonTemplate")
        IsolateCB:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -53)
        _G[IsolateCB:GetName() .. "Text"]:SetText("Restrict bankers to local realm or cluster")
        
        IsolateCB:SetScript("OnClick", function(self)
            if AlternateWorldDB and AlternateWorldDB.Settings then
                AlternateWorldDB.Settings.IsolateSingleRealms = self:GetChecked() and true or false
                AlternateWorldBankersView.RefreshActiveDropdowns(panel.activeContextRealmCache)
            end
        end)

        IsolateCB:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine("|cFFFFFFFFRestrict Banker Dropdowns|r")
            GameTooltip:AddLine("|cFFFFD100When enabled, lists are strictly limited to characters from your current realm, or siblings inside your custom cluster.|r", 1, 1, 1, true)
            GameTooltip:AddLine("|cFF888888Disable this to keep legacy behavior and view all characters across your entire account.|r", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        IsolateCB:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    -- 2. FIXED ANCHOR LOGIC: Instantiate or fetch Faction strings attached safely directly below the checkbox frame object
    local AllyHeaderLabel = panel.AllyHeaderLabel
    local HordeHeaderLabel = panel.HordeHeaderLabel
    if not AllyHeaderLabel then
        AllyHeaderLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        AllyHeaderLabel:SetPoint("TOPLEFT", IsolateCB, "BOTTOMLEFT", 160, -12) -- Anchors flawlessly 12px below checkbox
        AllyHeaderLabel:SetText("|TInterface\\TargetingFrame\\UI-PVP-Alliance:12:12:0:0:64:64:0:38:0:38|t |cFF0070DDAlliance Bankers|r")
        panel.AllyHeaderLabel = AllyHeaderLabel

        HordeHeaderLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        HordeHeaderLabel:SetPoint("TOPLEFT", AllyHeaderLabel, "TOPRIGHT", 25, 0) -- Anchors directly to the right of alliance string
        HordeHeaderLabel:SetText("|TInterface\\TargetingFrame\\UI-PVP-Horde:12:12:0:0:64:64:0:38:0:38|t |cFFFF0000Horde Bankers|r")
        panel.HordeHeaderLabel = HordeHeaderLabel
    end

    -- 3. Title Engine
    local MainTitleText = _G["AWBankersPanelGlobal"] and _G["AWBankersPanelGlobal"].MainTitleText or panel.MainTitleText
    if MainTitleText then
        if assignedCluster then
            local customClusterName = AlternateWorldDB.Settings.ClusterNames and AlternateWorldDB.Settings.ClusterNames[assignedCluster] or "Cluster"
            MainTitleText:SetText(string.format("|cFFFFFFFFBankers on %s|r", customClusterName))
        elseif not mustIsolate then
            MainTitleText:SetText("|cFFFFFFFFBank Managers|r")
        else
            MainTitleText:SetText(string.format("|cFFFFFFFFBankers on %s|r", contextRealm))
        end
    end
    
    if assignedCluster then
        IsolateCB:SetChecked(true)
        IsolateCB:Disable()
        _G[IsolateCB:GetName() .. "Text"]:SetTextColor(0.5, 0.5, 0.5)
    else
        IsolateCB:SetChecked(mustIsolate)
        IsolateCB:Enable()
        _G[IsolateCB:GetName() .. "Text"]:SetTextColor(1.0, 0.82, 0)
    end

    panel:Show()

    local scrollFrame = _G["AW_BankersScrollFrameInstance"]
    if scrollFrame then
        scrollFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -115)
    end

    for _, line in ipairs(AW_BankerRowsPool) do line:Hide() end

    local currentYOffset = -5
    for count, cat in ipairs(BANKER_CATEGORIES) do
        local row = AW_BankerRowsPool[count]
        if not row then
            row = CreateFrame("Frame", "AW_BankerRowLineInstance" .. count, scrollContent)
            row:SetSize(scrollContent:GetWidth(), ROW_HEIGHT)

            row.Icon = row:CreateTexture(nil, "OVERLAY")
            row.Icon:SetSize(20, 20)
            row.Icon:SetPoint("LEFT", row, "LEFT", 15, 0)

            row.Label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.Label:SetPoint("LEFT", row.Icon, "RIGHT", 10, 0)
            row.Label:SetJustifyH("LEFT")

            row.AllyMenu = CreateFrame("Frame", "AW_BankerAllyDropdown" .. count, row, "UIDropDownMenuTemplate")
            row.AllyMenu:SetPoint("LEFT", row, "LEFT", 145, -2)
            UIDropDownMenu_SetWidth(row.AllyMenu, 110)

            row.HordeMenu = CreateFrame("Frame", "AW_BankerHordeDropdown" .. count, row, "UIDropDownMenuTemplate")
            row.HordeMenu:SetPoint("LEFT", row.AllyMenu, "RIGHT", -15, 0)
            UIDropDownMenu_SetWidth(row.HordeMenu, 110)

            AW_BankerRowsPool[count] = row
        end

        if count == 1 then row:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 0, -5)
        else row:SetPoint("TOPLEFT", AW_BankerRowsPool[count - 1], "BOTTOMLEFT", 0, -2) end

        row.Icon:SetTexture(cat.icon)
        row.Label:SetText("|cFFFFFFFF" .. cat.name .. "|r")

        local allyAssignedKey = AlternateWorldBankersEngine.GetCategoryBanker(contextRealm, "Alliance", cat.id)
        if allyAssignedKey and AlternateWorldDB[allyAssignedKey] then
            UIDropDownMenu_SetText(row.AllyMenu, AlternateWorldBankersEngine.CleanClassColoredName(AlternateWorldDB[allyAssignedKey]))
        else
            UIDropDownMenu_SetText(row.AllyMenu, "|cFF888888(None assigned)|r")
        end
        UIDropDownMenu_Initialize(row.AllyMenu, function(self) InitializeCategoryDropdown(self, "Alliance", cat.id, row.AllyMenu, contextRealm) end)

        local hordeAssignedKey = AlternateWorldBankersEngine.GetCategoryBanker(contextRealm, "Horde", cat.id)
        if hordeAssignedKey and AlternateWorldDB[hordeAssignedKey] then
            UIDropDownMenu_SetText(row.HordeMenu, AlternateWorldBankersEngine.CleanClassColoredName(AlternateWorldDB[hordeAssignedKey]))
        else
            UIDropDownMenu_SetText(row.HordeMenu, "|cFF888888(None assigned)|r")
        end
        UIDropDownMenu_Initialize(row.HordeMenu, function(self) InitializeCategoryDropdown(self, "Horde", cat.id, row.HordeMenu, contextRealm) end)

        row:Show()
        currentYOffset = currentYOffset - ROW_HEIGHT - 2
    end
    scrollContent:SetHeight(math.abs(currentYOffset) + ROW_HEIGHT)
end

function AlternateWorldBankersView.RefreshActiveDropdowns(contextRealm)
    local panel = _G["AWBankersPanelGlobal"]
    if not panel then return end
    
    local mustIsolate = AlternateWorldDB.Settings and AlternateWorldDB.Settings.IsolateSingleRealms
    local assignedCluster = AlternateWorldDB.Settings.Clusters and AlternateWorldDB.Settings.Clusters[contextRealm]
    local MainTitleText = panel.MainTitleText
    
    if MainTitleText then
        if assignedCluster then
            local customClusterName = AlternateWorldDB.Settings.ClusterNames and AlternateWorldDB.Settings.ClusterNames[assignedCluster] or "Cluster"
            MainTitleText:SetText(string.format("|cFFFFFFFFBankers on %s|r", customClusterName))
        elseif not mustIsolate then
            MainTitleText:SetText("|cFFFFFFFFBank Managers|r")
        else
            MainTitleText:SetText(string.format("|cFFFFFFFFBankers on %s|r", contextRealm))
        end
    end

    for count, cat in ipairs(BANKER_CATEGORIES) do
        local row = AW_BankerRowsPool[count]
        if row then
            UIDropDownMenu_Initialize(row.AllyMenu, function(self) InitializeCategoryDropdown(self, "Alliance", cat.id, row.AllyMenu, contextRealm) end)
            UIDropDownMenu_Initialize(row.HordeMenu, function(self) InitializeCategoryDropdown(self, "Horde", cat.id, row.HordeMenu, contextRealm) end)
        end
    end
end

function AlternateWorldBankersView.HidePanel()
    if AlternateWorldBankersEngine then
        local panel = AlternateWorldBankersEngine.InitializeCorePanel(AlternateWorldMainContentWindow)
        if panel then panel:Hide() end
    end
end

function AlternateWorldBankersView.IsShown()
    if AlternateWorldBankersEngine then
        local panel = AlternateWorldBankersEngine.InitializeCorePanel(AlternateWorldMainContentWindow)
        return panel and panel:IsShown()
    end
    return false
end

-- ============================================================================
-- v0.5.0 VIRTUAL CHARACTERS ENGINE: Handles Dual-Box Multi-Account Properties
-- ============================================================================

local AW_VirtualButtonsPool = {}
local VirtualDialogFrame = nil

local function InitializeFactionDropdown(self)
    local factions = { { id = "Alliance", text = "|cFF0070DDAlliance|r" }, { id = "Horde", text = "|cFFFF0000Horde|r" } }
    local info = UIDropDownMenu_CreateInfo()
    local currentValue = self.selectedValue
    
    for _, f in ipairs(factions) do
        info.text = f.text
        info.value = f.id
        info.arg1 = f.id
        info.checked = (currentValue == f.id)
        
        info.func = function(button)
            local targetFaction = button.arg1
            UIDropDownMenu_SetText(self, button:GetText())
            self.selectedValue = targetFaction
        end
        UIDropDownMenu_AddButton(info)
    end
end

local function InitializeRealmDropdown(self)
    local info = UIDropDownMenu_CreateInfo()
    local currentValue = self.selectedValue
    
    info.text = "|cFF888888(Custom Realm...)|r"
    info.value = "custom"
    info.arg1 = "custom"
    info.checked = (currentValue == "custom")
    info.func = function(button)
        UIDropDownMenu_SetText(self, "(Custom Realm...)")
        self.selectedValue = "custom"
        if VirtualDialogFrame and VirtualDialogFrame.CustomRealmBox then
            VirtualDialogFrame.CustomRealmBox:Show()
            VirtualDialogFrame.CustomRealmBox:SetText("")
            VirtualDialogFrame.CustomRealmBox:SetFocus()
        end
    end
    UIDropDownMenu_AddButton(info)

    local knownRealmsMap = {}
    if AlternateWorldDB then
        for key, data in pairs(AlternateWorldDB) do
            if key ~= "Settings" and data and data.realm and data.realm ~= "Unknown" then
                knownRealmsMap[data.realm] = true
            end
        end
    end
    
    local sortedRealms = {}
    for rName in pairs(knownRealmsMap) do table.insert(sortedRealms, rName) end
    table.sort(sortedRealms)

    for _, rName in ipairs(sortedRealms) do
        info.text = rName
        info.value = rName
        info.arg1 = rName
        info.checked = (currentValue == rName)
        info.func = function(button)
            local targetRealm = button.arg1
            UIDropDownMenu_SetText(self, targetRealm)
            self.selectedValue = targetRealm
            if VirtualDialogFrame and VirtualDialogFrame.CustomRealmBox then
                VirtualDialogFrame.CustomRealmBox:Hide()
                VirtualDialogFrame.CustomRealmBox:SetText(targetRealm)
            end
        end
        UIDropDownMenu_AddButton(info)
    end
end

-- FIXED v0.5.0 UI PURGE: Disconnects the virtual panel list renderer from the standard Bankers scroll content view matrix
local originalShowData = AlternateWorldBankersView.ShowData
function AlternateWorldBankersView.ShowData(selectedCharacterKey)
    originalShowData(selectedCharacterKey)
end

-- End of [alternatebankersui.lua]
