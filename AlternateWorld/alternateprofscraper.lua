-- ============================================================================
-- Alternate World - Profession Tradeskills Scraper Module
-- ============================================================================

AlternateWorldProfessionScraper = {}

local function IsTrackingProfession(profName)
    if not profName then return false end
    -- Master dictionary map of all valid primary and secondary professions
    local tracked = {
        ["Alchemy"] = true, ["Blacksmithing"] = true, ["Enchanting"] = true,
        ["Engineering"] = true, ["Leatherworking"] = true, ["Tailoring"] = true,
        ["Mining"] = true, ["Herbalism"] = true, ["Skinning"] = true,
        ["Cooking"] = true, ["First Aid"] = true, ["Fishing"] = true
    }
    return tracked[profName] or false
end

-- Core Function: Loops current live window data and appends it to cache profiles
function AlternateWorldProfessionScraper.GetUpdatedProfessions(oldProfessionsMap)
    local currentMap = {}
    
    -- Retain previously scanned data structures intact for offline lookup matrix
    if oldProfessionsMap then
        for k, v in pairs(oldProfessionsMap) do
            currentMap[k] = {
                level = v.level or 0,
                maxLevel = v.maxLevel or 0,
                recipes = {}
            }
            if v.recipes then
                for recName in pairs(v.recipes) do
                    currentMap[k].recipes[recName] = true
                end
            end
        end
    end

    -- Step 1: Scan global skill lines panel for rank levels integers
    local numSkills = GetNumSkillLines() or 0
    for i = 1, numSkills do
        local skillName, isHeader, _, skillRank, _, _, skillMax = GetSkillLineInfo(i)
        if not isHeader and IsTrackingProfession(skillName) then
            if not currentMap[skillName] then 
                currentMap[skillName] = { recipes = {} } 
            end
            currentMap[skillName].level = skillRank
            currentMap[skillName].maxLevel = skillMax
        end
    end

    -- Step 2: Scan Recipes from Crafting windows frame (Beast Training, Enchanting etc.)
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

    -- Step 3: Scan Recipes from TradeSkill windows frame (Blacksmithing, Engineering etc.)
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

    return currentMap
end
