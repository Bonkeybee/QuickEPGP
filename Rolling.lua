QUICKEPGP.ROLLING = CreateFrame("Frame")

local LEVEL_INDEX = 1
local CLASS_INDEX = 2
local EP_INDEX = 3
local GP_INDEX = 4

local rollTable
local rolling = false
local highestRoller = nil
local currentItem = nil

-- ############################################################
-- ##### LOCAL FUNCTIONS ######################################
-- ############################################################

local function findHighestRoller(rollTable)
  local name = nil
  local pr = 0
  for player, playerData in pairs(rollTable) do
    local level = playerData[LEVEL_INDEX]
    local class = playerData[CLASS_INDEX]
    local ep = playerData[EP_INDEX]
    local gp = playerData[GP_INDEX]
    if (ep / gp > pr) then
      name = player
      pr = ep / gp
    end
  end
  return name
end

local function handleNeeding(player)
  if (not rollTable[player]) then
    SendChatMessage(format("%s needed (%s PR)", QUICKEPGP.getCharacterString(QUICKEPGP.guildMemberLevel(player), QUICKEPGP.guildMemberClass(player), player), QUICKEPGP.round(QUICKEPGP.guildMemberEP(player) / QUICKEPGP.guildMemberGP(player), 2)), "RAID")
  end
  rollTable[player] = {QUICKEPGP.guildMemberLevel(player), QUICKEPGP.guildMemberClass(player), QUICKEPGP.guildMemberEP(player), QUICKEPGP.guildMemberGP(player)}
  highestRoller = QUICKEPGP.comparePR(highestRoller, player, rollTable)
end

local function handlePassing(player)
  if (rollTable[player]) then
    SendChatMessage(format("%s passed", QUICKEPGP.getCharacterString(QUICKEPGP.guildMemberLevel(player), QUICKEPGP.guildMemberClass(player), player)), "RAID")
  end
  rollTable[player] = nil
  highestRoller = findHighestRoller(rollTable)
end

local function endRolling()
  local itemId = QUICKEPGP.getItemId(currentItem)
  if (itemId) then
    local cost = QUICKEPGP.getItemGP(itemId)
    if (cost) then
      if (highestRoller) then
        SendChatMessage(format("%s (%s PR) wins %s(%s GP)", QUICKEPGP.getCharacterString(QUICKEPGP.guildMemberLevel(highestRoller), QUICKEPGP.guildMemberClass(highestRoller), highestRoller), QUICKEPGP.round(QUICKEPGP.guildMemberEP(highestRoller) / QUICKEPGP.guildMemberGP(highestRoller), 2), currentItem, cost), "RAID_WARNING")
        SendChatMessage(format("%s (%s PR) wins %s(%s GP)", QUICKEPGP.getCharacterString(QUICKEPGP.guildMemberLevel(highestRoller), QUICKEPGP.guildMemberClass(highestRoller), highestRoller), QUICKEPGP.round(QUICKEPGP.guildMemberEP(highestRoller) / QUICKEPGP.guildMemberGP(highestRoller), 2), currentItem, cost), "OFFICER")
        GuildRosterSetOfficerNote(QUICKEPGP.guildMemberIndex(highestRoller), (QUICKEPGP.guildMemberEP(highestRoller) or 0)..","..((QUICKEPGP.guildMemberGP(highestRoller) + cost) or 50))
      else
        SendChatMessage(format("everyone passed on %s(%s GP)", currentItem, cost), "RAID_WARNING")
        SendChatMessage(format("everyone passed on %s(%s GP)", currentItem, cost), "OFFICER")
      end
    end
  end
  rolling = false
end

local last = GetTime()
local function onUpdate()
  local now = GetTime()
  if (not rolling) then
    last = now
    return
  end
  if (now - last >= 20) then
    if (rolling and currentItem) then
      local cost = QUICKEPGP.getItemGP(QUICKEPGP.getItemId(currentItem))
      if (highestRoller) then
        SendChatMessage(format("...still rolling on %s(%s GP) [%s (%s PR)]", currentItem, cost, QUICKEPGP.getCharacterString(QUICKEPGP.guildMemberLevel(highestRoller), QUICKEPGP.guildMemberClass(highestRoller), highestRoller), QUICKEPGP.round(QUICKEPGP.guildMemberEP(highestRoller) / QUICKEPGP.guildMemberGP(highestRoller), 2)), "RAID")
      else
        SendChatMessage(format("...still rolling on %s(%s GP)", currentItem, cost), "RAID")
      end
    end
    last = now
  end
end

-- ############################################################
-- ##### GLOBAL FUNCTIONS #####################################
-- ############################################################

QUICKEPGP.rolling = function()
  return rolling
end

QUICKEPGP.handleRolling = function(command, author)
  if (command == "need") then
    return handleNeeding(author)
  end
  if (command == "pass") then
    return handlePassing(author)
  end
  if (command == "end") then
    return endRolling()
  end
end

QUICKEPGP.startRolling = function(message, author)
  local player = UnitName("player")
  if (player == author) then
    local hasItemString = select(3, strfind(message, "|c(.+)|r"))
    if (hasItemString and QUICKEPGP.raidMemberTable and QUICKEPGP.raidMemberTable[player]) then
      local rank = QUICKEPGP.raidMemberTable[player][1]
      local channel = "RAID"
      if (rank > 0) then
        channel = "RAID_WARNING"
      end
      --local isMasterlooter = QUICKEPGP.raidMemberTable[player][2]
      if (rank > 0) then
        local itemStrings = "|c"..hasItemString.."|r"
        local itemParts = {strsplit("|", itemStrings)}
        local count = table.getn(itemParts) - 1
        if (count < 6) then
          local itemId = select(3, strfind(itemStrings, ":(%d+):"))
          if (itemId) then
            local cost = QUICKEPGP.getItemGP(itemId)
            if (cost) then
              SendChatMessage(format("starting rolls on %s(%s GP)", itemStrings, cost), channel)
              SendChatMessage(format("type NEED or PASS"), "RAID")
              rollTable = {}
              rolling = true
              highestRoller = nil
              currentItem = itemStrings
            end
          end
        end
      end
    end
  end
end

QUICKEPGP.ROLLING:SetScript("OnUpdate", onUpdate)
