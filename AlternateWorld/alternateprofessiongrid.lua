-- ============================================================================
-- Alternate World - Profession Grid Rendering Module (v0.2.0)
-- ============================================================================

AlternateWorldProfessionGrid = {}

local UIRowsPool = {}

local COL1_X = 15
local COL2_X = 260
local ROW_HEIGHT = 20

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

function AlternateWorldProfessionGrid.RefreshRecipesDisplay(scrollContentFrame)
    if not scrollContentFrame then return end
    
    for _, row in ipairs(UIRowsPool) do
        row:Hide()
    end
    
    local currentProf = AlternateWorldProfessionsView.GetLastSelectedProfession()
    if not currentProf then
        AlternateWorldProfessionsView.SetHeading("Select a Profession to begin.")
        return
    end

    AlternateWorldProfessionsView.SetHeading("Recipes for " .. currentProf)
    
    local filterText = AlternateWorldProfessionsView.GetSearchText()
    local recipeCraftersMap = {}
    local sortedRecipes = {}

    for charKey, charData in pairs(AlternateWorldDB) do
        if charData.professions and charData.professions[currentProf] then
            local profData = charData.professions[currentProf]
            if profData.recipes then
                for recipeName in pairs(profData.recipes) do
                    if not filterText or string.find(string.lower(recipeName), filterText) then
                        if not recipeCraftersMap[recipeName] then
                            recipeCraftersMap[recipeName] = {}
                            table.insert(sortedRecipes, recipeName)
                        end
                        table.insert(recipeCraftersMap[recipeName], {
                            name = charData.name,
                            classToken = charData.classToken,
                            level = profData.level or 0
                        })
                    end
                end
            end
        end
    end

    table.sort(sortedRecipes)

    local currentYOffset = -10
    local count = 0

    for _, recName in ipairs(sortedRecipes) do
        count = count + 1
        local rowFrame = UIRowsPool[count]

        if not rowFrame then
            rowFrame = CreateFrame("Frame", nil, scrollContentFrame)
            rowFrame:SetSize(scrollContentFrame:GetWidth() - 20, ROW_HEIGHT)
            
            rowFrame.Col1 = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            rowFrame.Col1:SetPoint("LEFT", rowFrame, "LEFT", COL1_X, 0)
            rowFrame.Col1:SetJustifyH("LEFT")
            rowFrame.Col1:SetTextColor(1, 1, 1)

            rowFrame.Col2 = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            rowFrame.Col2:SetPoint("LEFT", rowFrame, "LEFT", COL2_X, 0)
            rowFrame.Col2:SetJustifyH("LEFT")

            UIRowsPool[count] = rowFrame
        end

        if count == 1 then
            rowFrame:SetPoint("TOPLEFT", scrollContentFrame, "TOPLEFT", 0, -10)
        else
            rowFrame:SetPoint("TOPLEFT", UIRowsPool[count - 1], "BOTTOMLEFT", 0, -4)
        end

        rowFrame.Col1:SetText(recName)

        local craftersTextTable = {}
        for _, crafterInfo in ipairs(recipeCraftersMap[recName]) do
            local coloredName = AlternateWorldConfig.GetClassColoredText(crafterInfo.name, crafterInfo.classToken)
            table.insert(craftersTextTable, string.format("%s (%d)", coloredName, crafterInfo.level))
        end
        rowFrame.Col2:SetText(table.concat(craftersTextTable, ", "))
        
        rowFrame:Show()
        currentYOffset = currentYOffset - ROW_HEIGHT - 4
    end

    scrollContentFrame:SetHeight(math.abs(currentYOffset) + ROW_HEIGHT)
end
