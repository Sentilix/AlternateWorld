-- ============================================================================
-- Alternate World - Automated Mail Clerk Logistics Module (v0.3.0 - SUCCESS)
-- ============================================================================

local MailClerkFrame = CreateFrame("Frame")
-- FIXED: Enforced the exact verified native vanilla Era event token captured by the tracer
MailClerkFrame:RegisterEvent("MAIL_SEND_INFO_UPDATE")

MailClerkFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "MAIL_SEND_INFO_UPDATE" and AlternateWorldDB and AlternateWorldCategoryDB then
        -- Safety Lock: Only autofill if the recipient name box is completely empty
        local currentRecipient = SendMailNameEditBox:GetText() or ""
        if string.gsub(currentRecipient, "%s+", "") ~= "" then return end

        local currentRealm = GetRealmName()
        local currentFaction = UnitFactionGroup("player") or "Alliance"

        -- Sweep all 12 attachments lines dynamically to support any slot configuration placement
        for slotIndex = 1, 12 do
            local itemName, itemID, _, _, _, _, itemType, itemSubtype = GetSendMailItem(slotIndex)
            
            if itemID then
                local categoryID = AlternateWorldCategoryDB.GetItemCategory(itemID, itemType, itemSubtype)
                
                if categoryID and AlternateWorldDB.Settings and AlternateWorldDB.Settings.Bankers then
                    local realmData = AlternateWorldDB.Settings.Bankers[currentRealm]
                    local factionData = realmData and realmData[currentFaction]
                    local assignedBankerKey = factionData and factionData[categoryID]

                    if assignedBankerKey then
                        local namePart, realmPart = string.match(assignedBankerKey, "([^%-]+)%s*-%s*(.+)")
                        if namePart and realmPart then
                            namePart = string.gsub(namePart, "%s+", "")
                            realmPart = string.gsub(realmPart, "%s+", "")
                            
                            local currentCleanRealm = string.gsub(currentRealm, "%s+", "")
                            
                            if string.lower(realmPart) ~= string.lower(currentCleanRealm) then
                                SendMailNameEditBox:SetText(namePart .. "-" .. realmPart)
                            else
                                SendMailNameEditBox:SetText(namePart)
                            end
                            PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)
                            return -- SUCCESS BREAK: Stop sweeping further attachment slots instantly
                        end
                    end
                end
            end
        end
    end
end)

-- End of [alternatepost.lua]
