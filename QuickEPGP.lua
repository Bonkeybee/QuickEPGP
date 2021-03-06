QUICKEPGP_ADDON_NAME, QUICKEPGP = ...
QUICKEPGP.VERSION = GetAddOnMetadata(QUICKEPGP_ADDON_NAME, "Version")
QUICKEPGP.LIBS = LibStub("AceAddon-3.0"):NewAddon(QUICKEPGP_ADDON_NAME, "AceComm-3.0", "AceTimer-3.0")
QUICKEPGP.LIBS.GUI = LibStub("AceGUI-3.0")
QUICKEPGP.LIBS.MinimapIcon = LibStub("LibDBIcon-1.0")
QUICKEPGP.FRAME = CreateFrame("Frame")

QUICKEPGP.MINIMUM_EP = 0
QUICKEPGP.MINIMUM_GP = 50
QUICKEPGP.ADD = "+"
QUICKEPGP.MINUS = "-"

-- ############################################################
-- ##### LOCAL FUNCTIONS ######################################
-- ############################################################

local function epgpCommandMessage(message, name)
  local prefix = strsub(message, 1, 1)
  if ((prefix == QUICKEPGP.ADD or prefix == QUICKEPGP.MINUS) and QUICKEPGP.isMe(name) and CanEditOfficerNote()) then
    local hasItemString = select(3, strfind(message, "|c(.+)|r"))
    if (hasItemString) then
      QUICKEPGP.distributeItem(message, prefix)
    else
      local keys = {strfind(message, "(.)(%d*)(.*) (.*), (.*)")}
      local operation = keys[3]
      local amount = keys[4]
      local type = strtrim(keys[5])
      local unit = keys[6]
      local reason = keys[7]
      print(unit)
      if (operation == QUICKEPGP.ADD or operation == QUICKEPGP.MINUS) then
        if (operation == QUICKEPGP.MINUS) then
          amount = -amount
        end
        if (type == "EP") then
          QUICKEPGP.modifyEPGP(unit, amount, nil, reason)
        elseif (type == "GP") then
          QUICKEPGP.modifyEPGP(unit, nil, amount, reason)
        end
      end
    end
  end
end

local function onEvent(_, event, message, author)
  if (not message) then
    return
  end

  local name = QUICKEPGP.getSimpleCharacterName(author)
  if (event == "CHAT_MSG_OFFICER") then
    epgpCommandMessage(message, name)
  end

  if (event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER") then
    if (UnitIsUnit("player", name)) then
      local command = strlower(strsub(message, 1, 4))
      if (command == "roll") then
        local itemLink = strsub(message, 5)
        local itemId = QUICKEPGP.itemIdFromLink(itemLink)
        if itemId then
          return QUICKEPGP.startRolling(itemId, itemLink)
        end
      end
      command = strlower(strsub(message, 1, 6))
      if (command == "eproll") then
        local itemLink = strsub(message, 7)
        local itemId = QUICKEPGP.itemIdFromLink(itemLink)
        if itemId then
          return QUICKEPGP.startEPRolling(itemLink)
        end
      end
    end
    return QUICKEPGP.handleRolling(event, strlower(message), name)
  elseif (event == "CHAT_MSG_SYSTEM") then
    return QUICKEPGP.handleRolling(event, strlower(message), name)
  end
end

QUICKEPGP.FRAME:RegisterEvent("CHAT_MSG_WHISPER")
QUICKEPGP.FRAME:RegisterEvent("CHAT_MSG_RAID")
QUICKEPGP.FRAME:RegisterEvent("CHAT_MSG_RAID_LEADER")
QUICKEPGP.FRAME:RegisterEvent("CHAT_MSG_RAID_WARNING")
QUICKEPGP.FRAME:RegisterEvent("CHAT_MSG_OFFICER")
QUICKEPGP.FRAME:RegisterEvent("CHAT_MSG_SYSTEM")
QUICKEPGP.FRAME:SetScript("OnEvent", onEvent)

-- ############################################################
-- ##### GLOBAL FUNCTIONS #####################################
-- ############################################################

SLASH_EPGP1 = "/epgp"
SlashCmdList["EPGP"] = function(message)
  local command, arg1, arg2, arg3 = strsplit(" ", message:lower())
  if (command == "") then
    QUICKEPGP.InterfaceOptionsFrame_OpenToCategory_Fix(QUICKEPGP.menu)
  elseif (command == "help") then
    QUICKEPGP.info("Command List:")
    QUICKEPGP.info("/epgp about", " - version information")
    QUICKEPGP.info("/epgp pr [PLAYER]", " - calculates PR of self or the PLAYER")
    QUICKEPGP.info("/epgp pr [AMOUNT]", " - calculates PR of self after taking AMOUNT GP item")
    QUICKEPGP.info("/epgp start", " - starts an EPGP raid")
    QUICKEPGP.info("/epgp stop", " - stops an EPGP raid (will reward remaining time)")
    QUICKEPGP.info("/epgp status", " - shows status of an EPGP raid")
    QUICKEPGP.info("/epgp ignore", " - will turn off the EPGP start raid warning during this session")
  elseif (command == "about") then
    QUICKEPGP.info("installed version:", format(" %s", QUICKEPGP.VERSION))
  elseif (command == "pr") then
    if (arg1 and type(tonumber(arg1)) == "number") then
      local name = UnitName("player")
      local ep = QUICKEPGP.guildMemberEP(name)
      local gp = QUICKEPGP.guildMemberGP(name)
      local pr = QUICKEPGP.guildMemberPR(name)
      local cost = arg1
      local newpr = QUICKEPGP.round(ep / (gp + cost), 2)
      local status = "up"
      if (pr > newpr) then
        status = "down"
      end
      QUICKEPGP.info(format("Your new PR would be %s (%s from %s) with a %s GP item", newpr, status, pr, cost))
    else
      QUICKEPGP.info(QUICKEPGP.getEPGPPRMessage(arg1 or UnitName("player")))
    end
  elseif (command == "start" or command == "begin") then
    QUICKEPGP.startRaid()
  elseif (command == "stop" or command == "end") then
    QUICKEPGP.stopRaid()
  elseif (command == "status") then
    QUICKEPGP.raidStatus()
  elseif (command == "ignore") then
    QUICKEPGP.ignoreRaidWarning = true
    QUICKEPGP.info("Now ignoring raid start warnings until next reload")
  elseif (command == "toggle" and arg1 == "master") then
    QUICKEPGP.toggleMasterFrame()
  elseif command == "raid" then
    QUICKEPGP.RaidStandings:ToggleFrame()
  elseif command == "award" and arg1 == "raid" and tonumber(arg2) then
    QUICKEPGP.RaidReward(tonumber(arg2), arg3)
  elseif command == "track" then
    QUICKEPGP.Items:Track(string.sub(message, 7))
  elseif command == "toggle" and arg1 == "ontime" then
    QUICKEPGP.ToggleOnTime(arg2)
  else
    QUICKEPGP.error("invalid command - type `/epgp help` for a list of commands")
  end
end
