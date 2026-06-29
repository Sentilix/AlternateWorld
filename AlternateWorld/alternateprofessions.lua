-- ============================================================================
-- Alternate World - Professions View UI Module Panel (v0.2.0 - REFINED CONST)
-- ============================================================================
AlternateWorldProfessionsView = {}
local AWProfessionsPanel, AWProfScrollFrame, AWProfScrollContent, AWProfHeadingText, AWProfessionDropdown, AWProfHeaderIconTexture = nil, nil, nil, nil, nil, nil
local AWLastSelectedProfession, AWIsViewActive, AW_RowsPool = nil, false, {}
local COL1_X, COL2_X, ROW_HEIGHT = 15, 260, 20

local function GetSafeRecipeTexture(name)
    if not name then return "interface\\icons\\inv_misc_questionmark" end
    local l = string.lower(name)
    if AlternateWorldConstants and AlternateWorldConstants.RECIPE_FALLBACKS then
        for keyword, path in pairs(AlternateWorldConstants.RECIPE_FALLBACKS) do
            if string.find(l, keyword) then return path end
        end
    end
    if AWLastSelectedProfession then
        local pLower = string.lower(AWLastSelectedProfession)
        if pLower == "alchemy" then return "interface\\icons\\inv_potion_02"
        elseif pLower == "blacksmithing" then return "interface\\icons\\inv_sword_04"
        elseif pLower == "engineering" then return "interface\\icons\\inv_misc_gear_01"
        elseif pLower == "tailoring" then return "interface\\icons\\inv_fabric_linen_01"
        elseif pLower == "cooking" then return "interface\\icons\\inv_misc_food_15"
        elseif pLower == "first aid" then return "interface\\icons\\spell_holy_sealofsacrifice" end
    end
    return "interface\\icons\\inv_misc_gear_02"
end

function AlternateWorldProfessionsView.GetLastSelectedProfession() return AWLastSelectedProfession end
function AlternateWorldProfessionsView.SetLastSelectedProfession(val) AWLastSelectedProfession = val end
function AlternateWorldProfessionsView.GetDropdownFrame() return AWProfessionDropdown end

function AlternateWorldProfessionsView.GetSearchText()
    local s = _G["AW_ProfSearchBoxInstance"]
    if not s then return nil end
    
    local text = string.lower(s:GetText() or "")
    
    -- TECHNICAL HOOK: Clean up and strip out any stray or unmanaged blank spaces safely
    if string.trim then
        text = string.trim(text)
    else
        text = string.gsub(text, "^%s*(.-)%s*$", "%1")
    end
    
    if text == "search recipe..." or text == "" then 
        return nil -- Returns nil safely to tell the engine that NO search query is active!
    end
    return text
end


function AlternateWorldProfessionsView.TriggerRefresh()
    local activeKey = AlternateWorldMainFrameEngine and AlternateWorldMainFrameEngine.GetSelectedCharacterKey and AlternateWorldMainFrameEngine.GetSelectedCharacterKey()
    AlternateWorldProfessionsView.RefreshDisplay(activeKey)
end

function AlternateWorldProfessionsView.RefreshDisplay(mainSelectedCharacterKey)
    if not AWProfScrollContent or not AlternateWorldProfEngine then return end
    for _, row in ipairs(AW_RowsPool) do row:Hide() if row.Icon then row.Icon:Hide() end end
    
    if not AWLastSelectedProfession or type(AWLastSelectedProfession) ~= "string" then
        if AWProfHeadingText then AWProfHeadingText:SetText("Select a Profession.") end
        if AWProfHeaderIconTexture then AWProfHeaderIconTexture:Hide() end
        return
    end

    -- Extract active realm and configuration context flags safely
    local activeRealm = mainSelectedCharacterKey and string.match(mainSelectedCharacterKey, "%s*-%s*(.+)") or GetRealmName()
    local activeCharName = mainSelectedCharacterKey and string.gsub(string.match(mainSelectedCharacterKey, "([^%-]+)") or mainSelectedCharacterKey, "%s+", "")
    local mustIsolate = AlternateWorldDB.Settings and AlternateWorldDB.Settings.IsolateSingleRealmsProf
    local assignedCluster = AlternateWorldDB.Settings.Clusters and AlternateWorldDB.Settings.Clusters[activeRealm]

    -- Dynamic Header text updates based securely on active cluster config contexts
    if AWProfHeadingText then 
        if not mustIsolate then
            AWProfHeadingText:SetText("|cFFFFFFFFRecipes Catalogue|r")
        elseif assignedCluster then
            local customName = AlternateWorldDB.Settings.ClusterNames and AlternateWorldDB.Settings.ClusterNames[assignedCluster] or "Cluster"
            AWProfHeadingText:SetText(string.format("|cFFFFFFFFRecipes on %s|r", customName))
        else
            AWProfHeadingText:SetText(string.format("|cFFFFFFFFRecipes on %s|r", activeRealm))
        end
    end

    if AWProfHeaderIconTexture then 
        AWProfHeaderIconTexture:SetTexture(AlternateWorldProfEngine.GetProfessionIconTexture(AWLastSelectedProfession)) 
        AWProfHeaderIconTexture:Show() 
    end

    -- Fetch search parameters and let the data engine filter out mismatches first
    local filterText = AlternateWorldProfessionsView.GetSearchText()
    local recipesToSort, recipeCraftersMap = AlternateWorldProfEngine.CompileSortedRecipes(AWLastSelectedProfession, filterText)
    
    local function GetProfRealmContext(realmName)
        if AlternateWorldDB and AlternateWorldDB.Settings and AlternateWorldDB.Settings.Clusters then
            local assignedCluster = AlternateWorldDB.Settings.Clusters[realmName]
            if assignedCluster then return assignedCluster end
        end
        return realmName
    end

    local liveContext = GetProfRealmContext(activeRealm or GetRealmName())
    local currentYOffset, count = -10, 0
    
    -- FIXED v0.4.0 SEARCH ENGINE: Loop directly over the pre-sorted and pre-filtered records array map from your engine
    for _, recipeObj in ipairs(recipesToSort) do
        local recName = recipeObj.name
        local rawCrafters = recipeCraftersMap[recName] or {}
        local filteredCrafters = {}

        -- Evaluate scope boundaries cleanly only on recipes that actually survived the text search query
        for _, cInfo in ipairs(rawCrafters) do
            local dbRealm = activeRealm
            local dbFaction = "Alliance"
            for fullKey, dbData in pairs(AlternateWorldDB) do
                if fullKey ~= "Settings" and dbData and dbData.name == cInfo.name then
                    dbRealm = dbData.realm or dbRealm
                    dbFaction = dbData.faction or dbFaction
                    break
                end
            end

            local sharedScope = false
            if not mustIsolate then
                sharedScope = true 
            elseif assignedCluster then
                local altCluster = AlternateWorldDB.Settings.Clusters and AlternateWorldDB.Settings.Clusters[dbRealm]
                sharedScope = (altCluster == assignedCluster)
            else
                sharedScope = (dbRealm == activeRealm)
            end

            if sharedScope then
                local crafterFaction = dbFaction
                local isSelf = false
                for dbKey, dbData in pairs(AlternateWorldDB) do
                    if dbKey ~= "Settings" and dbData and dbData.name == cInfo.name and (dbData.realm or "Unknown") == dbRealm then
                        crafterFaction = dbData.faction or "Alliance"
                        if activeCharName and dbData.name == activeCharName and (dbData.realm or "Unknown") == activeRealm then
                            isSelf = true
                        end
                        break
                    end
                end

                table.insert(filteredCrafters, {
                    name = cInfo.name,
                    displayName = cInfo.displayName,
                    level = cInfo.level,
                    isGathering = cInfo.isGathering,
                    faction = crafterFaction,
                    realm = dbRealm,
                    isSelf = isSelf
                })
            end
        end

        if #filteredCrafters > 0 then
            count = count + 1
            local rowFrame = AW_RowsPool[count]
            if not rowFrame then
                local FIXED_ROW_HEIGHT = 48
                rowFrame = CreateFrame("Frame", "AW_GridRowInstance" .. count, AWProfScrollContent)
                rowFrame:SetSize(AWProfScrollContent:GetWidth() - 20, FIXED_ROW_HEIGHT)
                rowFrame.fixedHeightCache = FIXED_ROW_HEIGHT 
                
                rowFrame.Icon = rowFrame:CreateTexture(nil, "OVERLAY")
                rowFrame.Icon:SetSize(32, 32)
                rowFrame.Icon:SetPoint("TOPLEFT", rowFrame, "TOPLEFT", COL1_X, -2)
                
                rowFrame.Col1 = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
                rowFrame.Col1:SetPoint("TOPLEFT", rowFrame.Icon, "TOPRIGHT", 12, -1)
                rowFrame.Col1:SetJustifyH("LEFT")
                
                rowFrame.Col2 = CreateFrame("Frame", nil, rowFrame)
                rowFrame.Col2:SetPoint("TOPLEFT", rowFrame.Icon, "BOTTOMRIGHT", 12, 10)
                rowFrame.Col2:SetSize(AWProfScrollContent:GetWidth() - 80, 28) 
                
                rowFrame.Col2Text = rowFrame.Col2:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                rowFrame.Col2Text:SetAllPoints(rowFrame.Col2)
                rowFrame.Col2Text:SetJustifyH("LEFT")
                rowFrame.Col2Text:SetJustifyV("TOP") 
                rowFrame.Col2Text:SetWordWrap(true)
                
                AW_RowsPool[count] = rowFrame
            end
            
            local activeHeight = rowFrame.fixedHeightCache or 48
            if count == 1 then rowFrame:SetPoint("TOPLEFT", AWProfScrollContent, "TOPLEFT", 0, -10)
            else rowFrame:SetPoint("TOPLEFT", AW_RowsPool[count - 1], "BOTTOMLEFT", 0, -14) end
            
            rowFrame:EnableMouse(true)
            rowFrame:SetScript("OnEnter", function(self)
                if string.find(string.lower(recName), "skill") then 
                    GameTooltip:Hide()
                    return 
                end

                GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
                GameTooltip:ClearLines()
                
                local _, itemLink = GetItemInfo(recName)
                if itemLink then
                    GameTooltip:SetHyperlink(itemLink)
                else
                    local foundSpellID = nil
                    for id = 1, 50000 do
                        local sName = GetSpellInfo(id)
                        if sName and string.lower(sName) == string.lower(recName) then
                            foundSpellID = id
                            break
                        end
                    end
                    
                    if foundSpellID then
                        GameTooltip:SetHyperlink("spell:" .. foundSpellID)
                    else
                        GameTooltip:AddLine("|cFFFFFFFF" .. recName .. "|r")
                        GameTooltip:AddLine("|cFF888888Querying server cache... Hover again!|r")
                    end
                end
                GameTooltip:Show()
            end)
            rowFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)

            local recipeTexture = "interface\\icons\\inv_misc_questionmark"
            if AlternateWorldConstants and AlternateWorldConstants.GetSafeRecipeTexture then
                recipeTexture = AlternateWorldConstants.GetSafeRecipeTexture(recName, AWLastSelectedProfession)
            end
            rowFrame.Icon:SetTexture(recipeTexture)
            rowFrame.Icon:Show()
            
            rowFrame.Col1:SetText(recipeObj.color .. recName .. "|r")

            table.sort(filteredCrafters, function(a, b)
                if a.faction ~= b.faction then return a.faction == "Alliance" end
                return a.name < b.name
            end)

            local craftersTextTable = {}
            for _, crafterInfo in ipairs(filteredCrafters) do
                local nameText = crafterInfo.displayName or crafterInfo.name
                if crafterInfo.isGathering and crafterInfo.level then nameText = string.format("%s (%d)", nameText, crafterInfo.level) end
                
                local colorHex = "|cFF0070DD"
                if crafterInfo.isSelf then
                    colorHex = "|cFFFFD100"
                elseif crafterInfo.faction == "Horde" then
                    colorHex = "|cFFFF0000"
                end

                table.insert(craftersTextTable, string.format("%s%s|r", colorHex, nameText))
            end

            rowFrame.Col2Text:SetText("Crafters: " .. table.concat(craftersTextTable, ", "))
            rowFrame:Show()
            
            currentYOffset = currentYOffset - activeHeight - 14
        end
    end
    AWProfScrollContent:SetHeight(math.abs(currentYOffset) + 48)
end

function AlternateWorldProfessionsView.CreatePanel(parentWindow)
    local targetParent = parentWindow or _G["AlternateWorldMainContentWindow"]
    if not targetParent or AWProfessionsPanel then return AWProfessionsPanel end
    AWProfessionsPanel = CreateFrame("Frame", "AWProfessionsPanelGlobal", targetParent)
    AWProfessionsPanel:SetSize(464, 385)
    AWProfessionsPanel:SetPoint("TOPLEFT", targetParent, "TOPLEFT", 0, 0)
    AWProfessionsPanel:Hide()
    return AWProfessionsPanel
end

function AlternateWorldProfessionsView.ShowData(selectedCharacterKey)
    if not AWProfessionsPanel then AlternateWorldProfessionsView.CreatePanel(_G["AlternateWorldMainContentWindow"]) end
    if not AWProfessionsPanel then return end
    AWIsViewActive = true 
    AWProfessionsPanel:Show()
    
    local activeRealm = selectedCharacterKey and string.match(selectedCharacterKey, "%s*-%s*(.+)") or GetRealmName()
    local assignedCluster = AlternateWorldDB.Settings.Clusters and AlternateWorldDB.Settings.Clusters[activeRealm]
    
    -- INITIALIZE CONFIG LAYER: Fills with true automatically on a cluster realm if settings are untouched
    if AlternateWorldDB.Settings.IsolateSingleRealmsProf == nil then
        AlternateWorldDB.Settings.IsolateSingleRealmsProf = (assignedCluster ~= nil)
    end
    local mustIsolate = AlternateWorldDB.Settings.IsolateSingleRealmsProf

    if not AWProfessionDropdown and AlternateWorldMainTopBar then
        AWProfessionDropdown = CreateFrame("Frame", "AW_ProfMenuDropdownInstance", AlternateWorldMainTopBar, "UIDropDownMenuTemplate")
        AWProfessionDropdown:SetPoint("LEFT", AlternateWorldCharDropdown, "RIGHT", -5, 0) 
        UIDropDownMenu_SetWidth(AWProfessionDropdown, 120) 
        
        AWProfHeaderIconTexture = AWProfessionsPanel:CreateTexture(nil, "OVERLAY")
        AWProfHeaderIconTexture:SetSize(18, 18)
        AWProfHeaderIconTexture:SetPoint("TOPLEFT", AWProfessionsPanel, "TOPLEFT", 15, -12)
        AWProfHeaderIconTexture:Hide()
        
        AWProfHeadingText = AWProfessionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        AWProfHeadingText:SetPoint("LEFT", AWProfHeaderIconTexture, "RIGHT", 8, 0)
        
        AWProfScrollFrame = CreateFrame("ScrollFrame", "AW_ProfScrollFrameInstance", AWProfessionsPanel, "UIPanelScrollFrameTemplate")
        AWProfScrollFrame:SetPoint("TOPLEFT", AWProfHeaderIconTexture, "BOTTOMLEFT", 0, -45)
        AWProfScrollFrame:SetPoint("BOTTOMRIGHT", AWProfessionsPanel, "BOTTOMRIGHT", -30, -35)       

        AWProfScrollContent = CreateFrame("Frame", nil, AWProfScrollFrame)
        AWProfScrollContent:SetSize(434, 1)
        AWProfScrollFrame:SetScrollChild(AWProfScrollContent)
    end

    -- 1. UNIVERSAL PLUG-AND-PLAY CHECKBOX GENERATOR: Anchored dynamically inside the top bar lane
    local ProfIsolateCB = _G["AW_ProfIsolateCheckbox"]
    if not ProfIsolateCB and AWProfessionsPanel then
        ProfIsolateCB = CreateFrame("CheckButton", "AW_ProfIsolateCheckbox", AWProfessionsPanel, "InterfaceOptionsCheckButtonTemplate")
        ProfIsolateCB:SetPoint("TOPLEFT", AWProfessionsPanel, "TOPLEFT", 15, -35)
        _G[ProfIsolateCB:GetName() .. "Text"]:SetText("Restrict professions to local realm or cluster")
        
        ProfIsolateCB:SetScript("OnClick", function(self)
            if AlternateWorldDB and AlternateWorldDB.Settings then
                AlternateWorldDB.Settings.IsolateSingleRealmsProf = self:GetChecked() and true or false
                AlternateWorldProfessionsView.RefreshDisplay(selectedCharacterKey)
            end
        end)

        -- THE SIMPLE VERBATIM INDEX TOOLTIP LAYOUT CONFIG
        ProfIsolateCB:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
            GameTooltip:ClearLines()
            GameTooltip:AddLine("|cFFFFFFFFRestrict Profession Lists|r")
            GameTooltip:AddLine("|cFFFFD100When enabled, only crafters on the same realm or cluster as you will be listed.|r", 1, 1, 1, true)
            GameTooltip:AddLine("|cFF888888Disable this to view all crafters across your entire account.|r", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        ProfIsolateCB:SetScript("OnLeave", function() GameTooltip:Hide() end)
    end

    -- 2. FIXED v0.4.0 ENFORCE LIBERATION LAYER: Hard-forces the Classic Era frame engine to unlock button interaction states
    if ProfIsolateCB then
        ProfIsolateCB:Enable() -- HARD RE-ENABLE: Smashes through the UI cache block permanently
        ProfIsolateCB:SetChecked(mustIsolate)
        _G[ProfIsolateCB:GetName()]:SetAlpha(1.0) -- Restores layout visibility to 100%
        _G[ProfIsolateCB:GetName() .. "Text"]:SetTextColor(1.0, 0.82, 0) -- Forces crisp Blizzard Gold back on screen
        _G[ProfIsolateCB:GetName() .. "Text"]:SetAlpha(1.0)
        ProfIsolateCB:Show()
    end

    if AWProfessionDropdown and AlternateWorldProfDropdown then AlternateWorldProfDropdown.Setup(AWProfessionDropdown, AWProfessionsPanel, selectedCharacterKey) AWProfessionDropdown:Show() end
    local scanned = AlternateWorldProfEngine and AlternateWorldProfEngine.GetSortedScannedProfessions() or {}
    
    -- 3. FIXED v0.4.0 4-TIER PRIORITY ENGINE: Hierarchy weights 1 for Primary, 2 for Secondary, 3 for Gathering, and 4 for Riding
    if not AWLastSelectedProfession or type(AWLastSelectedProfession) ~= "string" then
        local localActiveProf = nil
        local charData = AlternateWorldDB[selectedCharacterKey]
        
        -- Custom dictionary mapping layout weights carefully to keep layout intuitive
        local PROF_WEIGHTS = {
            -- Tier 2: Secondary Recipe professions
            ["cooking"] = 2, ["first aid"] = 2,
            -- Tier 3: Gathering skills 
            ["mining"] = 3, ["herbalism"] = 3, ["skinning"] = 3, ["fishing"] = 3,
            -- Tier 4: Mounts and riding training anchors
            ["riding"] = 4, ["ridning"] = 4
        }

        if charData and charData.professions then
            local localProfs = {}
            for pName in pairs(charData.professions) do
                local lName = string.lower(pName)
                -- Default 1 for true Primary Crafting skills (Engineering, Enchanting etc.)
                local weight = PROF_WEIGHTS[lName] or 1
                table.insert(localProfs, { name = pName, weight = weight })
            end
            
            -- Sorts hierarchically: Lowest weight value wins (Primary -> Secondary -> Gathering -> Riding), then Alphabetical
            table.sort(localProfs, function(a, b)
                if a.weight ~= b.weight then
                    return a.weight < b.weight
                end
                return a.name < b.name
            end)
            
            if #localProfs > 0 then
                localActiveProf = localProfs[1].name -- Grab the first highest prioritized node string!
            end
        end

        -- Hard account wide fallback sweep layer if the current character has zero active data
        if not localActiveProf and #scanned > 0 then
            local fallbackProfs = {}
            for _, pName in ipairs(scanned) do
                local lName = string.lower(pName)
                local weight = PROF_WEIGHTS[lName] or 1
                table.insert(fallbackProfs, { name = pName, weight = weight })
            end
            table.sort(fallbackProfs, function(a, b)
                if a.weight ~= b.weight then return a.weight < b.weight end
                return a.name < b.name
            end)
            localActiveProf = fallbackProfs[1].name
        end

        AWLastSelectedProfession = localActiveProf or scanned[1] or "Alchemy"
    end

    -- Safely push the text layout string into the dropdown container field matrix
    if AWLastSelectedProfession and type(AWLastSelectedProfession) == "string" then
        UIDropDownMenu_SetText(AWProfessionDropdown, string.format("|T%s:14:14:0:0|t %s", AlternateWorldProfEngine.GetProfessionIconTexture(AWLastSelectedProfession), AWLastSelectedProfession))
    else
        UIDropDownMenu_SetText(AWProfessionDropdown, "No data scanned")
    end
    
    if #scanned == 0 then
        if AWProfHeadingText then AWProfHeadingText:SetText("|cFFFFFFFFRecipes Catalogue|r") end
        if not AWProfessionsPanel.InstructionsLabel then
            local lbl = AWProfessionsPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            -- FIXED v0.4.0 TOP ANCHOR: Anchors flawlessly 12px directly below your new checkbox frame object
            lbl:SetPoint("TOPLEFT", ProfIsolateCB, "BOTTOMLEFT", 5, -12)
            lbl:SetText("To begin: Open your character's Tradeskill window to scan recipes!")
            AWProfessionsPanel.InstructionsLabel = lbl
        end
        AWProfessionsPanel.InstructionsLabel:Show()
        if AWProfHeaderIconTexture then AWProfHeaderIconTexture:Hide() end
    else 
        if AWProfessionsPanel.InstructionsLabel then AWProfessionsPanel.InstructionsLabel:Hide() end
        AlternateWorldProfessionsView.RefreshDisplay(selectedCharacterKey) 
    end
end

function AlternateWorldProfessionsView.HidePanel()
    AWIsViewActive = false 
    if AWProfessionsPanel then AWProfessionsPanel:Hide() end
    if AWProfessionDropdown then AWProfessionDropdown:Hide() end
    if _G["AW_ProfIsolateCheckbox"] then _G["AW_ProfIsolateCheckbox"]:Hide() end -- NEW v0.4.0
    if AlternateWorldProfDropdown and AlternateWorldProfDropdown.HideSearch then AlternateWorldProfDropdown.HideSearch() end
end


function AlternateWorldProfessionsView.IsShown() return AWIsViewActive end

-- End of [alternateprofessions.lua]
