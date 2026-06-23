-- ============================================================================
-- Alternate World - Inventory View Module Panel (v0.2.0 - PERSONALIZED)
-- ============================================================================

AlternateWorldInventoryView = {}

local InventoryPanel = nil
local BagScrollFrame = nil
local BagScrollContent = nil

local BagsTitleText = nil
local BagsLastUpdateText = nil
local BankTitleText = nil
local BankLastUpdateText = nil
local BankEmptyTextString = nil

local AW_BagButtonPool = {}
local AW_BankButtonPool = {}

local BUTTON_SIZE, PADDING, BUTTONS_PER_ROW = 36, 6, 9

function AlternateWorldInventoryView.CreatePanel(parentWindow)
    if InventoryPanel then return InventoryPanel end

    InventoryPanel = CreateFrame("Frame", "AWInventoryPanelGlobal", parentWindow)
    InventoryPanel:SetAllPoints(parentWindow)
    InventoryPanel:Hide()

    BagScrollFrame = CreateFrame("ScrollFrame", "AW_InventoryScrollFrame", InventoryPanel, "UIPanelScrollFrameTemplate")
    BagScrollFrame:SetPoint("TOPLEFT", InventoryPanel, "TOPLEFT", 0, -5)
    BagScrollFrame:SetPoint("BOTTOMRIGHT", InventoryPanel, "BOTTOMRIGHT", -30, 15)

    BagScrollContent = CreateFrame("Frame", nil, BagScrollFrame)
    BagScrollContent:SetSize(InventoryPanel:GetWidth() - 40, 1)
    BagScrollFrame:SetScrollChild(BagScrollContent)

    BagsTitleText = BagScrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    BagsTitleText:SetPoint("TOPLEFT", BagScrollContent, "TOPLEFT", 15, -10)

    BagsLastUpdateText = BagScrollContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    BagsLastUpdateText:SetPoint("TOPLEFT", BagsTitleText, "BOTTOMLEFT", 0, -2)

    BankTitleText = BagScrollContent:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    BankLastUpdateText = BagScrollContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")

    BankEmptyTextString = BagScrollContent:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    BankEmptyTextString:SetText("|cFF888888Bank vault has not been scanned yet on this character.|r")

    return InventoryPanel
end

local function RenderGridSection(itemDataList, buttonPool, startX, startY, poolPrefix)
    local col, row = 0, 0
    for i, itemObj in ipairs(itemDataList) do
        local btn = buttonPool[i]
        if not btn then
            btn = CreateFrame("Button", "AW_InvGrid" .. poolPrefix .. i, BagScrollContent, "ItemButtonTemplate")
            btn:SetSize(BUTTON_SIZE, BUTTON_SIZE)
            btn:SetScript("OnEnter", function(self)
                if self.itemID then
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetHyperlink("item:" .. self.itemID)
                    GameTooltip:Show()
                end
            end)
            btn:SetScript("OnLeave", function(self) GameTooltip:Hide() end)
            buttonPool[i] = btn
        end

        local xOffset = startX + (col * (BUTTON_SIZE + PADDING))
        local yOffset = startY - (row * (BUTTON_SIZE + PADDING))
        btn:SetPoint("TOPLEFT", BagScrollContent, "TOPLEFT", xOffset, yOffset)

        local itemTexture = C_Item.GetItemIconByID(itemObj.id) or "interface\\icons\\inv_misc_questionmark"
        local iconTextureFrame = _G[btn:GetName() .. "IconTexture"]
        if iconTextureFrame then iconTextureFrame:SetTexture(itemTexture) end

        local countTextFrame = _G[btn:GetName() .. "Count"]
        if countTextFrame then
            if itemObj.count > 1 then countTextFrame:SetText(itemObj.count) countTextFrame:Show()
            else countTextFrame:Hide() end
        end

        btn.itemID = itemObj.id
        btn:Show()

        col = col + 1
        if col >= BUTTONS_PER_ROW then col = 0 row = row + 1 end
    end
    return col > 0 and (row + 1) or row
end

local function CompileSortedArray(rawItemsTable)
    local itemArray = {}
    if rawItemsTable then
        for _, itemData in ipairs(rawItemsTable) do
            local rawNumericID = tonumber(itemData.id)
            if rawNumericID then
                local currentName = itemData.name
                if not currentName or currentName == "Unknown Item" or currentName == "" then
                    currentName = GetItemInfo(rawNumericID) or "Unknown Item"
                end
                table.insert(itemArray, { id = rawNumericID, name = currentName, count = itemData.count or 1 })
            end
        end
    end
    table.sort(itemArray, function(a, b) return a.name < b.name end)
    return itemArray
end

function AlternateWorldInventoryView.ShowData(selectedCharacterKey)
    if not InventoryPanel or not AlternateWorldDB or not selectedCharacterKey then return end
    local data = AlternateWorldDB[selectedCharacterKey]
    if not data then return end

    -- FIXED LOGIC: Handles native language grammar apostrophe formatting rules cleanly
    local charName = data.name or "Character"
    local genitiveName = charName .. "'s"
    if string.sub(charName, -1) == "s" or string.sub(charName, -1) == "S" then
        genitiveName = charName .. "'"
    end

    if BagsTitleText then BagsTitleText:SetText("|cFFFFFFFF" .. genitiveName .. " Bag Inventory|r") end
    BagsLastUpdateText:SetText("Last Scan: |cFF888888" .. (data.bagsUpdated or "Never Scanned") .. "|r")

    for _, btn in ipairs(AW_BagButtonPool) do btn:Hide() end
    for _, btn in ipairs(AW_BankButtonPool) do btn:Hide() end
    BankTitleText:Hide() BankLastUpdateText:Hide() BankEmptyTextString:Hide()

    local sortedBags = CompileSortedArray(data.bagItems)
    local bagsRowsUsed = RenderGridSection(sortedBags, AW_BagButtonPool, 15, -50, "Bag")
    local bagsHeightDelta = bagsRowsUsed * (BUTTON_SIZE + PADDING)

    local bankTopY = -60 - bagsHeightDelta
    BankTitleText:SetPoint("TOPLEFT", BagScrollContent, "TOPLEFT", 15, bankTopY)
    BankTitleText:SetText("|cFFFFFFFF" .. genitiveName .. " Bank Vault|r")
    BankTitleText:Show()

    BankLastUpdateText:SetPoint("TOPLEFT", BankTitleText, "BOTTOMLEFT", 0, -2)
    BankLastUpdateText:SetText("Last Scan: |cFF888888" .. (data.bankUpdated or "Never Scanned") .. "|r")
    BankLastUpdateText:Show()

    local bankHeightDelta = 40
    if not data.bankItems or #data.bankItems == 0 then
        BankEmptyTextString:SetPoint("TOPLEFT", BankLastUpdateText, "BOTTOMLEFT", 0, -10)
        BankEmptyTextString:Show()
        bankHeightDelta = 30
    else
        local sortedBank = CompileSortedArray(data.bankItems)
        local bankRowsUsed = RenderGridSection(sortedBank, AW_BankButtonPool, 15, bankTopY - 40, "Bank")
        bankHeightDelta = bankRowsUsed * (BUTTON_SIZE + PADDING) + 20
    end

    local totalContentCanvasHeight = math.abs(bankTopY) + bankHeightDelta + 20
    BagScrollContent:SetHeight(totalContentCanvasHeight)
    InventoryPanel:Show()
end

function AlternateWorldInventoryView.HidePanel() if InventoryPanel then InventoryPanel:Hide() end end
function AlternateWorldInventoryView.IsShown() return InventoryPanel and InventoryPanel:IsShown() end

-- End of [alternateinventory.lua]
