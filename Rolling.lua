QUICKEPGP.ROLLING = CreateFrame("Frame")
local MODULE_NAME = "QEPGP-Rolling"

local ANNOUNCE_TIME = 20
local DELIMITER = ";"
local EMPTY = ""

local LEVEL_INDEX = 1
local CLASS_INDEX = 2
local EP_INDEX = 3
local GP_INDEX = 4

local last = GetTime()
local rolling = false
local rollTable = {}
local highestRoller = nil
local currentItem = nil
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

local function clearCurrentItem()
  currentItem = nil

  if QuickEPGProllFrame then
    QuickEPGProllFrame.Title:SetText(" ")
    QuickEPGProllFrame.Picture.Texture:SetTexture(nil)
  end

  if (QuickEPGPMasterLootFrame and QuickEPGPMasterLootFrame.Dropper and QuickEPGPMasterLootFrame.Dropper.Texture) then
    QuickEPGPMasterLootFrame.Dropper.Texture:SetTexture(nil)
    QuickEPGPMasterLootFrame.Dropper.Text:Show()
  end
end

local function setCurrentItem(itemLink)
  if itemLink then
    currentItem = itemLink
    local item = Item:CreateFromItemLink(itemLink)
    item:ContinueOnItemLoad(function()
      local texture = item:GetItemIcon()

      if QuickEPGProllFrame then
        local str = "|cFFFFFF00Rolling|r"
        if (iNeed) then
          str = "|cFF00FF00Needing|r"
        end
        if (iPass) then
          str = "|cFFFF0000Passing|r"
        end
        local cost = QUICKEPGP.getItemGP(QUICKEPGP.getItemId(currentItem))
        QuickEPGProllFrame.Title:SetText(str.." on "..currentItem.." |cFFFFFF00("..cost.." GP)|r")
        QuickEPGProllFrame.Picture.Texture:SetTexture(texture)
      end
      if (QuickEPGPMasterLootFrame and QuickEPGPMasterLootFrame.Dropper and QuickEPGPMasterLootFrame.Dropper.Texture) then
        QuickEPGPMasterLootFrame.Dropper.Texture:SetTexture(texture)
      end
    end)
  else
    clearCurrentItem()
    QUICKEPGP.error("QUICKEPGP::Invalid itemId "..(itemLink or EMPTY))
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
      QuickEPGProllFrame.Status:SetText(QUICKEPGP.colorByClass(highestRoller, QUICKEPGP.raidMemberClass(highestRoller)).." |cFFFFFF00("..QUICKEPGP.guildMemberPR(highestRoller).." PR)|r |cFFFF0000["..QUICKEPGP.guildMemberPR(highestRoller, true, cost).." PR]|r")
    else
      clearHighestRoller()
    end
  end
end

local function validateRoll(player)
  if (not QUICKEPGP.raidMember(player)) then
    QUICKEPGP.error("Skipping "..(player or EMPTY).."'s need roll: not in raid")
    return false
  end
  if (not QUICKEPGP.guildMember(player)) then
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
    setHighestRoller(QUICKEPGP.comparePR(highestRoller, player, rollTable))
  end
  QUICKEPGP.LIBS:SendCommMessage(MODULE_NAME, "URF"..DELIMITER..(currentItem or EMPTY)..DELIMITER..(highestRoller or EMPTY), "RAID", nil, "ALERT")
end

local function handlePassing(player)
  if (validateRoll(player)) then
    if (rollTable[player]) then
      SendChatMessage(format("%s passed", QUICKEPGP.getCharacterString(QUICKEPGP.guildMemberLevel(player), QUICKEPGP.guildMemberClass(player), player)), "RAID")
    end
    rollTable[player] = nil
    setHighestRoller(findHighestRoller(rollTable))
  end
  QUICKEPGP.LIBS:SendCommMessage(MODULE_NAME, "URF"..DELIMITER..(currentItem or EMPTY)..DELIMITER..(highestRoller or EMPTY), "RAID", nil, "ALERT")
end

local function clearRollData()
  rolling = false
  rollTable = {}
  clearCurrentItem()
  clearHighestRoller()
  iNeed = false
  iPass = false
end

local function closeRollFrame()
  if QuickEPGProllFrame then
    QuickEPGProllFrame:Hide()
  end
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
        SendChatMessage(format("%s (%s PR) wins %s(%s GP)", QUICKEPGP.getCharacterString(QUICKEPGP.guildMemberLevel(highestRoller), QUICKEPGP.guildMemberClass(highestRoller), highestRoller), QUICKEPGP.guildMemberPR(highestRoller), currentItem, cost), "RAID_WARNING")
        SendChatMessage(format("%s (%s PR) wins %s(%s GP)", QUICKEPGP.getCharacterString(QUICKEPGP.guildMemberLevel(highestRoller), QUICKEPGP.guildMemberClass(highestRoller), highestRoller), QUICKEPGP.guildMemberPR(highestRoller), currentItem, cost), "OFFICER")
        GuildRosterSetOfficerNote(QUICKEPGP.guildMemberIndex(highestRoller), (QUICKEPGP.guildMemberEP(highestRoller) or QUICKEPGP.MINIMUM_EP)..","..((QUICKEPGP.guildMemberGP(highestRoller) + cost) or QUICKEPGP.MINIMUM_GP))
      else
        SendChatMessage(format("Everyone passed on %s(%s GP)", currentItem, cost), "RAID_WARNING")
        SendChatMessage(format("Everyone passed on %s(%s GP)", currentItem, cost), "OFFICER")
      end
    end
  end
  QUICKEPGP.LIBS:SendCommMessage(MODULE_NAME, "CRF"..DELIMITER..(currentItem or EMPTY)..DELIMITER..(highestRoller or EMPTY), "RAID", nil, "ALERT")
end

local function openRollFrame(automatic)
  if automatic then
    local soundFile = QUICKEPGP.SOUNDS[QUICKEPGP_OPTIONS.ROLLING.openSound]
    if soundFile then
      PlaySoundFile(soundFile, "Master")
    end
  end

  if QuickEPGProllFrame then
    QuickEPGProllFrame:Show()
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
  pictureFrame:SetScript("OnMouseUp", function()
    if currentItem and IsControlKeyDown() then
    DressUpItemLink(currentItem)
  end end)
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
    local event, param1, param2 = strsplit(DELIMITER, message)
    if (event == "ORF" and not rolling) then
      openRollFrame(true)
      setCurrentItem(param1)
      setHighestRoller(param2)
    elseif (event == "CRF") then
      if UnitIsUnit("player", param2) then
        local soundFile = QUICKEPGP.SOUNDS[QUICKEPGP_OPTIONS.ROLLING.winSound]
        if soundFile then
          PlaySoundFile(soundFile, "Master")
        end
      end
      closeRollFrame()
      clearRollData()
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
        openRollFrame(true)
        setCurrentItem(itemLink)
        clearHighestRoller()
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
  if not QuickEPGPMasterLootFrame then
    QuickEPGPMasterLootFrame = CreateFrame("Frame", "QuickEPGPMasterLootFrame", UIParent)
    QuickEPGPMasterLootFrame:SetFrameStrata("DIALOG")
    QuickEPGPMasterLootFrame:SetSize(72, 150)
    QuickEPGPMasterLootFrame:SetPoint(QUICKEPGP_OPTIONS.MasterFrame.Point, UIParent, QUICKEPGP_OPTIONS.MasterFrame.Point, QUICKEPGP_OPTIONS.MasterFrame.X, QUICKEPGP_OPTIONS.MasterFrame.Y)
    QuickEPGPMasterLootFrame:SetClampedToScreen(true)
    QuickEPGPMasterLootFrame:EnableMouse(true)
    QuickEPGPMasterLootFrame:SetToplevel(true)
    QuickEPGPMasterLootFrame:SetMovable(true)
    QuickEPGPMasterLootFrame:RegisterForDrag("LeftButton")
    QuickEPGPMasterLootFrame:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", -- 131071
      tile = true,
      tileSize = 16
    })
    QuickEPGPMasterLootFrame:SetScript("OnDragStart", function(self)
      self:StartMoving()
    end)
    QuickEPGPMasterLootFrame:SetScript("OnDragStop", function(self)
      self:StopMovingOrSizing()
      local point, _, _, x, y = self:GetPoint(1)
      QUICKEPGP_OPTIONS.MasterFrame.X = x
      QUICKEPGP_OPTIONS.MasterFrame.Y = y
      QUICKEPGP_OPTIONS.MasterFrame.Point = point
    end)

    local padding = 4
    local dropper = CreateFrame("Frame", nil, QuickEPGPMasterLootFrame)
    QuickEPGPMasterLootFrame.Dropper = dropper
    dropper:SetSize(64, 64)
    dropper:SetPoint("TOPRIGHT", QuickEPGPMasterLootFrame, "TOPRIGHT", - padding, - padding)
    dropper:SetBackdrop({
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      edgeSize = 16,
      tile = true,
      tileSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    dropper:SetScript("OnMouseUp", function()
      if IsControlKeyDown() then
      if currentItem then
        DressUpItemLink(currentItem)
      end
    else
      local type, itemId, itemLink = GetCursorInfo()

      if type == "item" and itemId and itemLink then
        QUICKEPGP.startRolling(itemId, itemLink)
        ClearCursor()
      end
    end end)
    dropper.Texture = dropper:CreateTexture(nil, "BACKGROUND")
    dropper.Texture:SetAllPoints()
    dropper:SetScript("OnEnter", function(self)
      if currentItem then
      GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
      GameTooltip:SetHyperlink(currentItem)
      GameTooltip:Show()
    end end)
    dropper:SetScript("OnLeave", function(self)
      GameTooltip:Hide()
    end)

    local dropText = QuickEPGPMasterLootFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    dropper.Text = dropText
    dropText:SetSize(64, 64)
    dropText:SetPoint("TOPLEFT", dropper, "TOPLEFT", padding, - padding)
    dropText:SetTextColor(1, 1, 1, 1)
    dropText:SetText("DROP HERE TO START ROLL")

    local endButton = CreateFrame("Button", nil, QuickEPGPMasterLootFrame, "UIPanelButtonTemplate")
    endButton:SetText("END")
    endButton:SetPoint("TOP", dropper, "BOTTOM", 0, - padding)
    endButton:SetPoint("LEFT", dropper, "LEFT")
    endButton:SetPoint("RIGHT", dropper, "RIGHT")
    endButton:SetScript("OnClick", function()
      if rolling then
      endRolling()
    end end)

    local cancelButton = CreateFrame("Button", nil, QuickEPGPMasterLootFrame, "UIPanelButtonTemplate")
    cancelButton:SetText("CANCEL")
    cancelButton:SetPoint("TOP", endButton, "BOTTOM", 0, - padding)
    cancelButton:SetPoint("LEFT", endButton, "LEFT")
    cancelButton:SetPoint("RIGHT", endButton, "RIGHT")
    cancelButton:SetScript("OnClick", function()
      if rolling then
      endRolling(true)
    end end)

    local toggleManualButton = CreateFrame("Button", nil, QuickEPGPMasterLootFrame, "UIPanelButtonTemplate")
    toggleManualButton:SetText("Manual")
    toggleManualButton:SetPoint("BOTTOM", 0, padding)
    toggleManualButton:SetPoint("LEFT", dropper, "LEFT")
    toggleManualButton:SetPoint("RIGHT", dropper, "RIGHT")
    toggleManualButton:SetScript("OnClick", function()
      if QuickEPGPMasterLootFrame.Manual:IsShown() then
      QuickEPGPMasterLootFrame.Manual:Hide()
      QuickEPGPMasterLootFrame:SetWidth(72)
    else
      QuickEPGPMasterLootFrame.Manual:Show()
      QuickEPGPMasterLootFrame:SetWidth(300)
    end end)

    local manualFrame = CreateFrame("Frame", nil, QuickEPGPMasterLootFrame)
    QuickEPGPMasterLootFrame.Manual = manualFrame
    manualFrame:SetPoint("RIGHT", dropper, "LEFT", - padding, - padding)
    manualFrame:SetPoint("LEFT", padding, padding)
    manualFrame:SetPoint("TOP", - padding, - padding)
    manualFrame:SetPoint("BOTTOM", padding, padding)
    manualFrame:SetBackdrop({
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      edgeSize = 16,
      tile = true,
      tileSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })

    local manualHeader = manualFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    manualHeader:SetPoint("TOPLEFT", manualFrame, "TOPLEFT", padding * 2, - padding * 2)
    manualHeader:SetTextColor(1, 1, 1, 1)
    manualHeader:SetText("MANUAL EDIT:\n\nPlayer:")

    local nameBox = CreateFrame("EditBox", nil, manualFrame, "InputBoxTemplate")
    manualFrame.NameBox = nameBox
    nameBox:SetFontObject(ChatFontNormal)
    nameBox:ClearAllPoints() --bugfix
    nameBox:SetPoint("TOPLEFT", manualHeader, "BOTTOMLEFT", 0, - padding)
    nameBox:SetPoint("BOTTOMRIGHT", manualHeader, "BOTTOMRIGHT", 0, - padding - 22)
    nameBox:SetAutoFocus(false)

    local targetButton = CreateFrame("Button", nil, manualFrame, "UIPanelButtonTemplate")
    targetButton:SetPoint("TOP", nameBox, "TOP")
    targetButton:SetPoint("BOTTOM", nameBox, "BOTTOM")
    targetButton:SetPoint("LEFT", nameBox, "RIGHT")
    targetButton:SetText("Target")
    targetButton:SetScript("OnClick", function()
      QuickEPGPMasterLootFrame.Manual.NameBox:SetText(UnitName("target"))
    end)

    local valueHeader = manualFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    valueHeader:SetPoint("TOP", nameBox, "BOTTOM", 0, 0)
    valueHeader:SetPoint("LEFT", manualHeader, "LEFT", 0, 0)
    valueHeader:SetTextColor(1, 1, 1, 1)
    valueHeader:SetText("Amount:")

    local gpCheckBox = CreateFrame("CheckButton", "MLGPCheckbox", manualFrame, "UIRadioButtonTemplate")
    manualFrame.GPBox = gpCheckBox
    gpCheckBox:SetPoint("TOP", valueHeader, "BOTTOM", - padding, - padding)
    gpCheckBox:SetPoint("RIGHT", manualFrame, - padding - padding - 16, - padding)
    gpCheckBox:SetChecked(true)
    _G[gpCheckBox:GetName() .. "Text"]:SetText("GP")
    gpCheckBox:HookScript("OnClick", function(self)
      QuickEPGPMasterLootFrame.Manual.EPBox:SetChecked(not self:GetChecked())
    end)

    local epCheckBox = CreateFrame("CheckButton", "MLEPCheckbox", manualFrame, "UIRadioButtonTemplate")
    manualFrame.EPBox = epCheckBox
    epCheckBox:SetPoint("TOPRIGHT", gpCheckBox, "TOPLEFT", - padding - 16, 0)
    _G[epCheckBox:GetName() .. "Text"]:SetText("EP")
    epCheckBox:HookScript("OnClick", function(self)
      QuickEPGPMasterLootFrame.Manual.GPBox:SetChecked(not self:GetChecked())
    end)

    local valueBox = CreateFrame("EditBox", nil, manualFrame, "InputBoxTemplate")
    manualFrame.ValueBox = valueBox
    valueBox:SetFontObject(ChatFontNormal)
    valueBox:ClearAllPoints() --bugfix
    valueBox:SetPoint("TOP", epCheckBox, "TOP")
    valueBox:SetPoint("BOTTOM", epCheckBox, "BOTTOM")
    valueBox:SetPoint("RIGHT", epCheckBox, "LEFT", - padding, 0)
    valueBox:SetPoint("LEFT", nameBox, "LEFT", 0, 0)
    valueBox:SetAutoFocus(false)
    valueBox:SetNumeric()
    valueBox:SetNumber(0)

    local function ManualModifyEPGP(negate)
      local amount = QuickEPGPMasterLootFrame.Manual.ValueBox:GetNumber()
      local player = QuickEPGPMasterLootFrame.Manual.NameBox:GetText()

      if player then

        if negate then
          amount = -amount
        end

        local ep = nil
        local gp = nil

        if QuickEPGPMasterLootFrame.Manual.EPBox:GetChecked() then
          ep = amount
        else
          gp = amount
        end

        QUICKEPGP.modifyEPGP(player, ep, gp)
      end
    end

    local addButton = CreateFrame("Button", nil, manualFrame, "UIPanelButtonTemplate")
    addButton:SetText("Add")
    addButton:SetSize(90, 22)
    addButton:SetPoint("TOPLEFT", valueBox, "BOTTOMLEFT", 0, - padding)
    addButton:SetScript("OnClick", function()
      ManualModifyEPGP(false)
    end)

    local removeButton = CreateFrame("Button", nil, manualFrame, "UIPanelButtonTemplate")
    removeButton:SetText("Remove")
    removeButton:SetSize(90, 22)
    removeButton:SetPoint("TOPLEFT", addButton, "TOPRIGHT", padding, 0)
    removeButton:SetScript("OnClick", function()
      ManualModifyEPGP(true)
    end)

    manualFrame:Hide()
  end

  QuickEPGPMasterLootFrame:Show()
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
