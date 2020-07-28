local EP = "EP"
local GP = "GP"
local EMPTY = ""

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

local OVERRIDE = {
  --WORLD DROP OVERRIDES
  [18704] = 34, --Mature Blue Dragon Sinew
  [18665] = 136, --The Eye Of Shadow
  [20644] = 29, --Nightmare Engulfed Object
  --MOLTEN CORE OVERRIDES
  [18564] = 356, --Bindings of the Windseeker
  [18563] = 356, --Bindings of the Windseeker
  [18703] = 187, --Ancient Petrified Leaf
  [18646] = 136, --The Eye of Divinity
  [17204] = 712, --Eye of Sulfuras
  --ONYXIA'S LAIR OVERRIDES
  [18422] = 32, --Head of Onyxia TODO FREE P5
  [18423] = 32, --Head of Onyxia TODO FREE P5
  [18705] = 187, --Mature Black Dragon Sinew
  --BLACKWING LAIR OVERRIDES
  [19002] = 53, --Head of Nefarian TODO FREE P6
  [19003] = 53, --Head of Nefarian TODO FREE P6
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
  --RUINS OF AHN'QIRAH OVERRIDES
  [20890] = 52, --Qiraji Ornate Hilt
  [20886] = 52, --Qiraji Spiked Hilt
  [20889] = 22, --Qiraji Regal Drape
  [20885] = 22, --Qiraji Martial Drape
  [20888] = 20, --Qiraji Ceremonial Ring
  [20884] = 20, --Qiraji Magisterial Ring
  [21220] = 26, --Head Of Ossirian The Unscarred
  [21294] = 20, --Book Of Healing Touch Xi
  [21296] = 20, --Book Of Rejuvenation Xi
  [21295] = 20, --Book Of Starfire Vii
  [21307] = 20, --Guide Aspect Of The Hawk Vii
  [21304] = 20, --Guide Multi Shot V
  [21306] = 20, --Guide Serpent Sting Ix
  [21280] = 20, --Tome Of Arcane Missiles Viii
  [21279] = 20, --Tome Of Fireball Xii
  [21214] = 20, --Tome Of Frostbolt Xi
  [21289] = 20, --Libram Blessing Of Might Vii
  [21288] = 20, --Libram Blessing Of Wisdom Vi
  [21290] = 20, --Libram Holy Light Ix
  [21284] = 20, --Codex Of Greater Heal V
  [21287] = 20, --Codex Of Prayer Of Healing V
  [21285] = 20, --Codex Of Renew X
  [21300] = 20, --Handbook Of Backstab Ix
  [21302] = 20, --Handbook Of Deadly Poison V
  [21303] = 20, --Handbook Of Feint V
  [21293] = 20, --Tablet Of Grace Of Air Totem Iii
  [21291] = 20, --Tablet Of Healing Wave X
  [21292] = 20, --Tablet Of Strength Of Earth Totem V
  [21283] = 20, --Grimoire Of Corruption Vii
  [21282] = 20, --Grimoire Of Immolate Viii
  [21281] = 20, --Grimoire Of Shadow Bolt X
  [21298] = 20, --Manual Of Battle Shout Vii
  [21297] = 20, --Manual Of Heroic Strike Ix
  [21299] = 20, --Manual Of Revenge Vi
  --TEMPLE OF AHN'QIRAH OVERRIDES
  [21221] = 68, --Eye Of Cthun
  [21232] = 84, --Imperial Qiraji Armaments
  [21237] = 168, --Imperial Qiraji Regalia
  [20926] = 93, --Veknilashs Circlet
  [20927] = 93, --Ouros Intact Hide
  [20928] = 60, --Qiraji Bindings Of Command
  [20929] = 136, --Carapace Of The Old God
  [20930] = 93, --Veklors Diadem
  [20931] = 93, --Skin Of The Great Sandworm
  [20932] = 60, --Qiraji Bindings Of Dominance
  [20933] = 136 --Husk Of The Old God

  --TODO NAXXRAMAS OVERRIDES
}

-- ############################################################
-- ##### LOCAL FUNCTIONS ######################################
-- ############################################################

local function notifyEPGP(name, value, reason, type)
  if (name and value) then
    local message = ""
    if (value >= 0) then
      message = message .. "Adding "
    else
      message = message .. "Removing "
    end
    if (type == EP) then
      message = message .. value .. "EP to " .. name
    elseif (type == GP) then
      message = message .. value .. "GP to " .. name
    end
    if (reason) then
      message = message .. " for " .. reason
    end
    SendChatMessage(message, "OFFICER")
  end
end

-- ############################################################
-- ##### GLOBAL FUNCTIONS #####################################
-- ############################################################

QUICKEPGP.getEPGPPRMessage = function(name)
  local formattedName = (name or UnitName("player"))
  local member = QUICKEPGP.guildMember(formattedName, true)
  if (member) then
    local ep = QUICKEPGP.guildMemberEP(formattedName, true)
    local gp = QUICKEPGP.guildMemberGP(formattedName, true)
    local pr = QUICKEPGP.guildMemberPR(formattedName, true)
    if (ep and gp and pr) then
      if (UnitIsUnit("player", formattedName)) then
        return format("You have %s PR; (%s EP / %s GP)", pr, ep, gp)
      else
        return format("%s has %s PR; (%s EP / %s GP)", formattedName, pr, ep, gp)
      end
    end
  end
end

QUICKEPGP.calculateChange = function(name, value, type)
  value = (value or 0)
  if (QUICKEPGP.guildMember(name)) then
    if (type == EP) then --TODO DOES NOT ALWAYS PRODUCE NON-NIL
      return max((QUICKEPGP.guildMemberEP(name) or QUICKEPGP.MINIMUM_EP) + value, QUICKEPGP.MINIMUM_EP)
    elseif (type == GP) then
      return max((QUICKEPGP.guildMemberGP(name) or QUICKEPGP.MINIMUM_GP) + value, QUICKEPGP.MINIMUM_GP)
    end
  else
    QUICKEPGP.error("Skipping " .. (name or EMPTY) .. "'s EPGP change: not in guild")
  end
end

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

QUICKEPGP.getItemGP = function(itemId, silent)
  if (itemId) then
    itemId = tonumber(itemId)
    if (OVERRIDE[itemId]) then
      return OVERRIDE[itemId]
    end
    local _, _, itemRarity, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemId)
    if itemRarity and itemLevel then
      local slot = nil
      if (itemEquipLoc == nil or itemEquipLoc == "") then
        slot = "EXCEPTION"
        if not silent then
          QUICKEPGP.error(format("QUICKEPGP::Item %s has no itemEquipLoc (%s)", itemId, itemEquipLoc))
        end
      else
        slot = strsub(itemEquipLoc, strfind(itemEquipLoc, "INVTYPE_") + 8, string.len(itemEquipLoc))
      end
      local slotWeight = SLOTWEIGHTS[slot]
      if (slotWeight) then
        return math.floor((INFLATION_MOD * (EXPONENTIAL_MOD ^ ((itemLevel / 26) + (itemRarity - 4))) * slotWeight) * NORMALIZER_MOD)
      elseif not silent then
        QUICKEPGP.error(format("QUICKEPGP::Item %s has no valid slot weight (%s)", itemId, slot))
      end
    elseif not silent then
      QUICKEPGP.error("QUICKEPGP::Invalid itemId, returning 0")
    end
  end
  return 0
end

QUICKEPGP.modifyEPGP = function(name, dep, dgp, reason, mass)
  if (QUICKEPGP.guildMember(name)) then
    if (not mass) then
      notifyEPGP(name, dep, reason, EP)
      notifyEPGP(name, dgp, reason, GP)
    end
    QUICKEPGP.SafeSetOfficerNote(name, dep, dgp)
  end
end
