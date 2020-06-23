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

local function masterLootee(slot, type)
  local masterlooterIndex = nil
  for i = 1, 40 do
    local name = GetMasterLootCandidate(slot, i)
    if (name) then
      if (QUICKEPGP.isOnlineRaid(name)) then
        if (type == EQUIPPABLE) then
          if (QUICKEPGP_OPTIONS.LOOTING.equiplootee == 1 and QUICKEPGP.isMasterLooter(name)) then
            GiveMasterLoot(slot, i)
            return
          end
          if (QUICKEPGP_OPTIONS.LOOTING.equiplootee == 2 and QUICKEPGP.isMainAssist(name)) then
            GiveMasterLoot(slot, i)
            return
          end
        else
          if (QUICKEPGP_OPTIONS.LOOTING.otherlootee == 1 and QUICKEPGP.isMasterLooter(name)) then
            GiveMasterLoot(slot, i)
            return
          end
          if (QUICKEPGP_OPTIONS.LOOTING.otherlootee == 2 and QUICKEPGP.isMainAssist(name)) then
            GiveMasterLoot(slot, i)
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

local function onEvent(_, event)
  if (QUICKEPGP_OPTIONS.LOOTING.enabled and event == "LOOT_OPENED") then
    for i = 1, GetNumLootItems() do
      local lootMethod = GetLootMethod()
      if (lootMethod == FREE_FOR_ALL) then
        LootSlot(i)
        ConfirmLootSlot(i)
      elseif (lootMethod == ROUND_ROBIN) then
        LootSlot(i)
        ConfirmLootSlot(i)
      elseif (lootMethod == MASTER_LOOT) then
        if (QUICKEPGP.isMasterLooter()) then
          local _, _, _, _, rarity, locked, isQuest, _, isActive = GetLootSlotInfo(i)
          if (not isQuest and not isActive) then
            if (rarity and rarity > 1) then
              local itemLink = GetLootSlotLink(i)
              if (itemLink) then
                if (IsEquippableItem(itemLink) and rarity >= QUICKEPGP_OPTIONS.LOOTING.equiprarity) then
                  masterLootee(i, EQUIPPABLE)
                elseif (rarity >= QUICKEPGP_OPTIONS.LOOTING.otherrarity) then
                  masterLootee(i)
                end
              else
                LootSlot(i)
              end
            else
              LootSlot(i)
            end
          end
        end
      elseif (lootMethod == GROUP_LOOT) then
        LootSlot(i)
        --(roll frame)
      elseif (lootMethod == NEED_BEFORE_GREED) then
        LootSlot(i)
        --(roll frame)
      end
    end
  end
end

-- ############################################################
-- ##### GLOBAL FUNCTIONS #####################################
-- ############################################################

QUICKEPGP.LOOTING:RegisterEvent("LOOT_OPENED")
QUICKEPGP.LOOTING:SetScript("OnEvent", onEvent)
