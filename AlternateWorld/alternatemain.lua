-- ============================================================================
-- Alternate World - Main User Interface & Layout Frame (v0.3.0 - MENU BG RESTORED)
-- ============================================================================

AlternateWorldMainFrameEngine = {}

local AlternateWorldMainFrame = CreateFrame("Frame", "AlternateWorldMainFrame", UIParent, "BasicFrameTemplateWithInset")
AlternateWorldMainFrame:SetSize(600, 460) 
AlternateWorldMainFrame:SetPoint("CENTER", UIParent, "CENTER") 
AlternateWorldMainFrame:SetFrameStrata("HIGH")

local addonVersion = C_AddOns.GetAddOnMetadata("AlternateWorld", "Version") or "0.3.0"
AlternateWorldMainFrame.TitleText:SetText("Alternate World v" .. addonVersion)

AlternateWorldMainFrame:SetMovable(true)
AlternateWorldMainFrame:EnableMouse(true)
AlternateWorldMainFrame:RegisterForDrag("LeftButton")
AlternateWorldMainFrame:SetScript("OnDragStart", AlternateWorldMainFrame.StartMoving)
AlternateWorldMainFrame:SetScript("OnDragStop", AlternateWorldMainFrame.StopMovingOrSizing)
AlternateWorldMainFrame:Hide()

local selectedCharacterKey = nil
local function GetSelectedCharacterKey() return selectedCharacterKey end
function AlternateWorldMainFrameEngine.GetSelectedCharacterKey() return selectedCharacterKey end

SLASH_ALTERNATEWORLD1 = "/aw"
SLASH_ALTERNATEWORLD2 = "/alternateworld"
SlashCmdList["ALTERNATEWORLD"] = function()
    if AlternateWorldMainFrame:IsShown() then 
        AlternateWorldMainFrame:Hide() 
    else 
        AlternateWorldNavigation.HideAllPanels()
        AlternateWorldMainFrame:Show()
        AlternateWorldCharacterView.ShowData(selectedCharacterKey)
    end
end

AlternateWorldMainFrame:SetScript("OnUpdate", function(self, elapsed)
    if AlternateWorldCore and AlternateWorldCore.IsFullyLoaded() and AlternateWorldAttunementsView and AlternateWorldAttunementsView.OnUpdateTick then
        AlternateWorldAttunementsView.OnUpdateTick(selectedCharacterKey)
    end
end)

local TOPBAR_HEIGHT = 40
local TOTAL_WIDTH = AlternateWorldMainFrame:GetWidth() - 20 
local MENU_WIDTH = TOTAL_WIDTH * 0.20
local CONTENT_WIDTH = TOTAL_WIDTH * 0.80
local FRAME_HEIGHT = AlternateWorldMainFrame:GetHeight() - 35 - TOPBAR_HEIGHT 

AlternateWorldMainTopBar = CreateFrame("Frame", nil, AlternateWorldMainFrame)
AlternateWorldMainTopBar:SetSize(TOTAL_WIDTH, TOPBAR_HEIGHT)
AlternateWorldMainTopBar:SetPoint("TOPLEFT", AlternateWorldMainFrame, "TOPLEFT", 10, -25) 

AlternateWorldCharDropdown = CreateFrame("Frame", "AlternateWorldCharDropdown", AlternateWorldMainTopBar, "UIDropDownMenuTemplate")
AlternateWorldCharDropdown:SetPoint("LEFT", AlternateWorldMainTopBar, "LEFT", -10, 0)
UIDropDownMenu_SetWidth(AlternateWorldCharDropdown, 200)

local LeftMenu = CreateFrame("Frame", nil, AlternateWorldMainFrame)
LeftMenu:SetSize(MENU_WIDTH, FRAME_HEIGHT)
LeftMenu:SetPoint("TOPLEFT", AlternateWorldMainTopBar, "BOTTOMLEFT", 0, -5)

-- FIXED: Restored the classic atmospheric semitransparent background texture mapping layer
local menuBg = LeftMenu:CreateTexture(nil, "BACKGROUND")
menuBg:SetAllPoints(LeftMenu)
menuBg:SetTexture("Interface\\TalentFrame\\PriestDiscipline-Topleft")
menuBg:SetAlpha(0.6) 

AlternateWorldMainContentWindow = CreateFrame("Frame", "AlternateWorldMainContentWindow", AlternateWorldMainFrame)
AlternateWorldMainContentWindow:SetSize(CONTENT_WIDTH, FRAME_HEIGHT)
AlternateWorldMainContentWindow:SetPoint("TOPLEFT", LeftMenu, "TOPRIGHT", 0, 0)

AlternateWorldCharacterView.CreatePanel(AlternateWorldMainContentWindow)
AlternateWorldInventoryView.CreatePanel(AlternateWorldMainContentWindow)
AlternateWorldAttunementsView.CreatePanel(AlternateWorldMainContentWindow)
AlternateWorldHistoryView.CreatePanel(AlternateWorldMainContentWindow)
AlternateWorldProfessionsView.CreatePanel(AlternateWorldMainContentWindow)

AlternateWorldNavigation.CreateMenu(LeftMenu, GetSelectedCharacterKey)

local function InitializeDropdown(self, level)
    if not AlternateWorldDB then return end
    local sortedKeys = {}
    for key in pairs(AlternateWorldDB) do table.insert(sortedKeys, key) end
    table.sort(sortedKeys)
    
    local info = UIDropDownMenu_CreateInfo()
    for _, key in ipairs(sortedKeys) do
        local data = AlternateWorldDB[key]
        local displayName = AlternateWorldConfig.GetClassColoredText(key, data.classToken)
        local factionIconInline = ""
        if data.faction == "Alliance" then factionIconInline = "|TInterface\\TargetingFrame\\UI-PVP-Alliance:14:14:0:0:64:64:0:38:0:38|t "
        elseif data.faction == "Horde" then factionIconInline = "|TInterface\\TargetingFrame\\UI-PVP-Horde:14:14:0:0:64:64:0:38:0:38|t " end
        
        info.text = factionIconInline .. displayName
        info.value = key
        info.arg1 = key
        info.func = function(button, arg1)
            selectedCharacterKey = arg1
            UIDropDownMenu_SetText(AlternateWorldCharDropdown, factionIconInline .. displayName)
            AlternateWorldNavigation.RefreshActiveView(selectedCharacterKey)
        end
        info.checked = (selectedCharacterKey == key)
        UIDropDownMenu_AddButton(info, level)
    end
end

function AlternateWorldMainFrameEngine.OnAddonLoaded()
    local myName = UnitName("player")
    if myName and AlternateWorldDB then
        local foundKey = nil
        for dbKey in pairs(AlternateWorldDB) do
            local cleanDbName = string.match(dbKey, "([^%-]+)") or dbKey
            cleanDbName = string.gsub(cleanDbName, "%s+", "")
            if string.lower(cleanDbName) == string.lower(myName) then
                foundKey = dbKey
                break
            end
        end
        
        selectedCharacterKey = foundKey or (myName .. " - " .. GetRealmName())
        UIDropDownMenu_Initialize(AlternateWorldCharDropdown, InitializeDropdown)
        
        local currentData = AlternateWorldDB[selectedCharacterKey]
        local currentClassToken = currentData and currentData.classToken or select(2, UnitClass("player"))
        local coloredName = AlternateWorldConfig.GetClassColoredText(selectedCharacterKey, currentClassToken)
        local myFaction = currentData and currentData.faction or UnitFactionGroup("player")
        
        local myFactionIcon = ""
        if myFaction == "Alliance" then myFactionIcon = "|TInterface\\TargetingFrame\\UI-PVP-Alliance:14:14:0:0:64:64:0:38:0:38|t "
        elseif myFaction == "Horde" then myFactionIcon = "|TInterface\\TargetingFrame\\UI-PVP-Horde:14:14:0:0:64:64:0:38:0:38|t " end
        
        UIDropDownMenu_SetText(AlternateWorldCharDropdown, myFactionIcon .. coloredName)
        if AlternateWorldComm and AlternateWorldComm.Initialize then AlternateWorldComm.Initialize() end
    end
end

function AlternateWorldMainFrameEngine.RefreshUI() AlternateWorldNavigation.RefreshActiveView(selectedCharacterKey) end

-- End of [alternatemain.lua]
