-- ============================================================================
-- Alternate World - Live Data Scraping Module
-- ============================================================================

AlternateWorldScraper = {}

local function GetAverageItemLevel()
    local totalIlvl, equippedCount = 0, 0
    for slotID = 1, 17 do
        local itemLink = GetInventoryItemLink("player", slotID)
        if itemLink then
            local _, _, _, itemLevel = GetItemInfo(itemLink)
            if itemLevel and itemLevel > 0 then
                totalIlvl = totalIlvl + itemLevel
                equippedCount = equippedCount + 1
            end
        end
    end
    if equippedCount == 0 then return 0 end
    return math.floor((totalIlvl / equippedCount) * 10 + 0.5) / 10
end

local function GetCurrentSpec()
    local currentLevel = UnitLevel("player") or 1
    if currentLevel < 10 then 
        return "No Talents Yet (under lvl 10)", "Interface\\Icons\\Spell_Nature_Invisibilty" 
    end

    local numTabs = GetNumTalentTabs() or 0
    if numTabs == 0 then return nil, nil end 

    local _, classToken = UnitClass("player")
    if not classToken or not AlternateWorldConfig or not AlternateWorldConfig.TalentTrees[classToken] then 
        return "Unknown", "Interface\\Icons\\Spell_Nature_Invisibilty"
    end
    
    local trees = AlternateWorldConfig.TalentTrees[classToken]
    local treePoints = {0, 0, 0}
    local totalPointsAllocated = 0
    
    for tab = 1, 3 do
        local numTalents = GetNumTalents(tab) or 0
        local pointsInTab = 0
        for index = 1, numTalents do
            local _, _, _, _, currentRank = GetTalentInfo(tab, index)
            currentRank = tonumber(currentRank) or 0
            pointsInTab = pointsInTab + currentRank
        end
        treePoints[tab] = pointsInTab
        totalPointsAllocated = totalPointsAllocated + pointsInTab
    end
    
    if totalPointsAllocated == 0 then return nil, nil end

    local maxPoints, mainTreeIndex = -1, 1
    for i = 1, 3 do
        if treePoints[i] > maxPoints then
            maxPoints = treePoints[i]
            mainTreeIndex = i
        end
    end
    
    local treeString = trees[mainTreeIndex].name .. " (" .. treePoints[1] .. "/" .. treePoints[2] .. "/" .. treePoints[3] .. ")"
    return treeString, trees[mainTreeIndex].icon
end

function AlternateWorldScraper.ScanContainers(startBag, endBag)
    local itemsList = {}
    for bag = startBag, endBag do
        local slots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, slots do
            local itemLink = C_Container.GetContainerItemLink(bag, slot)
            if itemLink then
                local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
                local containerInfo = C_Container.GetContainerItemInfo(bag, slot)
                if itemID and containerInfo then
                    table.insert(itemsList, {
                        id = itemID,
                        count = containerInfo.stackCount or 1,
                        icon = containerInfo.iconFileID
                    })
                end
            end
        end
    end
    return itemsList
end

local function HasItemEverywhere(targetID, cachedBankItems)
    for bag = 0, 4 do
        local slots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, slots do
            local itemLink = C_Container.GetContainerItemLink(bag, slot)
            if itemLink then
                local id = tonumber(string.match(itemLink, "item:(%d+)"))
                if id == targetID then return true end
            end
        end
    end
    if cachedBankItems then
        for _, itemData in ipairs(cachedBankItems) do
            if itemData.id == targetID then return true end
        end
    end
    return false
end

local function ScanRaidLockouts()
    local savedLockouts = {}
    local numSaved = GetNumSavedInstances() or 0

    for i = 1, numSaved do
        local name, _, reset, _, locked = GetSavedInstanceInfo(i)
        if locked and reset and reset > 0 and name then
            local key = nil
            if string.find(name, "Molten Core") then key = "mc"
            elseif string.find(name, "Blackwing Lair") then key = "bwl"
            elseif string.find(name, "Onyxia") then key = "ony"
            elseif string.find(name, "Naxxramas") then key = "naxx"
            end

            if key then
                savedLockouts[key] = time() + reset
            end
        end
    end
    return savedLockouts
end

-- Master Scraper Loop: Compiles all individual scanning parameters into an isolated data array package
function AlternateWorldScraper.GatherFullSnapshot(existingCharData)
    local currentIlvl = 0
    pcall(function() currentIlvl = GetAverageItemLevel() end)
    
    local pSpecName, pSpecIcon = nil, nil
    pcall(function() pSpecName, pSpecIcon = GetCurrentSpec() end)
    
    -- Recover historical talent cache if server queries throttle out during screen loading states
    if not pSpecName and existingCharData then
        pSpecName = existingCharData.specText or "Loading..."
        pSpecIcon = existingCharData.specIcon or "Interface\\Icons\\Spell_Nature_Invisibilty"
    elseif not pSpecName then
        pSpecName = "Loading..."
        pSpecIcon = "Interface\\Icons\\Spell_Nature_Invisibilty"
    end
    
    local oldMax = 0
    local existingLockouts = nil
    local currentBankData = {}
    local currentBankTimestamp = "Never"
    local existingHistory = {}
    
    if existingCharData then
        oldMax = existingCharData.maxItemLevel or 0
        existingLockouts = existingCharData.activeRaidIDs
        currentBankData = existingCharData.bankItems or {}
        currentBankTimestamp = existingCharData.bankUpdated or "Never"
        existingHistory = existingCharData.historyLog or {}
    end
    local newMax = math.max(oldMax, currentIlvl)
    
    local genderString = "Male"
    if UnitSex("player") == 3 then genderString = "Female" end
    
    local currentBagData = AlternateWorldScraper.ScanContainers(0, 4)
    local currentTimestamp = date("%Y-%m-%d %H:%M")
    
    -- Complete Core Quest-ID checking matrix
    local isMC = C_QuestLog.IsQuestFlaggedCompleted(7848) or false
    local isBWL = C_QuestLog.IsQuestFlaggedCompleted(7761) or false
    local isOny = C_QuestLog.IsQuestFlaggedCompleted(6502) or C_QuestLog.IsQuestFlaggedCompleted(6570) or HasItemEverywhere(16309, currentBankData) or false
    local isNaxx = C_QuestLog.IsQuestFlaggedCompleted(9121) or C_QuestLog.IsQuestFlaggedCompleted(9122) or C_QuestLog.IsQuestFlaggedCompleted(9123) or false

    local isBRD = HasItemEverywhere(11000, currentBankData) or C_QuestLog.IsQuestFlaggedCompleted(4731) or false
    local isScholo = HasItemEverywhere(13704, currentBankData) or C_QuestLog.IsQuestFlaggedCompleted(5511) or false
    local isStrat = HasItemEverywhere(12382, currentBankData) or false
    local isGnomeregan = HasItemEverywhere(6990, currentBankData) or false
    local isMara = HasItemEverywhere(12219, currentBankData) or C_QuestLog.IsQuestFlaggedCompleted(5144) or false
    local isDM = HasItemEverywhere(18250, currentBankData) or false
    local isUBRS = HasItemEverywhere(12344, currentBankData) or C_QuestLog.IsQuestFlaggedCompleted(4742) or C_QuestLog.IsQuestFlaggedCompleted(4743) or false

    local currentLockouts = ScanRaidLockouts()
    if GetNumSavedInstances() == 0 and existingLockouts then
        for k, v in pairs(existingLockouts) do
            if v > time() then currentLockouts[k] = v end
        end
    end

    -- Construct and return the finalized object array package directly back to core database saver
    return {
        name = UnitName("player"),
        realm = GetRealmName(),
        race = UnitRace("player") or "Unknown",
        classToken = select(2, UnitClass("player")),
        classNameLocal = UnitClass("player") or "Unknown",
        zone = GetRealZoneText() or "Unknown",
        money = GetMoney() or 0,
        specText = pSpecName,
        specIcon = pSpecIcon,
        itemLevel = currentIlvl,
        maxItemLevel = newMax,
        gender = genderString,
        bagItems = currentBagData,
        bankItems = currentBankData,
        bagsUpdated = currentTimestamp,
        bankUpdated = currentBankTimestamp,
        attunements = {
            mc = isMC, bwl = isBWL, ony = isOny, naxx = isNaxx,
            brd = isBRD, scholo = isScholo, strat = isStrat,
            gnomer = isGnomeregan, mara = isMara, dm = isDM, ubrs = isUBRS
        },
        activeRaidIDs = currentLockouts,
        faction = UnitFactionGroup("player") or "Unknown",
        level = UnitLevel("player") or 1,
        historyLog = existingHistory
    }
end
