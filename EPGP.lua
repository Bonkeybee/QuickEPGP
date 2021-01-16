local EP = "EP"
local GP = "GP"
local EMPTY = ""
local addFormat = "Adding %d%s to %s (%s)"
local removeFormat = "Removing %d%s from %s (%s)"

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
  [18422] = 0, --Head of Onyxia
  [18423] = 0, --Head of Onyxia
  [18705] = 187, --Mature Black Dragon Sinew
  --BLACKWING LAIR OVERRIDES
  [19002] = 0, --Head of Nefarian
  [19003] = 0, --Head of Nefarian
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
  [21321] = 0, --Red Qiraji Resonating Crystal
  [21218] = 0, --Blue Qiraji Resonating Crystal
  [21323] = 0, --Green Qiraji Resonating Crystal
  [21324] = 0, --Yellow Qiraji Resonating Crystal
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
  [20933] = 136, --Husk Of The Old God
  --NAXXRAMAS OVERRIDES
  [23042] = 0, --Loathebs Reflection
  [23033] = 0, --Icy Scale Coif
  [23032] = 0, --Glacial Headdress
  [23028] = 0, --Hailstone Band
  [23020] = 0, --Polar Helmet
  [23019] = 0, --Icebane Helmet
  [22968] = 0, --Glacial Mantle
  [22967] = 0, --Icy Scale Spaulders
  [22941] = 0, --Polar Shoulder Pads
  [22940] = 0, --Icebane Pauldrons
  [22935] = 0, --Touch Of Frost
  [22520] = 113, --The Phylactery Of Kelthuzad
  [22372] = 91, --Desecrated Sandals
  [22371] = 102, --Desecrated Gloves
  [22370] = 102, --Desecrated Belt
  [22369] = 68, --Desecrated Bindings
  [22368] = 91, --Desecrated Shoulderpads
  [22367] = 136, --Desecrated Circlet
  [22366] = 136, --Desecrated Leggings
  [22365] = 91, --Desecrated Boots
  [22364] = 102, --Desecrated Handguards
  [22363] = 102, --Desecrated Girdle
  [22362] = 68, --Desecrated Wristguards
  [22361] = 91, --Desecrated Spaulders
  [22360] = 136, --Desecrated Headpiece
  [22359] = 136, --Desecrated Legguards
  [22358] = 91, --Desecrated Sabatons
  [22357] = 102, --Desecrated Gauntlets
  [22356] = 102, --Desecrated Waistguard
  [22355] = 68, --Desecrated Bracers
  [22354] = 91, --Desecrated Pauldrons
  [22353] = 136, --Desecrated Helmet
  [22352] = 136, --Desecrated Legplates
  [22349] = 168, --Desecrated Breastplate
  [22351] = 168, --Desecrated Robe
  [22350] = 168, --Desecrated Tunic
  [22726] = 1213 --Splinter Of Atiesh
}

local IGNORE = {
  [6265] = true
}

-- ############################################################
-- ##### LOCAL FUNCTIONS ######################################
-- ############################################################

local function notifyEPGP(name, value, type, reason)
  if (name and value) then
    local f = value >= 0 and addFormat or removeFormat
    local r = (reason and reason:len() > 0) and reason or "no reason specified"
    SendChatMessage(string.format(f, math.abs(value), type, name, r), "OFFICER")
  end
end

-- ############################################################
-- ##### GLOBAL FUNCTIONS #####################################
-- ############################################################

QUICKEPGP.decay = function()
  QUICKEPGP_PRE_DECAY = {}
  QUICKEPGP_POST_DECAY = {}

  QUICKEPGP.GUILD:RefreshAll()
  for name, data in pairs(QUICKEPGP.GUILD.Members) do
    if (name) then
      QUICKEPGP_PRE_DECAY[name] = (data.EP or QUICKEPGP.MINIMUM_EP) .. "," .. (data.GP or QUICKEPGP.MINIMUM_GP)

      local ep = math.floor((data.EP or QUICKEPGP.MINIMUM_EP) * 0.8)
      local gp = math.floor(max((data.GP or QUICKEPGP.MINIMUM_GP) * 0.8, QUICKEPGP.MINIMUM_GP))

      local dep = ep - data.EP
      local dgp = gp - data.GP

      QUICKEPGP.SafeSetOfficerNote(name, dep, dgp)
      QUICKEPGP_POST_DECAY[name] = ep .. "," .. gp
    end
  end
  SendChatMessage("EPGP decayed by 20%", "OFFICER")
end

QUICKEPGP.getEPGPPRMessage = function(name)
  local member = QUICKEPGP.GUILD:GetMemberInfo(name or UnitName("player"), true)
  if (member) then
    return ((not name or UnitIsUnit("player", name)) and "You have " or (name .. " has ")) .. member:GetEpGpPrMessage()
  end
end

QUICKEPGP.calculateChange = function(name, value, type)
  local member = QUICKEPGP.GUILD:GetMemberInfo(name)
  if member then
    if type == EP then
      return max(member.EP + (value or 0), QUICKEPGP.MINIMUM_EP)
    elseif type == GP then
      return max(member.GP + (value or 0), QUICKEPGP.MINIMUM_GP)
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

QUICKEPGP.compareRoll = function(epRollTable)
  local highestEP1 = {}
  highestEP1.name = nil
  highestEP1.ep = 0
  highestEP1.roll = nil
  for name, data in pairs(epRollTable) do
    if (name) then
      if (data[3] > highestEP1.ep) then
        highestEP1.roll = data[4]
        highestEP1.ep = data[3]
        highestEP1.name = name
      end
    end
  end

  local highestEP2 = {}
  highestEP2.name = nil
  highestEP2.ep = 0
  highestEP2.roll = nil
  for name, data in pairs(epRollTable) do
    if (name and name ~= highestEP1.name) then
      if (data[3] > highestEP2.ep) then
        highestEP2.roll = data[4]
        highestEP2.ep = data[3]
        highestEP2.name = name
      end
    end
  end

  if (not highestEP2.name) then
    return highestEP1.name
  end
  if (highestEP1.roll > highestEP2.roll) then
    return highestEP1.name
  else
    return highestEP2.name
  end
end

function QUICKEPGP.CalculateItemGP(itemId, itemRarity, itemLevel, itemEquipLoc, silent)
  if (IGNORE[itemId]) then
    return 0
  end
  if (OVERRIDE[itemId]) then
    return OVERRIDE[itemId]
  end
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
      return math.floor(
        (INFLATION_MOD * (EXPONENTIAL_MOD ^ ((itemLevel / 26) + (itemRarity - 4))) * slotWeight) * NORMALIZER_MOD
      )
    elseif not silent then
      QUICKEPGP.error(format("QUICKEPGP::Item %s has no valid slot weight (%s)", itemId, slot))
    end
  elseif not silent then
    QUICKEPGP.error("QUICKEPGP::Invalid itemId, returning 0")
  end
  return 0
end

QUICKEPGP.getItemGP = function(itemId, silent)
  itemId = tonumber(itemId)
  if (itemId) then
    local _, _, itemRarity, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemId)
    return QUICKEPGP.CalculateItemGP(itemId, itemRarity, itemLevel, itemEquipLoc, silent)
  end
  return 0
end

QUICKEPGP.modifyEPGP = function(name, dep, dgp, reason, mass)
  local member = QUICKEPGP.GUILD:GetMemberInfo(name)
  if (member) then
    if (not mass) then
      notifyEPGP(member.Name, dep, EP, reason)
      notifyEPGP(member.Name, dgp, GP, reason)
    end
    QUICKEPGP.SafeSetOfficerNote(member.Name, dep, dgp)
  end
end
