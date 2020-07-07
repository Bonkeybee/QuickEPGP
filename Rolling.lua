QUICKEPGP.ROLLING = CreateFrame("Frame")
local MODULE_NAME = "QEPGP-Rolling"

local ANNOUNCE_TIME = 20
local DELIMITER = ";"
local EMPTY = ""

local LEVEL_INDEX = 1
local CLASS_INDEX = 2
local EP_INDEX = 3
local GP_INDEX = 4

local rolling = false
local rollTable = {}
local highestRoller = nil
local currentItem = nil
local currentCost = nil
local iNeed = false
local iPass = false

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

local function updateRollFrame()
  if QuickEPGProllFrame then
    local str = "|cFFFFFF00Rolling|r"
    if (iNeed) then
      str = "|cFF00FF00Needing|r"
    end
    if (iPass) then
      str = "|cFFFF0000Passing|r"
    end
    if currentItem then
      QuickEPGProllFrame.Title:SetText(str.." on "..currentItem.." |cFFFFFF00("..currentCost.." GP)|r")
    else
      QuickEPGProllFrame.Title:SetText(" ")
    end
    if (highestRoller and highestRoller ~= EMPTY) then
      QuickEPGProllFrame.Status:SetText(QUICKEPGP.colorByClass(highestRoller, QUICKEPGP.raidMemberClass(highestRoller)).." |cFFFFFF00("..QUICKEPGP.guildMemberPR(highestRoller).." PR)|r |cFFFF0000["..QUICKEPGP.guildMemberPR(highestRoller, true, currentCost).." PR]|r")
    else
      QuickEPGProllFrame.Status:SetText(nil)
    end

    if (currentItem) then
      local btn = QuickEPGProllFrame.LootButton
      local _, _, _, _, _, _, _, _, _, texture = GetItemInfo(currentItem);
      QuickEPGProllFrame.Picture.Texture:SetTexture(texture)
    else
      QuickEPGProllFrame.Picture.Texture:SetTexture(nil)
    end

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

local function handleNeeding(player)
  if (validateRoll(player)) then
    if (not rollTable[player]) then
      SendChatMessage(format("%s needed (%s PR)", QUICKEPGP.getCharacterString(QUICKEPGP.guildMemberLevel(player), QUICKEPGP.guildMemberClass(player), player), QUICKEPGP.guildMemberPR(player)), "RAID")
    end
    rollTable[player] = {QUICKEPGP.guildMemberLevel(player), QUICKEPGP.guildMemberClass(player), QUICKEPGP.guildMemberEP(player), QUICKEPGP.guildMemberGP(player)}
    highestRoller = QUICKEPGP.comparePR(highestRoller, player, rollTable)
    updateRollFrame()
  end
  QUICKEPGP.LIBS:SendCommMessage(MODULE_NAME, "URF"..DELIMITER..(currentItem or EMPTY)..DELIMITER..(highestRoller or EMPTY), "RAID", nil, "ALERT")
end

local function handlePassing(player)
  if (validateRoll(player)) then
    if (rollTable[player]) then
      SendChatMessage(format("%s passed", QUICKEPGP.getCharacterString(QUICKEPGP.guildMemberLevel(player), QUICKEPGP.guildMemberClass(player), player)), "RAID")
    end
    rollTable[player] = nil
    highestRoller = findHighestRoller(rollTable)
    updateRollFrame()
  end
  QUICKEPGP.LIBS:SendCommMessage(MODULE_NAME, "URF"..DELIMITER..(currentItem or EMPTY)..DELIMITER..(highestRoller or EMPTY), "RAID", nil, "ALERT")
end

local function clearRollData()
  rolling = false
  rollTable = {}
  highestRoller = nil
  currentItem = nil
  currentCost = nil
  iNeed = false
  iPass = false
end

local function closeRollFrame()
  if QuickEPGProllFrame then
    QuickEPGProllFrame:Hide()
  end
  --clearRollData()
end

local function endRolling()
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
  closeRollFrame()
  clearRollData()
  QUICKEPGP.LIBS:SendCommMessage(MODULE_NAME, "CRF"..DELIMITER..(currentItem or EMPTY)..DELIMITER..(highestRoller or EMPTY), "RAID", nil, "ALERT")
end

local function openRollFrame()
  PlaySoundFile("Interface\\AddOns\\QuickEPGP\\Sounds\\whatcanidoforya.ogg", "Master")
  if QuickEPGProllFrame then
    QuickEPGProllFrame:Show()
    updateRollFrame()
    return
  end

  local rollFrame = CreateFrame("Frame", "QuickEPGProllFrame", UIParent)
  QuickEPGProllFrame = rollFrame
  tinsert(UISpecialFrames, "QuickEPGProllFrame")
  rollFrame:SetFrameStrata("DIALOG")
  rollFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", -- 131071
    tile = true,
    tileSize = 16
  })
  local width = 231
  rollFrame:SetPoint(QUICKEPGP_OPTIONS.RollFrame.Point, UIParent, QUICKEPGP_OPTIONS.RollFrame.Point, QUICKEPGP_OPTIONS.RollFrame.X, QUICKEPGP_OPTIONS.RollFrame.Y)
  rollFrame:SetSize(width, 46)
  rollFrame:SetClampedToScreen(true)
  rollFrame:EnableMouse(true)
  rollFrame:SetToplevel(true)
  rollFrame:SetMovable(true)
  rollFrame:RegisterForDrag("LeftButton")
  rollFrame:SetScript("OnDragStart", function(self)
    self:StartMoving()
  end)
  rollFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint(1)
    QUICKEPGP_OPTIONS.RollFrame.X = x
    QUICKEPGP_OPTIONS.RollFrame.Y = y
    QUICKEPGP_OPTIONS.RollFrame.Point = point
  end)

  local title = rollFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
  title:SetWidth(width * 2)
  title:SetHeight(12)
  title:SetPoint("BOTTOMLEFT", rollFrame, "TOPLEFT", 1, 1)
  title:SetTextColor(1, 1, 1, 1)
  title:SetText(" ")
  title:Show()
  rollFrame.Title = title

  local topRoller = rollFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
  topRoller:SetWidth(width * 2)
  topRoller:SetHeight(12)
  topRoller:SetPoint("TOPLEFT", rollFrame, "BOTTOMLEFT", 1, 1)
  topRoller:SetTextColor(1, 1, 1, 1)
  topRoller:SetText(" ")
  topRoller:Show()
  rollFrame.Status = topRoller

  local pictureFrame = CreateFrame("Frame", nil, rollFrame)
  pictureFrame:SetSize(40, 40)
  pictureFrame:SetPoint("BOTTOMLEFT", rollFrame, "BOTTOMLEFT", 4, 4)
  pictureFrame:Show()
  pictureFrame:EnableMouse(true)
  pictureFrame:RegisterForDrag("LeftButton")
  pictureFrame:SetScript("OnDragStart", function(self)
    QuickEPGProllFrame:StartMoving()
  end)
  pictureFrame:SetScript("OnDragStop", function(self)
    QuickEPGProllFrame:StopMovingOrSizing()
    local point, _, _, x, y = QuickEPGProllFrame:GetPoint(1)
    QUICKEPGP_OPTIONS.RollFrame.X = x
    QUICKEPGP_OPTIONS.RollFrame.Y = y
    QUICKEPGP_OPTIONS.RollFrame.Point = point
  end)
  pictureFrame:SetScript("OnEnter", function(self)
    if currentItem then
    GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
    GameTooltip:SetHyperlink(currentItem)
    GameTooltip:Show()
  end end)
  pictureFrame:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)
  local pictureTexture = pictureFrame:CreateTexture(nil, "BACKGROUND")
  pictureTexture:SetAllPoints()
  pictureFrame.Texture = pictureTexture
  rollFrame.Picture = pictureFrame

  local needButton = CreateFrame("Button", nil, rollFrame, "UIPanelButtonTemplate")
  needButton:SetSize(100, 42)
  needButton:SetText("NEED")
  needButton:SetPoint("BOTTOMLEFT", rollFrame, "BOTTOMLEFT", 44, 3)
  needButton:Show()
  needButton:SetScript("OnClick", function()
    iNeed = true
    iPass = false
    QUICKEPGP.LIBS:SendCommMessage(MODULE_NAME, "RN"..DELIMITER..UnitName("player"), "RAID", nil, "ALERT")
  end)

  local passButton = CreateFrame("Button", nil, rollFrame, "UIPanelButtonTemplate")
  passButton:SetSize(50, 42)
  passButton:SetText("PASS")
  passButton:SetPoint("BOTTOMLEFT", rollFrame, "BOTTOMLEFT", 144, 3)
  passButton:Show()
  passButton:SetScript("OnClick", function()
    iPass = true
    iNeed = false
    QUICKEPGP.LIBS:SendCommMessage(MODULE_NAME, "RP"..DELIMITER..UnitName("player"), "RAID", nil, "ALERT")
  end)

  local closeButton = CreateFrame("Button", nil, rollFrame, "UIPanelButtonTemplate")
  closeButton:SetSize(25, 42)
  closeButton:SetText("X")
  closeButton:SetPoint("BOTTOMLEFT", rollFrame, "BOTTOMLEFT", 194, 3)
  closeButton:Show()
  closeButton:SetScript("OnClick", function()
    closeRollFrame()
  end)
end

local handleRollFrameEvent = function(module, message, distribution, author)
  if (module ~= MODULE_NAME) then
    return
  end
  if (distribution == "RAID") then
    local event = strsplit(DELIMITER, message)
    if (event == "ORF" and not rolling) then
      local _, ci, hr = strsplit(DELIMITER, message)
      if (ci and ci ~= EMPTY) then
        currentItem = ci
      end
      if (hr and hr ~= EMPTY) then
        highestRoller = hr
      end
      openRollFrame()
    elseif (event == "CRF" and not rolling) then
      local _, ci, hr = strsplit(DELIMITER, message)
      if (ci and ci ~= EMPTY) then
        currentItem = ci
      end
      if (hr and hr ~= EMPTY) then
        highestRoller = hr
      end
      closeRollFrame()
      clearRollData()
    elseif (event == "URF" and not rolling) then
      local _, ci, hr = strsplit(DELIMITER, message)
      currentItem = ci
      highestRoller = hr
      updateRollFrame()
    elseif (event == "RN" and rolling) then
      local _, player = strsplit(DELIMITER, message)
      handleNeeding(player)
    elseif (event == "RP" and rolling) then
      local _, player = strsplit(DELIMITER, message)
      handlePassing(player)
    end
  end
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
      if (QUICKEPGP.guildMember(author)) then
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
      endRolling()
      local cost = QUICKEPGP.getItemGP(itemId)
      if (cost) then
        SendChatMessage(format("starting rolls on %s(%s GP)", itemLink, cost), "RAID_WARNING")
        SendChatMessage(format("type NEED or PASS"), "RAID")
        rolling = true
        rollTable = {}
        highestRoller = nil
        currentItem = itemLink
        currentCost = cost
        openRollFrame()
        QUICKEPGP.LIBS:SendCommMessage(MODULE_NAME, "ORF"..DELIMITER..itemLink..DELIMITER..(highestRoller or EMPTY), "RAID", nil, "ALERT")
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

QUICKEPGP.openMasterFrame = function()

  if QuickEPGPMasterLootFrame then
    QuickEPGPMasterLootFrame:Show()
    return
  end

  local textFrame = CreateFrame("Frame", "QuickEPGPMasterLootFrame", UIParent)
  QuickEPGPMasterLootFrame = textFrame
  textFrame:SetFrameStrata("DIALOG")
  textFrame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", -- 131071
    tile = true,
    tileSize = 16
  })

  local size = 110
  textFrame:SetPoint(QUICKEPGP_OPTIONS.MasterFrame.Point, UIParent, QUICKEPGP_OPTIONS.MasterFrame.Point, QUICKEPGP_OPTIONS.MasterFrame.X, QUICKEPGP_OPTIONS.MasterFrame.Y)
  textFrame:SetSize(size, size)
  textFrame:SetClampedToScreen(true)
  textFrame:EnableMouse(true)
  textFrame:SetToplevel(true)
  textFrame:SetMovable(true)
  textFrame:RegisterForDrag("LeftButton")
  textFrame:SetScript("OnDragStart", function(self)
    self:StartMoving()
  end)
  textFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, _, x, y = self:GetPoint(1)
    QUICKEPGP_OPTIONS.MasterFrame.X = x
    QUICKEPGP_OPTIONS.MasterFrame.Y = y
    QUICKEPGP_OPTIONS.MasterFrame.Point = point
  end)

  local padding = 4
  local text = textFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
  text:SetWidth(size)
  text:SetHeight(size)
  text:SetPoint("TOPLEFT", textFrame, "TOPLEFT", padding, padding)
  text:SetPoint("BOTTOMRIGHT", textFrame, "BOTTOMRIGHT", - padding, - padding)
  text:SetTextColor(1, 1, 1, 1)
  text:SetText("DRAG ITEM TO START ROLL\n\n\n\n\nCLICK TO END")
  text:Show()
  textFrame.text = text

  textFrame:SetScript("OnMouseUp", function(_, button)
    local type, itemId, itemLink = GetCursorInfo()

    if type == "item" and itemId and itemLink then
      QUICKEPGP.startRolling(itemId, itemLink)
      ClearCursor()
    elseif not type and rolling then
      endRolling()
    end
  end)
end

QUICKEPGP.closeMasterFrame = function()
  local frame = QuickEPGPMasterLootFrame
  if frame then
    frame:Hide()
  end
end

QUICKEPGP.toggleMasterFrame = function()
  if QuickEPGPMasterLootFrame and QuickEPGPMasterLootFrame:IsShown() then
    QUICKEPGP.closeMasterFrame()
  else
    QUICKEPGP.openMasterFrame()
  end
end

QUICKEPGP.toggleRollFrame = function()
  if QuickEPGProllFrame and QuickEPGProllFrame:IsShown() then
    closeRollFrame()
  else
    openRollFrame()
  end
end

QUICKEPGP.ROLLING:SetScript("OnUpdate", onUpdate)
QUICKEPGP.LIBS:RegisterComm(MODULE_NAME, handleRollFrameEvent)
