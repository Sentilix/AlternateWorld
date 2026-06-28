-- ============================================================================
-- Alternate World - Main User Interface & Layout Frame
-- ============================================================================

AlternateWorldMainFrameEngine = {}
local addonVersion = C_AddOns.GetAddOnMetadata("AlternateWorld", "Version") or "0.6.0"
local addonAuthor = C_AddOns.GetAddOnMetadata("AlternateWorld", "Author") or "Mimma @ EU-Pyrewood Village"

-- FIXED v0.6.1 FLIGHT SHIELD: Hard-locked memory cache variables to survive Blizzard realm-name phase drops
local cachedPlayerName = nil
local cachedPlayerRealm = nil
local cachedCharacterKey = nil

local AlternateWorldMainFrame = CreateFrame("Frame", "AlternateWorldMainFrame", UIParent, "BasicFrameTemplateWithInset")
AlternateWorldMainFrame:SetSize(650, 560) 
AlternateWorldMainFrame:SetPoint("CENTER", UIParent, "CENTER") 
AlternateWorldMainFrame:SetFrameStrata("HIGH")

AlternateWorldMainFrame.TitleText:SetText("Alternate World v" .. addonVersion)

AlternateWorldMainFrame:SetMovable(true)
AlternateWorldMainFrame:EnableMouse(true)
AlternateWorldMainFrame:RegisterForDrag("LeftButton")
AlternateWorldMainFrame:SetScript("OnDragStart", AlternateWorldMainFrame.StartMoving)
AlternateWorldMainFrame:SetScript("OnDragStop", AlternateWorldMainFrame.StopMovingOrSizing)
AlternateWorldMainFrame:Hide()

local selectedCharacterKey = nil

function AlternateWorldMainFrameEngine.GetVersion()
    return addonVersion
end

function AlternateWorldMainFrameEngine.GetAuthor()
    return addonAuthor
end

-- FIXED v0.6.1 ROUTING REPAIR: Always fallback onto the hard-locked boot cache if Blizzard drops realm strings during flight
local function GetSelectedCharacterKey()
    if cachedCharacterKey then
        return cachedCharacterKey
    end
    
    -- Emergency fallback if cache was uninitialized
    local liveName = UnitName("player")
    local liveRealm = GetRealmName()
    if liveName and liveRealm and liveRealm ~= "" then
        return liveName .. " - " .. liveRealm
    end
    return nil
end

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
local MENU_WIDTH = TOTAL_WIDTH * 0.266
local CONTENT_WIDTH = TOTAL_WIDTH - MENU_WIDTH
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

local menuBg = LeftMenu:CreateTexture(nil, "BACKGROUND")
menuBg:SetAllPoints(LeftMenu)
menuBg:SetTexture("Interface\\TalentFrame\\PriestDiscipline-Topleft")
menuBg:SetAlpha(0.6) 

local MenuSignatureText = LeftMenu:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
MenuSignatureText:SetPoint("BOTTOM", LeftMenu, "BOTTOM", 0, 1)
MenuSignatureText:SetScale(0.85)
MenuSignatureText:SetText("v" .. AlternateWorldMainFrameEngine.GetVersion() .. " " .. AlternateWorldMainFrameEngine.GetAuthor())

AlternateWorldMainContentWindow = CreateFrame("Frame", "AlternateWorldMainContentWindow", AlternateWorldMainFrame)
AlternateWorldMainContentWindow:SetSize(CONTENT_WIDTH, FRAME_HEIGHT)
AlternateWorldMainContentWindow:SetPoint("TOPLEFT", LeftMenu, "TOPRIGHT", 0, 0)

AlternateWorldCharacterView.CreatePanel(AlternateWorldMainContentWindow)
AlternateWorldInventoryView.CreatePanel(AlternateWorldMainContentWindow)
AlternateWorldAttunementsView.CreatePanel(AlternateWorldMainContentWindow)
AlternateWorldHistoryView.CreatePanel(AlternateWorldMainContentWindow)
AlternateWorldProfessionsView.CreatePanel(AlternateWorldMainContentWindow)

AlternateWorldNavigation.CreateMenu(LeftMenu, GetSelectedCharacterKey)
AlternateWorldRestedXPView.CreatePanel(AlternateWorldMainContentWindow)
AlternateWorldBankersEngine.InitializeCorePanel(AlternateWorldMainContentWindow)

local function InitializeDropdown(self, level)
    if not AlternateWorldDB then return end
    local sortedKeys = {}
    
    -- THE BULLETPROOF SHIELD: Only extracts keys that actually represent characters, avoiding any settings leak permanently
    for key, data in pairs(AlternateWorldDB) do 
        if key ~= "Settings" and type(data) == "table" and data.classToken then
            table.insert(sortedKeys, key) 
        end
    end
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

        if not AlternateWorldDB.Settings then AlternateWorldDB.Settings = {} end

        if not AlternateWorldDB.Settings.Clusters then 
            AlternateWorldCategoryDB = AlternateWorldCategoryDB or {} -- Safe check
            AlternateWorldDB.Settings.Clusters = {} 
        end

        if not AlternateWorldDB.Settings.ClusterNames then
            AlternateWorldDB.Settings.ClusterNames = {
                ["cluster_1"] = "Cluster 1",
                ["cluster_2"] = "Cluster 2",
                ["cluster_3"] = "Cluster 3",
                ["cluster_4"] = "Cluster 4",
                ["cluster_5"] = "Cluster 5"
            }
        end
    end
end

function AlternateWorldMainFrameEngine.RefreshUI() AlternateWorldNavigation.RefreshActiveView(selectedCharacterKey) end

-- ============================================================================
-- v0.6.0 EXTERNAL INTEGRATION ENGINE: Global Dynamic Interface Router
-- ============================================================================

local function ToggleAddonInterface()
    local mainWin = _G["AlternateWorldMainContentWindow"]
    local vbView = _G["AlternateWorldVirtualBankersView"]
    local normalBankersView = _G["AlternateWorldBankersView"]

    local isAnyViewActive = false
    if vbView and vbView.IsShown and vbView.IsShown() then
        isAnyViewActive = true
    elseif normalBankersView and normalBankersView.IsShown and normalBankersView.IsShown() then
        isAnyViewActive = true
    end

    if isAnyViewActive then
        if vbView and vbView.HidePanel then vbView.HidePanel() end
        if normalBankersView and normalBankersView.HidePanel then normalBankersView.HidePanel() end
        if mainWin then mainWin:Hide() end
    else
        -- FIXED v0.6.0 SLASH COMMAND BYPASS: Triggers your stable verified command path to initialize panels safely
        if SlashCmdList and SlashCmdList["ALTERNATEWORLD"] then
            SlashCmdList["ALTERNATEWORLD"]("")
        elseif SlashCmdList and SlashCmdList["AW"] then
            SlashCmdList["AW"]("")
        end
    end
end

-- ============================================================================
-- v0.6.0 MODULE A: Official WoW Interface Options & Configuration Panel
-- ============================================================================
-- FIXED v0.6.0 CONFIGURATION CORE: Obliterated the tainted button and established the options database grid
local configPanel = CreateFrame("Frame", "AW_BlizzardInterfaceOptionsCategoryPanel")
configPanel.name = "Alternate World" 

local title = configPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", configPanel, "TOPLEFT", 16, -16)
title:SetText("|cFFFFFFFFAlternate World - Options Configuration|r")

-- FIXED v0.6.0 DYNAMIC CHECKBOX: Spawns the premier settings checkbox (Default Enabled) aligned right under the title
local minimapCB = CreateFrame("CheckButton", "AW_OptionsMinimapToggleCB", configPanel, "InterfaceOptionsCheckButtonTemplate")
minimapCB:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
_G[minimapCB:GetName() .. "Text"]:SetText("Show Minimap Icon")
_G[minimapCB:GetName() .. "Text"]:SetTextColor(1, 1, 1)

-- Internal runtime handler checking database configuration states to toggle layout markers
local function RefreshOptionsCheckboxState()
    if AlternateWorldDB and AlternateWorldDB.Settings and AlternateWorldDB.Settings.MinimapButtonSpec then
        -- LibDBIcon uses .hide = true to hide, so we invert the boolean for the "Show" checkbox layout
        local isHidden = AlternateWorldDB.Settings.MinimapButtonSpec.hide or false
        minimapCB:SetChecked(not isHidden)
    else
        -- Default Enabled policy if variables are uninitialized during initial initialization sequences
        minimapCB:SetChecked(true)
    end
end

-- Monitor frame loading triggers to safely synchronize interface checks with SavedVariables loading paths
configPanel:SetScript("OnShow", function()
    RefreshOptionsCheckboxState()
end)

minimapCB:SetScript("OnClick", function(self)
    if not AlternateWorldDB then AlternateWorldDB = {} end
    if not AlternateWorldDB.Settings then AlternateWorldDB.Settings = {} end
    if not AlternateWorldDB.Settings.MinimapButtonSpec then
        AlternateWorldDB.Settings.MinimapButtonSpec = { hide = false }
    end

    local isChecked = self:GetChecked()
    
    -- Invert value directly into LibDBIcon specifications registry parameters
    AlternateWorldDB.Settings.MinimapButtonSpec.hide = not isChecked

    -- Live-toggles the physical minimap graphic texture immediately without demanding a UI /reload sequence
    local LDBIcon = LibStub and LibStub:GetLibrary("LibDBIcon-1.0", true)
    if LDBIcon then
        if isChecked then
            LDBIcon:Show("AlternateWorld")
        else
            LDBIcon:Hide("AlternateWorld")
        end
    end
end)

-- Enforces registration paths across both legacy and updated Classic Era settings frameworks cleanly
if _G["Settings"] and _G["Settings"].RegisterCanvasLayoutCategory then
    local category = _G["Settings"].RegisterCanvasLayoutCategory(configPanel, configPanel.name)
    if _G["Settings"].RegisterAddOnCategory then
        _G["Settings"].RegisterAddOnCategory(category)
    end
elseif InterfaceOptions_AddCategory then
    InterfaceOptions_AddCategory(configPanel)
end

-- ============================================================================
-- v0.6.0 MODULE B: External Integration Engine (Time-Delayed LibDataBroker)
-- ============================================================================
local integrationBootstrapper = CreateFrame("Frame")
integrationBootstrapper:RegisterEvent("PLAYER_LOGIN")

integrationBootstrapper:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        self:UnregisterEvent("PLAYER_LOGIN")
            
        -- FIXED v0.6.1 INSTANCE CAPTURE: Safely locks character identity strings before flight status alterations
        cachedPlayerName = UnitName("player")
        cachedPlayerRealm = GetRealmName()
        if cachedPlayerName and cachedPlayerRealm then
            cachedCharacterKey = cachedPlayerName .. " - " .. cachedPlayerRealm
        end
        
        local LibStub = _G["LibStub"]
        local LDB = LibStub and LibStub:GetLibrary("LibDataBroker-1.1", true)
        local LDBIcon = LibStub and LibStub:GetLibrary("LibDBIcon-1.0", true)

        if LDB then
            local AW_DataObject = LDB:NewDataObject("AlternateWorld", {
                type = "launcher",
                text = "Alternate World",
                icon = "Interface\\Icons\\inv_misc_head_human_02", -- Pure Signature Yellow Human Female
                
                OnTooltipShow = function(tooltip)
                    if tooltip and tooltip.AddLine then
                        tooltip:AddLine("|cFFFFFFFFAlternate World|r")
                        tooltip:AddLine("|cFF00FF00Left-Click:|r Toggle main dashboard view")
                        tooltip:AddLine("|cFF888888Drag:|r Move minimap button context")
                    end
                end,
                
                OnClick = function(arg1, arg2)
                    if arg1 == "LeftButton" or arg2 == "LeftButton" then
                        ToggleAddonInterface()
                    end
                end,
            })

            if not AlternateWorldDB then AlternateWorldDB = {} end
            if not AlternateWorldDB.Settings then AlternateWorldDB.Settings = {} end
            if not AlternateWorldDB.Settings.MinimapButtonSpec then
                AlternateWorldDB.Settings.MinimapButtonSpec = { hide = false }
            end
            
            if LDBIcon then
                LDBIcon:Register("AlternateWorld", AW_DataObject, AlternateWorldDB.Settings.MinimapButtonSpec)
            end
        end
    end
end)

-- End of [alternatemain.lua]
