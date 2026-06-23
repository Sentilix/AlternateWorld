-- ============================================================================
-- Alternate World - Profession Grid Rendering & Quality Sorter (v0.2.0)
-- ============================================================================

AlternateWorldProfessionGrid = {}

local AW_RowsPool = {}

local COL1_X = 15
local COL2_X = 260
local ROW_HEIGHT = 20

local QUALITY_WEIGHTS = {
    ["orange"]    = 1, 
    ["purple"]    = 2, 
    ["blue"]      = 3, 
    ["green"]     = 4, 
    ["white"]     = 5, 
    ["grey"]      = 6, 
    ["unknown"]   = 7
}

function AlternateWorldProfessionGrid.GetSortedScannedProfessions()
    if not AlternateWorldDB then return {} end
    local profSet = {}
    
    for _, charData in pairs(AlternateWorldDB) do
        if charData.professions then
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

local function GetRecipeColorAndWeight(recipeName)
    local itemColorHex = "|cFFFFFFFF" 
    local weight = QUALITY_WEIGHTS["white"]

    local _, itemLink = GetItemInfo(recipeName)
    if itemLink then
        if string.find(itemLink, "cffff8000") then
            itemColorHex, weight = "|cFFFF8000", QUALITY_WEIGHTS["orange"]
        elseif string.find(itemLink, "ffa335ee") then
            itemColorHex, weight = "|cFFA335EE", QUALITY_WEIGHTS["purple"]
        elseif string.find(itemLink, "ff0070dd") then
            itemColorHex, weight = "|cFF0070DD", QUALITY_WEIGHTS["blue"]
        elseif string.find(itemLink, "ff1eff00") then
            itemColorHex, weight = "|cFF1EFF00", QUALITY_WEIGHTS["green"]
        elseif string.find(itemLink, "ff9d9d9d") then
            itemColorHex, weight = "|cFF9D9D9D", QUALITY_WEIGHTS["grey"]
        end
    else
        local lowerName = string.lower(recipeName)
        if string.find(lowerName, "enchant") or string.find(lowerName, "healing") or string.find(lowerName, "spellpower") then
            itemColorHex, weight = "|cFF0070DD", QUALITY_WEIGHTS["blue"]
        end
    end

    return itemColorHex, weight
end

function AlternateWorldProfessionGrid.RefreshRecipesDisplay(scrollContentFrame, mainSelectedCharacterKey)
    if not scrollContentFrame then return end
    
    for _, row in ipairs(AW_RowsPool) do
        row:Hide()
    end
    
    if not AlternateWorldProfessionsView or not AlternateWorldProfessionsView.GetLastSelectedProfession then return end
    
    local currentProf = AlternateWorldProfessionsView.GetLastSelectedProfession()
    if not currentProf then
        if AlternateWorldProfessionsView.SetHeading then AlternateWorldProfessionsView.SetHeading("Select a Profession to begin.") end
        return
    end

    if AlternateWorldProfessionsView.SetHeading then AlternateWorldProfessionsView.SetHeading("Recipes for " .. currentProf) end
    
    local filterText = AlternateWorldProfessionsView.GetSearchText()
    local recipeCraftersMap = {}
    local recipesToSort = {}

    local activeCharName = nil
    if mainSelectedCharacterKey then
        activeCharName = string.match(mainSelectedCharacterKey, "([^%-]+)") or mainSelectedCharacterKey
        activeCharName = string.trim and string.trim(activeCharName) or activeCharName
    end

    for charKey, charData in pairs(AlternateWorldDB) do
        if charData.professions and charData.professions[currentProf] then
            local profData = charData.professions[currentProf]
            if profData.recipes then
                for recipeName in pairs(profData.recipes) do
                    if not filterText or string.find(string.lower(recipeName), filterText) then
                        if not recipeCraftersMap[recipeName] then
                            recipeCraftersMap[recipeName] = {}
                            local colorHex, weight = GetRecipeColorAndWeight(recipeName)
                            table.insert(recipesToSort, { name = recipeName, weight = weight, color = colorHex })
                        end
                        table.insert(recipeCraftersMap[recipeName], {
                            name = charData.name,
                            level = profData.level or 0
                        })
                    end
                end
            end
        end
    end

    table.sort(recipesToSort, function(a, b)
        if a.weight ~= b.weight then
            return a.weight < b.weight
        else
            return a.name < b.name
        end
    end)

    local currentYOffset = -10
    local count = 0

    for _, recipeObj in ipairs(recipesToSort) do
        count = count + 1
        local rowFrame = AW_RowsPool[count]
        local recName = recipeObj.name

        if not rowFrame then
            -- FIXED: Added AW_ unique names to table grid frame child pools objects
            rowFrame = CreateFrame("Frame", "AW_GridRowInstance" .. count, scrollContentFrame)
            rowFrame:SetSize(scrollContentFrame:GetWidth() - 20, ROW_HEIGHT)
            
            rowFrame.Col1 = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            rowFrame.Col1:SetPoint("LEFT", rowFrame, "LEFT", COL1_X, 0)
            rowFrame.Col1:SetJustifyH("LEFT")

            rowFrame.Col2 = CreateFrame("Frame", nil, rowFrame)
            rowFrame.Col2:SetSize(scrollContentFrame:GetWidth() - COL2_X - 10, ROW_HEIGHT)
            rowFrame.Col2:SetPoint("LEFT", rowFrame, "LEFT", COL2_X, 0)
            
            rowFrame.Col2Text = rowFrame.Col2:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            rowFrame.Col2Text:SetAllPoints(rowFrame.Col2)
            rowFrame.Col2Text:SetJustifyH("LEFT")

            AW_RowsPool[count] = rowFrame
        end

        if count == 1 then
            rowFrame:SetPoint("TOPLEFT", scrollContentFrame, "TOPLEFT", 0, -10)
        else
            rowFrame:SetPoint("TOPLEFT", AW_RowsPool[count - 1], "BOTTOMLEFT", 0, -4)
        end

        rowFrame.Col1:SetText(recipeObj.color .. recName .. "|r")

        local craftersTextTable = {}
        for _, crafterInfo in ipairs(recipeCraftersMap[recName]) do
            if activeCharName and crafterInfo.name == activeCharName then
                table.insert(craftersTextTable, string.format("|cFFFFFFFF%s (%d)|r", crafterInfo.name, crafterInfo.level))
            else
                table.insert(craftersTextTable, string.format("|cFFFFD700%s (%d)|r", crafterInfo.name, crafterInfo.level))
            end
        end
        
        rowFrame.Col2Text:SetText(table.concat(craftersTextTable, ", "))
        rowFrame:Show()
        currentYOffset = currentYOffset - ROW_HEIGHT - 4
    end

    scrollContentFrame:SetHeight(math.abs(currentYOffset) + ROW_HEIGHT)
end
