
local API = DigamAddonLib.API;

-- 1. CreateFrame requires BackdropTemplate in Forever if using :SetBackdrop()
function API.CreateFrame(frameType, frameName, parentFrame, inheritsFrame, id)
    -- Add BackdropTemplate if creating a Frame with a name/parent:
    if frameType == "Frame" and not inheritsFrame then
        inheritsFrame = "BackdropTemplate"
    end
    return CreateFrame(frameType, frameName, parentFrame, inheritsFrame, id);
end;

function API.GetAddOnMetadata(addonName, keyName)
    return C_AddOns.GetAddOnMetadata(addonName, keyName);
end;

-- Returns avgItemLevel, avgItemLevelEquipped, avgItemLevelPvP = GetAverageItemLevel()
function API.GetAverageItemLevel()
    return GetAverageItemLevel()
end;

function API.GetBuildInfo()
    return GetBuildInfo();
end;

-- Returns containerInfo = C_Container.GetContainerItemInfo(containerIndex, slotIndex)
function API.GetContainerItemInfo(containerIndex, slotIndex)
    return C_Container.GetContainerItemInfo(containerIndex, slotIndex)
end;

-- Returns itemLink = C_Container.GetContainerItemLink(containerIndex, slotIndex)
function API.GetContainerItemLink(containerIndex, slotIndex)
    return C_Container.GetContainerItemLink(containerIndex, slotIndex)
end;

-- Returns numSlots = C_Container.GetContainerNumSlots(containerIndex)
function API.GetContainerNumSlots(containerIndex)
    return C_Container.GetContainerNumSlots(containerIndex)
end;

-- Returns name, rank, maxRank = C_TradeSkillUI.GetRecipeProfessionInfo() equivalent variables
function API.GetCraftDisplaySkillLine()
    local info = C_TradeSkillUI.GetBaseProfessionInfo()
    if info then
        return info.professionName, info.professionRank, info.professionMaxRank
    end
    return nil, 0, 0
end;

-- Returns craftName, craftSubSpellName, craftType, numAvailable, isHeader, trainingPointCost, requiredLevel
function API.GetCraftInfo(index)
    local recipeID = C_TradeSkillUI.GetRecipeIDByIndex(index)
    if not recipeID then return nil end

    local info = C_TradeSkillUI.GetRecipeInfo(recipeID)
    if info then
        local craftType = info.difficulty
        if info.isHeader then craftType = "header" end
        
        return info.name, "", craftType, info.numAvailable, info.isHeader, 0, 0
    end
    return nil
end;

function API.GetGuildInfo(unitid)
    return GetGuildInfo(unitid);
end;

--  Returns itemLink
function API.GetInventoryItemLink(unit, slotID)
    return GetInventoryItemLink(unit, slotID);
end;

-- Returns iconFileID = C_Item.GetItemIconByID(itemID)
function API.GetItemIconByID(itemID)
    return C_Item.GetItemIconByID(itemID)
end;

--  Returns itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType, itemStackCount, itemEquipLoc, 
--  itemTexture, sellPrice, classID, subclassID, bindType, expansionID, setID, isCraftingReagent, itemDescription
function API.GetItemInfo(item)
    return C_Item.GetItemInfo(item);
end;

--  Returns itemID, itemType, itemSubType, itemEquipLoc, icon, classID, subclassID
function API.GetItemInfoInstant(item)
    return C_Item.GetItemInfoInstant(item);
end;

function API.GetLootMethod()
    return C_PartyInfo.GetLootMethod();
end

-- Returns copper = GetMoney()
function API.GetMoney()
    return GetMoney()
end;

function API.GetMouseButtonClicked()
    return GetMouseButtonClicked();
end;

function API.GetNumGroupMembers()
    return GetNumGroupMembers();
end;

-- Returns numSavedInstances = GetNumSavedInstances()
function API.GetNumSavedInstances()
    return GetNumSavedInstances()
end;

-- Returns numSkillLines = C_SkillInfo.GetNumSkillLines()
function API.GetNumSkillLines()
    return C_SkillInfo.GetNumSkillLines()
end;

--  Returns numTabs
function API.GetNumTalentTabs(isInspect, isPet)
    return GetNumTalentTabs(isInspect, isPet);
end;

function API.GetNumTrackingTypes()
    return C_Minimap.GetNumTrackingTypes();
end

-- Returns numSkills = total amount of individual recipes available
function API.GetNumTradeSkills()
    local recipeIDs = C_TradeSkillUI.GetAllRecipeIDs()
    return recipeIDs and #recipeIDs or 0
end;

--  Forever returned values: localizedClass, englishClass, localizedRace, englishRace, sex, name, realmName
function API.GetPlayerInfoByGUID(guid)
    return GetPlayerInfoByGUID(guid);
end;

function API.GetRaidRosterInfo(raidIndex)
    return GetRaidRosterInfo(raidIndex);
end;

function API.GetRealmName()
    return GetRealmName();
end;

-- Returns zoneText = GetRealZoneText()
function API.GetRealZoneText()
    return GetRealZoneText()
end;

-- Returns name, id, reset, difficulty, locked, extended, instanceIDMostSig, isRaid, maxPlayers, difficultyName, numEncounters, encounterProgress = GetSavedInstanceInfo(index)
function API.GetSavedInstanceInfo(index)
    return GetSavedInstanceInfo(index)
end;

--  Returns name, itemID, texture, count, quality
function API.GetSendMailItem(index)
    return GetSendMailItem(index);
end;

--  Returns itemLink
function API.GetSendMailItemLink(index)
    return GetSendMailItemLink(index);
end;

-- Returns name, isHeader, isExpanded, skillRank, numSteps, skillModifier, maxRank, isAbandonable, stepCost, rankCost, minLevel, skillLineID, canEnhance = GetSkillLineInfo(index)
function API.GetSkillLineInfo(index)
    local info = C_SkillInfo.GetSkillLineInfo(index)
    if info then
        return info.name, info.isHeader, info.isExpanded, info.skillRank, info.numSteps, 
               info.skillModifier, info.maxRank, info.isAbandonable, info.stepCost, 
               info.rankCost, info.minLevel, info.skillLineID, info.canEnhance
    end
    return nil
end;

-- Returns spellName, spellSubName = C_SpellBook.GetSpellBookItemName() equivalent variables
function API.GetSpellBookItemName(index, bookType)
    local bank = (bookType == "pet") and Enum.SpellBookSpellBank.Pet or Enum.SpellBookSpellBank.Player
    return C_SpellBook.GetSpellBookItemName(index, bank)
end;

function API.GetSpellCooldown(spellIdentifier)
    local info = C_Spell.GetSpellCooldown(spellIdentifier)
    if info then
        return info.startTime, info.duration, info.isEnabled, info.modRate
    end
    return 0, 0, false, 1;
end

function API.GetSpellIDForSpellIdentifier(spellIdentifier)
    return C_Spell.GetSpellIDForSpellIdentifier(spellIdentifier);
end;

-- 2. C_Spell.GetSpellInfo returns a table in Forever. Extract it to the old Era format:
function API.GetSpellInfo(spellIdentifier)
    if spellIdentifier then
        local spellInfo = C_Spell.GetSpellInfo(spellIdentifier)

        if spellInfo then
            return 
                spellInfo.name, 
                nil, -- rank does not exist in Forever backend
                spellInfo.iconID, 
                spellInfo.castTime, 
                spellInfo.minRange, 
                spellInfo.maxRange, 
                spellInfo.spellID, 
                spellInfo.originalIconID
        end
    end
    return nil    
end

-- Emulate the old layout where icon is 3rd and spellID is 7th return value
function API.GetSpellName(spellIdentifier)
    if spellIdentifier then
        -- Fetch the new unified spell data table from the modern backend
        local spellInfo = C_Spell.GetSpellInfo(spellIdentifier)
        if spellInfo then
            -- Returns: name(1), rank(2), iconID(3), castTime(4), minRange(5), maxRange(6), spellID(7)
            return 
                spellInfo.name, 
                nil, 
                spellInfo.iconID, 
                spellInfo.castTime, 
                spellInfo.minRange, 
                spellInfo.maxRange, 
                spellInfo.spellID
        end
    end
    return nil
end;

--  Returns name, iconTexture, tier, column, currentRank, maxRank, isExceptional, meetsPrereq = GetTalentInfo(tabIndex, talentIndex [, isInspect, isPet, groupIndex])
function API.GetTalentInfo(tabIndex, talentIndex, isInspect, isPet, groupIndex)
    return GetTalentInfo(tabIndex, talentIndex, isInspect, isPet, groupIndex);
end;

function API.GetTime()
    return GetTime();
end;

function API.GetTrackingInfo(index)
    return C_Minimap.GetTrackingInfo(index);
end;

-- 3. GetTrackingTexture() - use C_Minimap in Forever:
function API.GetTrackingTexture()
    local count = C_Minimap.GetNumTrackingTypes()
    for i = 1, count do
        local info = C_Minimap.GetTrackingInfo(i)
        if info and info.active then
            return info.texture -- Returns ikonet for the active tracking
        end
    end
    return nil
end;

-- Returns name, difficulty, numAvailable, isHeader, isExpanded, id
--  NOTE: THIS IS NOT COMPATIBLE WITH ERA, USE GetTradeSkillInfo_Era(index, professionName), which
--  has an added professionName parameter for filtering.
function API.GetTradeSkillInfo_Era(index, professionName)
    return API.GetTradeSkillInfo(index)
end

-- FIXED v1.0.0 FOREVER PROPER FILTER: Uses true underlying profession ID tracking maps to crush contamination
local PROFESSION_ID_MAP = {
    [171] = "Alchemy",
    [185] = "Cooking",
    [164] = "Blacksmithing",
    [333] = "Enchanting",
    [202] = "Engineering",
    [165] = "Leatherworking",
    [197] = "Tailoring",
    [186] = "Mining",
    [182] = "Herbalism",
    [393] = "Skinning",
    [129] = "First Aid",
    [356] = "Fishing",
}

-- Returns name, difficulty, numAvailable, isHeader, isExpanded, id
function API.GetTradeSkillInfo_Era(index, professionName)
    local recipeIDs = C_TradeSkillUI.GetFilteredRecipeIDs()
    if not recipeIDs or not recipeIDs[index] then return nil end
      
    local recipeID = recipeIDs[index]
    local info = C_TradeSkillUI.GetRecipeInfo(recipeID)
    if info then
        local currentProfInfo = C_TradeSkillUI.GetProfessionInfoByRecipeID(info.recipeID)
        local activeProfessionName = PROFESSION_ID_MAP[currentProfInfo.parentProfessionID];

        local difficulty = info.difficulty or "trivial"
        local isHeader = info.isHeader
        
        if not info.learned or not activeProfessionName then
            isHeader = true
            difficulty = "header"
        elseif professionName and activeProfessionName ~= professionName then
            -- If the scraper loops "Cooking", but the UI engine is still processing "Alchemy" -> Evict instantly!
            isHeader = true
            difficulty = "header"
        elseif info.isHeader then 
            difficulty = "header" 
        end
        
        return info.name, difficulty, info.numAvailable, isHeader, info.isExpanded, recipeID
    end
    return nil
end

-- Returns tradeskillName, currentLevel, maxLevel, skillLineModifier = C_TradeSkillUI.GetBaseProfessionInfo() equivalent variables
function API.GetTradeSkillLine()
    local info = C_TradeSkillUI.GetBaseProfessionInfo()
    if info then
        return info.professionName, info.professionRank, info.professionMaxRank, 0
    end
    return "UNKNOWN", 0, 0, 0
end;

-- Returns exhaustion = GetXPExhaustion()
function API.GetXPExhaustion()
    return GetXPExhaustion()
end;

function API.InCombatLockdown()
    return InCombatLockdown();
end;

function API.IsInGroup()
    return IsInGroup();
end;

function API.IsInInstance()
    return IsInInstance();
end

function API.IsInRaid()
    return IsInRaid();
end;

-- Returns isCompleted = C_QuestLog.IsQuestFlaggedCompleted(questID)
function API.IsQuestFlaggedCompleted(questID)
    return C_QuestLog.IsQuestFlaggedCompleted(questID)
end;

-- Returns resting = IsResting()
function API.IsResting()
    return IsResting()
end;

-- 4. IsSpellInRange returns booleans (true/false) instead of 1/0.
function API.IsSpellInRange(buffName, unitid)
    return C_Spell.IsSpellInRange(buffName, unitid)
end

function API.PlaySound(soundKitID, channel, forceMuteIfSessionMaxed, allowMultiple)
    return PlaySound(soundKitID, channel, forceMuteIfSessionMaxed, allowMultiple);
end;

function API.RegisterAddonMessagePrefix(prefix)
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix and prefix then
        return C_ChatInfo.RegisterAddonMessagePrefix(prefix);
    end
end;

function API.RequestRaidInfo()
    return RequestRaidInfo();
end;

function API.SendAddonMessage(addonPrefix, message, channel, target)
    C_ChatInfo.SendAddonMessage(addonPrefix, message, channel, target)
end;

function API.SetPortraitTexture(textureObject, unitToken, disableMasking)
    return SetPortraitTexture(textureObject, unitToken, disableMasking);
end;

function API.SendChatMessage(message, chatType, languageID, target)
    SendChatMessage(message, chatType, languageID, target)
end;

function API.UnitAffectingCombat(unitId)
    return UnitAffectingCombat(unitId);
end;

function API.UnitBuff(unitId, index, filter)
    -- Fallback to "HELPFUL" if no filter is supplied by the core
    local foreverFilter = "HELPFUL"
    if filter and filter ~= "" then
        -- Ensure "HELPFUL" is present unless the core explicitly requests debuffs ("HARMFUL")
        if not string.find(filter, "HELPFUL") and not string.find(filter, "HARMFUL") then
            foreverFilter = "HELPFUL|" .. filter
        else
            foreverFilter = filter
        end
    end

    -- Wrap the API call in a pcall to catch "secret while tainted" errors gracefully
    local success, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unitId, index, foreverFilter)
    if not success or not aura then
        return nil
    end
    
    -- Return the exact 11 classic values your Era-core expects
    return 
        aura.name, 
        "", -- Rank does not exist in retail backend
        aura.icon, 
        aura.applications, 
        aura.dispelType, 
        aura.duration, 
        aura.expirationTime, 
        aura.sourceUnit, 
        aura.isStealable, 
        false, -- nameplateShowPersonal
        aura.spellId
end;

function API.UnitClass(unitId)
    return UnitClass(unitId);
end;

function API.UnitCreatureFamily(unitId)
    return UnitCreatureFamily(unitId);
end;

function API.UnitFactionGroup(unitId)
    return UnitFactionGroup(unitId);
end;

function API.UnitGUID(unitId)
    return UnitGUID(unitId);
end;

function API.UnitHasIncomingResurrection(unitid)
    return UnitHasIncomingResurrection(unitid)
end;

function API.UnitIsConnected(unitId)
    return UnitIsConnected(unitId);
end;

function API.UnitIsDead(unitId)
    return UnitIsDead(unitId);
end;

function API.UnitIsDeadOrGhost(unitId)
    return UnitIsDeadOrGhost(unitId);
end;

function API.UnitIsGroupAssistant(unitId)
    return UnitIsGroupAssistant(unitId);
end;

function API.UnitIsGroupLeader(unitId)
    return UnitIsGroupLeader(unitId);
end;

function API.UnitIsVisible(unitId)
    return UnitIsVisible(unitId);
end;

--  Returns level
function API.UnitLevel(unit)
    return UnitLevel(unit);
end;

function API.UnitName(unitId)
    return UnitName(unitId)
end;

function API.UnitRace(unitid)
    local localizedRaceName, englishRaceName, raceID = UnitRace(unitid)
    
    if not localizedRaceName then
        localizedRaceName, englishRaceName = "Unknown", "Unknown"
    end
    
    return localizedRaceName, englishRaceName, raceID
end

function API.UnitSex(unitid)
    local sex = UnitSex(unitid)
    return sex or 1
end

-- Returns currentXP = UnitXP(unit)
function API.UnitXP(unit)
    return UnitXP(unit)
end;

-- Returns maxXP = UnitXPMax(unit)
function API.UnitXPMax(unit)
    return UnitXPMax(unit)
end;



--
--  UNIT_SPELLCAST_* functions:
--

--[[
Convert output from UNIT_SPELLCAST_START event in Forever to
the format it ws in Era.
--]]

--  Forever return values: unitCaster, unitTarget, castGUID, spellID, castBarID
function API.On_UNIT_SPELLCAST_SENT(...)
    local unitCaster, _,spellID, lineID = ...
    return unitCaster, nil,spellID, lineID;
end;

--  Forever return values: unitCaster, castGUID, spellID, castBarID
function API.Extract_UNIT_SPELLCAST_START(...)
    return ...;
end

--  Forever return values: unitCaster, castGUID, spellID, castBarID
function API.Extract_UNIT_SPELLCAST_STOP(...)
    return ...;
end

--  Forever return values: unitCaster, castGUID, spellID, castBarID
function API.Extract_UNIT_SPELLCAST_SUCCEEDED(...)
    return ...;
end

--  Forever return values: unitCaster, castGUID, spellID, reason
--  Note the extra Reason field.
function API.Extract_UNIT_SPELLCAST_FAILED(...)
    return ...;
end

--  Forever payload: unitTarget, isIncoming
--  Era return values: unitTarget
function API.Extract_INCOMING_RESURRECT_CHANGED(...)
    return ...;
end




function API.Extract_Unit_Target()
    local name = nil
    
    if UnitExists("mouseover") then
        name = GetUnitName("mouseover")
    elseif UnitExists("target") then
        name = GetUnitName("target")
    end
    
    if name == "" then
        name = nil;
    end

    return name;
end



