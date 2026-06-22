-- ============================================================================
-- Alternate World - Navigation & Menu Routing Module
-- ============================================================================

AlternateWorldNavigation = {}

-- Array list containing definitions for all active sidebar links
local MENU_ITEMS = {
    { text = "Character", view = AlternateWorldCharacterView },
    { text = "Inventory", view = AlternateWorldInventoryView },
    { text = "Attunements", view = AlternateWorldAttunementsView }
}

-- Shared internal pointer referencing generated menu buttons
local navigationButtons = {}

-- Helper: Closes every single registered panel viewport extension layout safely
function AlternateWorldNavigation.HideAllPanels()
    for _, item in ipairs(MENU_ITEMS) do
        if item.view and item.view.HidePanel then
            item.view.HidePanel()
        end
    end
end

-- Helper: Routes structural live data refresh targets directly into active screen blueprints
function AlternateWorldNavigation.RefreshActiveView(selectedCharacterKey)
    for _, item in ipairs(MENU_ITEMS) do
        if item.view and item.view.IsShown and item.view.IsShown() then
            item.view.ShowData(selectedCharacterKey)
            return
        end
    end
end

-- Main Constructor: Builds text links dynamically within left side column wrapper frame
function AlternateWorldNavigation.CreateMenu(leftMenuFrame, getSelectedKeyFunc)
    local previousAnchor = nil

    for i, item in ipairs(MENU_ITEMS) do
        local btn = CreateFrame("Frame", nil, leftMenuFrame)
        btn:SetSize(leftMenuFrame:GetWidth() - 20, 20)
        
        -- Mathematically stack menus vertically down beneath previous items
        if not previousAnchor then
            btn:SetPoint("TOPLEFT", leftMenuFrame, "TOPLEFT", 15, -15)
        else
            btn:SetPoint("TOPLEFT", previousAnchor, "BOTTOMLEFT", 0, -10)
        end

        btn:EnableMouse(true)

        -- Text FontString asset rendering
        btn.Text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btn.Text:SetPoint("LEFT", btn, "LEFT", 0, 0)
        btn.Text:SetText(item.text)

        -- Glow feedback trigger sequences on mouse hovers
        btn:SetScript("OnEnter", function() btn.Text:SetTextColor(1, 1, 1) end)
        btn:SetScript("OnLeave", function() btn.Text:SetTextColor(1, 0.82, 0) end)

        -- Left click interceptor hook to switch panels viewports
        btn:SetScript("OnMouseUp", function(self, button)
            if button == "LeftButton" then
                AlternateWorldNavigation.HideAllPanels()
                if item.view and item.view.ShowData then
                    item.view.ShowData(getSelectedKeyFunc())
                end
            end
        end)

        table.insert(navigationButtons, btn)
        previousAnchor = btn
    end
end
