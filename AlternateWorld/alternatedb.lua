-- ============================================================================
-- Alternate World - Database & Data Scraping Engine
-- ============================================================================

AlternateWorldDBEngine = {}

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
    
    local maxPoints, mainTreeIndex = -1, 1
    for i = 1, 3 do
        if treePoints[i] > maxPoints then
            maxPoints = treePoints[i]
            mainTreeIndex = i
        end
    end
    
    if totalPointsAllocated == 0 then
        return "Unspec (0/0/0)", "Interface\\Icons\\Spell_Nature_Invisibilty"
    else
        local formattedTreeString = "(" .. treePoints[1] .. "/" .. treePoints[2] .. "/" .. treePoints[3] .. ")"
        return trees[mainTreeIndex].name .. " " .. formattedTreeString, trees[mainTreeIndex].icon
    end
end

-- FIXED: Replaced C_Container with live, synchronous global API links to bypass asynchronous server caching bugs
local function ScanContainers(startBag, endBag)
    local itemsList = {}
    for bag = startBag, endBag do
        -- Works flawlessly across both standard bags and bank bag slots
        local slots = C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, slots do
            local itemLink = C_Container.GetContainerItemLink(bag, slot)
            if itemLink then
                -- Extract raw item ID from the item link string safely
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

function AlternateWorldDBEngine.SaveCurrentCharacterData()
    if not AlternateWorldDB then AlternateWorldDB = {} end
    
    local charName = UnitName("player")
    local realmName = GetRealmName()
    if not charName or not realmName then return end
    
    local myKey = charName .. " - " .. realmName
    local _, classToken = UnitClass("player")
    local currentIlvl = GetAverageItemLevel()
    local specName, specIcon = GetCurrentSpec()
    
    local oldMax = 0
    if AlternateWorldDB[myKey] and AlternateWorldDB[myKey].maxItemLevel then
        oldMax = AlternateWorldDB[myKey].maxItemLevel
    end
    local newMax = math.max(oldMax, currentIlvl)
    
    local genderString = "Male"
    if UnitSex("player") == 3 then genderString = "Female" end
    
    local currentBankData = {}
    local currentBankTimestamp = "Never"
    if AlternateWorldDB[myKey] then
        if AlternateWorldDB[myKey].bankItems then currentBankData = AlternateWorldDB[myKey].bankItems end
        if AlternateWorldDB[myKey].bankUpdated then currentBankTimestamp = AlternateWorldDB[myKey].bankUpdated end
    end
    
    local currentBagData = ScanContainers(0, 4)
    local currentTimestamp = date("%Y-%m-%d %H:%M")
    
    AlternateWorldDB[myKey] = {
        name = charName,
        realm = realmName,
        race = UnitRace("player") or "Unknown",
        classToken = classToken,
        classNameLocal = UnitClass("player") or "Unknown",
        zone = GetRealZoneText() or "Unknown",
        money = GetMoney() or 0,
        specText = specName,
        specIcon = specIcon,
        itemLevel = currentIlvl,
        maxItemLevel = newMax,
        gender = genderString,
        bagItems = currentBagData,
        bankItems = currentBankData,
        bagsUpdated = currentTimestamp,
        bankUpdated = currentBankTimestamp
    }
end

function AlternateWorldDBEngine.ScanBankData()
    local charName = UnitName("player")
    local realmName = GetRealmName()
    if not charName or not realmName then return end
    local myKey = charName .. " - " .. realmName
    
    if AlternateWorldDB and AlternateWorldDB[myKey] then
        AlternateWorldDB[myKey].bankItems = ScanContainers(-1, 11)
        AlternateWorldDB[myKey].bankUpdated = date("%Y-%m-%d %H:%M")
        AlternateWorldDBEngine.SaveCurrentCharacterData()
    end
end
