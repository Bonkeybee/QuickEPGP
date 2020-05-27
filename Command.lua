
SLASH_EPGP1 = "/epgp"
SlashCmdList["EPGP"] = function(message)
  local command, arg1, arg2, arg3 = strsplit(" ", message:lower())
  local prefix = strsub(command, 1, 1)
  if (command == "" or command == "help") then
    QUICKEPGP.info("Command List:")
    QUICKEPGP.info("/epgp about", " - version information")
    QUICKEPGP.info("/epgp pr [PLAYER]", " - calculates PR of self or the PLAYER")
    QUICKEPGP.info("/epgp pr [##]", " - calculates PR of self after taking ##GP item")
    QUICKEPGP.info("/epgp start", " - starts an EPGP raid")
    QUICKEPGP.info("/epgp stop", " - stops an EPGP raid (will reward remaining time)")
    QUICKEPGP.info("/epgp status", " - shows status of an EPGP raid")
    QUICKEPGP.info("/epgp ignore", " - will turn off the EPGP start raid warning during this session")
    QUICKEPGP.info("/epgp <+/-> ITEMLINK PLAYER", " - adds/removes GP cost of ITEMLINK to/from PLAYER") --todo
    QUICKEPGP.info("/epgp <+/-> <##EP/##GP> PLAYER", " - adds/removes ##EP/##GP to/from PLAYER") --todo
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
      local name = (arg1 or UnitName("player"))
      local member = QUICKEPGP.guildMember(name)
      if (member) then
        local ep = QUICKEPGP.guildMemberEP(name)
        local gp = QUICKEPGP.guildMemberGP(name)
        local pr = QUICKEPGP.guildMemberPR(name)
        if (name == UnitName("player")) then
          QUICKEPGP.info(format("You have %s PR; (%s EP / %s GP)", pr, ep, gp))
        else
          QUICKEPGP.info(format("%s has %s PR; (%s EP / %s GP)", QUICKEPGP.camel(name), pr, ep, gp))
        end
      end
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
  elseif (prefix == "+") then
    --todo
  elseif (prefix == "-") then
    --todo
  else
    QUICKEPGP.error("invalid command - type `/epgp help` for a list of commands")
  end
end
