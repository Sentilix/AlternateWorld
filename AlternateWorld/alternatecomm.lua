-- ============================================================================
-- Alternate World - Inter-Player Communication & Network Module
-- ============================================================================

AlternateWorldComm = {}

local CommFrame = nil
local ADDON_COMM_PREFIX = "AltWorldVer"

-- Register prefix instantly when file loads
if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
    C_ChatInfo.RegisterAddonMessagePrefix(ADDON_COMM_PREFIX)
end

function AlternateWorldComm.ExecuteVersionCheck()
    local myName = UnitName("player")
    local localVersion = C_AddOns.GetAddOnMetadata("AlternateWorld", "Version") or "0.2.0"
    
    print("|cFF2266DD[|r|cFF00CCFFAlternate World|r|cFF2266DD] Running version check...|r")
    
    if AlternateWorldMainFrameEngine and AlternateWorldMainFrameEngine.PrintVersionResult then
        AlternateWorldMainFrameEngine.PrintVersionResult(myName, localVersion)
    end

    if not IsInGroup() then return end

    local targetChannel = IsInRaid() and "RAID" or "PARTY"
    C_ChatInfo.SendAddonMessage(ADDON_COMM_PREFIX, "VERSION_REQUEST", targetChannel)
end

-- FIXED: Explicitly called from alternatemain once all global layout tables are ready
function AlternateWorldComm.Initialize()
    if CommFrame then return end

    CommFrame = CreateFrame("Frame")
    CommFrame:RegisterEvent("CHAT_MSG_ADDON")

    CommFrame:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
        if prefix ~= ADDON_COMM_PREFIX then return end
        
        local playerUnitName = UnitName("player")
        local cleanSender = string.match(sender, "([^%-]+)") or sender
        
        if message == "VERSION_REQUEST" then
            local targetChannel = IsInRaid() and "RAID" or "PARTY"
            if cleanSender ~= playerUnitName then
                local localVersion = C_AddOns.GetAddOnMetadata("AlternateWorld", "Version") or "0.2.0"
                C_ChatInfo.SendAddonMessage(ADDON_COMM_PREFIX, "VERSION_RESPONSE:" .. localVersion, targetChannel)
            end
            
        elseif string.match(message, "^VERSION_RESPONSE:") then
            if cleanSender ~= playerUnitName then
                local remoteVersion = string.sub(message, 18)
                if remoteVersion and AlternateWorldMainFrameEngine and AlternateWorldMainFrameEngine.PrintVersionResult then
                    AlternateWorldMainFrameEngine.PrintVersionResult(cleanSender, remoteVersion)
                end
            end
        end
    end)
end
