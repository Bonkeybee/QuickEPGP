QUICKEPGP.GUILD = CreateFrame("Frame")
local valid = false
local race = false

local INDEX_INDEX = 1
local LEVEL_INDEX = 2
local CLASS_INDEX = 3
local EP_INDEX = 4
local GP_INDEX = 5

-- ############################################################
-- ##### LOCAL FUNCTIONS ######################################
-- ############################################################

local function updateGuildMemberTable()
  race = false
  QUICKEPGP.guildMemberTable = {}
  for i = 1, GetNumGuildMembers() do
    local name, _, _, level, class, _, _, officerNote = GetGuildRosterInfo(i)
    if (name) then
      name = QUICKEPGP.getSimpleCharacterName(name, true)
      ep, gp = strsplit(",", officerNote)
      QUICKEPGP.guildMemberTable[name] = {i, level, class, ep, gp}
    end
  end
  if (race) then
    return check()
  end
  valid = true
end

local function check()
  if (not valid) then
    updateGuildMemberTable()
  end
end

local function onEvent(_, event, message, author)
  if (event == "GUILD_ROSTER_UPDATE") then
    valid = false
    race = true
  end
end

-- ############################################################
-- ##### GLOBAL FUNCTIONS #####################################
-- ############################################################

QUICKEPGP.guildMember = function(name)
  check()
  if (name) then
    name = strlower(name)
  end
  if (QUICKEPGP.guildMemberTable[name]) then
    return QUICKEPGP.guildMemberTable[name]
  else
    QUICKEPGP.error(format("%s is not a guild member", (name or "nil")))
  end
end
QUICKEPGP.guildMemberIndex = function(name)
  if (QUICKEPGP.guildMember(name)) then
    return QUICKEPGP.guildMember(name)[INDEX_INDEX]
  else
    QUICKEPGP.error("Cannot get guild member index")
  end
end
QUICKEPGP.guildMemberLevel = function(name)
  if (QUICKEPGP.guildMember(name)) then
    return QUICKEPGP.guildMember(name)[LEVEL_INDEX]
  else
    QUICKEPGP.error("Cannot get guild member level")
  end
end
QUICKEPGP.guildMemberClass = function(name)
  if (QUICKEPGP.guildMember(name)) then
    return QUICKEPGP.guildMember(name)[CLASS_INDEX]
  else
    QUICKEPGP.error("Cannot get guild member class")
  end
end
QUICKEPGP.guildMemberEP = function(name)
  if (QUICKEPGP.guildMember(name)) then
    return QUICKEPGP.guildMember(name)[EP_INDEX]
  else
    QUICKEPGP.error("Cannot get guild member EP")
  end
end
QUICKEPGP.guildMemberGP = function(name)
  if (QUICKEPGP.guildMember(name)) then
    return QUICKEPGP.guildMember(name)[GP_INDEX]
  else
    QUICKEPGP.error("Cannot get guild member GP")
  end
end
QUICKEPGP.guildMemberPR = function(name)
  if (QUICKEPGP.guildMember(name)) then
    return QUICKEPGP.round(QUICKEPGP.guildMember(name)[EP_INDEX] / QUICKEPGP.guildMember(name)[GP_INDEX], 2)
  else
    QUICKEPGP.error("Cannot get guild member PR")
  end
end

QUICKEPGP.GUILD:RegisterEvent("GUILD_ROSTER_UPDATE")
QUICKEPGP.GUILD:SetScript("OnEvent", onEvent)
