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
      QUICKEPGP.guildMemberTable[name] = {i, level, class, tonumber(ep), tonumber(gp)}
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
  local guildMemberData = QUICKEPGP.guildMember(name)
  if (guildMemberData) then
    return guildMemberData[INDEX_INDEX]
  else
    QUICKEPGP.error("Cannot get guild member "..(name or "").." index")
  end
end
QUICKEPGP.guildMemberLevel = function(name)
  local guildMemberData = QUICKEPGP.guildMember(name)
  if (guildMemberData) then
    return guildMemberData[LEVEL_INDEX]
  else
    QUICKEPGP.error("Cannot get guild member "..(name or "").." level")
  end
end
QUICKEPGP.guildMemberClass = function(name)
  local guildMemberData = QUICKEPGP.guildMember(name)
  if (guildMemberData) then
    return guildMemberData[CLASS_INDEX]
  else
    QUICKEPGP.error("Cannot get guild member "..(name or "").." class")
  end
end
QUICKEPGP.guildMemberEP = function(name)
  local guildMemberData = QUICKEPGP.guildMember(name)
  if (guildMemberData) then
    return guildMemberData[EP_INDEX]
  else
    QUICKEPGP.error("Cannot get guild member "..(name or "").." EP")
  end
end
QUICKEPGP.guildMemberGP = function(name)
  local guildMemberData = QUICKEPGP.guildMember(name)
  if (guildMemberData) then
    return guildMemberData[GP_INDEX]
  else
    QUICKEPGP.error("Cannot get guild member "..(name or "").." GP")
  end
end
QUICKEPGP.guildMemberPR = function(name)
  local guildMemberData = QUICKEPGP.guildMember(name)
  if (guildMemberData) then
    return QUICKEPGP.round(guildMemberData[EP_INDEX] / guildMemberData[GP_INDEX], 2)
  else
    QUICKEPGP.error("Cannot get guild member "..(name or "").." PR")
  end
end

QUICKEPGP.GUILD:RegisterEvent("GUILD_ROSTER_UPDATE")
QUICKEPGP.GUILD:SetScript("OnEvent", onEvent)
