QUICKEPGP.ROLLING = CreateFrame("Frame")
QUICKEPGP.ROLLING.MODULE_NAME = "QEPGP-Rolling"
local MODULE_NAME = QUICKEPGP.ROLLING.MODULE_NAME

local ANNOUNCE_TIME = 20
local DELIMITER = ";"
local EMPTY = ""

local LEVEL_INDEX = 1
--local CLASS_INDEX = 2 --TODO use class to determine if player can roll on currentItem as mainspec
local EP_INDEX = 3
local GP_INDEX = 4

local last = GetTime()
local rolling = false
local rollTable = {}
local highestRoller = nil
local currentItem = nil

-- ############################################################
-- ##### LOCAL FUNCTIONS ######################################
-- ############################################################

local function findHighestRoller(rollTable)
  local name = nil
  local highestPR = 0
  local highestLevel = 0
  for player, playerData in pairs(rollTable) do
    local level = playerData[LEVEL_INDEX]
    --local class = playerData[CLASS_INDEX] --TODO use class to determine if player can roll on currentItem as mainspec
    local ep = playerData[EP_INDEX]
    local gp = playerData[GP_INDEX]
    if (ep / gp > highestPR and level >= highestLevel) then
      name = player
      highestPR = ep / gp
      highestLevel = level
    end
  end
  return name
end

local function clearCurrentItem()
  currentItem = nil

  if QuickEPGProllFrame then
    QuickEPGProllFrame:SetItem()
  end

  if QuickEPGPMasterLootFrame then
    QuickEPGPMasterLootFrame:SetItem()
  end
end

local function setCurrentItem(itemLink)
  if itemLink then
    currentItem = itemLink
    local itemId = QUICKEPGP.getItemId(itemLink)
    local icon = GetItemIcon(itemId)

    if QuickEPGProllFrame then
      QuickEPGProllFrame:SetItem(itemLink, icon)
    end
    if QuickEPGPMasterLootFrame then
      QuickEPGPMasterLootFrame:SetItem(itemLink, icon)
    end
  else
    clearCurrentItem()
    QUICKEPGP.error("QUICKEPGP::Invalid itemId " .. (itemLink or EMPTY))
  end
end

local function clearHighestRoller()
  highestRoller = nil

  if QuickEPGProllFrame then
    QuickEPGProllFrame.Status:SetText(nil)
  end
end

local function setHighestRoller(name)
  highestRoller = name

  if QuickEPGProllFrame then
    if (name and name ~= EMPTY) then
      local cost = QUICKEPGP.getItemGP(QUICKEPGP.getItemId(currentItem))
      QuickEPGProllFrame.Status:SetText(
        QUICKEPGP.colorByClass(highestRoller, QUICKEPGP.raidMemberClass(highestRoller)) ..
          " |cFFFFFF00(" ..
            QUICKEPGP.guildMemberPR(highestRoller) ..
              " PR)|r |cFFFF0000[" .. QUICKEPGP.guildMemberPR(highestRoller, true, cost) .. " PR]|r"
      )
    else
      clearHighestRoller()
    end
  end
end

local function validateRoll(player)
  if (not QUICKEPGP.raidMember(player)) then
    QUICKEPGP.error("Skipping " .. (player or EMPTY) .. "'s need roll: not in raid")
    return false
  end
  if (not QUICKEPGP.GUILD:GetMemberInfo(player)) then
    QUICKEPGP.error("Skipping " .. (player or EMPTY) .. "'s need roll: not in guild")
    return false
  end
  return true
end

local function handleNeeding(player)
  if (validateRoll(player)) then
    if (not rollTable[player]) then
      SendChatMessage(
        format(
          "%s needed (%s PR)",
          QUICKEPGP.getCharacterString(QUICKEPGP.guildMemberLevel(player), QUICKEPGP.guildMemberClass(player), player),
          QUICKEPGP.guildMemberPR(player)
        ),
        "RAID"
      )
    end
    rollTable[player] = {
      QUICKEPGP.guildMemberLevel(player),
      QUICKEPGP.guildMemberClass(player),
      QUICKEPGP.guildMemberEP(player),
      QUICKEPGP.guildMemberGP(player)
    }
    setHighestRoller(QUICKEPGP.comparePR(highestRoller, player, rollTable))
  end
  QUICKEPGP.LIBS:SendCommMessage(
    MODULE_NAME,
    "URF" .. DELIMITER .. (currentItem or EMPTY) .. DELIMITER .. (highestRoller or EMPTY),
    "RAID",
    nil,
    "ALERT"
  )
end

local function handlePassing(player)
  if (validateRoll(player)) then
    if (rollTable[player]) then
      SendChatMessage(
        format(
          "%s passed",
          QUICKEPGP.getCharacterString(QUICKEPGP.guildMemberLevel(player), QUICKEPGP.guildMemberClass(player), player)
        ),
        "RAID"
      )
    end
    rollTable[player] = nil
    setHighestRoller(findHighestRoller(rollTable))
  end
  QUICKEPGP.LIBS:SendCommMessage(
    MODULE_NAME,
    "URF" .. DELIMITER .. (currentItem or EMPTY) .. DELIMITER .. (highestRoller or EMPTY),
    "RAID",
    nil,
    "ALERT"
  )
end

local function clearRollData()
  rolling = false
  rollTable = {}
  clearCurrentItem()
  clearHighestRoller()
end

local function endRolling(cancel)
  local itemId = QUICKEPGP.getItemId(currentItem)
  if (itemId) then
    local cost = QUICKEPGP.getItemGP(itemId)
    if (cost) then
      if cancel then
        SendChatMessage(format("Cancelled rolls on %s(%s GP)", currentItem, cost), "RAID_WARNING")
        clearHighestRoller()
      elseif (highestRoller) then
        SendChatMessage(
          format(
            "%s (%s PR) wins %s(%s GP)",
            QUICKEPGP.getCharacterString(
              QUICKEPGP.guildMemberLevel(highestRoller),
              QUICKEPGP.guildMemberClass(highestRoller),
              highestRoller
            ),
            QUICKEPGP.guildMemberPR(highestRoller),
            currentItem,
            cost
          ),
          "RAID_WARNING"
        )
        SendChatMessage(
          format(
            "%s (%s PR) wins %s(%s GP)",
            QUICKEPGP.getCharacterString(
              QUICKEPGP.guildMemberLevel(highestRoller),
              QUICKEPGP.guildMemberClass(highestRoller),
              highestRoller
            ),
            QUICKEPGP.guildMemberPR(highestRoller),
            currentItem,
            cost
          ),
          "OFFICER"
        )
        GuildRosterSetOfficerNote(
          QUICKEPGP.guildMemberIndex(highestRoller),
          (QUICKEPGP.guildMemberEP(highestRoller) or QUICKEPGP.MINIMUM_EP) ..
            "," .. ((QUICKEPGP.guildMemberGP(highestRoller) + cost) or QUICKEPGP.MINIMUM_GP)
        )
      else
        SendChatMessage(format("Everyone passed on %s(%s GP)", currentItem, cost), "RAID_WARNING")
        SendChatMessage(format("Everyone passed on %s(%s GP)", currentItem, cost), "OFFICER")
      end
    end
  end
  local message = "CRF" .. DELIMITER .. (currentItem or EMPTY) .. DELIMITER .. (highestRoller or EMPTY)
  QUICKEPGP.LIBS:SendCommMessage(MODULE_NAME, message, "RAID", nil, "ALERT")
  if QUICKEPGP.ROLLING.TrackedItem and QUICKEPGP.ROLLING.TrackedItem.Link == currentItem then
    QUICKEPGP.ROLLING.TrackedItem:SetWinner(highestRoller)
  end
  QUICKEPGP.ROLLING.TrackedItem = nil
  QUICKEPGP:CloseRollFrame()
  clearRollData()
end

local handleRollFrameEvent = function(module, message, distribution, _)
  if (module ~= MODULE_NAME) then
    return
  end
  if (distribution == "RAID") then
    local event, param1, param2 = strsplit(DELIMITER, message)
    if (event == "ORF" and not rolling) then
      QUICKEPGP:OpenRollFrame(true)
      setCurrentItem(param1)
      setHighestRoller(param2)
    elseif (event == "CRF") then
      if UnitIsUnit("player", param2) then
        local soundFile = QUICKEPGP.SOUNDS[QUICKEPGP_OPTIONS.ROLLING.winSound]
        if soundFile then
          PlaySoundFile(soundFile, "Master")
        end
      end
      if not rolling then
        QUICKEPGP:CloseRollFrame()
        clearRollData()
      end
    elseif (event == "URF" and not rolling) then
      setCurrentItem(param1)
      setHighestRoller(param2)
    elseif (event == "RN" and rolling) then
      handleNeeding(param1)
    elseif (event == "RP" and rolling) then
      handlePassing(param1)
    end
  end
end

local function onUpdate()
  local now = GetTime()
  if (not rolling) then
    last = now
    return
  end
  if (now - last >= ANNOUNCE_TIME) then
    if (rolling and currentItem) then
      local cost = QUICKEPGP.getItemGP(QUICKEPGP.getItemId(currentItem))
      if (highestRoller) then
        SendChatMessage(
          format(
            "...still rolling on %s(%s GP) [%s (%s PR)]",
            currentItem,
            cost,
            QUICKEPGP.getCharacterString(
              QUICKEPGP.guildMemberLevel(highestRoller),
              QUICKEPGP.guildMemberClass(highestRoller),
              highestRoller
            ),
            QUICKEPGP.guildMemberPR(highestRoller)
          ),
          "RAID"
        )
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

function QUICKEPGP.ROLLING:EndRolling(cancel)
  if rolling then
    endRolling(cancel)
  end
end

QUICKEPGP.handleRolling = function(event, command, author)
  if (rolling) then
    if (event == "CHAT_MSG_RAID" or event == "CHAT_MSG_RAID_LEADER") then
      if (command == "need") then
        return handleNeeding(author)
      end
      if (command == "pass") then
        return handlePassing(author)
      end
      if (command == "end" and UnitIsUnit("player", author)) then
        return endRolling()
      end
    end
    if (event == "CHAT_MSG_WHISPER") then
      if (QUICKEPGP.GUILD:GetMemberInfo(author)) then
        if (command == "need") then
          return handleNeeding(author)
        end
        if (command == "pass") then
          return handlePassing(author)
        end
      end
    end
  end
end

QUICKEPGP.startRolling = function(itemId, itemLink)
  if CanEditOfficerNote() then
    local raidMember = QUICKEPGP.raidMember(UnitName("player"))
    if (raidMember and raidMember[2] > 0) then
      if rolling then
        endRolling()
      end
      local cost = QUICKEPGP.getItemGP(itemId)
      if (cost) then
        SendChatMessage(format("Starting rolls on %s(%s GP)", itemLink, cost), "RAID_WARNING")
        SendChatMessage(format("Type NEED or PASS"), "RAID")
        last = GetTime()
        rolling = true
        rollTable = {}
        QUICKEPGP:OpenRollFrame(true)
        setCurrentItem(itemLink)
        clearHighestRoller()
        QUICKEPGP.LIBS:SendCommMessage(
          MODULE_NAME,
          "ORF" .. DELIMITER .. itemLink .. DELIMITER .. (highestRoller or EMPTY),
          "RAID",
          nil,
          "ALERT"
        )
      end
    end
  end
end

QUICKEPGP.distributeItem = function(message, type)
  local hasPlayer = select(4, strfind(message, "|c(.+)|r(.+)"))
  if (hasPlayer) then
    local player = strtrim(hasPlayer)
    if (QUICKEPGP.guildMemberIndex(player)) then
      local itemStrings = "|c" .. select(3, strfind(message, "|c(.+)|r")) .. "|r"
      local itemParts = {strsplit("|", itemStrings)}
      local count = table.getn(itemParts) - 1
      if (count < 6) then
        local itemId = select(3, strfind(itemStrings, ":(%d+):"))
        if (itemId) then
          if (type == QUICKEPGP.ADD) then
            QUICKEPGP.modifyEPGP(player, nil, (QUICKEPGP.getItemGP(itemId) or 0), itemStrings, false)
          elseif (type == QUICKEPGP.MINUS) then
            QUICKEPGP.modifyEPGP(player, nil, (-QUICKEPGP.getItemGP(itemId) or 0), itemStrings, false)
          end
        end
      end
    end
  end
end

QUICKEPGP.ROLLING:SetScript("OnUpdate", onUpdate)
QUICKEPGP.LIBS:RegisterComm(MODULE_NAME, handleRollFrameEvent)
