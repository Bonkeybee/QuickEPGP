QUICKEPGP_ADDON_NAME, QUICKEPGP = ...
QUICKEPGP.VERSION = GetAddOnMetadata(QUICKEPGP_ADDON_NAME, "Version")
QUICKEPGP.LIBS = LibStub("AceAddon-3.0"):NewAddon(QUICKEPGP_ADDON_NAME,
"AceComm-3.0")
QUICKEPGP.LIBS.GUI = LibStub("AceGUI-3.0")
QUICKEPGP.FRAME = CreateFrame("Frame")

QUICKEPGP.MINIMUM_EP = 0
QUICKEPGP.MINIMUM_GP = 50
QUICKEPGP.ADD = "+"
QUICKEPGP.MINUS = "-"

-- ############################################################
-- ##### LOCAL FUNCTIONS ######################################
-- ############################################################

local function onEvent(_, event, message, author)
  if (not message) then
    return
  end

  local name = QUICKEPGP.getSimpleCharacterName(author)
  local prefix = strsub(message, 1, 1)
  if (event == "CHAT_MSG_OFFICER") then
    if ((prefix == QUICKEPGP.ADD or prefix == QUICKEPGP.MINUS) and QUICKEPGP.isMe(name) and CanEditOfficerNote()) then
      local hasItemString = select(3, strfind(message, "|c(.+)|r"))
      if (hasItemString) then
        QUICKEPGP.distributeItem(message, prefix)
      else
        -- local keys = {strfind(message, "(.)(%d*)(.*) (.*), (.*)")}
        -- local operation = keys[3]
        -- local amount = keys[4]
        -- local type = strtrim(keys[5])
        -- local unit = keys[6]
        -- local reason = keys[7]
        -- if (operation == QUICKEPGP.ADD or operation == QUICKEPGP.MINUS) then
        --   if (operation == QUICKEPGP.MINUS) then
        --     amount = -amount
        --   end
        --   if (type == EP) then
        --     QUICKEPGP.modifyEPGP(unit, amount, nil, reason)
        --   elseif (type == GP) then
        --     QUICKEPGP.modifyEPGP(unit, nil, amount, reason)
        --   end
        -- end
      end
    end
  end

  if (event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER") then
    local command = strlower(strsub(message, 1, 4))

    if (command == "roll" and QUICKEPGP.isMe(name) and CanEditOfficerNote()) then
      return QUICKEPGP.startRolling(message, name)
    end

    if (QUICKEPGP.rolling()) then
      return QUICKEPGP.handleRolling(strlower(message), name)
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
