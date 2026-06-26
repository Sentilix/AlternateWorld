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
local AW_ExportDialogFrame = nil
local AW_StringDialogFrame = nil

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
        if _G["AW_VirtualBankerDialog"] and _G["AW_VirtualBankerDialog"].CustomRealmBox then
            _G["AW_VirtualBankerDialog"].CustomRealmBox:Show()
            _G["AW_VirtualBankerDialog"].CustomRealmBox:SetText("")
            _G["AW_VirtualBankerDialog"].CustomRealmBox:SetFocus()
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
            if _G["AW_VirtualBankerDialog"] and _G["AW_VirtualBankerDialog"].CustomRealmBox then
                _G["AW_VirtualBankerDialog"].CustomRealmBox:Hide()
                _G["AW_VirtualBankerDialog"].CustomRealmBox:SetText(targetRealm)
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
    doc:SetSize(430, 250)
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
    VBScrollFrame:SetPoint("TOPLEFT", enableCB, "BOTTOMLEFT", 0, -20)
    VBScrollFrame:SetPoint("BOTTOMRIGHT", VBPanel, "BOTTOMRIGHT", -30, 20)
    VBScrollFrame:Hide()

    VBScrollContent = CreateFrame("Frame", nil, VBScrollFrame)
    VBScrollContent:SetSize(460, 1)
    VBScrollFrame:SetScrollChild(VBScrollContent)

    -- 5. THE BUTTON CLUSTER UTILITIES (Add, Export, Import)
    local addBtn = CreateFrame("Button", "AW_VBFaneAddBtn", VBScrollContent, "UIPanelButtonTemplate")
    addBtn:SetSize(140, 20)
    addBtn:SetPoint("TOPLEFT", VBScrollContent, "TOPLEFT", 10, -10)
    addBtn:SetText("Add Virtual Banker")
    addBtn:SetScript("OnClick", function()
        if AlternateWorldBankersView and AlternateWorldBankersView.CreateVirtualBankerDialog then
            local dlg = AlternateWorldBankersView.CreateVirtualBankerDialog("Add")
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
            
            UIDropDownMenu_Initialize(dlg.RealmMenu, InitializeRealmDropdown)
            UIDropDownMenu_Initialize(dlg.FactionMenu, InitializeFactionDropdown)
            dlg:Show()
            dlg.NameBox:SetFocus()
        end
    end)
    VBScrollContent.AddBtn = addBtn

    local expBtn = CreateFrame("Button", "AW_VBFaneExportBtn", VBScrollContent, "UIPanelButtonTemplate")
    expBtn:SetSize(110, 20)
    expBtn:SetPoint("LEFT", addBtn, "RIGHT", 8, 0)
    expBtn:SetText("Export Bankers")
    expBtn:SetScript("OnClick", function()
        AlternateWorldVirtualBankersView.OpenExportSelectionWindow()
    end)
    VBScrollContent.ExpBtn = expBtn

    local impBtn = CreateFrame("Button", "AW_VBFaneImportBtn", VBScrollContent, "UIPanelButtonTemplate")
    impBtn:SetSize(110, 20)
    impBtn:SetPoint("LEFT", expBtn, "RIGHT", 8, 0)
    impBtn:SetText("Import Bankers")
    impBtn:SetScript("OnClick", function()
        AlternateWorldVirtualBankersView.OpenImportStringWindow()
    end)
    VBScrollContent.ImpBtn = impBtn

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

    -- 1. EXTRACT AND GROUP VIRTUALS BY 3-TIER SCORING: REALM -> FACTION -> NAME
    local rawList = {}
    for key, data in pairs(AlternateWorldDB) do
        if key ~= "Settings" and data and data.isVirtual then
            table.insert(rawList, data)
        end
    end
    
    table.sort(rawList, function(a, b)
        local aRealm = a.realm or ""
        local bRealm = b.realm or ""
        if aRealm ~= bRealm then
            return aRealm < bRealm
        end
        
        local aFaction = a.faction or ""
        local bFaction = b.faction or ""
        if aFaction ~= bFaction then
            return aFaction < bFaction
        end
        
        return (a.name or "") < (b.name or "")
    end)

    local currentYPositionMarker = -25
    local lastSeenRealm = nil
    local count = 0

    -- 2. VERTICAL GENERATION ENGINE WITH REALM HEADERS AND FACTION ICONS
    for _, data in ipairs(rawList) do
        local exactRealm = data.realm or "Unknown Realm"
        local vKey = data.name .. " - " .. exactRealm

        -- INJECT NEW REALM SECTION HEADER ONCE
        if exactRealm ~= lastSeenRealm then
            lastSeenRealm = exactRealm
            count = count + 1
            
            local headerFrame = AW_VBButtonsPool[count]
            if not headerFrame then
                headerFrame = CreateFrame("Frame", "AW_VBFaneHeaderItem" .. count, VBScrollContent)
                headerFrame:SetSize(VBScrollContent:GetWidth() - 20, 22)
                headerFrame.Text = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                headerFrame.Text:SetPoint("LEFT", headerFrame, "LEFT", 10, 0)
                AW_VBButtonsPool[count] = headerFrame
            end
            
            headerFrame.Text:SetText("|cFFFFFFFF" .. exactRealm .. "|r")
            headerFrame.Edit, headerFrame.Del, headerFrame.Icon = nil, nil, nil
            
            if count == 1 then
                headerFrame:SetPoint("TOPLEFT", VBScrollContent.AddBtn, "BOTTOMLEFT", -10, -15)
            else
                headerFrame:SetPoint("TOPLEFT", AW_VBButtonsPool[count - 1], "BOTTOMLEFT", 0, -14)
            end
            headerFrame:Show()
            currentYPositionMarker = currentYPositionMarker - 28
        end

        -- RENDER THE ACTUAL CHARACTER ROW LINE
        count = count + 1
        local btn = AW_VBButtonsPool[count]

        if not btn then
            btn = CreateFrame("Frame", "AW_VBFaneLineItem" .. count, VBScrollContent)
            btn:SetSize(VBScrollContent:GetWidth() - 20, 22)

            btn.Icon = btn:CreateTexture(nil, "OVERLAY")
            btn.Icon:SetSize(16, 16)
            btn.Icon:SetPoint("LEFT", btn, "LEFT", 15, 0)

            btn.Text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            btn.Text:SetPoint("LEFT", btn.Icon, "RIGHT", 8, 0)
            btn.Text:SetJustifyH("LEFT")

            btn.Edit = CreateFrame("Button", nil, btn, "UIPanelButtonTemplate")
            btn.Edit:SetSize(45, 16)
            btn.Edit:SetPoint("RIGHT", btn, "RIGHT", -95, 0)
            btn.Edit:SetText("Edit")

            btn.Del = CreateFrame("Button", nil, btn, "UIPanelButtonTemplate")
            btn.Del:SetSize(55, 16)
            btn.Del:SetPoint("LEFT", btn.Edit, "RIGHT", 6, 0)
            btn.Del:SetText("Delete")

            AW_VBButtonsPool[count] = btn
        end

        btn:SetPoint("TOPLEFT", AW_VBButtonsPool[count - 1], "BOTTOMLEFT", 0, -3)

        if data.faction == "Horde" then
            btn.Icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Horde")
            btn.Icon:SetTexCoord(0.04, 0.64, 0.02, 0.62)
        else
            btn.Icon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Alliance")
            btn.Icon:SetTexCoord(0.04, 0.64, 0.02, 0.62)
        end
        btn.Icon:Show()

        local nameColorHex = AlternateWorldConstants.VIRTUAL_BANKER_COLOR_HEX
        btn.Text:SetText(nameColorHex .. data.name .. "|r")

        btn.Edit:SetScript("OnClick", function()
            if AlternateWorldBankersView and AlternateWorldBankersView.CreateVirtualBankerDialog then
                local dlg = AlternateWorldBankersView.CreateVirtualBankerDialog("Edit")
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
            end
        end)

        btn.Del:SetScript("OnClick", function()
            if StaticPopup_Show then StaticPopup_Show("AW_CONFIRM_DELETE_VIRTUAL", data.name, nil, vKey) end
        end)

        btn:Show()
        currentYPositionMarker = currentYPositionMarker - 25
    end

    VBScrollContent:SetHeight(math.abs(currentYPositionMarker) + 40)
end

-- ============================================================================
-- v0.5.0 WEAKAURA ENGINE: Serialized Cross-Account Export & Import Core
-- ============================================================================

local ExportCheckboxesPool = {}
local ExportHeadersPool = {}

-- 1. THE UNIVERSAL WEAKAURA BOX LAYER (Handles copy selection highlight and inject imports)
function AlternateWorldVirtualBankersView.OpenCopyPasteBox(titleLabel, textContent, isExportMode)
    if AW_StringDialogFrame then AW_StringDialogFrame:Hide() end

    local f = CreateFrame("Frame", "AW_StringBoxWindowInstance", UIParent, "BackdropTemplate")
    f:SetSize(320, 180)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 50)
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

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    title:SetText("|cFFFFFFFF" .. titleLabel .. "|r")

    local scrollFrame = CreateFrame("ScrollFrame", "AW_StringScrollFrame", f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 20, -45)
    scrollFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -35, 55)

    local editBox = CreateFrame("EditBox", "AW_StringInputBoxArea", scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetMaxLetters(99999)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetWidth(255)
    scrollFrame:SetScrollChild(editBox)

    editBox:SetText(textContent)
    editBox:SetScript("OnEscapePressed", function() f:Hide() end)

    if isExportMode then
        editBox:SetFocus()
        editBox:HighlightText()
    else
        editBox:SetFocus()
    end

    local actionBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    actionBtn:SetSize(90, 22)
    -- FIXED v0.5.0 POSITION: Centered the button dynamically if in export close mode to make it visually pleasing
    if isExportMode then
        actionBtn:SetPoint("BOTTOM", f, "BOTTOM", 0, 20)
        actionBtn:SetText("Close")
    else
        actionBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 25, 20)
        actionBtn:SetText("Import")
    end
    
    actionBtn:SetScript("OnClick", function()
        if isExportMode then
            f:Hide()
        else
            local importStr = editBox:GetText()
            f:Hide()
            
            if importStr and importStr ~= "" then
                local importCount, updateCount = 0, 0
                
                for segment in string.gmatch(importStr, "([^;]+)") do
                    local name, realm, faction = string.match(segment, "([^:]+):([^:]+):([^:]+)")
                    
                    if name and realm and faction then
                        local dbKey = name .. " - " .. realm
                        
                        if AlternateWorldDB and AlternateWorldDB[dbKey] then
                            if AlternateWorldDB[dbKey].isVirtual then
                                AlternateWorldDB[dbKey].faction = faction
                                updateCount = updateCount + 1
                            end
                        else
                            if AlternateWorldBankersEngine and AlternateWorldBankersEngine.AddVirtualBanker then
                                AlternateWorldBankersEngine.AddVirtualBanker(name, faction, realm)
                                importCount = importCount + 1
                            end
                        end
                    end
                end
                
                AlternateWorldVirtualBankersView.RefreshList()
                local feedbackMsg = string.format("Import Done: %d Added, %d Updated.", importCount, updateCount)
                UIErrorsFrame:AddMessage("|cFF00FF00" .. feedbackMsg .. "|r", 1, 1, 1, 3)
            else
                UIErrorsFrame:AddMessage("|cFFFF0000Import Aborted: Textbox field was empty.|r")
            end
        end
    end)

    local cancelBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    cancelBtn:SetSize(90, 22)
    cancelBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -25, 20)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function() f:Hide() end)

    -- FIXED v0.5.0 VISIBILITY: Hide cancel button completely during exports since it serves no logistical purpose
    if isExportMode then cancelBtn:Hide() else cancelBtn:Show() end

    AW_StringDialogFrame = f
    f:Show()
end

-- 2. POPUP: The interactive Import input string frame
function AlternateWorldVirtualBankersView.OpenImportStringWindow()
    AlternateWorldVirtualBankersView.OpenCopyPasteBox("Import Shared Matrix String", "", false)
end

-- 3. UTILITY: Helper to fetch characters sorted by 3-TIER SCORING: REALM -> FACTION -> NAME
local function GetScannedCharactersInContext()
    local scopedChars = {}
    if not AlternateWorldDB then return scopedChars end

    local currentRealm = GetRealmName()
    local assignedCluster = AlternateWorldDB.Settings and AlternateWorldDB.Settings.Clusters and AlternateWorldDB.Settings.Clusters[currentRealm]

    local function IsInScope(charRealm)
        if assignedCluster then
            local altCluster = AlternateWorldDB.Settings.Clusters and AlternateWorldDB.Settings.Clusters[charRealm]
            return (altCluster == assignedCluster)
        end
        return (charRealm == currentRealm)
    end

    for key, data in pairs(AlternateWorldDB) do
        if key ~= "Settings" and data and data.realm and not data.isVirtual then
            if IsInScope(data.realm) then
                table.insert(scopedChars, data)
            end
        end
    end

    table.sort(scopedChars, function(a, b)
        local aRealm = a.realm or ""
        local bRealm = b.realm or ""
        if aRealm ~= bRealm then return aRealm < bRealm end
        
        local aFaction = a.faction or ""
        local bFaction = b.faction or ""
        if aFaction ~= bFaction then return aFaction < bFaction end
        
        return (a.name or "") < (b.name or "")
    end)
    
    return scopedChars
end

-- 4. POPUP: The interactive Checkbox Selection window for exporting characters with Realm Headers
function AlternateWorldVirtualBankersView.OpenExportSelectionWindow()
    if AW_ExportDialogFrame then AW_ExportDialogFrame:Hide() end

    local chars = GetScannedCharactersInContext()
    if #chars == 0 then
        UIErrorsFrame:AddMessage("|cFFFF0000Error: No scanned characters found on this realm/cluster to export!|r")
        return
    end

    -- Create backdrop layout frame container
    local f = CreateFrame("Frame", "AW_ExportSelectionWindowInstance", UIParent, "BackdropTemplate")
    f:SetSize(260, 340)
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

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    title:SetText("|cFFFFFFFFSelect Profiles to Export|r")

    local scFrame = CreateFrame("ScrollFrame", "AW_ExportScrollFrame", f, "UIPanelScrollFrameTemplate")
    scFrame:SetPoint("TOPLEFT", f, "TOPLEFT", 15, -45)
    scFrame:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -35, 55)

    local scContent = CreateFrame("Frame", nil, scFrame)
    scContent:SetSize(200, 1)
    scFrame:SetScrollChild(scContent)

    -- FIXED v0.5.0 PURGE LOGIC: Swapped ipairs to PAIRS to guarantee total cleanup sweeping regardless of index gaps holes
    for _, cb in pairs(ExportCheckboxesPool) do cb:Hide() end
    for _, hd in pairs(ExportHeadersPool) do hd:Hide() end

    local currentY = -5
    local lastSeenRealm = nil
    local hCount = 0
    local cbCount = 0

    for _, charData in ipairs(chars) do
        local exactRealm = charData.realm or "Unknown Realm"

        -- 1. HEADER HANDLER IN LINEAR LANE
        if exactRealm ~= lastSeenRealm then
            lastSeenRealm = exactRealm
            hCount = hCount + 1
            
            local headerRow = ExportHeadersPool[hCount]
            if not headerRow then
                headerRow = CreateFrame("Frame", "AW_ExportHeaderDummy" .. hCount, scContent)
                headerRow:SetSize(190, 20)
                headerRow.TextHeader = headerRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                headerRow.TextHeader:SetPoint("LEFT", headerRow, "LEFT", 5, 0)
                ExportHeadersPool[hCount] = headerRow
            end
            
            headerRow.TextHeader:SetText("|cFFFFFFFF" .. exactRealm .. "|r")
            headerRow:SetPoint("TOPLEFT", scContent, "TOPLEFT", 0, currentY)
            headerRow:Show()
            
            currentY = currentY - 22
        end

        -- 2. CHECKBOX HANDLER IN LINEAR LANE (Fejlsikret tæller uden huller i indekseringen)
        cbCount = cbCount + 1
        local cb = ExportCheckboxesPool[cbCount]
        if not cb then
            cb = CreateFrame("CheckButton", "AW_ExportCBRow" .. cbCount, scContent, "InterfaceOptionsCheckButtonTemplate")
            cb:SetSize(20, 20)
            
            cb.FactionIcon = cb:CreateTexture(nil, "OVERLAY")
            cb.FactionIcon:SetSize(14, 14)
            cb.FactionIcon:SetPoint("LEFT", cb, "RIGHT", 4, 0)
            
            local txt = _G[cb:GetName() .. "Text"]
            if txt then
                txt:ClearAllPoints()
                txt:SetPoint("LEFT", cb.FactionIcon, "RIGHT", 6, 0)
            end
            ExportCheckboxesPool[cbCount] = cb
        end

        cb:SetPoint("TOPLEFT", scContent, "TOPLEFT", 15, currentY)
        cb:SetChecked(false) 
        cb.charContextData = charData 

        if charData.faction == "Horde" then
            cb.FactionIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Horde")
            cb.FactionIcon:SetTexCoord(0.04, 0.64, 0.02, 0.62)
        else
            cb.FactionIcon:SetTexture("Interface\\TargetingFrame\\UI-PVP-Alliance")
            cb.FactionIcon:SetTexCoord(0.04, 0.64, 0.02, 0.62)
        end
        cb.FactionIcon:Show()

        local classColorHex = "|cFFFFFFFF"
        if charData.classToken and RAID_CLASS_COLORS[charData.classToken] then
            local c = RAID_CLASS_COLORS[charData.classToken]
            classColorHex = string.format("|cff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
        end

        _G[cb:GetName() .. "Text"]:SetText(classColorHex .. charData.name .. "|r")
        _G[cb:GetName() .. "Text"]:SetTextColor(1, 1, 1)
        
        -- FIXED v0.5.0 RECALL ASSURANCE: Forces re-shows safely under absolute linear layout rules
        cb:Show()

        currentY = currentY - 24
    end
    scContent:SetHeight(math.abs(currentY) + 15)

    local okBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    okBtn:SetSize(85, 22)
    okBtn:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 25, 20)
    okBtn:SetText("OK")
    okBtn:SetScript("OnClick", function()
        local compiledSegments = {}
        for i = 1, cbCount do
            local cb = ExportCheckboxesPool[i]
            if cb and cb:IsShown() and cb:GetChecked() and cb.charContextData then
                local d = cb.charContextData
                table.insert(compiledSegments, string.format("%s:%s:%s", d.name, d.realm, d.faction))
            end
        end

        f:Hide()
        if #compiledSegments > 0 then
            local finalString = table.concat(compiledSegments, ";")
            AlternateWorldVirtualBankersView.OpenCopyPasteBox("Export Generated String", finalString, true)
        else
            UIErrorsFrame:AddMessage("|cFFFF0000Export Aborted: No characters were checked.|r")
        end
    end)

    local cancelBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    cancelBtn:SetSize(85, 22)
    cancelBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -25, 20)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function() f:Hide() end)

    AW_ExportDialogFrame = f
    f:Show()
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
	