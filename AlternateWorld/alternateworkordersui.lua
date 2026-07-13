-- ============================================================================
-- Alternate World - Work Orders "McDonald's Screen" UI Module (v0.7.0)
-- ============================================================================
AlternateWorldWorkOrdersView = {}

local OrdersPanel, OrdersScrollFrame, OrdersScrollContent, OrdersHeadingText = nil, nil, nil, nil
local HeaderCol1, HeaderCol2, HeaderCol3 = nil, nil, nil
local Orders_RowsPool = {}
local ROW_HEIGHT = 24 

-- FIXED v0.7.0 SYMMETRIC MARGINS: Core horizontal left-anchors for perfect structural alignment
local COL1_X, COL2_X, COL3_X = 15, 260, 390 -- Shifted COL3 slightly left to leave 100% space for the delete cross

function AlternateWorldWorkOrdersView.CreatePanel(parentFrame)
    if OrdersPanel then return OrdersPanel end

    OrdersPanel = CreateFrame("Frame", "AW_WorkOrdersPanelContainer", parentFrame)
    OrdersPanel:SetSize(parentFrame:GetWidth() - 240, parentFrame:GetHeight() - 50)
    OrdersPanel:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", 235, -40)
    OrdersPanel:Hide()

    -- Main Panel Banner Title
    OrdersHeadingText = OrdersPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    OrdersHeadingText:SetPoint("TOPLEFT", OrdersPanel, "TOPLEFT", 15, 12)
    OrdersHeadingText:SetText("|cFFFFFFFFActive Work Orders|r")

    -- Column Headers setup
    HeaderCol1 = OrdersPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    HeaderCol1:SetPoint("TOPLEFT", OrdersPanel, "TOPLEFT", COL1_X, -15)
    HeaderCol1:SetText("|cFF888888Order|r")

    HeaderCol2 = OrdersPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    HeaderCol2:SetPoint("TOPLEFT", OrdersPanel, "TOPLEFT", COL2_X, -15) 
    HeaderCol2:SetText("|cFF888888Ordered By|r")

    HeaderCol3 = OrdersPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    HeaderCol3:SetPoint("TOPLEFT", OrdersPanel, "TOPLEFT", COL3_X, -15) 
    HeaderCol3:SetText("|cFF888888Status|r")

    -- Scroll Frame Setup
    OrdersScrollFrame = CreateFrame("ScrollFrame", "AW_WorkOrdersScrollFrameInstance", OrdersPanel, "UIPanelScrollFrameTemplate")
    OrdersScrollFrame:SetSize(OrdersPanel:GetWidth() - 35, OrdersPanel:GetHeight() - 55)
    OrdersScrollFrame:SetPoint("TOPLEFT", OrdersPanel, "TOPLEFT", 10, -32) 

    OrdersScrollContent = CreateFrame("Frame", "AW_WorkOrdersScrollContentInstance", OrdersScrollFrame)
    OrdersScrollContent:SetSize(OrdersScrollFrame:GetWidth(), 1)
    OrdersScrollFrame:SetScrollChild(OrdersScrollContent)

    return OrdersPanel
end

function AlternateWorldWorkOrdersView.HidePanel()
    if OrdersPanel then OrdersPanel:Hide() end
end

function AlternateWorldWorkOrdersView.IsShown()
    return OrdersPanel and OrdersPanel:IsShown()
end

-- FIXED v0.7.0 STATIC POPUP CONFIRMATION SHIELD: Register a secure confirmation dialogue box with the Blizzard engine layout rules
StaticPopupDialogs["AW_CONFIRM_DELETE_ORDER"] = {
    text = "Are you sure you want to delete this work order?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self, dataIndex)
        if AlternateWorldWorkOrdersView and AlternateWorldWorkOrdersView.ExecutePurge then
            AlternateWorldWorkOrdersView.ExecutePurge(dataIndex)
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Target handler executed exclusively AFTER the user confirms "Yes" on the interface pop-up element
function AlternateWorldWorkOrdersView.ExecutePurge(orderIndex)
    if not orderIndex or not AlternateWorldDB or not AlternateWorldDB.Settings or not AlternateWorldDB.Settings.WorkOrders then return end
    
    table.remove(AlternateWorldDB.Settings.WorkOrders, orderIndex)
    PlaySound(841) -- Crisp trash mechanical sound click
    AlternateWorldWorkOrdersView.ShowData()
end

-- Re-wired click handler pass targets the pop-up shield directly
function AlternateWorldWorkOrdersView.DeleteOrder(orderIndex)
    if not orderIndex then return end
    -- Trigger the central dialogue dialog layout frame overlay and pass the target data array index securely into memory
    StaticPopup_Show("AW_CONFIRM_DELETE_ORDER", nil, nil, orderIndex)
end

-- FIXED v0.7.0 DISPLAY ENGINE: Renders entries in a 3-column matrix grid, sorted with newest on top and Completed orders at the bottom
function AlternateWorldWorkOrdersView.ShowData(selectedCharacterKey)
    if not OrdersPanel or not OrdersScrollContent then return end
    OrdersPanel:Show()

    -- Reset visibility on the active rows template mapping pool
    for _, row in ipairs(Orders_RowsPool) do row:Hide() end

    -- Verify database records integrity baseline
    if not AlternateWorldDB or not AlternateWorldDB.Settings or not AlternateWorldDB.Settings.WorkOrders or #AlternateWorldDB.Settings.WorkOrders == 0 then
        OrdersHeadingText:SetText("|cFF888888No Active Orders. Kitchen is empty!|r")
        HeaderCol1:Hide() HeaderCol2:Hide() HeaderCol3:Hide()
        return
    end

    OrdersHeadingText:SetText("|cFFFFFFFFActive Work Orders|r")
    HeaderCol1:Show() HeaderCol2:Show() HeaderCol3:Show()
    
    local currentYOffset, count = -5, 0
    local totalOrders = #AlternateWorldDB.Settings.WorkOrders

    -- FIXED v0.7.0 TWO-PASS CHRONOLOGICAL SORTING: Split rendering to force Complete orders to the bottom
    
    -- STAGE 1: Loop BACKWARDS over active orders (Pending & Ready) to put the newest requests on top
    for i = totalOrders, 1, -1 do
        local order = AlternateWorldDB.Settings.WorkOrders[i]
        if order and order.status ~= "Complete" then
            count = count + 1
            AlternateWorldWorkOrdersView.RenderOrderRow(count, i, order, currentYOffset)
        end
    end

    -- STAGE 2: Loop BACKWARDS over Completed orders to place them at the absolute bottom of the kitchen screen
    for i = totalOrders, 1, -1 do
        local order = AlternateWorldDB.Settings.WorkOrders[i]
        if order and order.status == "Complete" then
            count = count + 1
            AlternateWorldWorkOrdersView.RenderOrderRow(count, i, order, currentYOffset)
        end
    end

    OrdersScrollContent:SetHeight(math.max(1, count * (ROW_HEIGHT + 4)))
end

-- FIXED v0.7.0 ATOMIC ROW RENDERER: Helper function to generate and anchor individual order rows cleanly
function AlternateWorldWorkOrdersView.RenderOrderRow(count, dbIndex, order, currentYOffset)
    local rowFrame = Orders_RowsPool[count]

    -- Instantiate a fresh structural 3-column layout row if missing from template memory
    if not rowFrame then
        rowFrame = CreateFrame("Frame", "AW_OrderRowInstance" .. count, OrdersScrollContent)
        rowFrame:SetSize(OrdersScrollContent:GetWidth() - 10, ROW_HEIGHT)
        
        local rCol1, rCol2, rCol3 = 5, (COL2_X - 10), (COL3_X - 10)

        -- Kolonne 1: Recipe String Node
        rowFrame.Col1Text = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rowFrame.Col1Text:SetPoint("LEFT", rowFrame, "LEFT", rCol1, 0)
        rowFrame.Col1Text:SetJustifyH("LEFT")
        rowFrame.Col1Text:SetWidth(240) 

        -- Kolonne 2: Ordered By Name
        rowFrame.Col2Text = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rowFrame.Col2Text:SetPoint("LEFT", rowFrame, "LEFT", rCol2, 0) 
        rowFrame.Col2Text:SetJustifyH("LEFT")
        rowFrame.Col2Text:SetWidth(rCol3 - rCol2 - 10)

        -- Kolonne 3: Status Tracking Node
        rowFrame.Col3Text = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        rowFrame.Col3Text:SetPoint("LEFT", rowFrame, "LEFT", rCol3, 0) 
        rowFrame.Col3Text:SetJustifyH("LEFT")

        -- Delete Button Cross [X]
        rowFrame.DeleteBtn = CreateFrame("Button", "AW_OrderRowDeleteBtn" .. count, rowFrame)
        rowFrame.DeleteBtn:SetSize(16, 16)
        rowFrame.DeleteBtn:SetPoint("RIGHT", rowFrame, "RIGHT", -15, 0)
        
        rowFrame.DeleteBtn.Text = rowFrame.DeleteBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        rowFrame.DeleteBtn.Text:SetAllPoints(rowFrame.DeleteBtn)
        rowFrame.DeleteBtn.Text:SetText("|cFFFF2222[X]|r")
        rowFrame.DeleteBtn.Text:SetJustifyH("CENTER")

        Orders_RowsPool[count] = rowFrame
    end

    -- Vertical row flow alignment logic
    if count == 1 then 
        rowFrame:SetPoint("TOPLEFT", OrdersScrollContent, "TOPLEFT", 0, currentYOffset)
    else 
        rowFrame:SetPoint("TOPLEFT", Orders_RowsPool[count - 1], "BOTTOMLEFT", 0, -4) 
    end

    local rawRealm = order.realm or GetRealmName()
    local shortRealm = string.sub(string.gsub(rawRealm, "%s+", ""), 1, 3)
    
    local factionIcon = ""
    if order.faction == "Alliance" then factionIcon = "|TInterface\\TargetingFrame\\UI-PVP-Alliance:11:11:0:0:64:64:0:38:0:38|t "
    elseif order.faction == "Horde" then factionIcon = "|TInterface\\TargetingFrame\\UI-PVP-Horde:11:11:0:0:64:64:0:38:0:38|t " end

    -- Dynamic Rarity Enforcement
    local itemColorPrefix = order.recipeColor or "|cFFFFFFFF"
    rowFrame.Col1Text:SetText(factionIcon .. itemColorPrefix .. (order.recipeName or "Unknown Recipe") .. "|r")

    -- Class Color parsing
    local rawIdentityText = string.format("%s-%s", order.orderedBy or "Alt", shortRealm)
    local activeClassToken = order.classToken or "PRIEST"
    local classColoredText = rawIdentityText
    if AlternateWorldConfig and AlternateWorldConfig.GetClassColoredText then
        classColoredText = AlternateWorldConfig.GetClassColoredText(rawIdentityText, activeClassToken)
    end
    rowFrame.Col2Text:SetText(classColoredText)

    -- Status texts formatting
    if order.status == "Pending" then
        rowFrame.Col3Text:SetText("|cFFFFD700Pending|r")
    elseif order.status == "Ready" then
        rowFrame.Col3Text:SetText("|cFF00FF00Ready|r")
    else
        rowFrame.Col3Text:SetText("|cFF888888Complete|r")
    end

    -- Bind the dynamic array location index securely using the original dbIndex pass parameters
    if rowFrame.DeleteBtn then
        rowFrame.DeleteBtn:SetScript("OnClick", function()
            AlternateWorldWorkOrdersView.DeleteOrder(dbIndex)
        end)
        rowFrame.DeleteBtn:Show()
    end

    rowFrame:Show()
end

-- End of [alternateworkordersui.lua]