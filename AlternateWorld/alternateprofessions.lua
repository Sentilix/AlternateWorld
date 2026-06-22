-- ============================================================================
-- Alternate World - Professions & Recipes View Module Panel (v0.2.0)
-- ============================================================================

AlternateWorldProfessionsView = {}

local ProfessionsPanel = nil
local ScrollFrame = nil
local ScrollContent = nil
local HeadingText = nil
local ProfessionDropdown = nil
local SearchBox = nil

local lastSelectedProfession = nil 

function AlternateWorldProfessionsView.GetLastSelectedProfession()
    return lastSelectedProfession
end

function AlternateWorldProfessionsView.GetSearchText()
    if not SearchBox then return nil end
    local text = string.lower(SearchBox:GetText() or "")
    if text == "search recipe..." or text == "" then return nil end
    return text
end

function AlternateWorldProfessionsView.SetHeading(text)
    if HeadingText then HeadingText:SetText(text) end
end

local function InitializeProfessionDropdown(self, level)
    if not AlternateWorldProfessionGrid or not AlternateWorldProfessionGrid.GetSortedScannedProfessions then return end
    
    local availableProfs = AlternateWorldProfessionGrid.GetSortedScannedProfessions()
    local info = UIDropDownMenu_CreateInfo()
    
    if #availableProfs == 0 then
        info.text = "No professions scanned yet"
        info.disabled = true
        UIDropDownMenu_AddButton(info, level)
        return
    end
    
    for _, profName in ipairs(availableProfs) do
        info.text = profName
        info.value = profName
        info.arg1 = profName
        info.func = function(button, arg1)
            lastSelectedProfession = arg1
            UIDropDownMenu_SetText(ProfessionDropdown, profName)
            if AlternateWorldProfessionGrid and AlternateWorldProfessionGrid.RefreshRecipesDisplay then
                AlternateWorldProfessionGrid.RefreshRecipesDisplay(ScrollContent)
            end
        end
        info.checked = (lastSelectedProfession == profName)
        UIDropDownMenu_AddButton(info, level)
    end
end

function AlternateWorldProfessionsView.CreatePanel(parentWindow)
    if ProfessionsPanel then return ProfessionsPanel end

    ProfessionsPanel = CreateFrame("Frame", nil, parentWindow)
    ProfessionsPanel:SetAllPoints(parentWindow)
    ProfessionsPanel:Hide()

    ProfessionDropdown = CreateFrame("Frame", "AlternateWorldProfMenuDropdown", ProfessionsPanel, "UIDropDownMenuTemplate")
    ProfessionDropdown:SetPoint("TOPLEFT", ProfessionsPanel, "TOPLEFT", -5, -10)
    UIDropDownMenu_SetWidth(ProfessionDropdown, 160)

    SearchBox = CreateFrame("EditBox", "AlternateWorldProfSearchBox", ProfessionsPanel, "InputBoxTemplate")
    SearchBox:SetSize(160, 20)
    SearchBox:SetPoint("TOPRIGHT", ProfessionsPanel, "TOPRIGHT", -25, -14)
    SearchBox:SetAutoFocus(false)
    SearchBox:SetText("Search recipe...")
    SearchBox:SetTextColor(0.6, 0.6, 0.6)

    SearchBox:SetScript("OnEditFocusGained", function(self)
        if self:GetText() == "Search recipe..." then
            self:SetText("")
            self:SetTextColor(1, 1, 1)
        end
    end)
    SearchBox:SetScript("OnEditFocusLost", function(self)
        if self:GetText() == "" then
            self:SetText("Search recipe...")
            self:SetTextColor(0.6, 0.6, 0.6)
        end
    end)
    SearchBox:SetScript("OnTextChanged", function(self, isUserInput)
        if isUserInput and AlternateWorldProfessionGrid and AlternateWorldProfessionGrid.RefreshRecipesDisplay then 
            AlternateWorldProfessionGrid.RefreshRecipesDisplay(ScrollContent) 
        end
    end)

    HeadingText = ProfessionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    HeadingText:SetPoint("TOPLEFT", ProfessionDropdown, "BOTTOMLEFT", 20, -10)

    ScrollFrame = CreateFrame("ScrollFrame", "AlternateWorldProfScrollFrame", ProfessionsPanel, "UIPanelScrollFrameTemplate")
    ScrollFrame:SetPoint("TOPLEFT", HeadingText, "BOTTOMLEFT", 0, -10)
    ScrollFrame:SetPoint("BOTTOMRIGHT", ProfessionsPanel, "BOTTOMRIGHT", -30, 15)

    ScrollContent = CreateFrame("Frame", nil, ScrollFrame)
    ScrollContent:SetSize(parentWindow:GetWidth() - 40, 1)
    ScrollFrame:SetScrollChild(ScrollContent)

    return ProfessionsPanel
end

function AlternateWorldProfessionsView.ShowData(selectedCharacterKey)
    if not ProfessionsPanel then return end
    
    UIDropDownMenu_Initialize(ProfessionDropdown, InitializeProfessionDropdown)
    
    local scanned = {}
    if AlternateWorldProfessionGrid and AlternateWorldProfessionGrid.GetSortedScannedProfessions then
        scanned = AlternateWorldProfessionGrid.GetSortedScannedProfessions()
    end

    if lastSelectedProfession then
        UIDropDownMenu_SetText(ProfessionDropdown, lastSelectedProfession)
    else
        if #scanned > 0 then
            lastSelectedProfession = scanned[1] -- FIXED: Hardlocked array indices string element extraction
            UIDropDownMenu_SetText(ProfessionDropdown, lastSelectedProfession)
        else
            UIDropDownMenu_SetText(ProfessionDropdown, "No data scanned")
        end
    end

    ProfessionsPanel:Show()
    
    if #scanned == 0 then
        HeadingText:SetText("|cFFFFFFFFTo begin: Open your character's Profession/Tradeskill window to scan your recipes live!|r")
    elseif AlternateWorldProfessionGrid and AlternateWorldProfessionGrid.RefreshRecipesDisplay then
        AlternateWorldProfessionGrid.RefreshRecipesDisplay(ScrollContent)
    end
end

function AlternateWorldProfessionsView.HidePanel()
    if ProfessionsPanel then ProfessionsPanel:Hide() end
end

function AlternateWorldProfessionsView.IsShown()
    return ProfessionsPanel and ProfessionsPanel:IsShown()
end
