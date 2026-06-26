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

local function InitializeCategoryDropdown(self, faction, categoryID, dropdownMenuFrame, contextRealm)
    if not AlternateWorldDB or not AlternateWorldBankersEngine then return end
    
    local sortedAlts = {}
    local mustIsolate = AlternateWorldDB.Settings and AlternateWorldDB.Settings.IsolateSingleRealms
    local assignedCluster = AlternateWorldDB.Settings.Clusters and AlternateWorldDB.Settings.Clusters[contextRealm]
    
    -- FIXED v0.4.0 SYSTEM POLICY: Strict hierarchical flow routing for dropdown populates
    if assignedCluster then
        -- Cluster Mode: Always strictly limited to the configured family
        for key, altData in pairs(AlternateWorldDB) do
            if key ~= "Settings" and altData and altData.name and altData.faction == faction then
                local altRealm = altData.realm or "Unknown"
                local altCluster = AlternateWorldDB.Settings.Clusters and AlternateWorldDB.Settings.Clusters[altRealm]
                if altCluster == assignedCluster then
                    table.insert(sortedAlts, key)
                end
            end
        end
    elseif mustIsolate then
        -- Single-Realm Isolation Mode: strictly limited to the current unassigned realm
        for key, altData in pairs(AlternateWorldDB) do
            if key ~= "Settings" and altData and altData.name and altData.faction == faction then
                if (altData.realm or "Unknown") == contextRealm then
                    table.insert(sortedAlts, key)
                end
            end
        end
    else
        -- Unrestricted Legacy Mode: Opens the floodgates for ALL known characters on the account
        for key, altData in pairs(AlternateWorldDB) do
            if key ~= "Settings" and altData and altData.name and altData.faction == faction then
                table.insert(sortedAlts, key)
            end
        end
    end
    table.sort(sortedAlts)

    local info = UIDropDownMenu_CreateInfo()
    info.text = "|cFF888888(None assigned)|r"
    info.value = "none"
    
    local activeBanker = AlternateWorldBankersEngine.GetCategoryBanker(contextRealm, faction, categoryID)
    info.checked = (activeBanker == nil)
    info.func = function()
        AlternateWorldBankersEngine.SetCategoryBanker(contextRealm, faction, categoryID, nil)
        UIDropDownMenu_SetText(dropdownMenuFrame, "|cFF888888(None assigned)|r")
    end
    UIDropDownMenu_AddButton(info)

    for _, altKey in ipairs(sortedAlts) do
        local altData = AlternateWorldDB[altKey]
        if altData then
            info.text = AlternateWorldBankersEngine.CleanClassColoredName(altData)
            info.value = altKey
            info.arg1 = altKey
            info.checked = (activeBanker == altKey)
            info.func = function(button)
                local targetKey = button.arg1
                AlternateWorldBankersEngine.SetCategoryBanker(contextRealm, faction, categoryID, targetKey)
                UIDropDownMenu_SetText(dropdownMenuFrame, button:GetText())
            end
            UIDropDownMenu_AddButton(info)
        end
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

-- FIXED v0.5.0 GLOBAL EXPORT: Enforces global registration so BOTH tabs can open this layout window instantly
-- FIXED v0.5.0 DYNAMIC HEADLINES: Injects a mode token switch to toggle between Add and Edit title contexts seamlessly
function AlternateWorldBankersView.CreateVirtualBankerDialog(mode)
    if VirtualDialogFrame then 
        -- If frame already exists, dynamically update the title string anyway before display
        local displayTitle = (mode == "Edit") and "Edit Virtual Banker" or "Add Virtual Banker"
        if VirtualDialogFrame.TitleText then VirtualDialogFrame.TitleText:SetText("|cFFFFFFFF" .. displayTitle .. "|r") end
        return VirtualDialogFrame 
    end

    local f = CreateFrame("Frame", "AW_VirtualBankerDialog", UIParent, "BackdropTemplate")
    f:SetSize(240, 240)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    f:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    local icon = f:CreateTexture(nil, "OVERLAY")
    icon:SetSize(18, 18)
    icon:SetPoint("TOPLEFT", f, "TOPLEFT", 22, -16)
    icon:SetTexture(236424) 
    f.TitleIcon = icon

    -- FIXED v0.5.0: Computes the dynamic string based on active call parameters mode state
    local titleText = (mode == "Edit") and "Edit Virtual Banker" or "Add Virtual Banker"
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    title:SetText("|cFFFFFFFF" .. titleText .. "|r")
    f.TitleText = title -- Cache reference for quick updates

    -- 1. NAME FIELD: Swapped string font templates to GameFontNormalSmall for rich yellow layouts
    local nameLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -45)
    nameLabel:SetText("Character Name:")

    local nameBox = CreateFrame("EditBox", "AW_VirtualNameInput", f, "InputBoxTemplate")
    nameBox:SetSize(190, 20)
    nameBox:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 4, -4)
    nameBox:SetAutoFocus(false)
    f.NameBox = nameBox

    -- 2. REALM FIELD: Forced custom yellow layouts
    local realmLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    realmLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -95)
    realmLabel:SetText("Target Realm Context:")

    local realmMenu = CreateFrame("Frame", "AW_VirtualRealmDropdown", f, "UIDropDownMenuTemplate")
    realmMenu:SetPoint("TOPLEFT", realmLabel, "BOTTOMLEFT", -15, -2)
    UIDropDownMenu_SetWidth(realmMenu, 165)
    f.RealmMenu = realmMenu

    local customRealmBox = CreateFrame("EditBox", "AW_VirtualCustomRealmInput", f, "InputBoxTemplate")
    customRealmBox:SetSize(190, 20)
    customRealmBox:SetPoint("TOPLEFT", realmMenu, "BOTTOMLEFT", 19, -2)
    customRealmBox:SetAutoFocus(false)
    customRealmBox:Hide()
    f.CustomRealmBox = customRealmBox

    -- 3. FACTION FIELD: Forced custom yellow layouts
    local factionLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    factionLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -150)
    factionLabel:SetText("Faction Alignment:")

    local factionMenu = CreateFrame("Frame", "AW_VirtualFactionDropdown", f, "UIDropDownMenuTemplate")
    factionMenu:SetPoint("TOPLEFT", factionLabel, "BOTTOMLEFT", -15, -2)
    UIDropDownMenu_SetWidth(factionMenu, 165)
    f.FactionMenu = factionMenu

    -- KEYBOARD INTERACTION HOOKS
    nameBox:SetScript("OnEnterPressed", function() f.SaveBtn:Click() end)
    nameBox:SetScript("OnEscapePressed", function() f:Hide() end)
    customRealmBox:SetScript("OnEnterPressed", function() f.SaveBtn:Click() end)
    customRealmBox:SetScript("OnEscapePressed", function() f:Hide() end)

    local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    saveBtn:SetSize(85, 22)
    saveBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 25, 20)
    saveBtn:SetText("OK") 
    f.SaveBtn = saveBtn
    
    saveBtn:SetScript("OnClick", function()
        local nameText = nameBox:GetText()
        local selectedFaction = factionMenu.selectedValue
        local realmText = customRealmBox:IsShown() and customRealmBox:GetText() or UIDropDownMenu_GetText(realmMenu)

        if nameText and nameText ~= "" and realmText and realmText ~= "" and selectedFaction then
            nameText = string.gsub(nameText, "%s+", "")
            if string.trim then realmText = string.trim(realmText)
            else realmText = string.gsub(realmText, "^%s*(.-)%s*$", "%1") end
            
            if string.len(nameText) > 0 then
                nameText = string.upper(string.sub(nameText, 1, 1)) .. string.lower(string.sub(nameText, 2))
            end

            local testKey = nameText .. " - " .. realmText
            local testKeyLower = string.lower(testKey)
            
            if AlternateWorldDB and not f.isEditingActiveMode then
                for dbKey, dbData in pairs(AlternateWorldDB) do
                    if dbKey ~= "Settings" and dbData and string.lower(dbKey) == testKeyLower then
                        UIErrorsFrame:AddMessage("|cFFFF0000Error: " .. nameText .. "-" .. realmText .. " already exists!|r")
                        PlaySound(SOUNDKIT.IG_QUEST_FAILED)
                        return
                    end
                end
            end

            if f.isEditingActiveMode and f.originalKeyCache and f.originalKeyCache ~= testKey then
                AlternateWorldBankersEngine.DeleteVirtualBanker(f.originalKeyCache)
            end

            AlternateWorldBankersEngine.AddVirtualBanker(nameText, selectedFaction, realmText)
            
            if AlternateWorldVirtualBankersView and AlternateWorldVirtualBankersView.RefreshList then
                AlternateWorldVirtualBankersView.RefreshList()
            end
            if AlternateWorldBankersView and AlternateWorldBankersView.RefreshVirtualList then
                AlternateWorldBankersView.RefreshVirtualList()
            end
            
            f:Hide()
        else
            UIErrorsFrame:AddMessage("Missing Fields! Complete all specifications.", 1, 0, 0, 1)
        end
    end)

    local cancelBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    cancelBtn:SetSize(85, 22)
    cancelBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -25, 20)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function() f:Hide() end)

    f:Hide()
    VirtualDialogFrame = f
    return f
end

StaticPopupDialogs["AW_CONFIRM_DELETE_VIRTUAL"] = {
    text = "Are you sure you want to delete the virtual banker %s?",
    button1 = "Yes, Delete",
    button2 = "Cancel",
    OnAccept = function(self, data)
        if data then
            AlternateWorldBankersEngine.DeleteVirtualBanker(data)
            AlternateWorldBankersView.RefreshVirtualList()
            UIErrorsFrame:AddMessage("Virtual Banker deleted successfully.", 1, 1, 0, 1)
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

function AlternateWorldBankersView.RefreshVirtualList()
    local panel = _G["AWBankersPanelGlobal"]
    if not panel or not AlternateWorldDB then return end
    
    local scrollFrame = _G["AW_BankersScrollFrameInstance"]
    local scrollContent = scrollFrame and scrollFrame:GetScrollChild()
    if not scrollContent then return end

    if not scrollContent.VirtualHeaderLabel then
        scrollContent.VirtualHeaderLabel = scrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        scrollContent.VirtualHeaderLabel:SetText("|cFF888888Cross-Account Virtual Managers|r")

        local addBtn = CreateFrame("Button", "AW_AddVirtualBankerBtn", scrollContent, "UIPanelButtonTemplate")
        addBtn:SetSize(60, 18)
        addBtn:SetText("+ Add")
        addBtn:SetScript("OnClick", function()
            local dlg = CreateVirtualBankerDialog()
            dlg.isEditingActiveMode = false 
            dlg.originalKeyCache = nil
            dlg.NameBox:SetText("")
            dlg.CustomRealmBox:SetText("")
            dlg.CustomRealmBox:Hide()
            
            local activeRealm = panel.activeContextRealmCache or GetRealmName()
            UIDropDownMenu_SetText(dlg.RealmMenu, activeRealm)
            dlg.RealmMenu.selectedValue = activeRealm
            dlg.CustomRealmBox:SetText(activeRealm)
            
            UIDropDownMenu_SetText(dlg.FactionMenu, "Select Faction...")
            dlg.FactionMenu.selectedValue = nil
            
            UIDropDownMenu_Initialize(dlg.RealmMenu, InitializeRealmDropdown)
            UIDropDownMenu_Initialize(dlg.FactionMenu, InitializeFactionDropdown)
            
            dlg:Show()
            dlg.NameBox:SetFocus()
        end)
        scrollContent.AddVirtualBtn = addBtn
    end

    local staticCategoriesCount = 13
    local lastStaticRow = _G["AW_BankerRowLineInstance" .. staticCategoriesCount]
    
    if lastStaticRow then
        scrollContent.VirtualHeaderLabel:SetPoint("TOPLEFT", lastStaticRow, "BOTTOMLEFT", 15, -30)
        scrollContent.AddVirtualBtn:SetPoint("LEFT", scrollContent.VirtualHeaderLabel, "RIGHT", 15, 0)
    else
        scrollContent.VirtualHeaderLabel:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 15, -450)
        scrollContent.AddVirtualBtn:SetPoint("LEFT", scrollContent.VirtualHeaderLabel, "RIGHT", 15, 0)
    end

    for _, btn in ipairs(AW_VirtualButtonsPool) do btn:Hide() end

    local sortedVirtuals = {}
    for key, data in pairs(AlternateWorldDB) do
        if key ~= "Settings" and data and data.isVirtual then
            table.insert(sortedVirtuals, key)
        end
    end
    table.sort(sortedVirtuals)

    local currentYPositionMarker = -25

    for count, vKey in ipairs(sortedVirtuals) do
        local data = AlternateWorldDB[vKey]
        local btn = AW_VirtualButtonsPool[count]
        
        if not btn then
            btn = CreateFrame("Frame", "AW_VirtualManagerLineItem" .. count, scrollContent)
            btn:SetSize(scrollContent:GetWidth() - 20, 22)
            
            btn.Text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            btn.Text:SetPoint("LEFT", btn, "LEFT", 10, 0)
            btn.Text:SetJustifyH("LEFT")
            
            btn.Edit = CreateFrame("Button", nil, btn, "UIPanelButtonTemplate")
            btn.Edit:SetSize(45, 16)
            btn.Edit:SetPoint("LEFT", btn, "LEFT", 180, 0)
            btn.Edit:SetText("Edit")
            
            btn.Del = CreateFrame("Button", nil, btn, "UIPanelButtonTemplate")
            btn.Del:SetSize(50, 16)
            btn.Del:SetPoint("LEFT", btn.Edit, "RIGHT", 6, 0)
            btn.Del:SetText("Delete") 
            
            AW_VirtualButtonsPool[count] = btn
        end

        if count == 1 then
            btn:SetPoint("TOPLEFT", scrollContent.VirtualHeaderLabel, "BOTTOMLEFT", 10, -10)
        else
            btn:SetPoint("TOPLEFT", AW_VirtualButtonsPool[count - 1], "BOTTOMLEFT", 0, -6)
        end

        btn.Edit:SetScript("OnClick", function()
            local dlg = CreateVirtualBankerDialog()
            dlg.isEditingActiveMode = true 
            dlg.originalKeyCache = vKey 
            dlg.NameBox:SetText(data.name or "")
            dlg.CustomRealmBox:SetText(data.realm or "")
            
            local knownRealmsMap = {}
            for k, d in pairs(AlternateWorldDB) do
                if k ~= "Settings" and d and d.realm then knownRealmsMap[d.realm] = true end
            end
            
            if knownRealmsMap[data.realm] then
                UIDropDownMenu_SetText(dlg.RealmMenu, data.realm)
                dlg.RealmMenu.selectedValue = data.realm
                dlg.CustomRealmBox:Hide()
            else
                UIDropDownMenu_SetText(dlg.RealmMenu, "(Custom Realm...)")
                dlg.RealmMenu.selectedValue = "custom"
                dlg.CustomRealmBox:Show()
            end
            
            local fText = data.faction == "Horde" and "|cFFFF0000Horde|r" or "|cFF0070DDAlliance|r"
            UIDropDownMenu_SetText(dlg.FactionMenu, fText)
            dlg.FactionMenu.selectedValue = data.faction
            
            UIDropDownMenu_Initialize(dlg.RealmMenu, InitializeRealmDropdown)
            UIDropDownMenu_Initialize(dlg.FactionMenu, InitializeFactionDropdown)
            
            dlg:Show()
            dlg.NameBox:SetFocus()
            dlg.NameBox:HighlightText()
        end)
        
        btn.Del:SetScript("OnClick", function()
            StaticPopup_Show("AW_CONFIRM_DELETE_VIRTUAL", data.name, nil, vKey)
        end)

        -- FIXED v0.5.0 PREMIUM IDENTIFICATION: Injects the aggressive Death Knight dark red token to segregate virtuals
        local nameColorHex = "|cFFFFFFFF"
        if data.isVirtual or data.classToken == "BANKER" then
            nameColorHex = "|cFFC41F3B" -- THE UNIFIED DEATH KNIGHT DARKRED IDENTITY FOR ERA VIRTUALS!
        elseif data.classToken and RAID_CLASS_COLORS[data.classToken] then
            local c = RAID_CLASS_COLORS[data.classToken]
            nameColorHex = string.format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
        end
        
        local sLabel = data.realm and (" - |cFF888888" .. data.realm .. "|r") or ""
        btn.Text:SetText(nameColorHex .. data.name .. "|r" .. sLabel)
        
        btn:Show()
        currentYPositionMarker = currentYPositionMarker - 28
    end

    local baseCategoriesHeight = (13 * 34) + 40
    local totalRequiredHeight = baseCategoriesHeight + math.abs(currentYPositionMarker) + 40
    scrollContent:SetHeight(totalRequiredHeight)
end

-- FIXED v0.5.0 UI PURGE: Disconnects the virtual panel list renderer from the standard Bankers scroll content view matrix
local originalShowData = AlternateWorldBankersView.ShowData
function AlternateWorldBankersView.ShowData(selectedCharacterKey)
    originalShowData(selectedCharacterKey)
end

-- End of [alternatebankersui.lua]
