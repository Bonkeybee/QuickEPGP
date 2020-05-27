QUICKEPGP.ROLLING = CreateFrame("Frame")
local MODULE_NAME = "QuickEPGP-Rolling"

local ANNOUNCE_TIME = 20
local DELIMITER = ":"
local EMPTY = ""

local LEVEL_INDEX = 1
local CLASS_INDEX = 2
local EP_INDEX = 3
local GP_INDEX = 4

local rolling = false
local rollTable = {}
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

local function updateRollFrame(rollFrame)
  if (not rollFrame) then
    rollFrame = _G["QuickEPGProllFrame"]
  end
  rollFrame:SetTitle("Rolling on "..currentItem)
  if (highestRoller) then
    rollFrame:SetStatusText(highestRoller.." ("..QUICKEPGP.guildMemberPR(highestRoller)..")")
  else
    rollFrame:SetStatusText(nil)
  end
end

local function validateRoll(player)
  if (not QUICKEPGP.raidMember(player)) then
    QUICKEPGP.error("Skipping "..(player or EMPTY).."'s need roll: not in raid")
    return false
  end
  if (not QUICKEPGP.guildMember(player)) then
    --TODO can remove once EPGP is desegregated
    QUICKEPGP.error("Skipping "..(player or EMPTY).."'s need roll: not in guild")
    return false
  end
  return true
end

local function handleNeeding(player, rollFrame)
  if (validateRoll(player)) then
    if (not rollTable[player]) then
      SendChatMessage(format("%s needed (%s PR)", QUICKEPGP.getCharacterString(QUICKEPGP.guildMemberLevel(player), QUICKEPGP.guildMemberClass(player), player), QUICKEPGP.guildMemberPR(player)), "RAID")
    end
    rollTable[player] = {QUICKEPGP.guildMemberLevel(player), QUICKEPGP.guildMemberClass(player), QUICKEPGP.guildMemberEP(player), QUICKEPGP.guildMemberGP(player)}
    highestRoller = QUICKEPGP.comparePR(highestRoller, player, rollTable)
    updateRollFrame(rollFrame)
  end
end

local function handlePassing(player, rollFrame)
  if (validateRoll(player)) then
    if (rollTable[player]) then
      SendChatMessage(format("%s passed", QUICKEPGP.getCharacterString(QUICKEPGP.guildMemberLevel(player), QUICKEPGP.guildMemberClass(player), player)), "RAID")
    end
    rollTable[player] = nil
    highestRoller = findHighestRoller(rollTable)
    updateRollFrame(rollFrame)
  end
end

local function clearRollData()
  rolling = false
  rollTable = {}
  highestRoller = nil
  currentItem = nil
end

local function closeRollFrame()
  if (_G["QuickEPGProllFrame"]) then
    _G["QuickEPGProllFrame"]:Hide()
    _G["QuickEPGProllFrame"] = nil
  end
end

local function endRolling(rollFrame)
  local itemId = QUICKEPGP.getItemId(currentItem)
  if (itemId) then
    local cost = QUICKEPGP.getItemGP(itemId)
    if (cost) then
      if (highestRoller) then
        SendChatMessage(format("%s (%s PR) wins %s(%s GP)", QUICKEPGP.getCharacterString(QUICKEPGP.guildMemberLevel(highestRoller), QUICKEPGP.guildMemberClass(highestRoller), highestRoller), QUICKEPGP.guildMemberPR(highestRoller), currentItem, cost), "RAID_WARNING")
        SendChatMessage(format("%s (%s PR) wins %s(%s GP)", QUICKEPGP.getCharacterString(QUICKEPGP.guildMemberLevel(highestRoller), QUICKEPGP.guildMemberClass(highestRoller), highestRoller), QUICKEPGP.guildMemberPR(highestRoller), currentItem, cost), "OFFICER")
        GuildRosterSetOfficerNote(QUICKEPGP.guildMemberIndex(highestRoller), (QUICKEPGP.guildMemberEP(highestRoller) or QUICKEPGP.MINIMUM_EP)..","..((QUICKEPGP.guildMemberGP(highestRoller) + cost) or QUICKEPGP.MINIMUM_GP))
      else
        SendChatMessage(format("everyone passed on %s(%s GP)", currentItem, cost), "RAID_WARNING")
        SendChatMessage(format("everyone passed on %s(%s GP)", currentItem, cost), "OFFICER")
      end
    end
  end
  clearRollData()
  closeRollFrame()
  QUICKEPGP.LIBS:SendCommMessage(MODULE_NAME, "CRF"..DELIMITER..(currentItem or EMPTY)..DELIMITER..(highestRoller or EMPTY), "RAID", nil, "ALERT")
end

local function openRollFrame()
  local rollFrame = QUICKEPGP.LIBS.GUI:Create("Frame")
  _G["QuickEPGProllFrame"] = rollFrame.frame
  tinsert(UISpecialFrames, "QuickEPGProllFrame")
  rollFrame:SetCallback("OnClose", function(widget) QUICKEPGP.LIBS.GUI:Release(widget) end)
  rollFrame:EnableResize(false)
  rollFrame:SetLayout("Flow")
  rollFrame:SetWidth(294)
  rollFrame:SetHeight(92)
  updateRollFrame(rollFrame)

  local btn1 = QUICKEPGP.LIBS.GUI:Create("Button")
  btn1:SetCallback("OnClick", function()
    handleNeeding(UnitName("player"), rollFrame)
  end)
  btn1:SetText("NEED")
  btn1:SetWidth(125)
  rollFrame:AddChild(btn1)

  local btn2 = QUICKEPGP.LIBS.GUI:Create("Button")
  btn2:SetCallback("OnClick", function()
    handlePassing(UnitName("player"), rollFrame)
  end)
  btn2:SetText("PASS")
  btn2:SetWidth(125)
  rollFrame:AddChild(btn2)
end

local last = GetTime()
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
        SendChatMessage(format("...still rolling on %s(%s GP) [%s (%s PR)]", currentItem, cost, QUICKEPGP.getCharacterString(QUICKEPGP.guildMemberLevel(highestRoller), QUICKEPGP.guildMemberClass(highestRoller), highestRoller), QUICKEPGP.guildMemberPR(highestRoller)), "RAID")
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
  endRolling()
  local player = UnitName("player")
  if (player == author) then
    local hasItemString = select(3, strfind(message, "|c(.+)|r"))
    if (hasItemString and QUICKEPGP.raidMember(player)) then
      local rank = QUICKEPGP.raidMember(player)[1]
      local channel = "RAID"
      if (rank > 0) then
        channel = "RAID_WARNING"
      end
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
              rolling = true
              rollTable = {}
              highestRoller = nil
              currentItem = itemStrings
              --openRollFrame()
              QUICKEPGP.LIBS:SendCommMessage(MODULE_NAME, "ORF"..DELIMITER..currentItem..DELIMITER..(highestRoller or EMPTY), "RAID", nil, "ALERT")
            end
          end
        end
      end
    end
  end
end

QUICKEPGP.distributeItem = function(message, type)
  local hasPlayer = select(4, strfind(message, "|c(.+)|r(.+)"))
  if (hasPlayer) then
    local player = strtrim(hasPlayer)
    if (QUICKEPGP.guildMemberIndex(player)) then
      local itemStrings = "|c"..select(3, strfind(message, "|c(.+)|r")).."|r"
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
