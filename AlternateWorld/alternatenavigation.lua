-- ============================================================================
-- Alternate World - Graphical Icon Navigation Menu Module (v0.3.0 - BANKERS)
-- ============================================================================

AlternateWorldNavigation = {}

local NavigationMenuPanel = nil
local MenuButtonsPool = {}

local MENU_ITEMS = {
    { id = "character",   text = "Characters",       icon = "interface\\icons\\inv_misc_head_human_02" },
    { id = "inventory",   text = "Bags & Banks",     icon = "interface\\icons\\inv_misc_bag_08" },
    { id = "attunements", text = "Raids & Dungeons", icon = "interface\\icons\\inv_misc_head_dragon_01" },
    { id = "history",     text = "History Log",      icon = "interface\\icons\\inv_misc_pocketwatch_02" },
    { id = "professions", text = "Professions",      icon = "interface\\icons\\trade_blacksmithing" },
    { id = "restedxp",     text = "Rested XP",        icon = "interface\\icons\\inv_misc_rune_01" },
    { id = "bankers",      text = "Bankers",          icon = "interface\\icons\\inv_misc_coin_17" },
    { id = "virtualbankers", text = "Virtual Bankers", icon = "interface\\icons\\spell_nature_reincarnation" },
    { id = "clusters",     text = "Clusters",         icon = "interface\\icons\\inv_ore_arcanite_01" } 
}

local PANELS_MAP = {
    ["character"]   = "AlternateWorldCharacterView",
    ["inventory"]   = "AlternateWorldInventoryView",
    ["attunements"] = "AlternateWorldAttunementsView",
    ["history"]     = "AlternateWorldHistoryView",
    ["professions"] = "AlternateWorldProfessionsView",
    ["restedxp"]    = "AlternateWorldRestedXPView",
    ["bankers"]     = "AlternateWorldBankersView",
    ["virtualbankers"] = "AlternateWorldVirtualBankersView",
    ["clusters"]    = "AlternateWorldClustersView" 
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

    for i, item in ipairs(MENU_ITEMS) do
        local btn = CreateFrame("Button", "AW_NavIconButton" .. i, NavigationMenuPanel)
        btn:SetSize(NavigationMenuPanel:GetWidth() - 10, 48)
        
        if i == 1 then btn:SetPoint("TOPLEFT", NavigationMenuPanel, "TOPLEFT", 5, -15)
        else btn:SetPoint("TOPLEFT", MenuButtonsPool[i - 1], "BOTTOMLEFT", 0, -3) end

        btn.Icon = btn:CreateTexture(nil, "OVERLAY")
        btn.Icon:SetSize(32, 32)
        btn.Icon:SetPoint("TOP", btn, "TOP", 0, 0)
        btn.Icon:SetTexture(item.icon)

        btn.Text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        btn.Text:SetPoint("TOP", btn.Icon, "BOTTOM", 0, -1)
        btn.Text:SetText(item.text)
        btn.Text:SetJustifyH("CENTER")

        local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
        highlight:SetAllPoints(btn.Icon)
        highlight:SetTexture("Interface\\Buttons\\CheckButtonHilight")
        highlight:SetBlendMode("ADD")

        btn:SetScript("OnClick", function()
            PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
            AlternateWorldNavigation.HideAllPanels()
            local targetObj = _G[PANELS_MAP[item.id]]
            local activeKey = GetSelectedCharacterKeyFunc and GetSelectedCharacterKeyFunc()
            if targetObj and targetObj.ShowData and activeKey then
                targetObj.ShowData(activeKey)
            end
        end)

        MenuButtonsPool[i] = btn
    end

    return NavigationMenuPanel
end

-- End of [alternatenavigation.lua]
