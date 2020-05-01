QUICKEPGP_ADDON_NAME, QUICKEPGP = ...
QUICKEPGP.VERSION = GetAddOnMetadata(QUICKEPGP_ADDON_NAME, "Version")
QUICKEPGP.LIBS = LibStub("AceAddon-3.0"):NewAddon(QUICKEPGP_ADDON_NAME,
"AceComm-3.0")
QUICKEPGP.FRAME = CreateFrame("Frame")

-- ############################################################
-- ##### LOCAL FUNCTIONS ######################################
-- ############################################################

local function onEvent(_, event, message, author)
  if (message == nil) then
    return
  end

  author = strsplit("-", author)
  local prefix = strsub(message, 1, 1)

  if (event == "CHAT_MSG_OFFICER") then
    if (prefix == "+" and CanEditOfficerNote()) then
      local hasItemString = select(3, strfind(message, "|c(.+)|r"))
      local hasPlayer = select(4, strfind(message, "|c(.+)|r(.+)"))
      if (hasItemString and hasPlayer) then
        local player = strtrim(hasPlayer)
        if (QUICKEPGP.guildMemberIndex(player)) then
          local itemStrings = "|c"..hasItemString.."|r"
          local itemParts = {strsplit("|", itemStrings)}
          local count = table.getn(itemParts) - 1
          if (count < 6) then
            local itemId = select(3, strfind(itemStrings, ":(%d+):"))
            if (itemId) then
              local cost = QUICKEPGP.getItemGP(itemId)
              if (cost) then
                SendChatMessage(format("Adding %s(%s GP) to %s", itemStrings, cost, player), "OFFICER")
                GuildRosterSetOfficerNote(QUICKEPGP.guildMemberIndex(player), (QUICKEPGP.guildMemberEP(player) or 0)..","..((QUICKEPGP.guildMemberGP(player) + cost) or 50))
              end
            end
          end
        end
      end
    end

    if (prefix == "-" and CanEditOfficerNote()) then
      local hasItemString = select(3, strfind(message, "|c(.+)|r"))
      local hasPlayer = select(4, strfind(message, "|c(.+)|r(.+)"))
      if (hasItemString and hasPlayer) then
        local player = strtrim(hasPlayer)
        if (QUICKEPGP.guildMemberIndex(player)) then
          local itemStrings = "|c"..hasItemString.."|r"
          local itemParts = {strsplit("|", itemStrings)}
          local count = table.getn(itemParts) - 1
          if (count < 6) then
            local itemId = select(3, strfind(itemStrings, ":(%d+):"))
            if (itemId) then
              local cost = QUICKEPGP.getItemGP(itemId)
              if (cost) then
                SendChatMessage(format("Removing %s(%s GP) from %s", itemStrings, cost, player), "OFFICER")
                GuildRosterSetOfficerNote(QUICKEPGP.guildMemberIndex(player), (QUICKEPGP.guildMemberEP(player) or 0)..","..((QUICKEPGP.guildMemberGP(player) - cost) or 50))
              end
            end
          end
        end
      end
    end
  end

  if (event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER") then
    local command = strlower(strsub(message, 1, 4))

    if (QUICKEPGP.rolling()) then
      return QUICKEPGP.handleRolling(strlower(message), author)
    end

    if (command == "roll" and CanEditOfficerNote()) then
      return QUICKEPGP.startRolling(message, author)
    end
  end

  if (event == "CHAT_MSG_WHISPER") then
    if (QUICKEPGP.rolling()) then
      if (QUICKEPGP.guildMember(author)) then
        return QUICKEPGP.handleRolling(strlower(message), author)
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
