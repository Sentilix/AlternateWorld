-- ============================================================================
-- Alternate World - Profession Dropdown & Search UI Control Module (v0.2.0)
-- ============================================================================

AlternateWorldProfDropdown = {}

local AWProfSearchBox = nil

local function InitializeAWProfessionDropdown(self, level)
    if not AlternateWorldProfEngine then return end
    local info = UIDropDownMenu_CreateInfo()
    local availableProfs = AlternateWorldProfEngine.GetSortedScannedProfessions()
    
    if #availableProfs == 0 then
        info.text = "No professions scanned yet"
        info.disabled = true
        UIDropDownMenu_AddButton(info, level)
        return
    end
    
    for _, profName in ipairs(availableProfs) do
        local profIconPath = AlternateWorldProfEngine.GetProfessionIconTexture(profName)
        info.text = string.format("|T%s:14:14:0:0|t %s", profIconPath, profName)
        info.value = profName
        info.arg1 = profName
        info.func = function(button, arg1)
            if AlternateWorldProfessionsView and AlternateWorldProfessionsView.SetLastSelectedProfession then
                AlternateWorldProfessionsView.SetLastSelectedProfession(arg1)
                
                local dropdownFrame = AlternateWorldProfessionsView.GetDropdownFrame and AlternateWorldProfessionsView.GetDropdownFrame()
                if dropdownFrame then
                    UIDropDownMenu_SetText(dropdownFrame, string.format("|T%s:14:14:0:0|t %s", profIconPath, profName))
                end
                
                if AlternateWorldProfessionsView.TriggerRefresh then
                    AlternateWorldProfessionsView.TriggerRefresh()
                end
            end
        end
        
        local currentActiveProf = AlternateWorldProfessionsView and AlternateWorldProfessionsView.GetLastSelectedProfession and AlternateWorldProfessionsView.GetLastSelectedProfession()
        info.checked = (currentActiveProf == profName)
        UIDropDownMenu_AddButton(info, level)
    end
end

function AlternateWorldProfDropdown.Setup(dropdownFrame, professionsPanel, selectedCharacterKey)
    if not dropdownFrame or not professionsPanel then return end
    
    UIDropDownMenu_Initialize(dropdownFrame, InitializeAWProfessionDropdown)

    if AlternateWorldMainTopBar and not AWProfSearchBox then
        AWProfSearchBox = CreateFrame("EditBox", "AW_ProfSearchBoxInstance", AlternateWorldMainTopBar, "InputBoxTemplate")
        AWProfSearchBox:SetSize(110, 20) 
        AWProfSearchBox:SetPoint("LEFT", dropdownFrame, "RIGHT", 15, 2) 
        AWProfSearchBox:SetAutoFocus(false)
        AWProfSearchBox:SetText("search recipe...")
        AWProfSearchBox:SetTextColor(0.6, 0.6, 0.6)
        
        AWProfSearchBox:SetScript("OnEditFocusGained", function(self) if self:GetText() == "search recipe..." then self:SetText(""); self:SetTextColor(1, 1, 1) end end)
        AWProfSearchBox:SetScript("OnEditFocusLost", function(self) if self:GetText() == "" then self:SetText("search recipe..."); self:SetTextColor(0.6, 0.6, 0.6) end end)
        AWProfSearchBox:SetScript("OnTextChanged", function(self, isUserInput) 
            if isUserInput and AlternateWorldProfessionsView and AlternateWorldProfessionsView.TriggerRefresh then 
                AlternateWorldProfessionsView.TriggerRefresh() 
            end 
        end)
    end

    if AWProfSearchBox then AWProfSearchBox:Show() end
end

function AlternateWorldProfDropdown.HideSearch()
    if AWProfSearchBox then AWProfSearchBox:Hide() end
end

-- End of [alternateprofui.lua]
