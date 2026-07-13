-- ============================================================================
-- Alternate World - Inter-Player Communication & Network Module
-- ============================================================================

AlternateWorldComm = {}

local CommFrame = nil
local ADDON_COMM_PREFIX = "AltWorldVer"

-- Register prefix instantly when file loads using the new secure global constants table
if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix and AlternateWorldConstants and AlternateWorldConstants.ADDON_COMM_PREFIX then
    C_ChatInfo.RegisterAddonMessagePrefix(AlternateWorldConstants.ADDON_COMM_PREFIX)
end

function AlternateWorldComm.Initialize()
    if CommFrame then return end

    CommFrame = CreateFrame("Frame")
    CommFrame:RegisterEvent("CHAT_MSG_ADDON")

    CommFrame:SetScript("OnEvent", function(self, event, prefix, message, channel, sender)
        -- FIXED v0.6.4 CONSTANT SYNCHRONIZATION: Now strictly targets the encapsulated namespace array
        if prefix ~= AlternateWorldConstants.ADDON_COMM_PREFIX then return end
        
        local playerUnitName = UnitName("player")
        local cleanSender = string.match(sender, "([^%-]+)") or sender
        
        if message == "VERSION_REQUEST" then
            local targetChannel = IsInRaid() and "RAID" or "PARTY"
            if cleanSender ~= playerUnitName then
                -- FIXED v0.6.4 DYNAMIC METADATA FALLBACK: Stripped hardcoded version strings to enforce single-source layout rules via the TOC file
                local localVersion = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("AlternateWorld", "Version") or "Unknown"
                
                C_ChatInfo.SendAddonMessage(AlternateWorldConstants.ADDON_COMM_PREFIX, "VERSION_RESPONSE:" .. localVersion, targetChannel)
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

