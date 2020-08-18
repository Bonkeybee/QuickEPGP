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
local TIME_REWARDS_TEMPLATE = {
  {Time = 1800 * 0, EP = 100},
  {Time = 1800 * 1, EP = 150},
  {Time = 1800 * 2, EP = 150},
  {Time = 1800 * 3, EP = 150},
  {Time = 1800 * 4, EP = 150},
  {Time = 1800 * 5, EP = 150},
  {Time = 1800 * 6, EP = 150}
}
local TIME_REWARDS_TEMPLATE_COUNT = QUICKEPGP.count(TIME_REWARDS_TEMPLATE)

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
      name = QUICKEPGP.NormalizeName(name)
      QUICKEPGP.raidMemberTable[name] = {online, (rank and 2 or 0), class, nil, isML}
    end
  end
  for i = 1, NUM_RAID_MEMBERS do
    local name, rank, _, _, _, class, _, online, _, role, isML = GetRaidRosterInfo(i)
    if (name) then
      name = QUICKEPGP.NormalizeName(name)
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

local function timeReward(index, value, pastEnd)
  local reason

  if index == 1 then
    reason = "raid start"
  elseif index == TIME_REWARDS_TEMPLATE_COUNT then
    reason = "raid end"
  elseif pastEnd then
    reason = "early raid end"
  else
    reason = "raid time"
  end

  for name, _ in pairs(QUICKEPGP.getRaidMembers()) do
    local ep = value

    if pastEnd and not QUICKEPGP_STARTING_RAIDERS[name] then
      ep = ep / 2
    end

    QUICKEPGP.modifyEPGP(name, ep, nil, reason, true)
  end
  if index then
    QUICKEPGP_TIME_REWARDS[index] = true
  end

  local message
  if pastEnd and QUICKEPGP.count(QUICKEPGP_STARTING_RAIDERS) > 0 then
    message =
      format("Adding %sEP to on-time raid members and %sEP to late raid members for %s", value, value / 2, reason)
  else
    message = format("Adding %sEP to all raid members for %s.", value, reason)
  end

  SendChatMessage(message, RAID)
  SendChatMessage(message, OFFICER)
end

QUICKEPGP.ignoreRaidWarning = not CanEditOfficerNote() -- Don't ask users to start epgp when they aren't capable of doing it
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
        if (not QUICKEPGP_TIME_REWARDS[index] and time > QUICKEPGP_RAIDING_TIMESTAMP + data.Time) then
          timeReward(index, data.EP)
          if (index == TIME_REWARDS_TEMPLATE_COUNT) then
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

function QUICKEPGP.RaidReward(value, reason)
  if CanEditOfficerNote() then
    for name, _ in pairs(QUICKEPGP.getRaidMembers()) do
      QUICKEPGP.modifyEPGP(name, value, nil, reason, true)
    end
    local message = format("Adding %sEP to all raid members for %s.", value, reason)
    SendChatMessage(message, RAID)
    SendChatMessage(message, OFFICER)
  else
    QUICKEPGP.error("You do not have permisson to do that.")
  end
end

function QUICKEPGP.ToggleOnTime(name)
  if QUICKEPGP_RAIDING_TIMESTAMP then
    local normalizedName = QUICKEPGP.NormalizeName(name)
    if normalizedName then
      if QUICKEPGP_STARTING_RAIDERS[normalizedName] == true then
        QUICKEPGP_STARTING_RAIDERS[normalizedName] = nil
        QUICKEPGP.info(format("%s is now marked as late."))
      else
        QUICKEPGP_STARTING_RAIDERS[normalizedName] = true
        QUICKEPGP.info(format("%s is now marked as on-time."))
      end
    else
      QUICKEPGP.error(format("Player '%s' not found.", name))
    end
  else
    QUICKEPGP.error("You have not started a raid! Can't toggle player start status.")
  end
end

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
      stepStatus(index, data.EP, data.Time)
    end
  else
    QUICKEPGP.error("You have not started a raid! Type '/epgp start' to start a raid.")
  end
end

QUICKEPGP.startRaid = function()
  if not CanEditOfficerNote() then
    QUICKEPGP.error("Only players who can edit Officer Notes may start an EPGP raid.")
    return
  end
  if (QUICKEPGP.isRaidLeader()) then
    if (not QUICKEPGP_RAIDING_TIMESTAMP) then
      QUICKEPGP_RAIDING_TIMESTAMP = GetServerTime()
      QUICKEPGP_TIME_REWARDS = {}
      QUICKEPGP_STARTING_RAIDERS = {}

      for i = 1, 40 do
        local name = UnitName("raid" .. i)
        if name then
          QUICKEPGP_STARTING_RAIDERS[name] = true
        else
          break
        end
      end

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
    local lastReward = TIME_REWARDS_TEMPLATE[TIME_REWARDS_TEMPLATE_COUNT]

    if not QUICKEPGP_TIME_REWARDS[TIME_REWARDS_TEMPLATE_COUNT] then
      -- Ending EP should be awarded in full to everyone.
      timeReward(TIME_REWARDS_TEMPLATE_COUNT, lastReward.EP)
    end

    for index, data in pairs(TIME_REWARDS_TEMPLATE) do
      if (not QUICKEPGP_TIME_REWARDS[index]) then
        timeReward(index, data.EP, true)
      end
    end
    QUICKEPGP_RAIDING_TIMESTAMP = nil
    QUICKEPGP_STARTING_RAIDERS = nil
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
    name = QUICKEPGP.NormalizeName(name)
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

QUICKEPGP.isRaidAssist = function(name)
  if (name == nil) then
    name = UnitName(PLAYER)
  end
  local raidMember = QUICKEPGP.raidMember(name)
  if (raidMember and raidMember[RANK_INDEX] == RAID_ASSIST) then
    return true
  end
  return false
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
