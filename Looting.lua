QUICKEPGP.LOOTING = CreateFrame("Frame")
local MODULE_NAME = "QuickEPGP-Looting"

local FREE_FOR_ALL = "freeforall"
local ROUND_ROBIN = "roundrobin"
local MASTER_LOOT = "master"
local GROUP_LOOT = "group"
local NEED_BEFORE_GREED = "needbeforegreed"
local EQUIPPABLE = "EQUIPPABLE"


-- ############################################################
-- ##### LOCAL FUNCTIONS ######################################
-- ############################################################

local function safeGiveMasterLoot(slot, playerIndex)
  local _, instanceType = GetInstanceInfo()
  if (not QUICKEPGP_OPTIONS.LOOTING.safe) then
    GiveMasterLoot(slot, playerIndex)
  elseif (instanceType == "raid") then
    GiveMasterLoot(slot, playerIndex)
  end
end

local function safeConfirmLootSlot(slot)
  local _, instanceType = GetInstanceInfo()
  if (not QUICKEPGP_OPTIONS.LOOTING.safe) then
    ConfirmLootSlot(slot)
  elseif (instanceType == "raid") then
    ConfirmLootSlot(slot)
  end
end

local function safeLootSlot(slot)
  local _, instanceType = GetInstanceInfo()
  if (not QUICKEPGP_OPTIONS.LOOTING.safe) then
    LootSlot(slot)
  elseif (instanceType == "raid") then
    LootSlot(slot)
  end
end

local function masterLootee(slot, type)
  local _, instanceType = GetInstanceInfo()
  local masterlooterIndex = nil
  for i = 1, 40 do
    local name = GetMasterLootCandidate(slot, i)
    if (name) then
      if (QUICKEPGP.isOnlineRaid(name)) then --TODO doesnt work for parties
        if (type == EQUIPPABLE) then
          if (QUICKEPGP_OPTIONS.LOOTING.equiplootee == 1 and QUICKEPGP.isMasterLooter(name)) then
            safeGiveMasterLoot(slot, i)
            return
          end
          if (QUICKEPGP_OPTIONS.LOOTING.equiplootee == 2 and QUICKEPGP.isMainAssist(name)) then
            safeGiveMasterLoot(slot, i)
            return
          end
        else
          if (QUICKEPGP_OPTIONS.LOOTING.otherlootee == 1 and QUICKEPGP.isMasterLooter(name)) then
            safeGiveMasterLoot(slot, i)
            return
          end
          if (QUICKEPGP_OPTIONS.LOOTING.otherlootee == 2 and QUICKEPGP.isMainAssist(name)) then
            safeGiveMasterLoot(slot, i)
            return
          end
        end

        if (QUICKEPGP.isMasterLooter(name)) then
          masterlooterIndex = i
        end
      end
    end
  end
  GiveMasterLoot(slot, masterlooterIndex)
  --TODO print error
end

local function freeForAll(i)
  if (GetLootMethod() == FREE_FOR_ALL) then
    safeLootSlot(i)
    safeConfirmLootSlot(i)
  end
end

local function roundRobin(i)
  if (GetLootMethod() == ROUND_ROBIN) then
    safeLootSlot(i)
    safeConfirmLootSlot(i)
  end
end

local function masterLoot(i)
  if (GetLootMethod() == MASTER_LOOT) then
    if (QUICKEPGP.isMasterLooter()) then
      local _, _, _, _, rarity, locked, isQuest, _, isActive = GetLootSlotInfo(i)
      if (not isQuest and not isActive) then
        if (rarity and rarity > 1) then
          local itemLink = GetLootSlotLink(i)
          if (itemLink) then
            if (IsEquippableItem(itemLink) and rarity >= QUICKEPGP_OPTIONS.LOOTING.equiprarity) then
              print(1)
              masterLootee(i, EQUIPPABLE)
            elseif (rarity >= QUICKEPGP_OPTIONS.LOOTING.otherrarity) then
              print(2)
              masterLootee(i)
            end
          else
            safeLootSlot(i)
          end
        else
          safeLootSlot(i)
        end
      end
    end
  end
end

local function groupLoot(i)
  if (GetLootMethod() == GROUP_LOOT) then
    safeLootSlot(i)
    --(roll frame)
  end
end

local function needBeforeGreed(i)
  if (GetLootMethod() == NEED_BEFORE_GREED) then
    safeLootSlot(i)
    --(roll frame)
  end
end

local function onEvent(_, event)
  if (QUICKEPGP_OPTIONS.LOOTING.enabled and event == "LOOT_OPENED") then
    for i = 1, GetNumLootItems() do
      freeForAll(i)
      roundRobin(i)
      masterLoot(i)
      groupLoot(i)
      needBeforeGreed(i)
    end
  end
end

-- ############################################################
-- ##### GLOBAL FUNCTIONS #####################################
-- ############################################################

QUICKEPGP.LOOTING:RegisterEvent("LOOT_OPENED")
QUICKEPGP.LOOTING:SetScript("OnEvent", onEvent)
