-- ============================================================================
-- Alternate World - Inventory View Module Panel
-- ============================================================================

AlternateWorldInventoryView = {}

local InventoryPanel = nil
local ScrollFrame = nil
local ScrollContent = nil

-- Generates a grid layout of items inside a specific container block frame
local function BuildItemGrid(parentFrame, itemsList, titleText, timestamp)
    -- Remove old dynamically generated entries before drawing a new snapshot
    if parentFrame.Items then
        for _, btn in ipairs(parentFrame.Items) do btn:Hide() end
    end
    parentFrame.Items = {}

    -- FIXED: Injected gray timestamp line strictly ABOVE section title labels
    if not parentFrame.TimeLabel then
        parentFrame.TimeLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        parentFrame.TimeLabel:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 10, 0)
        parentFrame.TimeLabel:SetTextColor(0.65, 0.65, 0.65) -- Slate Gray
    end
    parentFrame.TimeLabel:SetText("Last updated: " .. (timestamp or "Never"))

    -- Label Title (Shifted down below the newly introduced TimeLabel)
    if not parentFrame.Title then
        parentFrame.Title = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        parentFrame.Title:SetPoint("TOPLEFT", parentFrame.TimeLabel, "BOTTOMLEFT", 0, -4)
    end
    parentFrame.Title:SetText(titleText)

    if not itemsList or #itemsList == 0 then
        if not parentFrame.EmptyLabel then
            parentFrame.EmptyLabel = parentFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            parentFrame.EmptyLabel:SetPoint("TOPLEFT", parentFrame.Title, "BOTTOMLEFT", 10, -10)
        end
        parentFrame.EmptyLabel:SetText("No data cached yet for this section.")
        parentFrame.EmptyLabel:Show()
        return 50 
    else
        if parentFrame.EmptyLabel then parentFrame.EmptyLabel:Hide() end
    end

    local ICON_SIZE = 32
    local SPACING = 6
    local COLUMNS = 9
    local row, col = 0, 0

    for i, itemData in ipairs(itemsList) do
        local btn = CreateFrame("Button", nil, parentFrame, "ItemButtonTemplate")
        btn:SetSize(ICON_SIZE, ICON_SIZE)
        
        -- Y-Offset adjusted to account for double top header strings
        local xOffset = 10 + (col * (ICON_SIZE + SPACING))
        local yOffset = -45 - (row * (ICON_SIZE + SPACING))
        btn:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", xOffset, yOffset)
        
        if itemData.icon then btn.icon:SetTexture(itemData.icon) end
        
        if btn.Count then
            if itemData.count and itemData.count > 1 then
                btn.Count:SetText(itemData.count)
                btn.Count:Show() 
            else
                btn.Count:SetText("")
                btn.Count:Hide() 
            end
        end

        btn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetItemByID(itemData.id)
            GameTooltip:Show()
        end)
        btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        table.insert(parentFrame.Items, btn)

        col = col + 1
        if col >= COLUMNS then
            col = 0
            row = row + 1
        end
    end

    local finalRows = col == 0 and row or row + 1
    return 50 + (finalRows * (ICON_SIZE + SPACING))
end

function AlternateWorldInventoryView.CreatePanel(parentWindow)
    if InventoryPanel then return InventoryPanel end

    InventoryPanel = CreateFrame("Frame", nil, parentWindow)
    InventoryPanel:SetAllPoints(parentWindow)
    InventoryPanel:Hide()

    -- Main scrolling container architecture
    ScrollFrame = CreateFrame("ScrollFrame", "AlternateWorldInventoryScrollFrame", InventoryPanel, "UIPanelScrollFrameTemplate")
    ScrollFrame:SetPoint("TOPLEFT", InventoryPanel, "TOPLEFT", 10, -10)
    ScrollFrame:SetPoint("BOTTOMRIGHT", InventoryPanel, "BOTTOMRIGHT", -30, 10)

    ScrollContent = CreateFrame("Frame", nil, ScrollFrame)
    ScrollContent:SetSize(parentWindow:GetWidth() - 40, 1) 
    ScrollFrame:SetScrollChild(ScrollContent)

    ScrollContent.BagsFrame = CreateFrame("Frame", nil, ScrollContent)
    ScrollContent.BagsFrame:SetPoint("TOPLEFT", ScrollContent, "TOPLEFT", 0, -10)
    ScrollContent.BagsFrame:SetWidth(parentWindow:GetWidth() - 40)

    ScrollContent.BankFrame = CreateFrame("Frame", nil, ScrollContent)
    ScrollContent.BankFrame:SetWidth(parentWindow:GetWidth() - 40)

    return InventoryPanel
end

function AlternateWorldInventoryView.ShowData(selectedCharacterKey)
    if not InventoryPanel or not AlternateWorldDB or not selectedCharacterKey then return end
    
    local data = AlternateWorldDB[selectedCharacterKey]
    if not data then return end

    -- FIXED: Draw Grid 1 using independent bagsUpdated timestamp parameter
    local bagsHeight = BuildItemGrid(ScrollContent.BagsFrame, data.bagItems, "|cFFFFFFFF" .. data.name .. "'s Bags|r", data.bagsUpdated)
    ScrollContent.BagsFrame:SetHeight(bagsHeight)

    -- Reposition Grid 2 safely below Grid 1 dynamically
    ScrollContent.BankFrame:SetPoint("TOPLEFT", ScrollContent.BagsFrame, "BOTTOMLEFT", 0, -25)

    -- FIXED: Draw Grid 2 using independent bankUpdated timestamp parameter
    local bankHeight = BuildItemGrid(ScrollContent.BankFrame, data.bankItems, "|cFFFFFFFF" .. data.name .. "'s Bank|r", data.bankUpdated)
    ScrollContent.BankFrame:SetHeight(bankHeight)

    local totalHeight = bagsHeight + bankHeight + 50
    ScrollContent:SetHeight(totalHeight)

    InventoryPanel:Show()
end

function AlternateWorldInventoryView.HidePanel()
    if InventoryPanel then InventoryPanel:Hide() end
end

function AlternateWorldInventoryView.IsShown()
    return InventoryPanel and InventoryPanel:IsShown()
end
