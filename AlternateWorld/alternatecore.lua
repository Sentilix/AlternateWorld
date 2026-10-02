-- ============================================================================
-- Alternate World - Core Event & Orchestration Engine
-- ============================================================================

AlternateWorldCore = {}

-- Production Mode: Set to "0070dd" for Rare+. Set to "ff9d9d9d" for sandbox testing.
local LOOT_THRESHOLD_QUALITY = "0070dd" 

local CoreFrame = nil
local isAddonFullyLoaded = false
local pendingLevelUpLog = nil

local ATTUNEMENT_QUEST_MAP = {
    [7848] = "Molten Core Attunement", 
    [7761] = "Blackwing Lair Attunement",
    [6502] = "Onyxia's Lair Attunement (Alliance)", 
    [6570] = "Onyxia's Lair Attunement (Horde)",
    [9121] = "Naxxramas Attunement (Honored)", 
    [9122] = "Naxxramas Attunement (Revered)", 
    [9123] = "Naxxramas Attunement (Exalted)",
    [4731] = "BRD Shadowforge Key Access", 
    [5511] = "Scholomance Skeleton Key Access",
    [5144] = "Maraudon Scepter of Celebras Unlock", 
    [4742] = "UBRS Seal of Ascension Ring (Horde)", 
    [4743] = "UBRS Seal of Ascension Ring (Alliance)"
}

local REPUTATION_STANDINGS_MAP = {
    ["Hated"] = true, ["Hostile"] = true, ["Unfriendly"] = true, ["Neutral"] = true,
    ["Friendly"] = true, ["Honored"] = true, ["Revered"] = true, ["Exalted"] = true
}

local function CentralLiveContextGuard(event)
    -- We only enforce a switch if it's an event that triggers live server scanning
    if event == "BANKFRAME_OPENED" or event == "BAG_UPDATE" or event == "PLAYER_EQUIPMENT_CHANGED" then
        local currentKey = _G["AWCachedCharacterKey"]
        local myKey = AlternateWorld.lib:GetFullName("player")

        if not currentKey or not myKey then
            return;
        end;

        if currentKey ~= myKey then
            -- Hijack and lock the caching layer BEFORE any scraper module can read it
            _G["AWCachedCharacterKey"] = myKey
            
            -- Immediately snap the UI dropdown text and values back to the active character
            if AlternateWorld.Elements and AlternateWorld.Elements.CharacterDropdown then
                UIDropdownMenu_SetSelectedValue(AlternateWorld.Elements.CharacterDropdown, myKey)
                UIDropdownMenu_SetText(AlternateWorld.Elements.CharacterDropdown, AlternateWorld.lib:GetNormalName("player"))
            end
            
            -- Re-render view states synchronously so everything matches your own character
            if AlternateWorldCharacterEngine and AlternateWorldCharacterEngine.ProcessShowData then
                AlternateWorldCharacterEngine.ProcessShowData(myKey, AlternateWorld.Elements, AlternateWorld.Pool)
            end
            if AlternateWorldBagsEngine and AlternateWorldBagsEngine.RefreshBagsDisplay then
                AlternateWorldBagsEngine.RefreshBagsDisplay(myKey)
            end
        end
    end
end

local function FormatSecondsToHMS(totalSeconds)
    local rawSeconds = tonumber(totalSeconds)
    if not rawSeconds then return nil end

    local hours = math.floor(rawSeconds / 3600)
    local minutes = math.floor((rawSeconds % 3600) / 60)
    local seconds = math.floor(rawSeconds % 60)

    return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

function AlternateWorldCore.IsFullyLoaded()
    return isAddonFullyLoaded
end

function AlternateWorldCore.Initialize()
    if CoreFrame then return end

    CoreFrame = CreateFrame("Frame")
    
    CoreFrame:RegisterEvent("ADDON_LOADED")
    CoreFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    CoreFrame:RegisterEvent("CHARACTER_POINTS_CHANGED")
    CoreFrame:RegisterEvent("SPELLS_CHANGED")
    CoreFrame:RegisterEvent("PLAYER_MONEY")
    CoreFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
    CoreFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    CoreFrame:RegisterEvent("BANKFRAME_OPENED")
    CoreFrame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
    CoreFrame:RegisterEvent("BAG_UPDATE_DELAYED")
    CoreFrame:RegisterEvent("UNIT_QUEST_LOG_CHANGED")
    CoreFrame:RegisterEvent("ITEM_LOCK_CHANGED")
    CoreFrame:RegisterEvent("UPDATE_INSTANCE_INFO")

    CoreFrame:RegisterEvent("PLAYER_LEVEL_UP")
    CoreFrame:RegisterEvent("CHAT_MSG_LOOT")
    CoreFrame:RegisterEvent("QUEST_TURNED_IN")
    CoreFrame:RegisterEvent("CHAT_MSG_COMBAT_FACTION_CHANGE")
    CoreFrame:RegisterEvent("CHAT_MSG_SKILL")
    CoreFrame:RegisterEvent("TIME_PLAYED_MSG")

    CoreFrame:SetScript("OnEvent", function(self, event, arg1, arg2, ...)

        CentralLiveContextGuard(event);

        if event == "ADDON_LOADED" and arg1 == "AlternateWorld" then
            if not AlternateWorldDB then AlternateWorldDB = {} end
            
            if AlternateWorldMainFrameEngine and AlternateWorldMainFrameEngine.OnAddonLoaded then
                AlternateWorldMainFrameEngine.OnAddonLoaded()
            end
            
            isAddonFullyLoaded = true
            AlternateWorld.API.RequestRaidInfo()
        end

        if event == "PLAYER_ENTERING_WORLD" then
            local checkRealmOnLoad = AlternateWorld.API.GetRealmName()
            if checkRealmOnLoad and checkRealmOnLoad ~= "" then
                if AlternateWorldDBEngine and AlternateWorldDBEngine.SaveCurrentCharacterData then
                    AlternateWorldDBEngine.SaveCurrentCharacterData()
                end
            end
        end

        -- FIXED v0.6.4 LIVE EQUIPMENT UPDATE: Triggers a dynamic trailing debounce to eliminate Blizzard model race-conditions during ItemRack gear storms
        if event == "PLAYER_EQUIPMENT_CHANGED" then           
            -- Core execution block handles the data snapshot instantly in the background database
            if AlternateWorldDBEngine and AlternateWorldDBEngine.SaveCurrentCharacterData then
                AlternateWorldDBEngine.SaveCurrentCharacterData()
            end
            
            -- Secure the asynchronous timer frame object context safely
            if not AW_GearRefreshFrame then
                AW_GearRefreshFrame = CreateFrame("Frame")
            end
            
            -- FIXED v0.6.4 DYNAMIC TRAILING DEBOUNCE: Reset the accumulator directly outside the closure to restart the timer upon every gear event
            AW_GearElapsedDelay = 0
            
            -- Only bind the OnUpdate loop handler if it is not currently active in memory
            if not AW_GearRefreshFrame:GetScript("OnUpdate") then
                AW_GearRefreshFrame:SetScript("OnUpdate", function(self, elapsed)
                    AW_GearElapsedDelay = AW_GearElapsedDelay + elapsed
                    
                    -- FIXED v0.6.4 DEBOUNCE THRESHOLD: Trigger exactly 0.2 seconds AFTER the absolute final equipment piece has settled
                    if AW_GearElapsedDelay >= 0.2 then
                        -- Target reached! Clear the frame update listener immediately to close the execution thread cleanly
                        self:SetScript("OnUpdate", nil)
                        
                        -- Trigger the unified interface routing safely now that the Blizzard model textures are fully baked
                        if AlternateWorldMainFrameEngine and AlternateWorldMainFrameEngine.RefreshUI then
                            AlternateWorldMainFrameEngine.RefreshUI()
                        elseif AlternateWorldNavigation and AlternateWorldNavigation.RefreshActiveView and AWCachedCharacterKey then
                            AlternateWorldNavigation.RefreshActiveView(AWCachedCharacterKey)
                        end
                    end
                end)
            end
        end

        if event == "PLAYER_LEVEL_UP" and arg1 then
            pendingLevelUpLog = tonumber(arg1) or 1
            local ch = ChatFrame_TimePlayedCode or RequestTimePlayed
            if ch then ch() end 
        end

        if event == "TIME_PLAYED_MSG" and pendingLevelUpLog and arg1 then
            local formattedTimeStr = nil
            local rawSecondsFromArg = tonumber(arg1) or tonumber(arg2) or tonumber(string.match(arg1, "%d+"))
            if rawSecondsFromArg then
                formattedTimeStr = FormatSecondsToHMS(rawSecondsFromArg)
            end
            if not formattedTimeStr then
                formattedTimeStr = string.match(arg1, ".-played:?%s*(.-)%.?$") or arg1
            end
            
            local completeText = string.format("|cFF00CCFFReached Level %d! (Time Played: %s)|r", pendingLevelUpLog, formattedTimeStr)
            if AlternateWorldHistoryView and AlternateWorldHistoryView.LogEvent then
                AlternateWorldHistoryView.LogEvent(completeText)
            end
            pendingLevelUpLog = nil
        end

        if event == "CHAT_MSG_LOOT" and arg1 then
            local isPersonalLoot = string.find(arg1, "You receive loot:") or string.find(arg1, "Du modtager bytte:")
            
            if isPersonalLoot then
                local cleanLink = string.match(arg1, "(|c%x+|Hitem.-|h%[.-%]|h|r)")
                local shouldLog = false 
                
                if cleanLink then
                    if LOOT_THRESHOLD_QUALITY == "ff9d9d9d" then
                        shouldLog = true
                    else
                        if string.find(cleanLink, "cff0070dd") or string.find(cleanLink, "cffa335ee") or string.find(cleanLink, "cffff8000") then
                            shouldLog = true
                        end
                    end
                end
                
                if shouldLog and cleanLink and AlternateWorldHistoryView and AlternateWorldHistoryView.LogEvent then
                    AlternateWorldHistoryView.LogEvent(string.format("|cFFFFFFFFLooted item:|r %s", cleanLink))
                end
            end
        end

        if event == "QUEST_TURNED_IN" and arg1 then
            local targetQuestID = tonumber(arg1)
            if targetQuestID and ATTUNEMENT_QUEST_MAP[targetQuestID] and AlternateWorldHistoryView and AlternateWorldHistoryView.LogEvent then
                local msgText = string.format("|cFFFFD700Completed Attunement Quest: %s|r", ATTUNEMENT_QUEST_MAP[targetQuestID])
                AlternateWorldHistoryView.LogEvent(msgText)
            end
        end

        if event == "CHAT_MSG_COMBAT_FACTION_CHANGE" and arg1 then
            for standingName in pairs(REPUTATION_STANDINGS_MAP) do
                if string.find(arg1, standingName) then
                    local factionTitleName = string.match(arg1, "Reputation with%s+(.-)%s+has") or string.match(arg1, ".-with%s+(.-)%s+increased") or "Faction"
                    local finalMsg = string.format("|cFF35D335Reputation milestone reached: %s is now %s!|r", factionTitleName, standingName)
                    if AlternateWorldHistoryView and AlternateWorldHistoryView.LogEvent then
                        AlternateWorldHistoryView.LogEvent(finalMsg)
                    end
                    break
                end
            end
        end

        -- FIXED v1.0.0 SAFE STR CONVERSION: Protect text matching against C-Engine secret string taints in Forever
        if event == "CHAT_MSG_SKILL" and arg1 then
            -- Safe execution gate: Returns false if Blizzard throws a secret string memory exception
            local success, skillLevelValue = pcall(function()
                return tonumber(string.match(arg1, "%d+"))
            end)

            -- If the string conversion succeeded and we found a valid number, execute the milestones safely
            if success and skillLevelValue then
                if (skillLevelValue == 75 or skillLevelValue == 150 or skillLevelValue == 225 or skillLevelValue == 300 or skillLevelValue == 375 or skillLevelValue == 450) then
                    local skillNameStr = "Profession"
                    
                    -- Safe extraction of the profession name token from the chat layout
                    pcall(function()
                        skillNameStr = string.match(arg1, "Your skill in%s+(.-)%s+has") or "Profession"
                    end)

                    local profMsg = string.format("|cFFFFFFFFProfession milestone achieved: %s reached skill|r |cFFFFD700%d|r!", skillNameStr, skillLevelValue)
                    if AlternateWorldHistoryView and AlternateWorldHistoryView.LogEvent then
                        AlternateWorldHistoryView.LogEvent(profMsg)
                    end
                end
            end
        end

        if event == "BANKFRAME_OPENED" or event == "PLAYERBANKSLOTS_CHANGED" then
            if AlternateWorldDBEngine and AlternateWorldDBEngine.ScanBankData then
                AlternateWorldDBEngine.ScanBankData()
            end
        end

        if isAddonFullyLoaded and event ~= "ADDON_LOADED" then
            local currentLiveRealm = AlternateWorld.API.GetRealmName()
            if currentLiveRealm and currentLiveRealm ~= "" then
                if AlternateWorldDBEngine and AlternateWorldDBEngine.SaveCurrentCharacterData then
                    AlternateWorldDBEngine.SaveCurrentCharacterData()
                end
            end
        end

        if isAddonFullyLoaded and AlternateWorldMainFrameEngine and AlternateWorldMainFrameEngine.RefreshUI then
            AlternateWorldMainFrameEngine.RefreshUI()
        end
    end)
end

AlternateWorldCore.Initialize()
