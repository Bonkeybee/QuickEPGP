QUICKEPGP.RAID = CreateFrame("Frame")
local loaded = false
local valid = false
local race = false

local PLAYER = "player"
local MASTER_LOOT = "master"
local RAID_LEADER = 2
local RAID_ASSIST = 1
local MAIN_ASSIST = "MAINASSIST"
local RAID = "RAID"
local OFFICER = "OFFICER"

local NUM_RAID_MEMBERS = 40
local TIME_REWARDS_TEMPLATE = {}
TIME_REWARDS_TEMPLATE[1] = {0, 100, "raid start"}
TIME_REWARDS_TEMPLATE[2] = {3600, 100, "raid time"}
TIME_REWARDS_TEMPLATE[3] = {7200, 200, "raid time"}
TIME_REWARDS_TEMPLATE[4] = {10800, 300, "raid end"}

local ONLINE_INDEX = 1
local RANK_INDEX = 2
local CLASS_INDEX = 3
local ROLE_INDEX = 4
local ISML_INDEX = 5

-- ############################################################
-- ##### LOCAL FUNCTIONS ######################################
-- ############################################################

local function updateRaidMemberTable()
  race = false

  local groupMembers = GetHomePartyInfo()
  if (not groupMembers) then
    groupMembers = {}
  end
  local myName = UnitName(PLAYER)
  tinsert(groupMembers, myName)
  local lootmethod, masterlooterPartyID = GetLootMethod()

  QUICKEPGP.raidMemberTable = {}
  for i = 1, #groupMembers do
    local name = groupMembers[i]
    local online = UnitIsConnected(name)
    local rank = UnitIsGroupLeader(name)
    local _, class = UnitClass(name)
    local isML = nil
    if (lootmethod == MASTER_LOOT) then
      if (masterlooterPartyID == 0 and UnitIsUnit(name, PLAYER)) then
        isML = 1
      elseif (masterlooterPartyID == i) then
        isML = 1
      end
    end
    if (name) then
      QUICKEPGP.raidMemberTable[name] = {online, (rank and 2 or 0), class, nil, isML}
    end
  end
  for i = 1, NUM_RAID_MEMBERS do
    local name, rank, _, _, _, class, _, online, _, role, isML = GetRaidRosterInfo(i)
    if (name) then
      name = QUICKEPGP.getSimpleCharacterName(name, true)
      QUICKEPGP.raidMemberTable[name] = {online, rank, class, role, isML}
    end
  end
  if (race and not valid) then
    return updateRaidMemberTable()
  end
  valid = true
end

local function check()
  if (not valid) then
    updateRaidMemberTable()
  end
end

local function stepStatus(index, epStep, timeStep)
  local time = GetServerTime()
  if (not QUICKEPGP_TIME_REWARDS) then
    QUICKEPGP_TIME_REWARDS = {}
  end
  if (not QUICKEPGP_TIME_REWARDS[index]) then
    local remainingTime = QUICKEPGP.round(((QUICKEPGP_RAIDING_TIMESTAMP + timeStep) - time) / 60, 0)
    QUICKEPGP.info(
      format("%s EP:", epStep),
      format(
        " %s %s remaining (%s).",
        remainingTime,
        QUICKEPGP.pluralize("minute", "minutes", remainingTime),
        date("%I:%M %p", QUICKEPGP_RAIDING_TIMESTAMP + timeStep)
      )
    )
  else
    QUICKEPGP.info(format("%s EP:", epStep), format(" awarded"))
  end
end

local function timeReward(index, value, reason)
  for name, data in pairs(QUICKEPGP.getRaidMembers()) do
    QUICKEPGP.modifyEPGP(name, value, nil, reason, true)
  end
  QUICKEPGP_TIME_REWARDS[index] = true
  SendChatMessage(format("Adding %sEP to all raid members for %s.", value, reason), RAID)
  SendChatMessage(format("Adding %sEP to all raid members for %s.", value, reason), OFFICER)
end

QUICKEPGP.ignoreRaidWarning = false
local function onEvent(_, event)
  if (event == "ADDON_LOADED") then
    loaded = true
  end
  if (event == "GROUP_ROSTER_UPDATE") then
    valid = false
    race = true
  end
  if (event == "PLAYER_REGEN_DISABLED") then
    if
      (not QUICKEPGP.ignoreRaidWarning and not QUICKEPGP_RAIDING_TIMESTAMP and UnitInRaid(PLAYER) and
        QUICKEPGP.isRaidLeader())
     then
      QUICKEPGP.error("Did you mean to start a raid? Type '/epgp start' to start a raid.")
      QUICKEPGP.error("Type '/epgp ignore' to stop this message until you reload.")
    end
  end
end

local lastUpdate = GetTime()
local delay = 1
local function onUpdate()
  local now = GetTime()
  if (loaded and now - lastUpdate >= delay) then
    lastUpdate = now
    if (QUICKEPGP_RAIDING_TIMESTAMP) then
      local time = GetServerTime()
      if (not QUICKEPGP_TIME_REWARDS) then
        QUICKEPGP_TIME_REWARDS = {}
      end
      for index, data in pairs(TIME_REWARDS_TEMPLATE) do
        if (not QUICKEPGP_TIME_REWARDS[index] and time > QUICKEPGP_RAIDING_TIMESTAMP + data[1]) then
          timeReward(index, data[2], data[3])
          if (index == QUICKEPGP.count(TIME_REWARDS_TEMPLATE)) then
            QUICKEPGP.stopRaid()
          end
        end
      end
    end
  end
end

-- ############################################################
-- ##### GLOBAL FUNCTIONS #####################################
-- ############################################################

QUICKEPGP.raidStatus = function()
  if (QUICKEPGP_RAIDING_TIMESTAMP) then
    local time = GetServerTime()
    local duration = QUICKEPGP.round((time - QUICKEPGP_RAIDING_TIMESTAMP) / 60, 0)
    QUICKEPGP.info(
      format(
        "Raid started %s %s ago (%s).",
        duration,
        QUICKEPGP.pluralize("minute", "minutes", duration),
        date("%I:%M %p", QUICKEPGP_RAIDING_TIMESTAMP)
      )
    )
    for index, data in pairs(TIME_REWARDS_TEMPLATE) do
      stepStatus(index, data[2], data[1])
    end
  else
    QUICKEPGP.error("You have not started a raid! Type '/epgp start' to start a raid.")
  end
end

QUICKEPGP.startRaid = function()
  if (QUICKEPGP.isRaidLeader()) then
    if (not QUICKEPGP_RAIDING_TIMESTAMP) then
      QUICKEPGP_RAIDING_TIMESTAMP = GetServerTime()
      QUICKEPGP_TIME_REWARDS = {}
      QUICKEPGP.info("Raid started. Type '/epgp stop' to stop a raid.")
      QUICKEPGP.raidStatus()
    else
      QUICKEPGP.error("You have already started a raid! Type '/epgp stop' to stop a raid.")
    end
  else
    QUICKEPGP.error("Only raid leaders can start a raid.")
  end
end

QUICKEPGP.stopRaid = function()
  if (QUICKEPGP_RAIDING_TIMESTAMP) then
    if (not QUICKEPGP_TIME_REWARDS) then
      QUICKEPGP_TIME_REWARDS = {}
    end
    for index, data in pairs(TIME_REWARDS_TEMPLATE) do
      if (not QUICKEPGP_TIME_REWARDS[index]) then
        timeReward(index, data[2], data[3])
      end
    end
    QUICKEPGP_RAIDING_TIMESTAMP = nil
    QUICKEPGP_TIME_REWARDS = {}
    QUICKEPGP.info("Raid ended. Type '/epgp start' to start a new raid.")
  else
    QUICKEPGP.error("You have not started a raid! Type '/epgp start' to start a raid.")
  end
end

QUICKEPGP.getRaidMembers = function()
  check()
  return QUICKEPGP.raidMemberTable
end

QUICKEPGP.raidMember = function(name)
  check()
  if (name) then
    name = strlower(name)
  end
  if (QUICKEPGP.raidMemberTable[name]) then
    return QUICKEPGP.raidMemberTable[name]
  else
    QUICKEPGP.error(format("%s is not a raid member.", (name or "nil")))
  end
end

QUICKEPGP.isOnlineRaid = function(name)
  if (name == nil) then
    name = UnitName(PLAYER)
  end
  local raidMember = QUICKEPGP.raidMember(name)
  if (raidMember and raidMember[ONLINE_INDEX]) then
    return true
  end
  return false
end

QUICKEPGP.raidMemberClass = function(name)
  if (name == nil) then
    name = UnitName(PLAYER)
  end
  local raidMember = QUICKEPGP.raidMember(name)
  if (raidMember) then
    return raidMember[CLASS_INDEX]
  end
end

QUICKEPGP.isRaidLeader = function(name)
  if (name == nil) then
    name = UnitName(PLAYER)
  end
  local raidMember = QUICKEPGP.raidMember(name)
  if (raidMember and raidMember[RANK_INDEX] == RAID_LEADER) then
    return true
  end
  return false
end

QUICKEPGP.isMasterLooter = function(name)
  if (name == nil) then
    name = UnitName(PLAYER)
  end
  local raidMember = QUICKEPGP.raidMember(name)
  if (raidMember and raidMember[ISML_INDEX]) then
    return true
  end
  return false
end

QUICKEPGP.isMainAssist = function(name)
  if (name == nil) then
    name = UnitName(PLAYER)
  end
  local raidMember = QUICKEPGP.raidMember(name)
  if (raidMember and raidMember[ROLE_INDEX] == MAIN_ASSIST) then
    return true
  end
  return false
end

QUICKEPGP.RAID:RegisterEvent("ADDON_LOADED")
QUICKEPGP.RAID:RegisterEvent("PLAYER_REGEN_DISABLED")
QUICKEPGP.RAID:RegisterEvent("GROUP_ROSTER_UPDATE")
QUICKEPGP.RAID:SetScript("OnEvent", onEvent)
QUICKEPGP.RAID:SetScript("OnUpdate", onUpdate)
