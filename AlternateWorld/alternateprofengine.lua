-- ============================================================================
-- Alternate World - Profession Sorter Engine (v0.2.0 - RAW INJECTION)
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

function AlternateWorldProfEngine.GetSortedScannedProfessions()
    if not AlternateWorldDB then return {} end
    local s, list = {}, {}
    for _, c in pairs(AlternateWorldDB) do
        if c.professions then for p in pairs(c.professions) do if type(p) == "string" then s[p] = true end end end
    end
    for n in pairs(s) do table.insert(list, n) end
    table.sort(list)
    return list
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
    
    -- Force lower-case check, and fallback to string extraction if it's a table
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
                                -- FIXED: Completely bypassed filter strings to eliminate text blocks drops
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
