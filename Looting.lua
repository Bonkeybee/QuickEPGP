QUICKEPGP.LOOTING = CreateFrame("Frame")
local MODULE_NAME = "QuickEPGP-Looting"

local TICK_RATE = 0.01

local EMPTY = ""
local INSTANCE_TYPE = "raid"
local FREE_FOR_ALL = "freeforall"
local ROUND_ROBIN = "roundrobin"
local MASTER_LOOT = "master"
local GROUP_LOOT = "group"
local NEED_BEFORE_GREED = "needbeforegreed"
local EQUIPPABLE = "EQUIPPABLE"
local MAX_PARTY_SIZE = 40
local MAX_NUM_LOOT = 12

local looting = false

-- ############################################################
-- ##### LOCAL FUNCTIONS ######################################
-- ############################################################

local function safeGiveMasterLoot(slot, playerIndex)
  local _, instanceType = GetInstanceInfo()
  if (not QUICKEPGP_OPTIONS.LOOTING.safe) then
    GiveMasterLoot(slot, playerIndex)
  elseif (instanceType == INSTANCE_TYPE) then
    GiveMasterLoot(slot, playerIndex)
  end
end

local function safeConfirmLootSlot(slot)
  local _, instanceType = GetInstanceInfo()
  if (not QUICKEPGP_OPTIONS.LOOTING.safe) then
    ConfirmLootSlot(slot)
  elseif (instanceType == INSTANCE_TYPE) then
    ConfirmLootSlot(slot)
  end
end

local function safeLootSlot(slot)
  local _, instanceType = GetInstanceInfo()
  if (not QUICKEPGP_OPTIONS.LOOTING.safe) then
    LootSlot(slot)
  elseif (instanceType == INSTANCE_TYPE) then
    LootSlot(slot)
  end
end

local function masterLootee(slot, type)
  local _, instanceType = GetInstanceInfo()
  local masterlooterIndex = nil
  for i = 1, MAX_PARTY_SIZE do
    local name = GetMasterLootCandidate(slot, i)
    if (name) then
      if (QUICKEPGP.isOnlineRaid(name)) then
        if (type == EQUIPPABLE) then
          if (QUICKEPGP_OPTIONS.LOOTING.equiplootee == 1 and QUICKEPGP.isMasterLooter(name)) then
            safeGiveMasterLoot(slot, i)
            return
          end
          if (QUICKEPGP_OPTIONS.LOOTING.equiplootee == 2 and QUICKEPGP.isMainAssist(name)) then
            safeGiveMasterLoot(slot, i)
            return
          end
          if (QUICKEPGP_OPTIONS.LOOTING.equiplootee == 3 and (QUICKEPGP_OPTIONS.LOOTING.equiplooteechar or EMPTY) == name) then
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
          if (QUICKEPGP_OPTIONS.LOOTING.otherlootee == 3 and (QUICKEPGP_OPTIONS.LOOTING.otherlooteechar or EMPTY) == name) then
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
        if (rarity) then
          local itemLink = GetLootSlotLink(i)
          if (itemLink) then
            if (IsEquippableItem(itemLink) and rarity >= QUICKEPGP_OPTIONS.LOOTING.equiprarity) then
              masterLootee(i, EQUIPPABLE)
            elseif (rarity >= QUICKEPGP_OPTIONS.LOOTING.otherrarity) then
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

local function getActualNumLootItems()
  local count = 0
  for i = 1, GetNumLootItems() do
    local _, _, _, _, rarity, locked, isQuest, _, isActive = GetLootSlotInfo(i)
    if (not isQuest and not isActive) then
      if (rarity) then
        local itemLink = GetLootSlotLink(i)
        if (itemLink) then
          if (IsEquippableItem(itemLink) and rarity >= QUICKEPGP_OPTIONS.LOOTING.equiprarity) then
            count = count + 1
          elseif (rarity >= QUICKEPGP_OPTIONS.LOOTING.otherrarity) then
            count = count + 1
          end
        else
          count = count + 1
        end
      else
        count = count + 1
      end
    end
  end
  return count
end

local function setMasterLoot()
  SetLootMethod("Master", UnitName("Player"), QUICKEPGP_OPTIONS.LOOTING.masterthreshold)
end

local function onEvent(_, event, arg1, arg2)
  if (QUICKEPGP_OPTIONS.LOOTING.enabled) then
    if (event == "LOOT_OPENED") then
      if (getActualNumLootItems() > 0) then
        looting = true
      end
    end

    if (event == "LOOT_CLOSED") then
      looting = false
    end

    if (event == "PLAYER_ENTERING_WORLD") then
      local isInitialLogin = arg1
      local isReloadingUi = arg2
      if (not isInitialLogin and not isReloadingUi and QUICKEPGP.isInRaidInstance()) then
        setMasterLoot()
      end
    end
  end
end

local last = GetTime()
local function onUpdate()
  if (QUICKEPGP_OPTIONS.LOOTING.enabled) then
    if (looting) then
      local now = GetTime()
      if (now - last >= TICK_RATE) then
        for i = 1, MAX_NUM_LOOT do
          freeForAll(i)
          roundRobin(i)
          masterLoot(i)
          groupLoot(i)
          needBeforeGreed(i)
        end
        last = now
      end
    end
  end
end

-- ############################################################
-- ##### GLOBAL FUNCTIONS #####################################
-- ############################################################

QUICKEPGP.LOOTING:RegisterEvent("LOOT_OPENED")
QUICKEPGP.LOOTING:RegisterEvent("LOOT_CLOSED")
QUICKEPGP.LOOTING:RegisterEvent("PLAYER_ENTERING_WORLD")
QUICKEPGP.LOOTING:SetScript("OnEvent", onEvent)
QUICKEPGP.LOOTING:SetScript("OnUpdate", onUpdate)
