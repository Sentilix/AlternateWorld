-- ============================================================================
-- Alternate World - Bankers User Interface Layout Module (v0.4.0 - FIXED)
-- ============================================================================

AlternateWorldBankersView = {}

local AW_BankerRowsPool = {}
local ROW_HEIGHT = 32

local BANKER_CATEGORIES = {
    { id = "Tailoring", name = "Tailoring", icon = "interface\\icons\\trade_tailoring" },
    { id = "Mining", name = "Ores & Bars", icon = "interface\\icons\\trade_mining" },
    { id = "Gems", name = "Gems & Stones", icon = "interface\\icons\\inv_misc_gem_emerald_02" },
    { id = "Enchanting", name = "Enchanting", icon = "interface\\icons\\trade_engraving" },
    { id = "Herbalism", name = "Herbs", icon = "interface\\icons\\spell_nature_naturetouchgrow" },
    { id = "Skinning", name = "Leather & Hides", icon = "interface\\icons\\inv_misc_pelt_wolf_01" },
    { id = "MiscMats", name = "Materials", icon = "interface\\icons\\inv_summerfest_firepotion" },
    { id = "Consumables", name = "Consumables", icon = "interface\\icons\\inv_misc_food_99" },
    { id = "QuestItems", name = "Quest items", icon = "interface\\icons\\achievement_quests_completed_06" },
    { id = "Reputation", name = "Reputation", icon = "interface\\icons\\achievement_reputation_01" },
    { id = "Gear", name = "Gear", icon = "interface\\icons\\inv_sword_29" },
    { id = "Recipes", name = "Patterns", icon = "interface\\icons\\inv_scroll_06" },
    { id = "Lockboxes", name = "Lockboxes", icon = "interface\\icons\\inv_box_03" }
}

local function InitializeCategoryDropdown(self, faction, categoryID, dropdownMenuFrame)
    if not AlternateWorldDB or not AlternateWorldBankersEngine then return end
    
    local currentRealm = GetRealmName()
    local sortedAlts = AlternateWorldBankersEngine.GetSortedFactionKeys(faction)

    local info = UIDropDownMenu_CreateInfo()
    info.text = "|cFF888888(None assigned)|r"
    info.value = "none"
    
    local activeBanker = AlternateWorldBankersEngine.GetCategoryBanker(currentRealm, faction, categoryID)
    info.checked = (activeBanker == nil)
    info.func = function()
        AlternateWorldBankersEngine.SetCategoryBanker(currentRealm, faction, categoryID, nil)
        UIDropDownMenu_SetText(dropdownMenuFrame, "|cFF888888(None assigned)|r")
    end
    UIDropDownMenu_AddButton(info)

    for _, altKey in ipairs(sortedAlts) do
        local altData = AlternateWorldDB[altKey]
        if altData then
            info.text = AlternateWorldBankersEngine.CleanClassColoredName(altData)
            info.value = altKey
            info.arg1 = altKey -- FIXED v0.4.0 DROPDOWN CLOSURE: Binds the explicit character key to the button argument
            info.checked = (activeBanker == altKey)
            info.func = function(button)
                -- Safely extracts the true bound key value instead of referencing the loop's end variable state
                local targetKey = button.arg1
                AlternateWorldBankersEngine.SetCategoryBanker(currentRealm, faction, categoryID, targetKey)
                UIDropDownMenu_SetText(dropdownMenuFrame, button:GetText())
            end
            UIDropDownMenu_AddButton(info)
        end
    end
end

function AlternateWorldBankersView.ShowData(selectedCharacterKey)
    local parentWindow = AlternateWorldMainContentWindow
    if not parentWindow or not AlternateWorldBankersEngine then return end

    -- Trækker sikkert rammerne ud fra din core datamotor
    local panel, scrollContent = AlternateWorldBankersEngine.InitializeCorePanel(parentWindow)
    if not panel or not scrollContent then return end
    panel:Show()

    local currentRealm = GetRealmName()
    for _, line in ipairs(AW_BankerRowsPool) do line:Hide() end

    local currentYOffset = -5
    for count, cat in ipairs(BANKER_CATEGORIES) do
        local row = AW_BankerRowsPool[count]
        if not row then
            row = CreateFrame("Frame", "AW_BankerRowLineInstance" .. count, scrollContent)
            row:SetSize(scrollContent:GetWidth(), ROW_HEIGHT)

            row.Icon = row:CreateTexture(nil, "OVERLAY")
            row.Icon:SetSize(20, 20)
            row.Icon:SetPoint("LEFT", row, "LEFT", 15, 0)

            row.Label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.Label:SetPoint("LEFT", row.Icon, "RIGHT", 10, 0)
            row.Label:SetJustifyH("LEFT")

            row.AllyMenu = CreateFrame("Frame", "AW_BankerAllyDropdown" .. count, row, "UIDropDownMenuTemplate")
            row.AllyMenu:SetPoint("LEFT", row, "LEFT", 145, -2)
            UIDropDownMenu_SetWidth(row.AllyMenu, 110)

            row.HordeMenu = CreateFrame("Frame", "AW_BankerHordeDropdown" .. count, row, "UIDropDownMenuTemplate")
            row.HordeMenu:SetPoint("LEFT", row.AllyMenu, "RIGHT", -15, 0)
            UIDropDownMenu_SetWidth(row.HordeMenu, 110)

            AW_BankerRowsPool[count] = row
        end

        if count == 1 then row:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 0, -5)
        else row:SetPoint("TOPLEFT", AW_BankerRowsPool[count - 1], "BOTTOMLEFT", 0, -2) end

        row.Icon:SetTexture(cat.icon)
        row.Label:SetText("|cFFFFFFFF" .. cat.name .. "|r")

        -- Alliance dropdown rendering via cluster-engine data
        local allyAssignedKey = AlternateWorldBankersEngine.GetCategoryBanker(currentRealm, "Alliance", cat.id)
        if allyAssignedKey and AlternateWorldDB[allyAssignedKey] then
            UIDropDownMenu_SetText(row.AllyMenu, AlternateWorldBankersEngine.CleanClassColoredName(AlternateWorldDB[allyAssignedKey]))
        else
            UIDropDownMenu_SetText(row.AllyMenu, "|cFF888888(None assigned)|r")
        end
        UIDropDownMenu_Initialize(row.AllyMenu, function(self) InitializeCategoryDropdown(self, "Alliance", cat.id, row.AllyMenu) end)

        -- Horde dropdown rendering via cluster-engine data
        local hordeAssignedKey = AlternateWorldBankersEngine.GetCategoryBanker(currentRealm, "Horde", cat.id)
        if hordeAssignedKey and AlternateWorldDB[hordeAssignedKey] then
            UIDropDownMenu_SetText(row.HordeMenu, AlternateWorldBankersEngine.CleanClassColoredName(AlternateWorldDB[hordeAssignedKey]))
        else
            UIDropDownMenu_SetText(row.HordeMenu, "|cFF888888(None assigned)|r")
        end
        UIDropDownMenu_Initialize(row.HordeMenu, function(self) InitializeCategoryDropdown(self, "Horde", cat.id, row.HordeMenu) end)

        row:Show()
        currentYOffset = currentYOffset - ROW_HEIGHT - 2
    end
    scrollContent:SetHeight(math.abs(currentYOffset) + ROW_HEIGHT)
end

function AlternateWorldBankersView.HidePanel()
    if AlternateWorldBankersEngine then
        local panel = AlternateWorldBankersEngine.InitializeCorePanel(AlternateWorldMainContentWindow)
        if panel then panel:Hide() end
    end
end

function AlternateWorldBankersView.IsShown()
    if AlternateWorldBankersEngine then
        local panel = AlternateWorldBankersEngine.InitializeCorePanel(AlternateWorldMainContentWindow)
        return panel and panel:IsShown()
    end
    return false
end

-- End of [alternatebankersui.lua]
