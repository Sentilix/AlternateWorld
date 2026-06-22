-- ============================================================================
-- Alternate World - Main User Interface & Layout Frame
-- ============================================================================

AlternateWorldMainFrameEngine = {}

local AlternateWorldMainFrame = CreateFrame("Frame", "AlternateWorldMainFrame", UIParent, "BasicFrameTemplateWithInset")
AlternateWorldMainFrame:SetSize(600, 460) 
AlternateWorldMainFrame:SetPoint("CENTER", UIParent, "CENTER") 

local addonVersion = C_AddOns.GetAddOnMetadata("AlternateWorld", "Version") or "0.1.0"
AlternateWorldMainFrame.TitleText:SetText("Alternate World v" .. addonVersion)

AlternateWorldMainFrame:SetMovable(true)
AlternateWorldMainFrame:EnableMouse(true)
AlternateWorldMainFrame:RegisterForDrag("LeftButton")
AlternateWorldMainFrame:SetScript("OnDragStart", AlternateWorldMainFrame.StartMoving)
AlternateWorldMainFrame:SetScript("OnDragStop", AlternateWorldMainFrame.StopMovingOrSizing)
AlternateWorldMainFrame:Hide()

local selectedCharacterKey = nil

local function GetSelectedCharacterKey()
    return selectedCharacterKey
end

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

-- Live update loop handler
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

local TopBar = CreateFrame("Frame", nil, AlternateWorldMainFrame)
TopBar:SetSize(TOTAL_WIDTH, TOPBAR_HEIGHT)
TopBar:SetPoint("TOPLEFT", AlternateWorldMainFrame, "TOPLEFT", 10, -25) 

local CharacterDropdown = CreateFrame("Frame", "AlternateWorldCharDropdown", TopBar, "UIDropDownMenuTemplate")
CharacterDropdown:SetPoint("LEFT", TopBar, "LEFT", -10, 0)
UIDropDownMenu_SetWidth(CharacterDropdown, 200)

local LeftMenu = CreateFrame("Frame", nil, AlternateWorldMainFrame)
LeftMenu:SetSize(MENU_WIDTH, FRAME_HEIGHT)
LeftMenu:SetPoint("TOPLEFT", TopBar, "BOTTOMLEFT", 0, -5)

local menuBg = LeftMenu:CreateTexture(nil, "BACKGROUND")
menuBg:SetAllPoints(LeftMenu)
menuBg:SetTexture("Interface\\TalentFrame\\PriestDiscipline-Topleft")
menuBg:SetAlpha(0.6) 

local ContentWindow = CreateFrame("Frame", nil, AlternateWorldMainFrame)
ContentWindow:SetSize(CONTENT_WIDTH, FRAME_HEIGHT)
ContentWindow:SetPoint("TOPLEFT", LeftMenu, "TOPRIGHT", 0, 0)

-- Build sub-panels canvases hooks
AlternateWorldCharacterView.CreatePanel(ContentWindow)
AlternateWorldInventoryView.CreatePanel(ContentWindow)
AlternateWorldAttunementsView.CreatePanel(ContentWindow)
AlternateWorldHistoryView.CreatePanel(ContentWindow)
AlternateWorldProfessionsView.CreatePanel(ContentWindow) -- FIXED: Added panel framework initialization loop

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
        if data.faction == "Alliance" then
            factionIconInline = "|TInterface\\TargetingFrame\\UI-PVP-Alliance:14:14:0:0:64:64:0:38:0:38|t "
        elseif data.faction == "Horde" then
            factionIconInline = "|TInterface\\TargetingFrame\\UI-PVP-Horde:14:14:0:0:64:64:0:38:0:38|t "
        end
        
        info.text = factionIconInline .. displayName
        info.value = key
        info.arg1 = key
        info.func = function(button, arg1)
            selectedCharacterKey = arg1
            UIDropDownMenu_SetText(CharacterDropdown, factionIconInline .. displayName)
            AlternateWorldNavigation.RefreshActiveView(selectedCharacterKey)
        end
        info.checked = (selectedCharacterKey == key)
        UIDropDownMenu_AddButton(info, level)
    end
end

-- Core Callback Link: Triggered natively by the background Core engine when addon loads
function AlternateWorldMainFrameEngine.OnAddonLoaded()
    local myName = UnitName("player")
    local myRealm = GetRealmName()
    if myName and myRealm then
        selectedCharacterKey = myName .. " - " .. myRealm
        UIDropDownMenu_Initialize(CharacterDropdown, InitializeDropdown)
        
        local currentClassToken = select(2, UnitClass("player"))
        local coloredName = AlternateWorldConfig.GetClassColoredText(selectedCharacterKey, currentClassToken)
        local myFaction = UnitFactionGroup("player")
        local myFactionIcon = ""
        if myFaction == "Alliance" then myFactionIcon = "|TInterface\\TargetingFrame\\UI-PVP-Alliance:14:14:0:0:64:64:0:38:0:38|t "
        elseif myFaction == "Horde" then myFactionIcon = "|TInterface\\TargetingFrame\\UI-PVP-Horde:14:14:0:0:64:64:0:38:0:38|t " end
        
        UIDropDownMenu_SetText(CharacterDropdown, myFactionIcon .. coloredName)
    end
end

-- Core Callback Link: Repaints the actively viewed panel blueprint layer on background ticks
function AlternateWorldMainFrameEngine.RefreshUI()
    AlternateWorldNavigation.RefreshActiveView(selectedCharacterKey)
end
