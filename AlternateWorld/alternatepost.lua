-- ============================================================================
-- Alternate World - Automated Mail Clerk Logistics Module (v0.4.0 - CLUSTERED)
-- ============================================================================

local MailClerkFrame = CreateFrame("Frame")
MailClerkFrame:RegisterEvent("MAIL_SEND_INFO_UPDATE")

-- Internal shortcut to map realms families dynamically
local function GetPostRealmContext(realmName)
    if AlternateWorldDB and AlternateWorldDB.Settings and AlternateWorldDB.Settings.Clusters then
        local assignedCluster = AlternateWorldDB.Settings.Clusters[realmName]
        if assignedCluster then return assignedCluster end
    end
    return realmName
end

MailClerkFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "MAIL_SEND_INFO_UPDATE" and AlternateWorldDB and AlternateWorldCategoryDB then
        local currentRecipient = SendMailNameEditBox:GetText() or ""
        if string.gsub(currentRecipient, "%s+", "") ~= "" then return end

        local currentRealm = GetRealmName()
        local currentFaction = UnitFactionGroup("player") or "Alliance"
        local livePostContext = GetPostRealmContext(currentRealm)

        for slotIndex = 1, 12 do
            local itemLink = GetSendMailItemLink(slotIndex)
            
            if itemLink then
                local itemID = string.match(itemLink, "item:(%d+)")
                
                if itemID then
                    local itemName, _, _, _, _, _, itemType, itemSubtype = GetSendMailItem(slotIndex)
                    local categoryID = AlternateWorldCategoryDB.GetItemCategory(itemID, itemType, itemSubtype)
                    
                    if categoryID and AlternateWorldDB.Settings and AlternateWorldDB.Settings.Bankers then
                        -- Query the global cluster bucket or single realm matrix folder safely
                        local realmData = AlternateWorldDB.Settings.Bankers[livePostContext]
                        local factionData = realmData and realmData[currentFaction]
                        local assignedBankerKey = factionData and factionData[categoryID]

                        if assignedBankerKey then
                            local namePart, realmPart = string.match(assignedBankerKey, "([^%-]+)%s*-%s*(.+)")
                            if namePart and realmPart then
                                namePart = string.gsub(namePart, "%s+", "")
                                realmPart = string.gsub(realmPart, "%s+", "")
                                
                                local cleanCurrentRealm = string.gsub(currentRealm, "%s+", "")
                                local cleanDestRealm = string.gsub(realmPart, "%s+", "")
                                
                                -- FIXED v0.4.0 POST ENGINE: Appends cross-realm -Server suffixes automatically if inside cluster family
                                if string.lower(cleanDestRealm) ~= string.lower(cleanCurrentRealm) then
                                    SendMailNameEditBox:SetText(namePart .. "-" .. realmPart)
                                else
                                    SendMailNameEditBox:SetText(namePart)
                                end
                                PlaySound(856)
                                return 
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- End of [alternatepost.lua]
