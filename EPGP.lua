local EP = "EP"
local GP = "GP"
local DELIMITER = ","

local MINIMUM_EP = 0
local MINIMUM_GP = 50
local INFLATION_MOD = 10
local EXPONENTIAL_MOD = 4
local NORMALIZER_MOD = 0.125
local SLOTWEIGHTS = {
  ["2HWEAPON"] = 2,
  ["WEAPONMAINHAND"] = 1,
  ["WEAPON"] = 1,
  ["WEAPONOFFHAND"] = 1,
  ["HOLDABLE"] = 1,
  ["SHIELD"] = 1,
  ["WAND"] = 0.5,
  ["RANGED"] = 0.75,
  ["RANGEDRIGHT"] = 0.75,
  ["THROWN"] = 0.75,
  ["RELIC"] = 0.75,
  ["HEAD"] = 1,
  ["NECK"] = 0.5,
  ["SHOULDER"] = 0.75,
  ["CLOAK"] = 0.5,
  ["CHEST"] = 1,
  ["ROBE"] = 1,
  ["WRIST"] = 0.5,
  ["HAND"] = 0.75,
  ["WAIST"] = 0.75,
  ["LEGS"] = 1,
  ["FEET"] = 0.75,
  ["FINGER"] = 0.5,
  ["TRINKET"] = 0.75,
  ["QUEST"] = 0,
  ["EXCEPTION"] = 1
}

--TODO AQ items
--TODO NAXX items
local OVERRIDE = {
  --MOLTEN CORE OVERRIDES
  [18564] = 356, --Bindings of the Windseeker
  [18563] = 356, --Bindings of the Windseeker
  [18703] = 187, --Ancient Petrified Leaf
  [18646] = 136, --The Eye of Divinity
  [17204] = 712, --Eye of Sulfuras

  --ONYXIA'S LAIR OVERRIDES
  [18422] = 32, --Head of Onyxia
  [18423] = 32, --Head of Onyxia
  [18705] = 187, --Mature Black Dragon Sinew

  --BLACKWING LAIR OVERRIDES
  [19002] = 53, --Head of Nefarian
  [19003] = 53, --Head of Nefarian

  --ZUL'GURUB OVERRIDES
  [19717] = 16, --Primal Hakkari Armsplint
  [19716] = 16, --Primal Hakkari Bindings
  [19718] = 16, --Primal Hakkari Stanchion
  [19719] = 24, --Primal Hakkari Girdle
  [19720] = 24, --Primal Hakkari Sash
  [19724] = 40, --Primal Hakkari Aegis
  [19723] = 40, --Primal Hakkari Kossack
  [19722] = 40, --Primal Hakkari Tabard
  [19721] = 35, --Primal Hakkari Shawl
  [19802] = 35, --Heart of Hakkar

  --TODO AQ20 OVERRIDES

  --TODO AQ40 OVERRIDES

  --TODO NAXXRAMAS OVERRIDES

}

-- ############################################################
-- ##### LOCAL FUNCTIONS ######################################
-- ############################################################

local function notifyEPGP(name, value, reason, type)
  if (name and value) then
    local message = ""
    if (value >= 0) then
      message = message.."Adding "
    else
      message = message.."Removing "
    end
    if (type == EP) then
      message = message..value.."EP to "..name
    elseif (type == GP) then
      message = message..value.."GP to "..name
    end
    if (reason) then
      message = message.." for "..reason
    end
    SendChatMessage(message, "OFFICER")
  end
end

local function calculateChange(name, value, type)
  if (type == EP) then
    return (QUICKEPGP.guildMemberEP(name) + (value or 0)) or MINIMUM_EP
  elseif (type == GP) then
    return (QUICKEPGP.guildMemberGP(name) + (value or 0)) or MINIMUM_GP
  end
end

-- ############################################################
-- ##### GLOBAL FUNCTIONS #####################################
-- ############################################################

QUICKEPGP.comparePR = function(name1, name2, rollTable)
  if (not name1) then
    return name2
  end
  if (not name2) then
    return name1
  end
  if (rollTable[name1][1] > rollTable[name2][1]) then
    return name1
  end
  if (rollTable[name2][1] > rollTable[name1][1]) then
    return name2
  end
  if ((rollTable[name1][3] / rollTable[name1][4]) >= (rollTable[name2][3] / rollTable[name2][4])) then
    return name1
  else
    return name2
  end
end

QUICKEPGP.getItemGP = function(itemId)
  local itemId = tonumber(itemId)
  if (OVERRIDE[itemId]) then
    return OVERRIDE[itemId]
  end
  local _, _, itemRarity, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemId)
  local slot = nil
  if (itemEquipLoc == nil or itemEquipLoc == "") then
    slot = "EXCEPTION"
    QUICKEPGP.error(format("QUICKEPGP::Item %s has no itemEquipLoc (%s)", itemId, itemEquipLoc))
  else
    slot = strsub(itemEquipLoc, strfind(itemEquipLoc, "INVTYPE_") + 8, string.len(itemEquipLoc))
  end
  local slotWeight = SLOTWEIGHTS[slot]
  if (slotWeight) then
    return math.floor((INFLATION_MOD * (EXPONENTIAL_MOD^((itemLevel / 26) + (itemRarity - 4))) * slotWeight) * NORMALIZER_MOD)
  else
    QUICKEPGP.error(format("QUICKEPGP::Item %s has no valid slot weight (%s)", itemId, slot))
  end
end

QUICKEPGP.modifyEPGP = function(name, ep, gp, reason)
  notifyEPGP(name, ep, reason, EP)
  notifyEPGP(name, ep, reason, GP)
  GuildRosterSetOfficerNote(QUICKEPGP.guildMemberIndex(name), calculateChange(name, ep, EP)..DELIMITER..calculateChange(name, gp, GP))
end
