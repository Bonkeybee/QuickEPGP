QUICKEPGP_ADDON_NAME, QUICKEPGP = ...
QUICKEPGP.VERSION = GetAddOnMetadata(QUICKEPGP_ADDON_NAME, "Version")
QUICKEPGP.LIBS = LibStub("AceAddon-3.0"):NewAddon(QUICKEPGP_ADDON_NAME,
"AceComm-3.0")
QUICKEPGP.FRAME = CreateFrame("Frame")

QUICKEPGP.ADD = "+"
QUICKEPGP.MINUS = "-"

-- ############################################################
-- ##### LOCAL FUNCTIONS ######################################
-- ############################################################

local function onEvent(_, event, message, author)
  if (not message) then
    return
  end

  local prefix = strsub(message, 1, 1)
  if (event == "CHAT_MSG_OFFICER") then
    if (CanEditOfficerNote() and (prefix == QUICKEPGP.ADD or prefix == QUICKEPGP.MINUS)) then
      QUICKEPGP.distributeItem(message, prefix)
    end
  end

  local name = QUICKEPGP.getSimpleCharacterName(author)
  if (event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER") then
    local command = strlower(strsub(message, 1, 4))

    if (QUICKEPGP.rolling()) then
      return QUICKEPGP.handleRolling(strlower(message), name)
    end

    if (command == "roll" and CanEditOfficerNote()) then
      return QUICKEPGP.startRolling(message, name)
    end
  end

  if (event == "CHAT_MSG_WHISPER") then
    if (QUICKEPGP.rolling()) then
      if (QUICKEPGP.guildMember(name)) then
        return QUICKEPGP.handleRolling(strlower(message), name)
      end
    end
  end
end

QUICKEPGP.FRAME:RegisterEvent("CHAT_MSG_WHISPER")
QUICKEPGP.FRAME:RegisterEvent("CHAT_MSG_RAID")
QUICKEPGP.FRAME:RegisterEvent("CHAT_MSG_RAID_LEADER")
QUICKEPGP.FRAME:RegisterEvent("CHAT_MSG_RAID_WARNING")
QUICKEPGP.FRAME:RegisterEvent("CHAT_MSG_OFFICER")
QUICKEPGP.FRAME:SetScript("OnEvent", onEvent)
