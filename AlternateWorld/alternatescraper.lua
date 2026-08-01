-- ============================================================================
-- Alternate World - Live Data Scraping Module (Core Chars - v0.3.0)
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
        -- FIXED v0.6.0 BANK ISOLATION: Explicitly skips active inventory bags (0-4) ONLY during a bank vault scan (-1 to 11)
        local isContaminatedRow = (startBag == -1 and bag >= 0 and bag <= 4)
        
        if not isContaminatedRow then
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
    end
    return itemsList
end

-- Global matrix buffer for instant keyring lookups during a single snapshot pass
local localKeyringCache = {}

local function HasItemEverywhere(targetID, cachedBankItems)
    -- 1. Scan normal inventory bags (0 to 4)
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
    
    -- 2. FIXED v0.6.1 INSTANT BUFFER LOOKUP: Check if the key already exists inside the memory cache
    if localKeyringCache[targetID] then
        return true
	end
    
    -- 3. Scan bank fallback array cache
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
            elseif string.find(name, "Zul'Gurub") then key = "zg"
            elseif string.find(name, "Ruins of Ahn'Qiraj") then key = "aq20"
            elseif string.find(name, "Ahn'Qiraj") then key = "aq40"
            end

            if key then savedLockouts[key] = time() + reset end
        end
    end
    return savedLockouts
end

function AlternateWorldScraper.GatherFullSnapshot(existingCharData)
    local currentIlvl = 0

    -- FIXED v0.6.1 SINGLE-PASS KEYRING SCANNER: Populates the lookup table once per snapshot to kill API storms permanently
    localKeyringCache = {} -- Wipe memory buffer fresh
    if KEYRING_CONTAINER then
        local keyringSlots = C_Container.GetContainerNumSlots(KEYRING_CONTAINER) or 0
        for slot = 1, keyringSlots do
            local itemLink = C_Container.GetContainerItemLink(KEYRING_CONTAINER, slot)
            if itemLink then
                local id = tonumber(string.match(itemLink, "item:(%d+)"))
                if id then
                    localKeyringCache[id] = true
                end
            end
        end
    end

    local currentIlvl = 0
    pcall(function() currentIlvl = GetAverageItemLevel() end)
    
    local pSpecName, pSpecIcon = nil, nil
    pcall(function() pSpecName, pSpecIcon = GetCurrentSpec() end)
    
    if not pSpecName and existingCharData then
        pSpecName = existingCharData.specText or "Loading..."
        pSpecIcon = existingCharData.specIcon or "Interface\\Icons\\Spell_Nature_Invisibilty"
    elseif not pSpecName then
        pSpecName = "Loading..."
        pSpecIcon = "Interface\\Icons\\Spell_Nature_Invisibilty"
    end
    
    local oldMax, existingLockouts = 0, nil
    local currentBankData, currentBankTimestamp = {}, "Never"
    local existingHistory, existingProfessions = {}, {}
    local isCharacterFavorite = false
    local cachedMoneyValue = 0 -- FIXED v0.6.1: Default to 0
    
    if existingCharData then
        oldMax = existingCharData.maxItemLevel or 0
        existingLockouts = existingCharData.activeRaidIDs
        currentBankData = existingCharData.bankItems or {}
        currentBankTimestamp = existingCharData.bankUpdated or "Never"
        existingHistory = existingCharData.historyLog or {}
        existingProfessions = existingCharData.professions or {}
        isCharacterFavorite = existingCharData.isFavourite or false
        -- FIXED v0.6.1 GOLD RETENTION: Safely extract legacy money metrics before database override
        cachedMoneyValue = existingCharData.money or 0
    elseif AlternateWorldDB and _G["AWCachedCharacterKey"] then
        local backupKey = _G["AWCachedCharacterKey"]
        if AlternateWorldDB[backupKey] then
            local backupData = AlternateWorldDB[backupKey]
            oldMax = backupData.maxItemLevel or 0
            existingLockouts = backupData.activeRaidIDs
            currentBankData = backupData.bankItems or {}
            currentBankTimestamp = backupData.bankUpdated or "Never"
            existingHistory = backupData.historyLog or {}
            existingProfessions = backupData.professions or {}
            isCharacterFavorite = backupData.isFavourite or false
            cachedMoneyValue = backupData.money or 0
        end
    end
    
    local newMax = math.max(oldMax, currentIlvl)
    
    local genderString = "Male"
    if UnitSex("player") == 3 then genderString = "Female" end
    
    -- Scan normal bags (0 to 4)
    local currentBagData = AlternateWorldScraper.ScanContainers(0, 4)
    
    -- FIXED v0.6.1 API COMPATIBILITY: Query the keyring vault utilizing the dedicated Blizzard engine constant directly
    if KEYRING_CONTAINER then
        local keyringSlots = C_Container.GetContainerNumSlots(KEYRING_CONTAINER) or 0
        for slot = 1, keyringSlots do
            local itemLink = C_Container.GetContainerItemLink(KEYRING_CONTAINER, slot)
            if itemLink then
                local itemID = tonumber(string.match(itemLink, "item:(%d+)"))
                local containerInfo = C_Container.GetContainerItemInfo(KEYRING_CONTAINER, slot)
                if itemID and containerInfo then
                    table.insert(currentBagData, {
                        id = itemID,
                        count = containerInfo.stackCount or 1,
                        icon = containerInfo.iconFileID
                    })
                end
            end
        end
    end
    
    local currentTimestamp = date("%Y-%m-%d %H:%M")
    
    local isMC = C_QuestLog.IsQuestFlaggedCompleted(7848) or false
    local isBWL = C_QuestLog.IsQuestFlaggedCompleted(7761) or false
    local isOny = C_QuestLog.IsQuestFlaggedCompleted(6502) or C_QuestLog.IsQuestFlaggedCompleted(6570) or HasItemEverywhere(16309, currentBankData) or false
    local isNaxx = C_QuestLog.IsQuestFlaggedCompleted(9121) or C_QuestLog.IsQuestFlaggedCompleted(9122) or C_QuestLog.IsQuestFlaggedCompleted(9123) or false

    local isBRD = HasItemEverywhere(11000, currentBankData) or C_QuestLog.IsQuestFlaggedCompleted(4731) or false
    local isScholo = HasItemEverywhere(13704, currentBankData) or C_QuestLog.IsQuestFlaggedCompleted(5511) or false
    local isStrat = HasItemEverywhere(12382, currentBankData) or false
    local isGnomeregan = HasItemEverywhere(6893, currentBankData) or false 
    local isMara = HasItemEverywhere(17191, currentBankData) or C_QuestLog.IsQuestFlaggedCompleted(7046) or false
    local isDM = HasItemEverywhere(18250, currentBankData) or false
    local isUBRS = HasItemEverywhere(12344, currentBankData) or C_QuestLog.IsQuestFlaggedCompleted(4742) or C_QuestLog.IsQuestFlaggedCompleted(4743) or false
    local isSM = HasItemEverywhere(7146, currentBankData) or false

    local currentLockouts = ScanRaidLockouts()
    if GetNumSavedInstances() == 0 and existingLockouts then
        for k, v in pairs(existingLockouts) do
            if v > time() then currentLockouts[k] = v end
        end
    end

    local finalProfessions = existingProfessions
    if AlternateWorldProfScraper and AlternateWorldProfScraper.GetUpdatedProfessions then
        finalProfessions = AlternateWorldProfScraper.GetUpdatedProfessions(existingProfessions)
    end

    local currentXP = UnitXP("player") or 0
    local maxXP = UnitXPMax("player") or 1
    local restedXP = GetXPExhaustion() or 0
    local isCharacterResting = IsResting() or false
    
    -- FIXED v0.6.1 LIVE GOLD SCRAPER: Capture current player money wealth directly from the Blizzard API engine
    local liveMoneyValue = GetMoney() or cachedMoneyValue or 0

    return {
        name = UnitName("player"),
        realm = GetRealmName(),
        level = UnitLevel("player") or 1,
        race = UnitRace("player") or "Unknown",
        classToken = select(2, UnitClass("player")),
        classNameLocal = UnitClass("player") or "Unknown",
        faction = UnitFactionGroup("player") or "Alliance",
        gender = genderString,
        zone = GetRealZoneText() or "Unknown Zone",
        
        specText = pSpecName,
        specIcon = pSpecIcon,

        -- Nested structural arrays
        bagItems = currentBagData,
        bagsUpdated = currentTimestamp,
        bankItems = currentBankData,
        bankUpdated = currentBankTimestamp,
        historyLog = existingHistory,
        professions = finalProfessions,
        activeRaidIDs = currentLockouts,
        
        -- FIXED v0.6.1 ITEM LEVEL SYMMETRY: Enforce dual naming structures to feed both data loader and UI fields cleanly
        maxItemLevel = newMax,
        itemLevel = currentIlvl or newMax or 0, -- FIXED: Extra layout mapping node injected
        
        -- FIXED v0.6.1 GOLD TRANSACTION TRACKING: Inject your true character money directly into the database payload
        money = liveMoneyValue,
        
        -- Attunement state registry logs
        attunements = {
            MC = isMC, BWL = isBWL, Onyxia = isOny, Naxxramas = isNaxx,
            BRDKey = isBRD, ScholoKey = isScholo, StratKey = isStrat,
            UBRSKey = isUBRS, MaraKey = isMara, GnomereganKey = isGnomeregan,
			DMKey = isDM, ScarletKey = isSM
        },
        
        -- Rested XP calculations parameters
        currentXP = currentXP,
        maxXP = maxXP,
        restedXP = restedXP,
        isResting = isCharacterResting,
        
        -- FIXED v0.6.1 DATA PROTECTION: Visual favorite state survives all automatic ticks
        isFavourite = isCharacterFavorite,
    }
end

-- ============================================================================
-- Alternate World - Profession & Spellbook Scraper Module (v0.4.0)
-- ============================================================================

AlternateWorldProfScraper = {}

local ScraperFrame = nil

local function IsTrackingProfession(profName)
    if not profName then return false end
    local tracked = {
        ["Alchemy"] = true, ["Blacksmithing"] = true, ["Enchanting"] = true,
        ["Engineering"] = true, ["Leatherworking"] = true, ["Tailoring"] = true,
        ["Mining"] = true, ["Herbalism"] = true, ["Skinning"] = true,
        ["Cooking"] = true, ["First Aid"] = true, ["Fishing"] = true
    }
    return tracked[profName] or false
end

function AlternateWorldProfScraper.GetUpdatedProfessions(oldProfessionsMap)
    local currentMap = {}
    
    if oldProfessionsMap then
        for k, v in pairs(oldProfessionsMap) do
            currentMap[k] = { level = v.level or 0, maxLevel = v.maxLevel or 0, recipes = {} }
            if v.recipes then for recName in pairs(v.recipes) do currentMap[k].recipes[recName] = true end end
        end
    end

    local numSkills = GetNumSkillLines() or 0
    for i = 1, numSkills do
        local skillName, isHeader, _, skillRank, _, _, skillMax = GetSkillLineInfo(i)
        if not isHeader and IsTrackingProfession(skillName) then
            if not currentMap[skillName] then currentMap[skillName] = { recipes = {} } end
            currentMap[skillName].level = skillRank
            currentMap[skillName].maxLevel = skillMax
        end
    end

    -- FIXED v0.4.0 CORE SCRACTER LINK: Inject recipes safely into the primary profiles recipes data container cache array
    local craftName, _, numCrafts = GetCraftDisplaySkillLine()
    if craftName and IsTrackingProfession(craftName) and numCrafts and numCrafts > 0 then
        if not currentMap[craftName] then currentMap[craftName] = { recipes = {} } end
        for i = 1, numCrafts do
            local recipeName, recipeType = GetCraftInfo(i)
            if recipeName and recipeType ~= "header" then 
                currentMap[craftName].recipes[recipeName] = true 
            end
        end
    end

    local tradeName = GetTradeSkillLine()
    local numTradeSkills = GetNumTradeSkills() or 0
    if tradeName and IsTrackingProfession(tradeName) and numTradeSkills > 0 then
        if not currentMap[tradeName] then currentMap[tradeName] = { recipes = {} } end
        for i = 1, numTradeSkills do
            local recipeName, recipeType = GetTradeSkillInfo(i)
            if recipeName and recipeType ~= "header" then 
                currentMap[tradeName].recipes[recipeName] = true 
            end
        end
    end

    local spellIndex = 1
    while true do
        local spellName, spellSubName = GetSpellBookItemName(spellIndex, SpellBookFrame.bookType)
        if not spellName then break end
        
        local lSpell = string.lower(spellName)
        if string.find(lSpell, "riding") or string.find(lSpell, "ridning") or string.find(lSpell, "warhorse") or string.find(lSpell, "felsteed") then
            currentMap["Riding"] = { level = 75, maxLevel = 150, recipes = {} }
            break
        elseif string.find(lSpell, "charger") or string.find(lSpell, "dreadsteed") then
            currentMap["Riding"] = { level = 150, maxLevel = 150, recipes = {} }
            break
        end
        spellIndex = spellIndex + 1
    end

    return currentMap
end

function AlternateWorldProfScraper.Initialize()
    if ScraperFrame then return end
    ScraperFrame = CreateFrame("Frame")
    ScraperFrame:RegisterEvent("TRADE_SKILL_SHOW")
    ScraperFrame:RegisterEvent("TRADE_SKILL_UPDATE")
    ScraperFrame:RegisterEvent("CRAFT_SHOW")
    ScraperFrame:RegisterEvent("CRAFT_UPDATE")
    ScraperFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

    ScraperFrame:SetScript("OnEvent", function(self, event, ...)
        if AlternateWorldDBEngine and AlternateWorldDBEngine.SaveCurrentCharacterData then
            if event ~= "PLAYER_ENTERING_WORLD" then
                AlternateWorldDBEngine.SaveCurrentCharacterData()
            end
            if AlternateWorldMainFrameEngine and AlternateWorldMainFrameEngine.RefreshUI then AlternateWorldMainFrameEngine.RefreshUI() end
        end
    end)
end

AlternateWorldProfScraper.Initialize()

-- End of [alternatescraper.lua]

