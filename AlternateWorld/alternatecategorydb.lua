-- ============================================================================
-- Alternate World - Global Loot Category Database Engine (v0.3.0 - SUBTYPE SIKRET)
-- ============================================================================
AlternateWorldCategoryDB = {}

local TAILORING_IDS = { [2589]=true,[2996]=true,[2592]=true,[2997]=true,[4306]=true,[4305]=true,[4338]=true,[4339]=true,[14047]=true,[14048]=true,[14256]=true,[14342]=true }
local MINING_IDS = { [2770]=true,[2840]=true,[2771]=true,[2841]=true,[2842]=true,[2772]=true,[2845]=true,[3575]=true,[3470]=true,[2847]=true,[3858]=true,[3860]=true,[7911]=true,[6037]=true,[4475]=true,[3577]=true,[10620]=true,[12359]=true,[11370]=true,[11371]=true,[12360]=true,[18562]=true,[18567]=true }
local GEMS_IDS = { [2775]=true,[2835]=true,[2836]=true,[2838]=true,[818]=true,[1206]=true,[1210]=true,[1705]=true,[3864]=true,[5504]=true,[5565]=true,[7909]=true,[7910]=true,[12361]=true,[12363]=true,[12364]=true,[12799]=true,[12354]=true,[12365]=true }
local ENCHANTING_IDS = { [10940]=true,[11083]=true,[11128]=true,[11137]=true,[11174]=true,[11175]=true,[14343]=true,[14344]=true,[20725]=true,[10938]=true,[10939]=true,[10998]=true,[11082]=true,[11134]=true,[11135]=true,[11176]=true,[11177]=true,[16202]=true,[16203]=true,[10978]=true,[11124]=true,[11139]=true,[11178]=true,[14341]=true,[6218]=true,[6338]=true,[11130]=true,[11145]=true,[16206]=true }
local HERBALISM_IDS = { [2449]=true,[765]=true,[785]=true,[2447]=true,[2450]=true,[2452]=true,[2453]=true,[3355]=true,[3356]=true,[3357]=true,[3358]=true,[3818]=true,[3820]=true,[3821]=true,[4625]=true,[8831]=true,[8836]=true,[8838]=true,[8839]=true,[8845]=true,[8846]=true,[13463]=true,[13464]=true,[13465]=true,[13466]=true,[13467]=true,[13468]=true,[19726]=true }
local SKINNING_IDS = { [2318]=true,[2319]=true,[4234]=true,[4304]=true,[8171]=true,[2320]=true,[2321]=true,[4235]=true,[8169]=true,[8172]=true,[15407]=true,[15409]=true,[8170]=true }
local MISCMATS_IDS = { [7067]=true,[7068]=true,[7070]=true,[7069]=true,[12803]=true,[12808]=true,[12809]=true,[12810]=true,[12811]=true,[7080]=true,[10286]=true,[12805]=true,[5500]=true,[7971]=true,[18335]=true,[14515]=true,[12804]=true,[10631]=true,[10630]=true,[7076]=true,[7078]=true,[18512]=true,[7077]=true,[7079]=true,[7081]=true,[7082]=true }
local LOCKBOX_IDS = { [4632]=true,[4633]=true,[4634]=true,[4636]=true,[4638]=true,[5757]=true,[5758]=true,[5759]=true,[16885]=true,[16886]=true,[4637]=true,[5760]=true }
local CONSUMABLES_IDS = { [12662]=true,[20520]=true,[12451]=true,[12450]=true,[12455]=true,[12457]=true,[14530]=true,[8545]=true,[5755]=true,[3386]=true,[13456]=true,[6051]=true,[20748]=true,[20749]=true,[20007]=true,[18465]=true,[21217]=true,[13931]=true,[13454]=true,[9155]=true,[13444]=true,[13443]=true,[9030]=true,[13935]=true,[12218]=true,[21023]=true,[13928]=true,[18254]=true,[13927]=true,[21153]=true,[21114]=true,[21151]=true,[6052]=true,[13459]=true,[13457]=true,[13446]=true,[20744]=true,[184937]=true }
local QUESTITEMS_IDS = { [3016]=true,[3017]=true,[3018]=true,[3019]=true,[3020]=true,[3021]=true,[3022]=true,[3023]=true,[3024]=true,[3025]=true,[3026]=true,[3027]=true,[3028]=true,[3029]=true,[3030]=true,[4098]=true,[5647]=true,[11018]=true,[11041]=true,[11750]=true,[5648]=true,[5649]=true,[5650]=true,[5651]=true,[5652]=true,[5653]=true,[5654]=true,[5655]=true,[5656]=true,[5657]=true,[5658]=true,[9223]=true,[2725]=true,[2726]=true,[2727]=true,[2728]=true,[2729]=true,[2739]=true,[2740]=true,[2741]=true,[2742]=true,[2743]=true,[2744]=true,[2748]=true,[2749]=true,[2750]=true,[2751]=true,[11040]=true,[9259]=true,[11078]=true,[11184]=true,[11185]=true,[11186]=true,[11188]=true,[2735]=true,[2736]=true,[2737]=true,[2738]=true,[19278]=true,[19231]=true,[19227]=true,[19230]=true,[19232]=true,[19233]=true,[19234]=true,[19235]=true,[19236]=true,[19258]=true,[19276]=true,[19277]=true,[19279]=true,[19280]=true,[19281]=true,[19282]=true,[19237]=true,[19240]=true,[19241]=true,[19242]=true,[19243]=true,[19244]=true,[19245]=true,[19246]=true,[19247]=true,[19254]=true,[19255]=true,[19256]=true,[19257]=true,[19264]=true,[19266]=true,[19267]=true,[19273]=true,[19260]=true,[11732]=true,[11733]=true,[11734]=true,[11736]=true,[11737]=true,[18332]=true }
local REPUTATION_IDS = { [19698]=true,[19699]=true,[19700]=true,[19701]=true,[19702]=true,[19703]=true,[19704]=true,[19705]=true,[19706]=true,[19707]=true,[19708]=true,[19709]=true,[19710]=true,[19711]=true,[19712]=true,[19713]=true,[19714]=true,[19715]=true,[20858]=true,[20859]=true,[20860]=true,[20861]=true,[20862]=true,[20863]=true,[20864]=true,[20865]=true,[20866]=true,[20867]=true,[20868]=true,[20869]=true,[20870]=true,[20871]=true,[20872]=true,[20873]=true,[22714]=true,[22715]=true,[22716]=true,[22717]=true,[22718]=true,[22719]=true,[22720]=true,[22721]=true,[22722]=true,[12840]=true,[18944]=true,[18945]=true,[22525]=true,[22526]=true,[22527]=true,[22528]=true,[22529]=true }

function AlternateWorldCategoryDB.GetItemCategory(itemID, itemType, itemSubtype)
    if not itemID then return nil end
    local idNum = tonumber(itemID)

    -- STEP 1: PRIORITY SCANNER - Inspects proper 4-argument Era GetItemInfoInstant structure
    local _, typeStr, subTypeStr = GetItemInfoInstant(idNum)
    if typeStr then
        local lowerType = string.lower(typeStr)
        local lowerSub = subTypeStr and string.lower(subTypeStr) or ""
        
        if lowerType == "recipe" then return "Recipes" end
       
        -- STEP 2: SUBTYPE PROTECTION - If it has a hard armor/weapon material slot subtype, FORCE to Gear immediately!
        if lowerType == "weapon" or lowerType == "armor" then
            if lowerSub == "cloth" or lowerSub == "leather" or lowerSub == "mail" or lowerSub == "plate" or lowerSub == "shields" or lowerSub == "staves" or lowerSub == "one-handed swords" or lowerSub == "two-handed swords" or lowerSub == "daggers" or lowerSub == "maces" or lowerSub == "axes" or lowerSub == "bows" or lowerSub == "guns" or lowerSub == "crossbows" or lowerSub == "wands" or lowerSub == "fist weapons" or lowerSub == "polearms" then
                return "Gear"
            end
            
            -- Fallback for vanity/misc armor items that are still linked to quests/reputation
            if QUESTITEMS_IDS[idNum] then return "QuestItems" end
            if REPUTATION_IDS[idNum] then return "Reputation" end
            return "Gear"
        end
    end

    -- STEP 3: CORE ID MATCH Sweeps
    if TAILORING_IDS[idNum] then return "Tailoring" end
    if MINING_IDS[idNum] then return "Mining" end
    if GEMS_IDS[idNum] then return "Gems" end
    if ENCHANTING_IDS[idNum] then return "Enchanting" end
    if HERBALISM_IDS[idNum] then return "Herbalism" end
    if SKINNING_IDS[idNum] then return "Skinning" end
    if MISCMATS_IDS[idNum] then return "MiscMats" end
    if LOCKBOX_IDS[idNum] then return "Lockboxes" end
    if CONSUMABLES_IDS[idNum] then return "Consumables" end
    if QUESTITEMS_IDS[idNum] then return "QuestItems" end
    if REPUTATION_IDS[idNum] then return "Reputation" end
    
    -- Legacy ranges for backup safety
    if (idNum >= 2287 and idNum <= 2303) or (idNum >= 5411 and idNum <= 6473) or (idNum >= 12581 and idNum <= 22312) then
        return "Recipes"
    end
    
    return nil
end

-- End of [alternatecategorydb.lua]
