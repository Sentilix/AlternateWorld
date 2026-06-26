-- ============================================================================
-- Alternate World - Virtual Bankers Profile View UI Module (v0.5.0)
-- ============================================================================

AlternateWorldVirtualBankersView = {}

local VBPanel = nil
local VBScrollFrame = nil
local VBScrollContent = nil
local DocumentationLabel = nil
local VBIsViewActive = false

local AW_VBButtonsPool = {}

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

function AlternateWorldVirtualBankersView.CreatePanel(parentWindow)
    if VBPanel then return VBPanel end

    -- 1. BASE PANEL SETUP
    VBPanel = CreateFrame("Frame", "AW_VirtualBankersPanelGlobal", parentWindow)
    VBPanel:SetAllPoints(parentWindow)
    VBPanel:Hide()
    -- FIXED v0.5.0 HEADER: Injects a clean, standalone section title string in the top left area
    VBPanel.Title = VBPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    VBPanel.Title:SetPoint("TOPLEFT", VBPanel, "TOPLEFT", 20, -10)
    VBPanel.Title:SetText("|cFFFFFFFFVirtual Bankers Management|r")
    
    -- 2. DYNAMIC CHECKBOX SETUP
    local enableCB = CreateFrame("CheckButton", "AW_VBEnableCheckbox", VBPanel, "InterfaceOptionsCheckButtonTemplate")
    enableCB:SetPoint("TOPLEFT", VBPanel, "TOPLEFT", 20, -35)
    _G[enableCB:GetName() .. "Text"]:SetText("Enable Virtual Bankers setup")
    _G[enableCB:GetName() .. "Text"]:SetTextColor(1.0, 0.82, 0)

    enableCB:SetScript("OnClick", function(self)
        if not AlternateWorldDB.Settings then AlternateWorldDB.Settings = {} end
        AlternateWorldDB.Settings.EnableVirtualBankers = self:GetChecked() and true or false
        AlternateWorldVirtualBankersView.ToggleModeLayout()
    end)
    VBPanel.EnableCB = enableCB

    -- 3. THE COMPACT DOCUMENTATION LAYOUT
    local doc = VBPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    doc:SetPoint("TOPLEFT", enableCB, "BOTTOMLEFT", 6, -20)
    doc:SetSize(400, 250)
    doc:SetJustifyH("LEFT")
    doc:SetJustifyV("TOP")
    doc:SetSpacing(5)
    
    local docText = "|cFFFFFFFFWelcome to Virtual Vault Logistics v0.5.0|r\n\n" ..
                    "This advanced operations module allows you to manually deploy cross-account characters " ..
                    "and ghost alts directly into your local database grid network.\n\n" ..
                    "|cFF888888How it works:|r\n" ..
                    "By bypassing Blizzard's hard account storage boundaries, Virtual Bankers act as valid " ..
                    "mail delivery endpoints and vault category managers across your entire account.\n\n" ..
                    "|cFFFF0000[Status: DISABLED]|r\n" ..
                    "When this checkbox is cleared, all virtual entities are safely suspended in memory. " ..
                    "They will temporarily disappear from your postoffice autocomplete boxes and category selectors.\n\n" ..
                    "|cFF00FF00Check the box above to unleash your multi-account trade network and manage profiles!|r"
    doc:SetText(docText)
    DocumentationLabel = doc

    -- 4. THE LIVE FLEET MANAGER VIEWPORT
    VBScrollFrame = CreateFrame("ScrollFrame", "AW_VBScrollFrameInstance", VBPanel, "UIPanelScrollFrameTemplate")
    VBScrollFrame:SetPoint("TOPLEFT", enableCB, "BOTTOMLEFT", 0, -40)
    VBScrollFrame:SetPoint("BOTTOMRIGHT", VBPanel, "BOTTOMRIGHT", -30, 20)
    VBScrollFrame:Hide()

    VBScrollContent = CreateFrame("Frame", nil, VBScrollFrame)
    VBScrollContent:SetSize(434, 1)
    VBScrollFrame:SetScrollChild(VBScrollContent)

    -- 5. THE DEDICATED INLINE +ADD ACTION TRIGGER BUTTON
    local addBtn = CreateFrame("Button", "AW_VBFaneAddBtn", VBScrollContent, "UIPanelButtonTemplate")
    addBtn:SetSize(70, 20)
    addBtn:SetPoint("TOPLEFT", VBScrollContent, "TOPLEFT", 10, -10)
    addBtn:SetText("+ Add New")
    addBtn:SetScript("OnClick", function()
        if AlternateWorldBankersView and AlternateWorldBankersView.CreateVirtualBankerDialog then
            local dlg = AlternateWorldBankersView.CreateVirtualBankerDialog()
            dlg.isEditingActiveMode = false 
            dlg.originalKeyCache = nil
            dlg.NameBox:SetText("")
            dlg.CustomRealmBox:SetText("")
            dlg.CustomRealmBox:Hide()
            
            local activeRealm = GetRealmName()
            UIDropDownMenu_SetText(dlg.RealmMenu, activeRealm)
            dlg.RealmMenu.selectedValue = activeRealm
            dlg.CustomRealmBox:SetText(activeRealm)
            UIDropDownMenu_SetText(dlg.FactionMenu, "Select Faction...")
            dlg.FactionMenu.selectedValue = nil
            
            -- FIXED v0.5.0 INITIALIZATION HOOKS: Binds directly to internal local file routines safely
            UIDropDownMenu_Initialize(dlg.RealmMenu, InitializeRealmDropdown)
            UIDropDownMenu_Initialize(dlg.FactionMenu, InitializeFactionDropdown)
            dlg:Show()
            dlg.NameBox:SetFocus()
        end
    end)
    VBScrollContent.AddBtn = addBtn

    return VBPanel
end

function AlternateWorldVirtualBankersView.ToggleModeLayout()
    if not VBPanel then return end
    if not AlternateWorldDB.Settings then AlternateWorldDB.Settings = {} end
    local isEnabled = AlternateWorldDB.Settings.EnableVirtualBankers or false

    VBPanel.EnableCB:SetChecked(isEnabled)

    if isEnabled then
        if DocumentationLabel then DocumentationLabel:Hide() end
        if VBScrollFrame then VBScrollFrame:Show() end
        AlternateWorldVirtualBankersView.RefreshList()
    else
        if VBScrollFrame then VBScrollFrame:Hide() end
        if DocumentationLabel then DocumentationLabel:Show() end
    end
end

function AlternateWorldVirtualBankersView.RefreshList()
    if not VBScrollContent or not AlternateWorldDB then return end
    for _, btn in ipairs(AW_VBButtonsPool) do btn:Hide() end

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
        local btn = AW_VBButtonsPool[count]

        if not btn then
            btn = CreateFrame("Frame", "AW_VBFaneLineItem" .. count, VBScrollContent)
            btn:SetSize(VBScrollContent:GetWidth() - 20, 24)

            btn.Text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            btn.Text:SetPoint("LEFT", btn, "LEFT", 15, 0)
            btn.Text:SetJustifyH("LEFT")

            btn.Edit = CreateFrame("Button", nil, btn, "UIPanelButtonTemplate")
            btn.Edit:SetSize(45, 18)
            btn.Edit:SetPoint("LEFT", btn, "LEFT", 220, 0)
            btn.Edit:SetText("Edit")

            btn.Del = CreateFrame("Button", nil, btn, "UIPanelButtonTemplate")
            btn.Del:SetSize(55, 18)
            btn.Del:SetPoint("LEFT", btn.Edit, "RIGHT", 6, 0)
            btn.Del:SetText("Delete")

            AW_VBButtonsPool[count] = btn
        end

        if count == 1 then
            btn:SetPoint("TOPLEFT", VBScrollContent.AddBtn, "BOTTOMLEFT", -10, -15)
        else
            btn:SetPoint("TOPLEFT", AW_VBButtonsPool[count - 1], "BOTTOMLEFT", 0, -6)
        end

        local nameColorHex = "|cFFC41F3B" 
        local sLabel = data.realm and (" - |cFF888888" .. data.realm .. "|r") or ""
        local factionText = data.faction == "Horde" and " (|cFFFF0000Horde|r)" or " (|cFF0070DDAlliance|r)"
        
        btn.Text:SetText(nameColorHex .. data.name .. "|r" .. sLabel .. factionText)

        btn.Edit:SetScript("OnClick", function()
            if AlternateWorldBankersView and AlternateWorldBankersView.CreateVirtualBankerDialog then
                local dlg = AlternateWorldBankersView.CreateVirtualBankerDialog()
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
                
                -- FIXED v0.5.0 INITIALIZATION HOOKS: Binds Edit triggers straight to internal functions safely
                UIDropDownMenu_Initialize(dlg.RealmMenu, InitializeRealmDropdown)
                UIDropDownMenu_Initialize(dlg.FactionMenu, InitializeFactionDropdown)
                
                dlg:Show()
                dlg.NameBox:SetFocus()
                dlg.NameBox:HighlightText()
            end
        end)

        btn.Del:SetScript("OnClick", function()
            if StaticPopup_Show then StaticPopup_Show("AW_CONFIRM_DELETE_VIRTUAL", data.name, nil, vKey) end
        end)

        btn:Show()
        currentYPositionMarker = currentYPositionMarker - 30
    end

    VBScrollContent:SetHeight(math.abs(currentYPositionMarker) + 40)
end

function AlternateWorldVirtualBankersView.ShowData(selectedCharacterKey)
    if not VBPanel then AlternateWorldVirtualBankersView.CreatePanel(_G["AlternateWorldMainContentWindow"]) end
    if not VBPanel then return end
    VBIsViewActive = true
    VBPanel:Show()

    AlternateWorldVirtualBankersView.ToggleModeLayout()
end

function AlternateWorldVirtualBankersView.HidePanel() if VBPanel then VBPanel:Hide() VBIsViewActive = false end end
function AlternateWorldVirtualBankersView.IsShown() return VBPanel and VBPanel:IsShown() end

-- End of [alternatevirtualbankerui.lua]
