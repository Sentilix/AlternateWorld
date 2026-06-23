-- ============================================================================
-- Alternate World - Professions View UI Module Panel (v0.2.0 - REFINED CONST)
-- ============================================================================
AlternateWorldProfessionsView = {}
local AWProfessionsPanel, AWProfScrollFrame, AWProfScrollContent, AWProfHeadingText, AWProfessionDropdown, AWProfHeaderIconTexture = nil, nil, nil, nil, nil, nil
local AWLastSelectedProfession, AWIsViewActive, AW_RowsPool = nil, false, {}
local COL1_X, COL2_X, ROW_HEIGHT = 15, 260, 20

local function GetSafeRecipeTexture(name)
    if not name then return "interface\\icons\\inv_misc_questionmark" end
    local l = string.lower(name)
    if AlternateWorldConstants and AlternateWorldConstants.RECIPE_FALLBACKS then
        for keyword, path in pairs(AlternateWorldConstants.RECIPE_FALLBACKS) do
            if string.find(l, keyword) then return path end
        end
    end
    if AWLastSelectedProfession then
        local pLower = string.lower(AWLastSelectedProfession)
        if pLower == "alchemy" then return "interface\\icons\\inv_potion_02"
        elseif pLower == "blacksmithing" then return "interface\\icons\\inv_sword_04"
        elseif pLower == "engineering" then return "interface\\icons\\inv_misc_gear_01"
        elseif pLower == "tailoring" then return "interface\\icons\\inv_fabric_linen_01"
        elseif pLower == "cooking" then return "interface\\icons\\inv_misc_food_15"
        elseif pLower == "first aid" then return "interface\\icons\\spell_holy_sealofsacrifice" end
    end
    return "interface\\icons\\inv_misc_gear_02"
end

function AlternateWorldProfessionsView.GetLastSelectedProfession() return AWLastSelectedProfession end
function AlternateWorldProfessionsView.SetLastSelectedProfession(val) AWLastSelectedProfession = val end
function AlternateWorldProfessionsView.GetDropdownFrame() return AWProfessionDropdown end
function AlternateWorldProfessionsView.GetSearchText()
    local s = _G["AW_ProfSearchBoxInstance"]
    if not s then return nil end
    local text = string.lower(s:GetText() or "")
    return (text == "search recipe..." or text == "") and nil or text
end

function AlternateWorldProfessionsView.TriggerRefresh()
    local activeKey = AlternateWorldMainFrameEngine and AlternateWorldMainFrameEngine.GetSelectedCharacterKey and AlternateWorldMainFrameEngine.GetSelectedCharacterKey()
    AlternateWorldProfessionsView.RefreshDisplay(activeKey)
end

function AlternateWorldProfessionsView.RefreshDisplay(mainSelectedCharacterKey)
    if not AWProfScrollContent or not AlternateWorldProfEngine then return end
    for _, row in ipairs(AW_RowsPool) do row:Hide() if row.Icon then row.Icon:Hide() end end
    if not AWLastSelectedProfession or type(AWLastSelectedProfession) ~= "string" then
        if AWProfHeadingText then AWProfHeadingText:SetText("Select a Profession.") end
        if AWProfHeaderIconTexture then AWProfHeaderIconTexture:Hide() end
        return
    end
    if AWProfHeadingText then AWProfHeadingText:SetText("|cFFFFFFFFRecipes for " .. AWLastSelectedProfession .. "|r") end
    if AWProfHeaderIconTexture then AWProfHeaderIconTexture:SetTexture(AlternateWorldProfEngine.GetProfessionIconTexture(AWLastSelectedProfession)) AWProfHeaderIconTexture:Show() end
    local filterText = AlternateWorldProfessionsView.GetSearchText()
    local recipesToSort, recipeCraftersMap = AlternateWorldProfEngine.CompileSortedRecipes(AWLastSelectedProfession, filterText)
    local activeCharName = mainSelectedCharacterKey and string.gsub(string.match(mainSelectedCharacterKey, "([^%-]+)") or mainSelectedCharacterKey, "%s+", "")
    
    -- FIXED VISUAL LAYOUT: Raised rows dimensions to match the new 32x32 catalog geometries
    local NEW_ROW_HEIGHT = 42
    local currentYOffset, count = -10, 0
    
    for _, recipeObj in ipairs(recipesToSort) do
        count = count + 1
        local rowFrame = AW_RowsPool[count]
        local recName = recipeObj.name
        if not rowFrame then
            rowFrame = CreateFrame("Frame", "AW_GridRowInstance" .. count, AWProfScrollContent)
            rowFrame:SetSize(AWProfScrollContent:GetWidth() - 20, NEW_ROW_HEIGHT)
            
            -- FIXED ENGINE: Expanded texture canvas size to 32x32 pixels
            rowFrame.Icon = rowFrame:CreateTexture(nil, "OVERLAY")
            rowFrame.Icon:SetSize(32, 32)
            rowFrame.Icon:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", COL1_X, -2)
            
            -- FIXED TYPOGRAPHY: Large white heading text stacked dynamically to the right
            rowFrame.Col1 = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            rowFrame.Col1:SetPoint("TOPLEFT", rowFrame.Icon, "TOPRIGHT", 12, -1)
            rowFrame.Col1:SetJustifyH("LEFT")
            
            -- FIXED ALIGNMENT: Crafters name lines wrapped neatly directly underneath the heading title
            rowFrame.Col2 = CreateFrame("Frame", nil, rowFrame)
            rowFrame.Col2:SetPoint("TOPLEFT", rowFrame.Col1, "BOTTOMLEFT", 0, -4)
            rowFrame.Col2:SetPoint("BOTTOMRIGHT", rowFrame, "BOTTOMRIGHT", -10, 2)
            
            rowFrame.Col2Text = rowFrame.Col2:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            rowFrame.Col2Text:SetAllPoints(rowFrame.Col2)
            rowFrame.Col2Text:SetJustifyH("LEFT")
            AW_RowsPool[count] = rowFrame
        end
        
        if count == 1 then rowFrame:SetPoint("TOPLEFT", AWProfScrollContent, "TOPLEFT", 0, -10)
        else rowFrame:SetPoint("TOPLEFT", AW_RowsPool[count - 1], "BOTTOMLEFT", 0, -12) end -- Balanced spacing padding
        
        local recipeTexture = "interface\\icons\\inv_misc_questionmark"
        if AlternateWorldConstants and AlternateWorldConstants.GetSafeRecipeTexture then
            recipeTexture = AlternateWorldConstants.GetSafeRecipeTexture(recName, AWLastSelectedProfession)
        end
        rowFrame.Icon:SetTexture(recipeTexture)
        rowFrame.Icon:Show()
        
        rowFrame.Col1:SetText(recipeObj.color .. recName .. "|r")
        local craftersTextTable = {}
        for _, crafterInfo in ipairs(recipeCraftersMap[recName]) do
            local nameText = crafterInfo.displayName or crafterInfo.name
            if crafterInfo.isGathering and crafterInfo.level then nameText = string.format("%s (%d)", nameText, crafterInfo.level) end
            if activeCharName and string.gsub(crafterInfo.name or "", "%s+", "") == activeCharName then table.insert(craftersTextTable, string.format("|cFFFFFFFF%s|r", nameText))
            else table.insert(craftersTextTable, string.format("|cFFFFD700%s|r", nameText)) end
        end
        rowFrame.Col2Text:SetText("Crafters: " .. table.concat(craftersTextTable, ", "))
        rowFrame:Show()
        currentYOffset = currentYOffset - NEW_ROW_HEIGHT - 12
    end
    AWProfScrollContent:SetHeight(math.abs(currentYOffset) + NEW_ROW_HEIGHT)
end

function AlternateWorldProfessionsView.CreatePanel(parentWindow)
    local targetParent = parentWindow or _G["AlternateWorldMainContentWindow"]
    if not targetParent or AWProfessionsPanel then return AWProfessionsPanel end
    AWProfessionsPanel = CreateFrame("Frame", "AWProfessionsPanelGlobal", targetParent)
    AWProfessionsPanel:SetSize(464, 385)
    AWProfessionsPanel:SetPoint("TOPLEFT", targetParent, "TOPLEFT", 0, 0)
    AWProfessionsPanel:Hide()
    return AWProfessionsPanel
end

function AlternateWorldProfessionsView.ShowData(selectedCharacterKey)
    if not AWProfessionsPanel then AlternateWorldProfessionsView.CreatePanel(_G["AlternateWorldMainContentWindow"]) end
    if not AWProfessionsPanel then return end
    AWIsViewActive = true 
    AWProfessionsPanel:Show()
    if not AWProfessionDropdown and AlternateWorldMainTopBar then
        AWProfessionDropdown = CreateFrame("Frame", "AW_ProfMenuDropdownInstance", AlternateWorldMainTopBar, "UIDropDownMenuTemplate")
        AWProfessionDropdown:SetPoint("LEFT", AlternateWorldCharDropdown, "RIGHT", -5, 0) 
        UIDropDownMenu_SetWidth(AWProfessionDropdown, 120) 
        AWProfHeaderIconTexture = AWProfessionsPanel:CreateTexture(nil, "OVERLAY")
        AWProfHeaderIconTexture:SetSize(18, 18)
        AWProfHeaderIconTexture:SetPoint("TOPLEFT", AWProfessionsPanel, "TOPLEFT", 15, -12)
        AWProfHeaderIconTexture:Hide()
        AWProfHeadingText = AWProfessionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        AWProfHeadingText:SetPoint("LEFT", AWProfHeaderIconTexture, "RIGHT", 8, 0)
        AWProfScrollFrame = CreateFrame("ScrollFrame", "AW_ProfScrollFrameInstance", AWProfessionsPanel, "UIPanelScrollFrameTemplate")
        AWProfScrollFrame:SetPoint("TOPLEFT", AWProfHeaderIconTexture, "BOTTOMLEFT", 0, -18)
        AWProfScrollFrame:SetPoint("BOTTOMRIGHT", AWProfessionsPanel, "BOTTOMRIGHT", -30, 15)
        AWProfScrollContent = CreateFrame("Frame", nil, AWProfScrollFrame)
        AWProfScrollContent:SetSize(434, 1)
        AWProfScrollFrame:SetScrollChild(AWProfScrollContent)
    end
    if AWProfessionDropdown and AlternateWorldProfDropdown then AlternateWorldProfDropdown.Setup(AWProfessionDropdown, AWProfessionsPanel, selectedCharacterKey) AWProfessionDropdown:Show() end
    local scanned = AlternateWorldProfEngine and AlternateWorldProfEngine.GetSortedScannedProfessions() or {}
    if AWLastSelectedProfession and type(AWLastSelectedProfession) == "string" then
        UIDropDownMenu_SetText(AWProfessionDropdown, string.format("|T%s:14:14:0:0|t %s", AlternateWorldProfEngine.GetProfessionIconTexture(AWLastSelectedProfession), AWLastSelectedProfession))
    else
        if #scanned > 0 then
            -- FIXED FOR REAL: Safe explicit string index 1 extraction from the scanned list array
            AWLastSelectedProfession = scanned[1] or "Alchemy"
            UIDropDownMenu_SetText(AWProfessionDropdown, string.format("|T%s:14:14:0:0|t %s", AlternateWorldProfEngine.GetProfessionIconTexture(AWLastSelectedProfession), AWLastSelectedProfession))
        else UIDropDownMenu_SetText(AWProfessionDropdown, "No data scanned") end
    end
    if #scanned == 0 then
        if AWProfHeadingText then AWProfHeadingText:SetText("|cFFFFFFFFTo begin: Open your character's Tradeskill window to scan recipes!|r") end
        if AWProfHeaderIconTexture then AWProfHeaderIconTexture:Hide() end
    else AlternateWorldProfessionsView.RefreshDisplay(selectedCharacterKey) end
end

function AlternateWorldProfessionsView.HidePanel()
    AWIsViewActive = false 
    if AWProfessionsPanel then AWProfessionsPanel:Hide() end
    if AWProfessionDropdown then AWProfessionDropdown:Hide() end
    if AlternateWorldProfDropdown and AlternateWorldProfDropdown.HideSearch then AlternateWorldProfDropdown.HideSearch() end
end

function AlternateWorldProfessionsView.IsShown() return AWIsViewActive end

-- End of [alternateprofessions.lua]
