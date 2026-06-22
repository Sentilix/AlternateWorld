-- ============================================================================
-- Alternate World - Database Core Engine
-- ============================================================================

AlternateWorldDBEngine = {}

-- Main Constructor: Packages fully gathered data snapshots securely into account matrices
function AlternateWorldDBEngine.SaveCurrentCharacterData()
    if not AlternateWorldDB then AlternateWorldDB = {} end
    
    local charName = UnitName("player")
    local realmName = GetRealmName()
    if not charName or not realmName then return end
    
    local myKey = charName .. " - " .. realmName
    
    -- Safety hook: If the scraping module hasn't loaded yet, abort to prevent zero-overwrites
    if not AlternateWorldScraper or not AlternateWorldScraper.GatherFullSnapshot then return end
    
    -- Request a fresh, comprehensive data pack directly from the scraper module
    local currentSnapshot = AlternateWorldScraper.GatherFullSnapshot(AlternateWorldDB[myKey])
    if not currentSnapshot then return end
    
    -- Inject the completely compiled profile directly into the global data tree
    AlternateWorldDB[myKey] = currentSnapshot
end

-- Bank Sync Entry Hook
function AlternateWorldDBEngine.ScanBankData()
    local charName = UnitName("player")
    local realmName = GetRealmName()
    if not charName or not realmName then return end
    local myKey = charName .. " - " .. realmName
    
    if AlternateWorldDB and AlternateWorldDB[myKey] and AlternateWorldScraper and AlternateWorldScraper.ScanContainers then
        -- Force a synchronous scan of the bank bags (-1 and 5 to 11)
        AlternateWorldDB[myKey].bankItems = AlternateWorldScraper.ScanContainers(-1, 11)
        AlternateWorldDB[myKey].bankUpdated = date("%Y-%m-%d %H:%M")
        
        -- Re-run master save to ensure cross-dependencies remain synchronized
        AlternateWorldDBEngine.SaveCurrentCharacterData()
    end
end
