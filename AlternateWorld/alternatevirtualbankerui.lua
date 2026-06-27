-- ============================================================================
-- Alternate World - Virtual Bankers Profile View UI Module (v0.5.1)
-- ============================================================================

AlternateWorldVirtualBankersView = {}

local VBPanel = nil
local VBScrollFrame = nil
local VBScrollContent = nil
local DocumentationLabel = nil
local VBIsViewActive = false

local AW_VBRowsPool = {}
local AW_VBHeadersPool = {}

-- FIXED v0.5.1 GLOBAL REGISTRY: Locked safely into the global namespace to prevent nil scope bugs
AlternateWorldVirtualBankersView.ExportCheckboxesPool = {}
AlternateWorldVirtualBankersView.ExportHeadersPool = {}

local AW_ExportDialogFrame = nil
local AW_StringDialogFrame = nil
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

function AlternateWorldVirtualBankersView.CreateVirtualBankerDialog(mode)
    if VirtualDialogFrame then 
        local displayTitle = (mode == "Edit") and "Edit Virtual Banker" or "Add Virtual Banker"
        if VirtualDialogFrame.TitleText then VirtualDialogFrame.TitleText:SetText("|cFFFFFFFF" .. displayTitle .. "|r") end
        return VirtualDialogFrame 
    end

    local parentWin = UIParent
    local f = CreateFrame("Frame", "AW_VirtualBankerDialog", parentWin, "BackdropTemplate")
    f:SetSize(240, 240)
    f:SetPoint("CENTER", parentWin, "CENTER", 0, 40)
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    -- FIXED v0.5.1 SOLID SHIELD: Spawns an independent solid frame layer behind to absorb 100% background transparency noise
    if not f.SolidBgTextureLayer then
        f.SolidBgTextureLayer = f:CreateTexture(nil, "BACKGROUND")
        f.SolidBgTextureLayer:SetPoint("TOPLEFT", f, "TOPLEFT", 11, -11)
        f.SolidBgTextureLayer:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -11, 11)
        f.SolidBgTextureLayer:SetColorTexture(0.06, 0.06, 0.06, 1)
    end

    f:SetBackdrop({
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    local icon = f:CreateTexture(nil, "OVERLAY")
    icon:SetSize(18, 18)
    icon:SetPoint("TOPLEFT", f, "TOPLEFT", 22, -16)
    icon:SetTexture(236424) 
    f.TitleIcon = icon

    local titleText = (mode == "Edit") and "Edit Virtual Banker" or "Add Virtual Banker"
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    title:SetText("|cFFFFFFFF" .. titleText .. "|r")
    f.TitleText = title 

    local nameLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    nameLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -45)
    nameLabel:SetText("Character Name:")

    local nameBox = CreateFrame("EditBox", "AW_VirtualNameInput", f, "InputBoxTemplate")
    nameBox:SetSize(190, 20)
    nameBox:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 4, -4)
    nameBox:SetAutoFocus(false)
    f.NameBox = nameBox

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

    local factionLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    factionLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 24, -150)
    factionLabel:SetText("Faction Alignment:")

    local factionMenu = CreateFrame("Frame", "AW_VirtualFactionDropdown", f, "UIDropDownMenuTemplate")
    factionMenu:SetPoint("TOPLEFT", factionLabel, "BOTTOMLEFT", -15, -2)
    UIDropDownMenu_SetWidth(factionMenu, 165)
    f.FactionMenu = factionMenu

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

        if nameText and nameText ~= "" and realmText and realmText ~= "" and realmText ~= "(Custom Realm...)" then
            nameText = string.gsub(nameText, "%s+", "")
            if string.trim then realmText = string.trim(realmText)
            else realmText = string.gsub(realmText, "^%s*(.-)%s*$", "%1") end
            
            local nameLen = strlenutf8(nameText)
            local isNameValid = (nameLen >= 2 and nameLen <= 12 and not string.match(nameText, "[^%a]"))
            if not isNameValid then
                UIErrorsFrame:AddMessage("|cFFFF0000Error: Invalid name! Letters only (2-12 chars).|r")
                PlaySound(846)
                return
            end

            local realmLen = strlenutf8(realmText)
            local isRealmValid = (realmLen >= 4 and realmLen <= 24)
            if isRealmValid and not string.match(realmText, "[\128-\255]") then
                if string.match(realmText, "[^%a%d%s'%-]") then isRealmValid = false end
            end
            if not isRealmValid then
                UIErrorsFrame:AddMessage("|cFFFF0000Error: Invalid realm name format detected!|r")
                PlaySound(846)
                return
            end

            if string.len(nameText) > 0 then
                nameText = string.upper(string.sub(nameText, 1, 1)) .. string.lower(string.sub(nameText, 2))
            end

            local testKey = nameText .. " - " .. realmText
            local testKeyLower = string.lower(testKey)
            
            if AlternateWorldDB and not f.isEditingActiveMode then
                for dbKey, dbData in pairs(AlternateWorldDB) do
                    if dbKey ~= "Settings" and dbData and string.lower(dbKey) == testKeyLower then
                        UIErrorsFrame:AddMessage("|cFFFF0000Error: " .. nameText .. " already exists!|r")
                        return
                    end
                end
            end

            if f.isEditingActiveMode and f.originalKeyCache and f.originalKeyCache ~= testKey then
                AlternateWorldBankersEngine.DeleteVirtualBanker(f.originalKeyCache)
            end

            AlternateWorldBankersEngine.AddVirtualBanker(nameText, selectedFaction, realmText)
            AlternateWorldVirtualBankersView.RefreshList()
            f:Hide()
        else
            UIErrorsFrame:AddMessage("Missing Fields! Enter valid specification strings.", 1, 0, 0, 1)
        end
    end)

    local cancelBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    cancelBtn:SetSize(85, 22)
    cancelBtn:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -25, 20)
    cancelBtn:SetText("Cancel")
    cancelBtn:SetScript("OnClick", function() f:Hide() end)

    f:Hide()
    VirtualDialogFrame = f
    
    -- FIXED v0.5.1 PARENT ONHIDE WATCHDOG: Closes the Add/Edit frame instantly when the main addon window is closed
    local mainWin = _G["AlternateWorldMainContentWindow"]
    if mainWin then
        mainWin:HookScript("OnHide", function() f:Hide() end)
    end
    
    return f
end

function AlternateWorldVirtualBankersView.CreatePanel(parentWindow)
    if VBPanel then return VBPanel end

    -- 1. BASE PANEL SETUP
    VBPanel = CreateFrame("Frame", "AW_VirtualBankersPanelGlobal", parentWindow)
    VBPanel:SetAllPoints(parentWindow)
    VBPanel:Hide()

    VBPanel.Title = VBPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    VBPanel.Title:SetPoint("TOPLEFT", VBPanel, "TOPLEFT", 20, -10)
    VBPanel.Title:SetText("|cFFFFFFFFWelcome to the Virtual Banker setup!|r")

    -- 2. DYNAMIC CHECKBOX SETUP
    local enableCB = CreateFrame("CheckButton", "AW_VBEnableCheckbox", VBPanel, "InterfaceOptionsCheckButtonTemplate")
    enableCB:SetPoint("TOPLEFT", VBPanel, "TOPLEFT", 20, -35)
    
    local cbText = _G[enableCB:GetName() .. "Text"]
    if cbText then
        cbText:SetText("Enable Virtual Bankers setup")
        cbText:SetTextColor(1.0, 0.82, 0)
    end

    enableCB:SetScript("OnClick", function(self)
        if not AlternateWorldDB.Settings then AlternateWorldDB.Settings = {} end
        AlternateWorldDB.Settings.EnableVirtualBankers = self:GetChecked() and true or false
        AlternateWorldVirtualBankersView.ToggleModeLayout()
    end)
    VBPanel.EnableCB = enableCB

    -- 3. THE COMPACT DOCUMENTATION LAYOUT (420px width limit)
    local doc = VBPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    doc:SetPoint("TOPLEFT", enableCB, "BOTTOMLEFT", 6, -20)
    doc:SetSize(420, 250)
    doc:SetJustifyH("LEFT")
    doc:SetJustifyV("TOP")
    doc:SetSpacing(5)
    
    local docText = "|cFFFFFFFFWelcome to the Virtual Banker setup!|r\n\n" ..
                    "If you want to set up automatic mail recipients for characters that are " ..
                    "not on your current account, you can create a " .. AlternateWorldConstants.VIRTUAL_BANKER_COLOR_HEX .. "Virtual Banker|r.\n\n" ..
                    "A Virtual Banker acts as a reference to a character on a different account. " ..
                    "You can either create it manually, or export one or more characters from another account.\n\n" ..
                    "Virtual Bankers are ideal for players who frequently send materials to characters " ..
                    "outside their own account - such as alt accounts or guild bankers.\n\n" ..
                    "|cFFFFD100Click the checkbox above to create, export, or import bankers.|r"
    doc:SetText(docText)
    DocumentationLabel = doc

    -- 4. THE LIVE FLEET MANAGER VIEWPORT
    VBScrollFrame = CreateFrame("ScrollFrame", "AW_VBScrollFrameInstance", VBPanel, "UIPanelScrollFrameTemplate")
    VBScrollFrame:SetPoint("TOPLEFT", enableCB, "BOTTOMLEFT", 0, -20)
    VBScrollFrame:SetPoint("BOTTOMRIGHT", VBPanel, "BOTTOMRIGHT", -30, 20)
    VBScrollFrame:Hide()

    VBScrollContent = CreateFrame("Frame", nil, VBScrollFrame)
    VBScrollContent:SetSize(200, 1)
    VBScrollFrame:SetScrollChild(VBScrollContent)

    -- 5. THE BUTTON CLUSTER UTILITIES (Add, Export, Import)
    local addBtn = CreateFrame("Button", "AW_VBFaneAddBtn", VBScrollContent, "UIPanelButtonTemplate")
    addBtn:SetSize(140, 20)
    addBtn:SetPoint("TOPLEFT", VBScrollContent, "TOPLEFT", 10, -10)
    addBtn:SetText("Add Virtual Banker")
    
    addBtn:SetScript("OnClick", function()
        local dlg = AlternateWorldVirtualBankersView.CreateVirtualBankerDialog("Add")
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
    if not VBScrollContent or not VBScrollFrame or not AlternateWorldDB then return end
    
    for _, btn in pairs(AW_VBRowsPool) do btn:Hide() end
    for _, hd in pairs(AW_VBHeadersPool) do hd:Hide() end

    local rawList = {}
    for key, data in pairs(AlternateWorldDB) do
        if key ~= "Settings" and data and data.isVirtual then
            table.insert(rawList, data)
        end
    end
    
    table.sort(rawList, function(a, b)
        local aRealm = a.realm or ""
        local bRealm = b.realm or ""
        if aRealm ~= bRealm then return aRealm < bRealm end
        
        local aFaction = a.faction or ""
        local bFaction = b.faction or ""
        if aFaction ~= bFaction then return aFaction < bFaction end
        
        return (a.name or "") < (b.name or "")
    end)

    local frameWidth = VBScrollFrame:GetWidth() - 26
    VBScrollContent:SetWidth(frameWidth)

    local currentYPositionMarker = -25
    local lastSeenRealm = nil
    
    local hCount = 0
    local rowCount = 0
    local lastRenderedWidget = VBScrollContent.AddBtn

    for _, data in ipairs(rawList) do
        local exactRealm = data.realm or "Unknown Realm"
        local vKey = data.name .. " - " .. exactRealm

        if exactRealm ~= lastSeenRealm then
            lastSeenRealm = exactRealm
            hCount = hCount + 1
            
            local headerFrame = AW_VBHeadersPool[hCount]
            if not headerFrame then
                headerFrame = CreateFrame("Frame", "AW_VBFaneHeaderItemGlobal" .. hCount, VBScrollContent)
                headerFrame.Text = headerFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                headerFrame.Text:SetPoint("LEFT", headerFrame, "LEFT", 10, 0)
                AW_VBHeadersPool[hCount] = headerFrame
            end
            
            headerFrame:SetSize(frameWidth, 22)
            headerFrame.Text:SetText("|cFFFFFFFF" .. exactRealm .. "|r")
            
            if lastRenderedWidget == VBScrollContent.AddBtn then
                headerFrame:SetPoint("TOPLEFT", VBScrollContent.AddBtn, "BOTTOMLEFT", -10, -15)
            else
                headerFrame:SetPoint("TOPLEFT", lastRenderedWidget, "BOTTOMLEFT", 0, -14)
            end
            
            headerFrame:Show()
            lastRenderedWidget = headerFrame
            currentYPositionMarker = currentYPositionMarker - 28
        end

        rowCount = rowCount + 1
        local btn = AW_VBRowsPool[rowCount]

        if not btn then
            btn = CreateFrame("Frame", "AW_VBFaneLineRowItem" .. rowCount, VBScrollContent)
            
            btn.Icon = btn:CreateTexture(nil, "OVERLAY")
            btn.Icon:SetSize(16, 16)
            btn.Icon:SetPoint("LEFT", btn, "LEFT", 15, 0)

            btn.Text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            btn.Text:SetPoint("LEFT", btn.Icon, "RIGHT", 8, 0)
            btn.Text:SetJustifyH("LEFT")

            btn.Edit = CreateFrame("Button", nil, btn, "UIPanelButtonTemplate")
            btn.Edit:SetSize(45, 16)
            btn.Edit:SetText("Edit")

            btn.Del = CreateFrame("Button", nil, btn, "UIPanelButtonTemplate")
            btn.Del:SetSize(55, 16)
            btn.Del:SetText("Delete")

            AW_VBRowsPool[rowCount] = btn
        end

        btn:SetSize(frameWidth, 22)
        
        btn.Edit:ClearAllPoints()
        btn.Edit:SetPoint("TOPRIGHT", btn, "TOPRIGHT", -95, -3)
        
        btn.Del:ClearAllPoints()
        btn.Del:SetPoint("LEFT", btn.Edit, "RIGHT", 6, 0)

        btn:SetPoint("TOPLEFT", lastRenderedWidget, "BOTTOMLEFT", 0, -3)

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
            local dlg = AlternateWorldVirtualBankersView.CreateVirtualBankerDialog("Edit")
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
            if StaticPopup_Show then StaticPopup_Show("AW_CONFIRM_DELETE_VIRTUAL", data.name, nil, vKey) end
        end)

        btn:Show()
        lastRenderedWidget = btn
        currentYPositionMarker = currentYPositionMarker - 25
    end

    VBScrollContent:SetHeight(math.abs(currentYPositionMarker) + 40)
end

-- ============================================================================
-- v0.5.1 EXPORT & IMPORT ENGINE: Universal Textbox & Data Validation Core
-- ============================================================================

function AlternateWorldVirtualBankersView.OpenCopyPasteBox(titleLabel, textContent, isExportMode)
    if AW_StringDialogFrame then AW_StringDialogFrame:Hide() end

    local parentWin = UIParent
    local f = CreateFrame("Frame", "AW_StringBoxWindowInstance", parentWin, "BackdropTemplate")
    f:SetSize(320, 180)
    f:SetPoint("CENTER", parentWin, "CENTER", 0, 50)
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    
    if not f.SolidBgTextureLayer then
        f.SolidBgTextureLayer = f:CreateTexture(nil, "BACKGROUND")
        f.SolidBgTextureLayer:SetPoint("TOPLEFT", f, "TOPLEFT", 11, -11)
        f.SolidBgTextureLayer:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -11, 11)
        f.SolidBgTextureLayer:SetColorTexture(0.06, 0.06, 0.06, 1)
    end

    f:SetBackdrop({
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
                        local nameLen = strlenutf8(name)
                        local realmLen = strlenutf8(realm)

                        local isNameValid = (nameLen >= 2 and nameLen <= 12 and not string.match(name, "%s"))
                        if isNameValid and not string.match(name, "[\128-\255]") then
                            if string.match(name, "[^%a]") then isNameValid = false end
                        end

                        local isRealmValid = (realmLen >= 4 and realmLen <= 24)
                        if isRealmValid and not string.match(realm, "[\128-\255]") then
                            if string.match(realm, "[^%a%d%s'%-]") then isRealmValid = false end
                        end

                        local isFactionValid = (faction == "Alliance" or faction == "Horde")

                        if isNameValid and isRealmValid and isFactionValid then
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
                end
                
                local vbView = _G["AlternateWorldVirtualBankersView"]
                if vbView and vbView.RefreshList then
                    vbView.RefreshList()
                end
                
                local feedbackMsg = string.format("Import Done: %d Added, %d Updated.", importCount, updateCount)
                UIErrorsFrame:AddMessage("|cFF00FF00" .. feedbackMsg .. "|r", 1, 1, 1)
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

    if isExportMode then cancelBtn:Hide() else cancelBtn:Show() end

    AW_StringDialogFrame = f
    f:Show()
    
    -- FIXED v0.5.1 PARENT ONHIDE WATCHDOG: Closes this popup instantly when the main addon window is closed
    local mainWin = _G["AlternateWorldMainContentWindow"]
    if mainWin then
        mainWin:HookScript("OnHide", function() f:Hide() end)
    end
end

function AlternateWorldVirtualBankersView.OpenImportStringWindow()
    AlternateWorldVirtualBankersView.OpenCopyPasteBox("Import Shared Matrix String", "", false)
end

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

function AlternateWorldVirtualBankersView.OpenExportSelectionWindow()
    if AW_ExportDialogFrame then AW_ExportDialogFrame:Hide() end

    local chars = GetScannedCharactersInContext()
    if #chars == 0 then
        UIErrorsFrame:AddMessage("|cFFFF0000Error: No scanned characters found on this realm/cluster to export!|r")
        return
    end

    local parentWin = UIParent
    local f = CreateFrame("Frame", "AW_ExportSelectionWindowInstance", parentWin, "BackdropTemplate")
    f:SetSize(260, 340)
    f:SetPoint("CENTER", parentWin, "CENTER", 0, 40)
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    
    -- FIXED v0.5.1 TRANSPARENCY: Injects a 100% solid dark slate background texture layer below borders
    if not f.SolidBgTextureLayer then
        f.SolidBgTextureLayer = f:CreateTexture(nil, "BACKGROUND")
        f.SolidBgTextureLayer:SetPoint("TOPLEFT", f, "TOPLEFT", 11, -11)
        f.SolidBgTextureLayer:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -11, 11)
        f.SolidBgTextureLayer:SetColorTexture(0.06, 0.06, 0.06, 1)
    end

    f:SetBackdrop({
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

    local scContent = f.ScrollContentCacheNode
    if not scContent then
        scContent = CreateFrame("Frame", nil, scFrame)
        f.ScrollContentCacheNode = scContent
    end
    scContent:SetSize(200, 1)
    scFrame:SetScrollChild(scContent)

    for _, cb in pairs(AlternateWorldVirtualBankersView.ExportCheckboxesPool) do cb:Hide() end
    for _, hd in pairs(AlternateWorldVirtualBankersView.ExportHeadersPool) do hd:Hide() end

    local currentY = -5
    local lastSeenRealm = nil
    local hCount = 0
    local cbCount = 0

    for _, charData in ipairs(chars) do
        local exactRealm = charData.realm or "Unknown Realm"

        if exactRealm ~= lastSeenRealm then
            lastSeenRealm = exactRealm
            hCount = hCount + 1
            
            local headerRow = AlternateWorldVirtualBankersView.ExportHeadersPool[hCount]
            if not headerRow then
                headerRow = CreateFrame("Frame", "AW_ExportHeaderDummy" .. hCount, scContent)
                headerRow:SetSize(190, 20)
                headerRow.TextHeader = headerRow:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                headerRow.TextHeader:SetPoint("LEFT", headerRow, "LEFT", 5, 0)
                AlternateWorldVirtualBankersView.ExportHeadersPool[hCount] = headerRow
            end
            
            headerRow:SetParent(scContent)
            headerRow.TextHeader:SetText("|cFFFFFFFF" .. exactRealm .. "|r")
            headerRow:SetPoint("TOPLEFT", scContent, "TOPLEFT", 0, currentY)
            headerRow:Show()
            
            currentY = currentY - 22
        end

        cbCount = cbCount + 1
        local cb = AlternateWorldVirtualBankersView.ExportCheckboxesPool[cbCount]
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
            AlternateWorldVirtualBankersView.ExportCheckboxesPool[cbCount] = cb
        end

        cb:SetParent(scContent)
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
            local cb = AlternateWorldVirtualBankersView.ExportCheckboxesPool[i]
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
    cancelBtn:SetScript("OnClick", function() f:Hide() end)

    AW_ExportDialogFrame = f
    f:Show()
    
    -- FIXED v0.5.1 PARENT ONHIDE WATCHDOG: Closes this popup instantly when the main addon window is closed
    local mainWin = _G["AlternateWorldMainContentWindow"]
    if mainWin then
        mainWin:HookScript("OnHide", function() f:Hide() end)
    end
end

-- ============================================================================
-- CENTRAL POPUP & INITIALIZATION CORE
-- ============================================================================

StaticPopupDialogs["AW_CONFIRM_DELETE_VIRTUAL"] = {
    text = "Are you sure you want to delete the virtual banker %s?",
    button1 = "Yes, Delete",
    button2 = "Cancel",
    OnAccept = function(self, data)
        if data then
            AlternateWorldBankersEngine.DeleteVirtualBanker(data)
            AlternateWorldVirtualBankersView.RefreshList()
            UIErrorsFrame:AddMessage("Virtual Banker deleted successfully.", 1, 1, 0, 1)
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

function AlternateWorldVirtualBankersView.ShowData(selectedCharacterKey)
    if not VBPanel then AlternateWorldVirtualBankersView.CreatePanel(_G["AlternateWorldMainContentWindow"]) end
    if not VBPanel then return end
    VBIsViewActive = true
    VBPanel:Show()
    AlternateWorldVirtualBankersView.ToggleModeLayout()
end

-- FIXED v0.5.1 GLOBAL DISMISS FRAMEWORK: Forces child elements to close down cleanly when the panel vanishes
function AlternateWorldVirtualBankersView.HidePanel() 
    if VBPanel then VBPanel:Hide() end
    VBIsViewActive = false 
    
    -- FIXED v0.5.1: Resolves global variable mapping to ensure popups close instantly when addon is closed
    if _G["AW_ExportSelectionWindowInstance"] then _G["AW_ExportSelectionWindowInstance"]:Hide() end
    if _G["AW_StringBoxWindowInstance"] then _G["AW_StringBoxWindowInstance"]:Hide() end
    if _G["AW_VirtualBankerDialog"] then _G["AW_VirtualBankerDialog"]:Hide() end
end

function AlternateWorldVirtualBankersView.IsShown() return VBPanel and VBPanel:IsShown() end

-- End of [alternatevirtualbankerui.lua]
