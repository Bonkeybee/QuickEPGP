QUICKEPGP.RAID = CreateFrame("Frame")

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

local function onEvent(_, event, message, author)
  if (event == "PLAYER_ENTERING_WORLD") then
    return updateRaidMemberTable()
  end
  if (event == "GROUP_ROSTER_UPDATE") then
    return updateRaidMemberTable()
  end
end

QUICKEPGP.RAID:RegisterEvent("PLAYER_ENTERING_WORLD")
QUICKEPGP.RAID:RegisterEvent("GROUP_ROSTER_UPDATE")
QUICKEPGP.RAID:SetScript("OnEvent", onEvent)
