-- ============================================================================
-- Alternate World - Main User Interface & Layout Frame
-- ============================================================================

AlternateWorldMainFrameEngine = {}

local AlternateWorldMainFrame = CreateFrame("Frame", "AlternateWorldMainFrame", UIParent, "BasicFrameTemplateWithInset")
AlternateWorldMainFrame:SetSize(600, 460) 
AlternateWorldMainFrame:SetPoint("CENTER", UIParent, "CENTER") 

local addonVersion = C_AddOns.GetAddOnMetadata("AlternateWorld", "Version") or "0.2.0"
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

-- SLASH COMMAND 1: Standard GUI Toggler
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

-- NEW UI METHOD: Class-colors the sender name and prints the reported version safely into local chat
function AlternateWorldMainFrameEngine.PrintVersionResult(senderName, reportedVersion)
    local cleanName = string.match(senderName, "([^%-]+)") or senderName
    local _, classToken = UnitClass(cleanName)
    local formattedName = cleanName
    
    if classToken and AlternateWorldConfig and AlternateWorldConfig.GetClassColoredText then
        formattedName = AlternateWorldConfig.GetClassColoredText(cleanName, classToken)
    end
    
    local msg = string.format(
        "|cFF2266DD[|r|cFF00CCFFAlternate World|r|cFF2266DD] |r%s|cFF2266DD is using version |r|cFFFFD700%s|r", 
        formattedName, 
        reportedVersion
    )
    print(msg)
end

-- SLASH COMMAND 2: Group/Raid Version Checker Engine routed to the new safe gateway
SLASH_ALTERNATEWORLDVERSION1 = "/awversion"
SLASH_ALTERNATEWORLDVERSION2 = "/alternateworldversion"
SlashCmdList["ALTERNATEWORLDVERSION"] = function()
    if AlternateWorldComm and AlternateWorldComm.ExecuteVersionCheck then
        AlternateWorldComm.ExecuteVersionCheck()
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

AlternateWorldCharacterView.CreatePanel(ContentWindow)
AlternateWorldInventoryView.CreatePanel(ContentWindow)
AlternateWorldAttunementsView.CreatePanel(ContentWindow)
AlternateWorldHistoryView.CreatePanel(ContentWindow)
AlternateWorldProfessionsView.CreatePanel(ContentWindow)

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
        
        -- FIXED: Safely activate the communication listener once all window engines are 100% declared
        if AlternateWorldComm and AlternateWorldComm.Initialize then
            AlternateWorldComm.Initialize()
        end
    end
end

function AlternateWorldMainFrameEngine.RefreshUI()
    AlternateWorldNavigation.RefreshActiveView(selectedCharacterKey)
end
