QUICKEPGP.GUILD = CreateFrame("Frame")

local INDEX_INDEX = 1
local LEVEL_INDEX = 2
local CLASS_INDEX = 3
local EP_INDEX = 4
local GP_INDEX = 5

-- ############################################################
-- ##### LOCAL FUNCTIONS ######################################
-- ############################################################

local function updateGuildMemberTable()
  QUICKEPGP.guildMemberTable = {}
  for i = 1, 1000 do
    local name, _, _, level, class, _, _, officerNote = GetGuildRosterInfo(i)
    if (name) then
      name = strsplit("-", name)
      ep, gp = strsplit(",", officerNote)
      QUICKEPGP.guildMemberTable[name] = {i, level, class, ep, gp}
    end
  end
end

local function onEvent(_, event, message, author)
  if (event == "PLAYER_ENTERING_WORLD") then
    return updateGuildMemberTable()
  end
  if (event == "GUILD_ROSTER_UPDATE") then
    return updateGuildMemberTable()
  end
end

-- ############################################################
-- ##### GLOBAL FUNCTIONS #####################################
-- ############################################################
QUICKEPGP.guildMember = function(name)
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

QUICKEPGP.GUILD:RegisterEvent("PLAYER_ENTERING_WORLD")
QUICKEPGP.GUILD:RegisterEvent("GUILD_ROSTER_UPDATE")
QUICKEPGP.GUILD:SetScript("OnEvent", onEvent)
