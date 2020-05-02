QUICKEPGP.RAID = CreateFrame("Frame")
local valid = false
local race = false

-- ############################################################
-- ##### LOCAL FUNCTIONS ######################################
-- ############################################################

local function updateRaidMemberTable()
  QUICKEPGP.raidMemberTable = {}
  for i = 1, 40 do
    local name, rank, _, _, _, _, _, _, _, _, isML = GetRaidRosterInfo(i)
    if (name) then
      name = strsplit("-", name)
      QUICKEPGP.raidMemberTable[name] = {rank, isML}
    end
  end
end

local function check()
  if (not valid) then
    updateRaidMemberTable()
  end
end

local function onEvent(_, event, message, author)
  if (event == "GROUP_ROSTER_UPDATE") then
    valid = false
    race = true
  end
end

-- ############################################################
-- ##### GLOBAL FUNCTIONS #####################################
-- ############################################################

QUICKEPGP.raidMember = function(name)
  check()
  if (QUICKEPGP.raidMemberTable[name]) then
    return QUICKEPGP.raidMemberTable[name]
  else
    QUICKEPGP.error(format("%s is not a raid member", (name or "nil")))
  end
end

QUICKEPGP.RAID:RegisterEvent("GROUP_ROSTER_UPDATE")
QUICKEPGP.RAID:SetScript("OnEvent", onEvent)
