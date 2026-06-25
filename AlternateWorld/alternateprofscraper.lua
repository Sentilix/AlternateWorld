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

-- End of [alternateprofscraper.lua]
