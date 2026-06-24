-- ============================================================================
-- Alternate World - Bankers View UI Module Panel (v0.3.0 - REBALANCED)
-- ============================================================================

AlternateWorldBankersView = {}

local BankersPanel = nil
local BankersScrollContent = nil
local AW_BankerRowsPool = {}
local CurrentContextRealm = nil
local ROW_HEIGHT = 44

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

function AlternateWorldBankersView.CreatePanel(parentWindow)
    if BankersPanel then return BankersPanel end
    if AlternateWorldBankersEngine and AlternateWorldBankersEngine.InitializeCorePanel then
        BankersPanel, BankersScrollContent = AlternateWorldBankersEngine.InitializeCorePanel(parentWindow)
    end
    return BankersPanel
end

local function InitializeFactionDropdown(self, targetFaction, dropdownMenuFrame, categoryID, textFrame)
    if not AlternateWorldDB or not CurrentContextRealm or not AlternateWorldBankersEngine then return end
    local sortedKeys = AlternateWorldBankersEngine.GetSortedFactionKeys(targetFaction)

    local info = UIDropDownMenu_CreateInfo()
    info.text = "|cFF888888(None)|r"
    info.value = "none"
    info.checked = (not AlternateWorldDB.Settings.Bankers[CurrentContextRealm] or not AlternateWorldDB.Settings.Bankers[CurrentContextRealm][targetFaction] or AlternateWorldDB.Settings.Bankers[CurrentContextRealm][targetFaction][categoryID] == nil)
    info.func = function()
        AlternateWorldDB.Settings.Bankers[CurrentContextRealm][targetFaction][categoryID] = nil
        UIDropDownMenu_SetText(dropdownMenuFrame, "|cFF888888(None)|r")
        if textFrame then textFrame:SetText("") end
    end
    UIDropDownMenu_AddButton(info, 1)

    for _, key in ipairs(sortedKeys) do
        local data = AlternateWorldDB[key]
        local formattedString = AlternateWorldBankersEngine.CleanClassColoredName(data)

        info.text = formattedString
        info.value = key
        info.checked = (AlternateWorldDB.Settings.Bankers[CurrentContextRealm][targetFaction][categoryID] == key)
        info.func = function()
            AlternateWorldDB.Settings.Bankers[CurrentContextRealm][targetFaction][categoryID] = key
            UIDropDownMenu_SetText(dropdownMenuFrame, formattedString)
            if textFrame and AlternateWorldCharacterEngine then
                local freeBags = AlternateWorldCharacterEngine.GetFreeBagSlotsCount(data)
                local freeBank = AlternateWorldCharacterEngine.GetFreeBankSlotsCount(data)
                textFrame:SetText(string.format("Free: |cFFFFFFFF%d|r Bag / |cFFFFFFFF%d|r Bank", freeBags, freeBank))
            end
        end
        UIDropDownMenu_AddButton(info, 1)
    end
end

local function SetupMenuSelectionDisplay(targetFaction, dropdownMenuFrame, categoryID, textFrame)
    if not AlternateWorldDB or not AlternateWorldBankersEngine then return end
    local assignedKey = AlternateWorldDB.Settings.Bankers[CurrentContextRealm][targetFaction][categoryID]
    if assignedKey and AlternateWorldDB[assignedKey] then
        local data = AlternateWorldDB[assignedKey]
        UIDropDownMenu_SetText(dropdownMenuFrame, AlternateWorldBankersEngine.CleanClassColoredName(data))
        if textFrame and AlternateWorldCharacterEngine then
            local freeBags = AlternateWorldCharacterEngine.GetFreeBagSlotsCount(data)
            local freeBank = AlternateWorldCharacterEngine.GetFreeBankSlotsCount(data)
            textFrame:SetText(string.format("Free: |cFFFFFFFF%d|r Bag / |cFFFFFFFF%d|r Bank", freeBags, freeBank))
        end
    else
        UIDropDownMenu_SetText(dropdownMenuFrame, "|cFF888888(None)|r")
        if textFrame then textFrame:SetText("") end
    end
end

function AlternateWorldBankersView.ShowData(selectedCharacterKey)
    if not BankersPanel or not BankersScrollContent or not AlternateWorldDB or not selectedCharacterKey then return end
    BankersPanel:Show()

    local activeCharData = AlternateWorldDB[selectedCharacterKey]
    if not activeCharData then return end

    CurrentContextRealm = activeCharData.realm or GetRealmName()

    if not AlternateWorldDB.Settings then AlternateWorldDB.Settings = {} end
    if not AlternateWorldDB.Settings.Bankers then AlternateWorldDB.Settings.Bankers = {} end
    if not AlternateWorldDB.Settings.Bankers[CurrentContextRealm] then AlternateWorldDB.Settings.Bankers[CurrentContextRealm] = {} end
    if not AlternateWorldDB.Settings.Bankers[CurrentContextRealm]["Alliance"] then AlternateWorldDB.Settings.Bankers[CurrentContextRealm]["Alliance"] = {} end
    if not AlternateWorldDB.Settings.Bankers[CurrentContextRealm]["Horde"] then AlternateWorldDB.Settings.Bankers[CurrentContextRealm]["Horde"] = {} end

    for _, row in ipairs(AW_BankerRowsPool) do row:Hide() end

    local currentYOffset, count = -5, 0
    for i, cat in ipairs(BANKER_CATEGORIES) do
        count = count + 1
        local row = AW_BankerRowsPool[count]
        if not row then
            row = CreateFrame("Frame", "AW_BankerRowInstance" .. count, BankersScrollContent)
            row:SetSize(BankersScrollContent:GetWidth(), ROW_HEIGHT)
            row.Icon = row:CreateTexture(nil, "OVERLAY")
            row.Icon:SetSize(28, 28)
            row.Icon:SetPoint("LEFT", row, "LEFT", 20, 4)
            row.Label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.Label:SetPoint("LEFT", row.Icon, "RIGHT", 8, 4)
            row.Label:SetSize(110, ROW_HEIGHT)
            row.Label:SetJustifyH("LEFT")
            row.AllyMenu = CreateFrame("Frame", "AW_AllyBankDropdown" .. count, row, "UIDropDownMenuTemplate")
            row.AllyMenu:SetPoint("LEFT", row, "LEFT", 138, 2)
            UIDropDownMenu_SetWidth(row.AllyMenu, 100)
            row.AllySlotsText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            row.AllySlotsText:SetPoint("TOPLEFT", row.AllyMenu, "BOTTOMLEFT", 20, 4)
            row.AllySlotsText:SetJustifyH("LEFT")
            row.HordeMenu = CreateFrame("Frame", "AW_HordeBankDropdown" .. count, row, "UIDropDownMenuTemplate")
            row.HordeMenu:SetPoint("LEFT", row, "LEFT", 283, 2)
            UIDropDownMenu_SetWidth(row.HordeMenu, 100)
            row.HordeSlotsText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            row.HordeSlotsText:SetPoint("TOPLEFT", row.HordeMenu, "BOTTOMLEFT", 20, 4)
            row.HordeSlotsText:SetJustifyH("LEFT")
            AW_BankerRowsPool[count] = row
        end
        if count == 1 then row:SetPoint("TOPLEFT", BankersScrollContent, "TOPLEFT", 0, -5)
        else row:SetPoint("TOPLEFT", AW_BankerRowsPool[count - 1], "BOTTOMLEFT", 0, -4) end

        row.Icon:SetTexture(cat.icon)
        row.Label:SetText("|cFFFFFFFF" .. cat.name .. "|r")

        UIDropDownMenu_Initialize(row.AllyMenu, function(self) InitializeFactionDropdown(self, "Alliance", row.AllyMenu, cat.id, row.AllySlotsText) end)
        SetupMenuSelectionDisplay("Alliance", row.AllyMenu, cat.id, row.AllySlotsText)
        UIDropDownMenu_Initialize(row.HordeMenu, function(self) InitializeFactionDropdown(self, "Horde", row.HordeMenu, cat.id, row.HordeSlotsText) end)
        SetupMenuSelectionDisplay("Horde", row.HordeMenu, cat.id, row.HordeSlotsText)

        row:Show()
        currentYOffset = currentYOffset - ROW_HEIGHT - 4
    end
    BankersScrollContent:SetHeight(math.abs(currentYOffset) + ROW_HEIGHT)
end

function AlternateWorldBankersView.HidePanel() if BankersPanel then BankersPanel:Hide() end end
function AlternateWorldBankersView.IsShown() return BankersPanel and BankersPanel:IsShown() end

-- End of [alternatebankersui.lua]
