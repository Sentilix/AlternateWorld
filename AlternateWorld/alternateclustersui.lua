-- ============================================================================
-- Alternate World - Server Clusters Layout UI Panel Module (v0.4.0 - FINAL)
-- ============================================================================

AlternateWorldClustersView = {}

local ClustersPanel = nil
local MainTitleText = nil
local SubTitleText = nil
local ClustersScrollFrame = nil
local ClustersScrollContent = nil
local SummaryContainer = nil

local AW_ClusterRowsPool = {}
local SummaryStringsPool = {}
local ROW_HEIGHT = 32

function AlternateWorldClustersView.CreatePanel(parentWindow)
    if ClustersPanel then return ClustersPanel end

    ClustersPanel = CreateFrame("Frame", "AWClustersPanelGlobal", parentWindow)
    ClustersPanel:SetAllPoints(parentWindow)
    ClustersPanel:Hide()

    MainTitleText = ClustersPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    MainTitleText:SetPoint("TOPLEFT", ClustersPanel, "TOPLEFT", 20, -10)
    MainTitleText:SetText("|cFFFFFFFFAccount Server Clusters Manager|r")

    SubTitleText = ClustersPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    SubTitleText:SetPoint("TOPLEFT", MainTitleText, "BOTTOMLEFT", 0, -2)
    SubTitleText:SetText("Link your characters realms into shared clusters to unify mail and space tracking layout buckets")

    ClustersScrollFrame = CreateFrame("ScrollFrame", "AW_ClustersScrollFrameInstance", ClustersPanel, "UIPanelScrollFrameTemplate")
    ClustersScrollFrame:SetPoint("TOPLEFT", ClustersPanel, "TOPLEFT", 0, -50)
    ClustersScrollFrame:SetPoint("BOTTOMRIGHT", ClustersPanel, "BOTTOMRIGHT", -30, 110)

    ClustersScrollContent = CreateFrame("Frame", nil, ClustersScrollFrame)
    ClustersScrollContent:SetSize(ClustersPanel:GetWidth() - 40, 1)
    ClustersScrollFrame:SetScrollChild(ClustersScrollContent)

    local Divider = ClustersPanel:CreateTexture(nil, "BACKGROUND")
    Divider:SetSize(ClustersPanel:GetWidth() - 20, 2)
    Divider:SetPoint("BOTTOMLEFT", ClustersPanel, "BOTTOMLEFT", 10, 105)
    Divider:SetColorTexture(0.3, 0.3, 0.3, 0.6)

    SummaryContainer = CreateFrame("Frame", "AW_ClustersSummaryBox", ClustersPanel)
    SummaryContainer:SetPoint("TOPLEFT", Divider, "BOTTOMLEFT", 10, -5)
    SummaryContainer:SetPoint("BOTTOMRIGHT", ClustersPanel, "BOTTOMRIGHT", -10, 5)

    return ClustersPanel
end

local function InitializeRealmDropdown(self, realmName, dropdownMenuFrame, iconTexture)
    if not AlternateWorldDB or not AlternateWorldClusterConstants then return end

    local info = UIDropDownMenu_CreateInfo()
    info.text = "|cFF888888(None)|r"
    info.value = "none"
    info.checked = (AlternateWorldDB.Settings.Clusters[realmName] == nil)
    info.func = function()
        AlternateWorldDB.Settings.Clusters[realmName] = nil
        UIDropDownMenu_SetText(dropdownMenuFrame, "|cFF888888(None)|r")
        if iconTexture then iconTexture:Hide() end
        AlternateWorldClustersView.RefreshClusterView()
    end
    UIDropDownMenu_AddButton(info, 1)

    for i = 1, 5 do
        local clusterKey = "cluster_" .. i
        local customName = AlternateWorldDB.Settings.ClusterNames[clusterKey] or ("Cluster " .. i)
        local asset = AlternateWorldClusterConstants.Assets[clusterKey]

        info.text = "|T" .. asset.icon .. ":12:12:0:0|t " .. customName
        info.value = clusterKey
        info.checked = (AlternateWorldDB.Settings.Clusters[realmName] == clusterKey)
        info.func = function()
            AlternateWorldDB.Settings.Clusters[realmName] = clusterKey
            UIDropDownMenu_SetText(dropdownMenuFrame, customName)
            if iconTexture then
                iconTexture:SetTexture(asset.icon)
                iconTexture:Show()
            end
            AlternateWorldClustersView.RefreshClusterView()
        end
        UIDropDownMenu_AddButton(info, 1)
    end
end

function AlternateWorldClustersView.ShowData()
    if not ClustersPanel then
        AlternateWorldClustersView.CreatePanel(AlternateWorldMainContentWindow)
    end
    if not ClustersPanel then return end
    ClustersPanel:Show()
    AlternateWorldClustersView.RefreshClusterView()
end

function AlternateWorldClustersView.RefreshClusterView()
    if not ClustersPanel or not AlternateWorldDB or not AlternateWorldClusterConstants then return end

    local knownRealmsMap = {}
    for key, data in pairs(AlternateWorldDB) do
        if key ~= "Settings" and data and data.realm and data.realm ~= "Unknown" then
            knownRealmsMap[data.realm] = true
        end
    end

    local sortedRealms = {}
    for rName in pairs(knownRealmsMap) do table.insert(sortedRealms, rName) end
    table.sort(sortedRealms)

    for _, row in ipairs(AW_ClusterRowsPool) do row:Hide() end

    local currentYOffset = -5
    for count, rName in ipairs(sortedRealms) do
        local row = AW_ClusterRowsPool[count]
        if not row then
            row = CreateFrame("Frame", "AW_ClusterRowLine" .. count, ClustersScrollContent)
            row:SetSize(ClustersScrollContent:GetWidth(), ROW_HEIGHT)

            row.Icon = row:CreateTexture(nil, "OVERLAY")
            row.Icon:SetSize(16, 16)
            row.Icon:SetPoint("LEFT", row, "LEFT", 20, 0)
            row.Icon:Hide()

            row.Label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            row.Label:SetPoint("LEFT", row.Icon, "RIGHT", 8, 0)
            row.Label:SetJustifyH("LEFT")

            row.Menu = CreateFrame("Frame", "AW_ClusterRealmDropdown" .. count, row, "UIDropDownMenuTemplate")
            row.Menu:SetPoint("RIGHT", row, "RIGHT", -10, -2)
            UIDropDownMenu_SetWidth(row.Menu, 130)

            AW_ClusterRowsPool[count] = row
        end

        if count == 1 then row:SetPoint("TOPLEFT", ClustersScrollContent, "TOPLEFT", 0, -5)
        else row:SetPoint("TOPLEFT", AW_ClusterRowsPool[count - 1], "BOTTOMLEFT", 0, -2) end

        row.Label:SetText("|cFFFFFFFF" .. rName .. "|r")

        local activeCluster = AlternateWorldDB.Settings.Clusters[rName]
        if activeCluster and AlternateWorldClusterConstants.Assets[activeCluster] then
            row.Icon:SetTexture(AlternateWorldClusterConstants.Assets[activeCluster].icon)
            row.Icon:Show()
            local cName = AlternateWorldDB.Settings.ClusterNames[activeCluster] or AlternateWorldClusterConstants.Assets[activeCluster].name
            UIDropDownMenu_SetText(row.Menu, cName)
        else
            row.Icon:Hide()
            UIDropDownMenu_SetText(row.Menu, "|cFF888888(None)|r")
        end

        UIDropDownMenu_Initialize(row.Menu, function(self) InitializeRealmDropdown(self, rName, row.Menu, row.Icon) end)

        row:Show()
        currentYOffset = currentYOffset - ROW_HEIGHT - 2
    end
    ClustersScrollContent:SetHeight(math.abs(currentYOffset) + ROW_HEIGHT)

    for _, str in ipairs(SummaryStringsPool) do str:Hide() end

    local sumYOffset = 0
    for i = 1, 5 do
        local clusterKey = "cluster_" .. i
        local asset = AlternateWorldClusterConstants.Assets[clusterKey]
        local customName = AlternateWorldDB.Settings.ClusterNames[clusterKey] or asset.name

        local connectedList = {}
        for rName, cKey in pairs(AlternateWorldDB.Settings.Clusters) do
            if cKey == clusterKey then table.insert(connectedList, rName) end
        end
        table.sort(connectedList)
        local connectedStr = #connectedList > 0 and table.concat(connectedList, ", ") or "|cFF888888(Empty Pool)|r"

        local sumBtn = SummaryStringsPool[i]
        if not sumBtn then
            sumBtn = CreateFrame("Button", "AW_ClusterSummaryRow" .. i, SummaryContainer)
            sumBtn:SetSize(SummaryContainer:GetWidth() - 20, 16)
            
            sumBtn.Text = sumBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            sumBtn.Text:SetAllPoints(sumBtn)
            sumBtn.Text:SetJustifyH("LEFT")

            sumBtn:SetScript("OnClick", function()
                local currentSavedName = AlternateWorldDB.Settings.ClusterNames[clusterKey] or customName
                local popup = StaticPopup_Show("AW_RENAME_CLUSTER_PROMPT", currentSavedName)
                
                if popup and popup.EditBox then
                    popup.data = clusterKey
                    popup.EditBox:SetText(currentSavedName)
                    popup.EditBox:HighlightText()
                    
                    popup.EditBox:SetScript("OnEnterPressed", function(self)
                        local text = self:GetText()
                        if text and string.gsub(text, "%s+", "") ~= "" then
                            AlternateWorldDB.Settings.ClusterNames[clusterKey] = text
                            AlternateWorldClustersView.RefreshClusterView()
                            StaticPopup_Hide("AW_RENAME_CLUSTER_PROMPT")
                        end
                    end)
                    
                    popup.EditBox:SetScript("OnEscapePressed", function(self)
                        StaticPopup_Hide("AW_RENAME_CLUSTER_PROMPT")
                    end)
                end
            end)

            SummaryStringsPool[i] = sumBtn
        end

        sumBtn:SetPoint("TOPLEFT", SummaryContainer, "TOPLEFT", 10, sumYOffset)
        sumBtn.Text:SetText(string.format("|T%s:12:12:0:0|t |cFFFFFFFF%s:|r |cFFFFD100%s|r", asset.icon, customName, connectedStr))
        sumBtn:Show()

        sumYOffset = sumYOffset - 18
    end
end

function AlternateWorldClustersView.HidePanel() if ClustersPanel then ClustersPanel:Hide() end end
function AlternateWorldClustersView.IsShown() return ClustersPanel and ClustersPanel:IsShown() end

-- End of [alternateclustersui.lua]
