-- ============================================================================
-- Alternate World - Profession Sorter Engine (v0.4.0 - NESTED FIXED)
-- ============================================================================

AlternateWorldProfEngine = {}

local WEIGHTS = {["orange"]=1, ["purple"]=2, ["blue"]=3, ["green"]=4, ["white"]=5, ["grey"]=6}
local ICONS = {
    ["alchemy"]="interface\\icons\\trade_alchemy", ["blacksmithing"]="interface\\icons\\trade_blacksmithing",
    ["enchanting"]="interface\\icons\\trade_engraving", ["engineering"]="interface\\icons\\trade_engineering",
    ["leatherworking"]="interface\\icons\\trade_leatherworking", ["tailoring"]="interface\\icons\\trade_tailoring",
    ["mining"]="interface\\icons\\trade_mining", ["herbalism"]="interface\\icons\\spell_nature_naturetouchgrow",
    ["skinning"]="interface\\icons\\inv_misc_pelt_wolf_01", ["cooking"]="interface\\icons\\inv_misc_food_15",
    ["first aid"]="interface\\icons\\spell_holy_sealofsacrifice", ["fishing"]="interface\\icons\\trade_fishing",
    ["riding"]="interface\\icons\\spell_nature_swiftness"
}

function AlternateWorldProfEngine.GetProfessionIconTexture(p) return ICONS[string.lower(p or "")] or "interface\\icons\\inv_misc_questionmark" end

local function GetBankerRealmContext(realmName)
    if AlternateWorldDB and AlternateWorldDB.Settings and AlternateWorldDB.Settings.Clusters then
        local assignedCluster = AlternateWorldDB.Settings.Clusters[realmName]
        if assignedCluster then return assignedCluster end
    end
    return realmName
end

-- FIXED v0.4.0 DUAL ENGINE: Dynamically splits logic depending on dropdown menu sweeps or specific recipe rows lookups
function AlternateWorldProfEngine.GetSortedScannedProfessions(recipeID, contextRealm)
    if not AlternateWorldDB then return {} end
    
    -- POLICY BRANCH A: Called by dropdown menu to scan all account wide distinct professions
    if not recipeID then
        local profSet = {}
        for key, charData in pairs(AlternateWorldDB) do
            if key ~= "Settings" and charData.professions then
                for profName in pairs(charData.professions) do
                    profSet[profName] = true
                end
            end
        end
        local sortedList = {}
        for name in pairs(profSet) do table.insert(sortedList, name) end
        table.sort(sortedList)
        return sortedList
    end

    -- POLICY BRANCH B: Called by recipe grid to locate specific learned item crafters
    local matchingCrafters = {}
    local mustIsolate = AlternateWorldDB.Settings and AlternateWorldDB.Settings.IsolateSingleRealmsProf
    local liveContext = GetBankerRealmContext(contextRealm or GetRealmName())
    local myName = UnitName("player")

    for key, altData in pairs(AlternateWorldDB) do
        if key ~= "Settings" and altData and altData.name and altData.professions then
            local altRealm = altData.realm or "Unknown"
            local altContext = GetBankerRealmContext(altRealm)
            local isSelf = (altData.name == myName and altRealm == contextRealm)

            local sharedScope = false
            local assignedCluster = AlternateWorldDB.Settings.Clusters and AlternateWorldDB.Settings.Clusters[contextRealm]
            
            if assignedCluster then
                sharedScope = (altContext == liveContext)
            elseif mustIsolate then
                sharedScope = (altRealm == contextRealm)
            else
                sharedScope = true
            end

            if sharedScope then
                for profName, profData in pairs(altData.professions) do
                    if profData.recipes and profData.recipes[recipeID] then
                        table.insert(matchingCrafters, {
                            key = key,
                            name = altData.name,
                            realm = altRealm,
                            faction = altData.faction or "Alliance",
                            classToken = altData.classToken or "WARRIOR",
                            isSelf = isSelf
                        })
                        break
                    end
                end
            end
        end
    end

    table.sort(matchingCrafters, function(a, b)
        if a.faction ~= b.faction then return a.faction == "Alliance" end
        return a.name < b.name
    end)

    return matchingCrafters
end

function AlternateWorldProfEngine.GetRecipeColorAndWeight(n)
    local hex, w = "|cFFFFFFFF", WEIGHTS["white"]
    if not n then return hex, w end
    local _, link = GetItemInfo(n)
    if link then
        if string.find(link, "cffff8000") then hex, w = "|cFFFF8000", WEIGHTS["orange"]
        elseif string.find(link, "ffa335ee") then hex, w = "|cFFA335EE", WEIGHTS["purple"]
        elseif string.find(link, "ff0070dd") then hex, w = "|cFF0070DD", WEIGHTS["blue"]
        elseif string.find(link, "ff1eff00") then hex, w = "|cFF1EFF00", WEIGHTS["green"]
        elseif string.find(link, "ff9d9d9d") then hex, w = "|cFF9D9D9D", WEIGHTS["grey"] end
    else
        local l = string.lower(n)
        if string.find(l, "enchant") or string.find(l, "healing") or string.find(l, "spellpower") or string.find(l, "thorium") or string.find(l, "arcanite") then hex, w = "|cFF0070DD", WEIGHTS["blue"]
        elseif string.find(l, "mithril") or string.find(l, "heavy") or string.find(l, "iron") or string.find(l, "silk") then hex, w = "|cFF1EFF00", WEIGHTS["green"]
        elseif string.find(l, "rough") or string.find(l, "coarse") or string.find(l, "linen") then hex, w = "|cFF9D9D9D", WEIGHTS["grey"] end
    end
    return hex, w
end

function AlternateWorldProfEngine.CompileSortedRecipes(prof, filter)
    local cmap, list, gList = {}, {}, {}
    if not AlternateWorldDB or not prof then return list, cmap end
    
    local pLower = "alchemy"
    if type(prof) == "string" then pLower = string.lower(prof)
    elseif type(prof) == "table" and prof[1] then pLower = string.lower(prof[1]) end

    for charKey, c in pairs(AlternateWorldDB) do
        if c.professions then
            for pName, pData in pairs(c.professions) do
                if type(pName) == "string" and string.lower(pName) == pLower then
                    local rSub = ""
                    local r = string.match(charKey, "%s*-%s*(.+)")
                    if r then rSub = "-" .. string.sub(string.gsub(r, "%s+", ""), 1, 3) end
                    local dName = (c.name or "Alt") .. rSub

                    table.insert(gList, { name = c.name or "Alt", displayName = dName, level = pData.level or 0 })
                    
                    if pData.recipes then
                        for recipeName, isLearned in pairs(pData.recipes) do
                            if type(recipeName) == "string" then
                                -- FIXED v0.4.0 SEARCH FILTER: Restores active text string pattern matching queries
                                if not filter or string.find(string.lower(recipeName), filter) then
                                    if not cmap[recipeName] then
                                        cmap[recipeName] = {}
                                        local h, w = AlternateWorldProfEngine.GetRecipeColorAndWeight(recipeName)
                                        table.insert(list, { name = recipeName, weight = w, color = h })
                                    end
                                    table.insert(cmap[recipeName], { name = c.name or "Alt", displayName = dName, isGathering = false })
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    if #list == 0 and #gList > 0 then
        local row = "Gathering Skill"
        if pLower == "fishing" then row = "Fishing Skill"
        elseif pLower == "herbalism" then row = "Herbalism Skill"
        elseif pLower == "skinning" then row = "Skinning Skill" end
        table.insert(list, { name = row, weight = 5, color = "|cFFFFFFFF" })
        cmap[row] = {}
        for _, g in ipairs(gList) do table.insert(cmap[row], { name = g.name, displayName = g.displayName, level = g.level, isGathering = true }) end
    end

    table.sort(list, function(a, b) if a.weight ~= b.weight then return a.weight < b.weight else return a.name < b.name end end)
    for _, arr in pairs(cmap) do table.sort(arr, function(a, b) return a.displayName < b.displayName end) end

    return list, cmap
end

-- End of [alternateprofengine.lua]
