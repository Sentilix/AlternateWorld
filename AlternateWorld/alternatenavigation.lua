-- ============================================================================
-- Alternate World - Graphical Icon Navigation Menu Module (v0.3.0 - BANKERS)
-- ============================================================================

AlternateWorldNavigation = {}

local NavigationMenuPanel = nil
local MenuButtonsPool = {}

-- FIXED v0.7.0 TWIN-COLUMN MATRIX CONFIGURATION: Updated category registry with the new Work Orders layout segment
local MENU_ITEMS = {
    { id = "character",       text = "Characters",       icon = "interface\\icons\\inv_misc_head_human_02" },
    { id = "clusters",        text = "Clusters",          icon = "interface\\icons\\inv_ore_arcanite_01" },
    
    { id = "inventory",       text = "Bags & Banks",     icon = "interface\\icons\\inv_misc_bag_08" },
    { id = "attunements",     text = "Raids & Dungeons", icon = "interface\\icons\\inv_misc_head_dragon_01" },
    
    { id = "restedxp",        text = "Rested XP",         icon = "interface\\icons\\inv_misc_rune_01" },
    { id = "history",         text = "History Log",       icon = "interface\\icons\\inv_misc_pocketwatch_02" },
    
    { id = "professions",     text = "Professions",       icon = "interface\\icons\\trade_blacksmithing" },
    { id = "workorders",      text = "Work Orders",       icon = "Interface\\Icons\\INV_Gizmo_Goblingtonkcontroller" }, -- Injected Goblin Tonk Controller
    
    { id = "bankers",         text = "Bankers",           icon = "interface\\icons\\inv_misc_coin_17" },
    { id = "virtualbankers",  text = "Virtual Bankers",   icon = 236424 }
}

-- FIXED v0.7.0 EXTENDED MAPPER: Map your new workorders panel view node safely
local PANELS_MAP = {
    ["character"]      = "AlternateWorldCharacterView",
    ["inventory"]      = "AlternateWorldInventoryView",
    ["attunements"]    = "AlternateWorldAttunementsView",
    ["history"]        = "AlternateWorldHistoryView",
    ["professions"]    = "AlternateWorldProfessionsView",
    ["restedxp"]       = "AlternateWorldRestedXPView",
    ["bankers"]        = "AlternateWorldBankersView",
    ["virtualbankers"] = "AlternateWorldVirtualBankersView",
    ["clusters"]       = "AlternateWorldClustersView",
    ["workorders"]     = "AlternateWorldWorkOrdersView" -- Setup frame hook target
}

function AlternateWorldNavigation.HideAllPanels()
    for _, globalName in pairs(PANELS_MAP) do
        local obj = _G[globalName]
        if obj and obj.HidePanel then obj.HidePanel() end
    end
end

function AlternateWorldNavigation.RefreshActiveView(selectedCharacterKey)
    if not selectedCharacterKey then return end
    for id, globalName in pairs(PANELS_MAP) do
        local obj = _G[globalName]
        if obj and obj.IsShown and obj.IsShown() and obj.ShowData then
            obj.ShowData(selectedCharacterKey)
            return
        end
    end
    if AlternateWorldCharacterView and AlternateWorldCharacterView.ShowData then
        AlternateWorldCharacterView.ShowData(selectedCharacterKey)
    end
end

function AlternateWorldNavigation.CreateMenu(parentMenuFrame, GetSelectedCharacterKeyFunc)
    if NavigationMenuPanel then return NavigationMenuPanel end
    NavigationMenuPanel = parentMenuFrame

    -- GRID LAYOUT PARAMS: Balanced column padding locked tight to the left margin with custom asymmetrical column width
    local startX = 2      -- Secured left alignment baseline for Column 1
    local startY = -15    -- Top padding from top edge of navigation panel
    local colWidth = 93   
    local rowHeight = 72  -- Secured vertical row spacing pass
    
    for i, item in ipairs(MENU_ITEMS) do
        -- MATHEMATICAL MATRIX FORMULA: Calculate precise structural coordinates dynamically based on the linear loop index pass
        local row = math.floor((i - 1) / 2)  -- Resolves to 0 for Row 1, 1 for Row 2, down to 4 for Row 5
        local col = (i - 1) % 2               -- Resolves to 0 for Column 1 (Left), 1 for Column 2 (Right)

        local currentX = startX + (col * colWidth)
        local currentY = startY - (row * rowHeight)

        local btn = CreateFrame("Button", "AW_NavIconButton" .. i, NavigationMenuPanel)
        btn:SetSize(colWidth - 4, 64) -- Adjusted cell width context to maintain symmetric boundaries
        btn:SetPoint("TOPLEFT", NavigationMenuPanel, "TOPLEFT", currentX, currentY)

        -- ICON TEXTURE BIND: Anchor icon directly to the TOP-CENTER of the button cell box
        btn.Icon = btn:CreateTexture(nil, "OVERLAY")
        btn.Icon:SetSize(32, 32) -- Restored to full crisp 32x32 resolution size
        btn.Icon:SetPoint("TOP", btn, "TOP", 0, 0)
        btn.Icon:SetTexture(item.icon)

        -- FONTSTRING ROUTING: Place text strictly CENTERED directly BELOW the icon structure
        btn.Text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        btn.Text:SetPoint("TOP", btn.Icon, "BOTTOM", 0, -3) -- Centered precisely under the frame skull
        btn.Text:SetText(item.text)
        btn.Text:SetJustifyH("CENTER")
        btn.Text:SetWidth(colWidth - 12) -- Enforce safety wrap metrics to completely prevent line bleeding

        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints(btn.Icon)
        highlight:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        highlight:SetBlendMode("ADD")

        btn:SetScript("OnClick", function()
            PlaySound(841)
            AlternateWorldNavigation.HideAllPanels()
            
            local targetObj = _G[PANELS_MAP[item.id]]           
            local activeKey = _G["AWCachedCharacterKey"]
            
            if (not activeKey or activeKey == "") and GetSelectedCharacterKeyFunc then
                activeKey = GetSelectedCharacterKeyFunc()
            end
            
            if targetObj and targetObj.ShowData and activeKey then
                targetObj.ShowData(activeKey)
            end
        end)

        MenuButtonsPool[i] = btn
    end

    return NavigationMenuPanel
end

-- End of [alternatenavigation.lua]
