-- ============================================================================
-- Alternate World - Configuration & Static Data Dictionary
-- ============================================================================

AlternateWorldConfig = {}

-- Hardcoded tree definitions for Classic Era mapping to guarantee accurate icons/names
AlternateWorldConfig.TalentTrees = {
    ["WARRIOR"] = {
        { name = "Arms", icon = "Interface\\Icons\\Ability_Warrior_SavageBlow" },
        { name = "Fury", icon = "Interface\\Icons\\Ability_Warrior_InnerRage" },
        { name = "Protection", icon = "Interface\\Icons\\INV_Shield_06" }
    },
    ["MAGE"] = {
        { name = "Arcane", icon = "Interface\\Icons\\Spell_Holy_MagicalShield" },
        { name = "Fire", icon = "Interface\\Icons\\Spell_Fire_FireBolt02" },
        { name = "Frost", icon = "Interface\\Icons\\Spell_Frost_FrostBolt02" }
    },
    ["ROGUE"] = {
        { name = "Assassination", icon = "Interface\\Icons\\Ability_Rogue_DeadlyLook" },
        { name = "Combat", icon = "Interface\\Icons\\Ability_BackStab" },
        { name = "Subtlety", icon = "Interface\\Icons\\Ability_Stealth" }
    },
    ["PRIEST"] = {
        { name = "Discipline", icon = "Interface\\Icons\\Spell_Holy_WordFortitude" },
        { name = "Holy", icon = "Interface\\Icons\\Spell_Holy_GuardianSpirit" },
        { name = "Shadow", icon = "Interface\\Icons\\Spell_Shadow_ShadowWordPain" }
    },
    ["HUNTER"] = {
        { name = "Beast Mastery", icon = "Interface\\Icons\\Ability_Hunter_BeastTaming" },
        { name = "Marksmanship", icon = "Interface\\Icons\\Ability_Marksmanship" },
        { name = "Survival", icon = "Interface\\Icons\\Ability_Hunter_SwiftStrike" }
    },
    ["WARLOCK"] = {
        { name = "Affliction", icon = "Interface\\Icons\\Spell_Shadow_DeathCoil" },
        { name = "Demonology", icon = "Interface\\Icons\\Spell_Shadow_Metamorphosis" },
        { name = "Destruction", icon = "Interface\\Icons\\Spell_Shadow_RainOfFire" }
    },
    ["PALADIN"] = {
        { name = "Holy", icon = "Interface\\Icons\\Spell_Holy_HolyBolt" },
        { name = "Protection", icon = "Interface\\Icons\\Spell_Holy_DevotionAura" },
        { name = "Retribution", icon = "Interface\\Icons\\Spell_Holy_AuraOfLight" }
    },
    ["DRUID"] = {
        { name = "Balance", icon = "Interface\\Icons\\Spell_Nature_StarFall" },
        { name = "Feral", icon = "Interface\\Icons\\Ability_Druid_CatForm" },
        { name = "Restoration", icon = "Interface\\Icons\\Spell_Nature_HealingTouch" }
    },
    ["SHAMAN"] = {
        { name = "Elemental", icon = "Interface\\Icons\\Spell_Nature_Lightning" },
        { name = "Enhancement", icon = "Interface\\Icons\\Spell_Nature_LightningShield" },
        { name = "Restoration", icon = "Interface\\Icons\\Spell_Nature_MagicSensility" }
    }
}

-- Helper: Wraps text in official Blizzard Class Colours based on class token
function AlternateWorldConfig.GetClassColoredText(text, classToken)
    if classToken and RAID_CLASS_COLORS[classToken] then
        local color = RAID_CLASS_COLORS[classToken]
        return string.format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, text)
    end
    return text
end

-- Helper: Generates the inline string for the Class Icon
function AlternateWorldConfig.GetInlineClassIcon(classToken)
    if not classToken then return "" end
    local texturePath = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
    local coords = CLASS_ICON_TCOORDS[classToken]
    
    -- FIXED: Unpack the four indexes from the coordinates array safely before calculating pixel ratios
    if coords and coords[1] and coords[2] and coords[3] and coords[4] then
        local left, right, top, bottom = coords[1] * 256, coords[2] * 256, coords[3] * 256, coords[4] * 256
        return "|T" .. texturePath .. ":14:14:0:0:256:256:" .. left .. ":" .. right .. ":" .. top .. ":" .. bottom .. "|t "
    end
    return ""
end
