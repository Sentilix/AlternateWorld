-- ============================================================================
-- Alternate World - Navigation & Menu Routing Module (DYNAMIC v0.2.0)
-- ============================================================================

AlternateWorldNavigation = {}

-- FIXED: Converted views to strict global string registry keys to eliminate load-time nil pointers
local MENU_ITEMS = {
    { text = "Character", viewKey = "AlternateWorldCharacterView" },
    { text = "Inventory", viewKey = "AlternateWorldInventoryView" },
    { text = "Attunements", viewKey = "AlternateWorldAttunementsView" },
    { text = "History", viewKey = "AlternateWorldHistoryView" },
    { text = "Professions", viewKey = "AlternateWorldProfessionsView" }
}

local navigationButtons = {}

function AlternateWorldNavigation.HideAllPanels()
    for _, item in ipairs(MENU_ITEMS) do
        local viewObj = _G[item.viewKey]
        if viewObj and viewObj.HidePanel then viewObj.HidePanel() end
    end
end

function AlternateWorldNavigation.RefreshActiveView(selectedCharacterKey)
    for _, item in ipairs(MENU_ITEMS) do
        local viewObj = _G[item.viewKey]
        if viewObj and viewObj.IsShown and viewObj.IsShown() then
            if viewObj.ShowData then
                viewObj.ShowData(selectedCharacterKey)
            end
            return
        end
    end
end

function AlternateWorldNavigation.CreateMenu(leftMenuFrame, getSelectedKeyFunc)
    local previousAnchor = nil

    for i, item in ipairs(MENU_ITEMS) do
        local btn = CreateFrame("Frame", nil, leftMenuFrame)
        btn:SetSize(leftMenuFrame:GetWidth() - 20, 20)
        
        if not previousAnchor then
            btn:SetPoint("TOPLEFT", leftMenuFrame, "TOPLEFT", 15, -15)
        else
            btn:SetPoint("TOPLEFT", previousAnchor, "BOTTOMLEFT", 0, -10)
        end

        btn:EnableMouse(true)

        btn.Text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.Text:SetPoint("LEFT", btn, "LEFT", 0, 0)
        btn.Text:SetText(item.text)

        btn:SetScript("OnEnter", function() btn.Text:SetTextColor(1, 1, 1) end)
        btn:SetScript("OnLeave", function() btn.Text:SetTextColor(1, 0.82, 0) end)

        -- FIXED: Fetch the view object dynamically from global space inside the mouse event runtime boundary
        btn:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" then
                AlternateWorldNavigation.HideAllPanels()
                local viewObj = _G[item.viewKey]
                if viewObj and viewObj.ShowData then
                    viewObj.ShowData(getSelectedKeyFunc())
                end
            end
        end)

        table.insert(navigationButtons, btn)
        previousAnchor = btn
    end
end
