-- ============================================================================
-- Alternate World - Global Constants Registry Dictionary (v0.2.0)
-- ============================================================================

local addonMetadata = {
	["ADDONNAME"]		= "AlternateWorld",
	["SHORTNAME"]		= "AlternateWorld",
	["PREFIX"]			= "AWorldv1",
	["NORMALCHATCOLOR"]	= "40A0F8",
	["HOTCHATCOLOR"]	= "00F0F0",
};

AlternateWorld = select(2, ...)
AlternateWorld.lib = DigamAddonLib:New(addonMetadata);
AlternateWorld.API = AlternateWorld.lib.API;



AlternateWorldConstants = {}

AlternateWorldConstants.CLASS_COORDS = {
    ["WARRIOR"]     = {0, 0.25, 0, 0.25},
    ["MAGE"]        = {0.25, 0.5, 0, 0.25},
    ["ROGUE"]       = {0.5, 0.75, 0, 0.25},
    ["DRUID"]       = {0.75, 1, 0, 0.25},
    ["HUNTER"]      = {0, 0.25, 0.25, 0.5},
    ["SHAMAN"]      = {0.25, 0.5, 0.25, 0.5},
    ["PRIEST"]      = {0.5, 0.75, 0.25, 0.5},
    ["WARLOCK"]     = {0.75, 1, 0.25, 0.5},
    ["PALADIN"]     = {0, 0.25, 0.5, 0.75}
}

AlternateWorldConstants.RECIPE_FALLBACKS = {
    ["enchant"] = "interface\\icons\\trade_engraving", -- FIXED: Corrected spelling from engraging back to engraving
    ["potion"]  = "interface\\icons\\inv_potion_01",
    ["elixir"]  = "interface\\icons\\inv_potion_10",
    ["flask"]   = "interface\\icons\\inv_potion_13",
    ["iron"]    = "interface\\icons\\inv_ingot_03",
    ["leather"] = "interface\\icons\\inv_misc_armorkit_03",
    ["shirt"]   = "interface\\icons\\inv_shirt_01",
    ["boot"]    = "interface\\icons\\inv_boots_05",
    ["glove"]   = "interface\\icons\\inv_gloves_05",
    ["chest"]   = "interface\\icons\\inv_chest_chain",
    ["bracer"]  = "interface\\icons\\inv_bracer_02",
    ["belt"]    = "interface\\icons\\inv_belt_02",
    ["scroll"]  = "interface\\icons\\inv_scroll_03",
    ["bandage"] = "interface\\icons\\spell_holy_sealofsacrifice",
    ["oil"]     = "interface\\icons\\inv_potion_104",
    ["stone"]   = "interface\\icons\\inv_stone_04",
    ["scope"]   = "interface\\icons\\inv_misc_spyglass_02",
    ["reagent"] = "interface\\icons\\inv_misc_dust_01"
}

-- FIXED v0.5.0 BRAND CONSTANTS: Centralized premium color tokens for all cross-account virtual entities
AlternateWorldConstants.VIRTUAL_BANKER_COLOR_HEX = "|cFF00FF98" -- THE EXCLUSIVE JADE-GREEN SIGNATURE TINT
-- FIXED v0.5.0 BRAND CONSTANTS: New frame registration for the WeakAura export portal engine
AlternateWorldConstants.EXPORT_DIALOG_ICON_ID = 236424 -- Reuses the premium green Thermaplugg sprite
-- FIXED v0.6.4 NETWORK CONSTANT: Encapsulated addon prefix to ensure global data layout security across files
AlternateWorldConstants.ADDON_COMM_PREFIX = "AltWorldVer"
-- FIXED v0.6.4 CHAT LAYOUT CONSTANT: Centralized brand prefix string utilizing the official alliance blue hex color format
AlternateWorldConstants.CHAT_PREFIX = "|cFF0070DD[Alternate World]|r"

function AlternateWorldConstants.GetSafeRecipeTexture(name, currentProf)
    if not name then return "interface\\icons\\inv_misc_questionmark" end
    local l = string.lower(name)
    for keyword, path in pairs(AlternateWorldConstants.RECIPE_FALLBACKS) do
        if string.find(l, keyword) then return path end
    end
    if currentProf then
        local pLower = string.lower(currentProf)
        if pLower == "alchemy" then return "interface\\icons\\inv_potion_02"
        elseif pLower == "blacksmithing" then return "interface\\icons\\inv_sword_04"
        elseif pLower == "engineering" then return "interface\\icons\\inv_misc_gear_01"
        elseif pLower == "tailoring" then return "interface\\icons\\inv_fabric_linen_01"
        elseif pLower == "cooking" then return "interface\\icons\\inv_misc_food_15"
        elseif pLower == "first aid" then return "interface\\icons\\spell_holy_sealofsacrifice" end
    end
    return "interface\\icons\\inv_misc_gear_02"
end


-- FIXED v0.6.4 CENTRAL PRINT UTILITY: Globally accessible custom print wrapper that automatically prepends the centralized chat prefix
function AddonPrint(...)
    local prefix = AlternateWorldConstants and AlternateWorldConstants.CHAT_PREFIX or "|cFF0070DD[Alternate World]|r"
    
    -- Pass all incoming vararg parameters cleanly into the native print engine alongside the prefix
    print(prefix, ...)
end


-- ============================================================================
-- Alternate World - Server Clusters Core Constants & Dialogs Engine (v0.4.0)
-- ============================================================================

AlternateWorldClusterConstants = {}

AlternateWorldClusterConstants.Assets = {
    ["cluster_1"] = { name = "Cluster 1", icon = "interface\\icons\\inv_jewelcrafting_gem_04" },
    ["cluster_2"] = { name = "Cluster 2", icon = "interface\\icons\\inv_jewelcrafting_gem_02" },
    ["cluster_3"] = { name = "Cluster 3", icon = "interface\\icons\\inv_jewelcrafting_gem_03" },
    ["cluster_4"] = { name = "Cluster 4", icon = "interface\\icons\\inv_jewelcrafting_gem_01" },
    ["cluster_5"] = { name = "Cluster 5", icon = "interface\\icons\\inv_jewelcrafting_gem_05" }
}

-- FIXED v0.4.0 MERGED DIALOG: Stripped OnShow layer to avoid Blizzard cache resets
StaticPopupDialogs["AW_RENAME_CLUSTER_PROMPT"] = {
    text = "Enter new name for %s (Max 20 characters):",
    button1 = "Accept",
    button2 = "Cancel",
    hasEditBox = 1,
    maxLetters = 20,
    OnAccept = function(self, data)
        local text = self.EditBox:GetText()
        if text and string.gsub(text, "%s+", "") ~= "" and data then
            AlternateWorldDB.Settings.ClusterNames[data] = text
            if AlternateWorldClustersView and AlternateWorldClustersView.RefreshClusterView then
                AlternateWorldClustersView.RefreshClusterView()
            end
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

-- End of [alternateconstants.lua]
