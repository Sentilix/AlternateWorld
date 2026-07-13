-- ============================================================================
-- Alternate World - Main User Interface & Layout Frame
-- ============================================================================

AlternateWorldMainFrameEngine = {}
local addonVersion = C_AddOns.GetAddOnMetadata("AlternateWorld", "Version") or "0.6.4"
local addonAuthor = C_AddOns.GetAddOnMetadata("AlternateWorld", "Author") or "Mimma @ EU-Pyrewood Village"

local cachedPlayerName = nil
local cachedPlayerRealm = nil
AWCachedCharacterKey = nil

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

function AlternateWorldMainFrameEngine.GetVersion()
    return addonVersion
end

function AlternateWorldMainFrameEngine.GetAuthor()
    return addonAuthor
end

local function GetSelectedCharacterKey()
    if AWCachedCharacterKey then
        return AWCachedCharacterKey
    end
    
    -- Emergency fallback if cache was uninitialized
    local liveName = UnitName("player")
    local liveRealm = GetRealmName()
    if liveName and liveRealm and liveRealm ~= "" then
        AWCachedCharacterKey = liveName .. " - " .. liveRealm;
        return AWCachedCharacterKey;
    end

    return nil
end

function AlternateWorldMainFrameEngine.GetSelectedCharacterKey()
    return GetSelectedCharacterKey();
end

SLASH_ALTERNATEWORLD1 = "/aw"
SLASH_ALTERNATEWORLD2 = "/alternateworld"
SlashCmdList["ALTERNATEWORLD"] = function()
    if AlternateWorldMainFrame:IsShown() then 
        AlternateWorldMainFrame:Hide() 
    else 
        AlternateWorldNavigation.HideAllPanels()
        AlternateWorldMainFrame:Show()
        
        -- FIXED v0.6.2 DROPDOWN ACTIVATION HOOK: Core callback reference now safely targets the validated engine scope
        if AlternateWorldCharDropdown and AlternateWorldMainFrameEngine.InitializeDropdown then
            UIDropDownMenu_Initialize(AlternateWorldCharDropdown, AlternateWorldMainFrameEngine.InitializeDropdown)
            
            -- Render front-facing header string text safely after initialization is locked
            local data = AlternateWorldDB and AlternateWorldDB[AWCachedCharacterKey]
            if data and AlternateWorldConfig and AlternateWorldConfig.GetClassColoredText then
                local displayName = AlternateWorldConfig.GetClassColoredText(AWCachedCharacterKey, data.classToken) or "|cFFFFFFFF" .. (data.name or "Character") .. "|r"
                local factionIconInline = ""
                if data.faction == "Alliance" then factionIconInline = "|TInterface\\TargetingFrame\\UI-PVP-Alliance:14:14:0:0:64:64:0:38:0:38|t "
                elseif data.faction == "Horde" then factionIconInline = "|TInterface\\TargetingFrame\\UI-PVP-Horde:14:14:0:0:64:64:0:38:0:38|t " end
                UIDropDownMenu_SetText(AlternateWorldCharDropdown, factionIconInline .. displayName)
            end
        end

        AlternateWorldCharacterView.ShowData(AWCachedCharacterKey)
    end
end

-- FIXED v0.6.4 SLASH COMMAND: Displays local version and broadcasts queries utilizing the unified constants matrix
SLASH_ALTERNATEWORLDVERSION1 = "/awversion"
SLASH_ALTERNATEWORLDVERSION2 = "/alternateworldversion"
SlashCmdList["ALTERNATEWORLDVERSION"] = function()
    local localVersion = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("AlternateWorld", "Version") or "Unknown"
    local myPlayerName = UnitName("player") or "Character"
    
    -- FIXED v0.6.4 LEAN PRINT: Stripped all text concatenation hooks to leverage the centralized wrapper natively
    AddonPrint("Querying network for other active versions...")
    AddonPrint(string.format("%s is using Alternate World v%s", myPlayerName, localVersion))
    
    local targetChannel = nil
    if IsInRaid() then targetChannel = "RAID"
    elseif IsInGroup() then targetChannel = "PARTY" end
    
    if targetChannel and AlternateWorldConstants and AlternateWorldConstants.ADDON_COMM_PREFIX then
        pcall(function()
            C_ChatInfo.SendAddonMessage(AlternateWorldConstants.ADDON_COMM_PREFIX, "VERSION_REQUEST", targetChannel)
        end)
    end
end

-- FIXED v0.6.4 NETWORK RECEIVER: Cleanly routes cross-client outputs straight into the unified printing hub
function AlternateWorldMainFrameEngine.PrintVersionResult(senderName, versionString)
    if not senderName or not versionString then return end
    
    AddonPrint(string.format("%s is using Alternate World v%s", tostring(senderName), tostring(versionString)))
end

AlternateWorldMainFrame:SetScript("OnUpdate", function(self, elapsed)
    if AlternateWorldCore and AlternateWorldCore.IsFullyLoaded() and AlternateWorldAttunementsView and AlternateWorldAttunementsView.OnUpdateTick then
        AlternateWorldAttunementsView.OnUpdateTick(AWCachedCharacterKey)
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

-- FIXED v0.6.2 REALM SUB-MENU ENGINE: Splits character data into Level 1 realms and strips realm suffixes from Level 2 rows to optimize text space
function AlternateWorldMainFrameEngine.InitializeDropdown(self, level)
    if not AlternateWorldDB then return end
    
    level = level or 1

    -- LEVEL 1: Dynamically scan and extract all unique realms active inside your database
    if level == 1 then
        local realmSet = {}
        for key, data in pairs(AlternateWorldDB) do
            if key ~= "Settings" and type(data) == "table" and data.classToken and not data.isVirtual then
                local realmName = data.realm or string.match(key, "%s*-%s*(.+)") or "Unknown Realm"
                realmSet[realmName] = true
            end
        end
        
        -- Sort realms alphabetically for precise UX structure
        local sortedRealms = {}
        for realmName in pairs(realmSet) do table.insert(sortedRealms, realmName) end
        table.sort(sortedRealms)
        
        -- Build the Level 1 realm folder row entries
        for _, realmName in ipairs(sortedRealms) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = "|TInterface\\Icons\\INV_Misc_Book_09:14:14:0:0|t |cFFFFFFFF" .. realmName .. "|r"
            info.value = realmName
            info.hasArrow = true -- Spawns the Level 2 flyout arrow indicator dynamically
            info.notCheckable = true
            UIDropDownMenu_AddButton(info, level)
        end
        return
    end

    -- LEVEL 2: Render individual characters residing strictly on the hovered realm selection context
    if level == 2 then
        local targetRealm = UIDROPDOWNMENU_MENU_VALUE -- Extract the hovered realm string from the Level 1 parent object
        local sortedKeys = {}
        
        -- Filter character profile keys that match the active sub-menu realm boundary pass
        for key, data in pairs(AlternateWorldDB) do 
            if key ~= "Settings" and type(data) == "table" and data.classToken and not data.isVirtual then
                local altRealm = data.realm or string.match(key, "%s*-%s*(.+)") or "Unknown Realm"
                if altRealm == targetRealm then
                    table.insert(sortedKeys, key) 
                end
            end
        end
        table.sort(sortedKeys)
        
        -- Populate individual character execution rows inside the designated server submenu container
        for _, key in ipairs(sortedKeys) do
            local data = AlternateWorldDB[key]
            local info = UIDropDownMenu_CreateInfo()
            
            local displayName = nil
            if AlternateWorldConfig and AlternateWorldConfig.GetClassColoredText and data and data.classToken then
                displayName = AlternateWorldConfig.GetClassColoredText(key, data.classToken)
            end
            if not displayName or displayName == "" then
                displayName = "|cFFFFFFFF" .. (data and data.name or "Character") .. "|r"
            end
    
            -- TECHNICAL TEXT PURIFICATION: Strip any realm naming suffixes from Level 2 to maximize text space layout parameters
            local cleanDisplayName = string.gsub(displayName, "%s*-%s*[^|]+", "")
            
            -- Compile the faction alignment graphics safely to attach into the text string layout parameters
            local factionIconInline = ""
            if data and data.faction == "Alliance" then 
                factionIconInline = "|TInterface\\TargetingFrame\\UI-PVP-Alliance:14:14:0:0:64:64:0:38:0:38|t "
            elseif data and data.faction == "Horde" then 
                factionIconInline = "|TInterface\\TargetingFrame\\UI-PVP-Horde:14:14:0:0:64:64:0:38:0:38|t " 
            end
            
            info.text = factionIconInline .. cleanDisplayName
            info.value = key
            info.arg1 = key
            
            -- Core function executor triggered instantly when a row item is clicked inside Level 2
            info.func = function(button, arg1)
                AWCachedCharacterKey = arg1
                
                if AlternateWorldCharDropdown then
                    UIDropDownMenu_SetText(AlternateWorldCharDropdown, factionIconInline .. displayName)
                end
                
                if AlternateWorldNavigation and AlternateWorldNavigation.RefreshActiveView then
                    AlternateWorldNavigation.RefreshActiveView(AWCachedCharacterKey)
                end
                
                CloseDropDownMenus() -- Terminate all active dropdown matrices cleanly upon choice confirmation
            end
            
            info.checked = (AWCachedCharacterKey == key)
            UIDropDownMenu_AddButton(info, level)
        end
    end
end

function AlternateWorldMainFrameEngine.OnAddonLoaded()
    local myFullName = GetSelectedCharacterKey()

    if myFullName and AlternateWorldDB then       
        AWCachedCharacterKey = myFullName;
        
        local currentData = AlternateWorldDB[AWCachedCharacterKey]
        local currentClassToken = currentData and currentData.classToken or select(2, UnitClass("player"))
        local coloredName = AlternateWorldConfig.GetClassColoredText(AWCachedCharacterKey, currentClassToken)
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
-- v0.6.1 MODULE B: External Integration Engine (Time-Delayed LibDataBroker)
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
            AWCachedCharacterKey = cachedPlayerName .. " - " .. cachedPlayerRealm
        end
        
        -- FIXED v0.6.1 MASTER ONHIDE WATCHDOG: Syncs all inner layers perfectly when the frame window is closed via the red X
        if AlternateWorldMainFrame and AlternateWorldMainFrame.HookScript then
            AlternateWorldMainFrame:HookScript("OnHide", function()
                if AlternateWorldNavigation and AlternateWorldNavigation.HideAllPanels then
                    AlternateWorldNavigation.HideAllPanels()
                end
            end)
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
