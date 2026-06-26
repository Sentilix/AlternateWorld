-- ============================================================================
-- Alternate World - Global Constants Registry Dictionary (v0.2.0)
-- ============================================================================

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

-- End of [alternateconstants.lua]
