local function CreateTrackingRow(parent, showBackdrop)
  local root = CreateFrame("Frame", nil, parent)
  root:SetHeight(48)

  if showBackdrop then
    root:SetBackdrop(
      {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", -- 131071
        tile = true,
        tileSize = 16
      }
    )
  end

  root.RemoveButton = CreateFrame("Button", nil, root, "UIPanelButtonTemplate")
  root.RemoveButton:SetSize(24, 24)
  root.RemoveButton:SetPoint("TOPRIGHT", root, "TOPRIGHT")
  root.RemoveButton:SetText("X")
  root.RemoveButton:SetScript(
    "OnClick",
    function()
      if root.Item then
        QUICKEPGP.Items:Untrack(root.Item)
      end
    end
  )

  root.RollButton = CreateFrame("Button", nil, root, "UIPanelButtonTemplate")
  root.RollButton:SetSize(60, 24)
  root.RollButton:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT")
  root.RollButton:SetText("Roll")
  root.RollButton:SetScript(
    "OnClick",
    function()
      if root.Item then
        if root.Item.Winner and root.Item.Winner ~= "x" then
          root.Item:RevertWinner()
        else
          root.Item:StartRolling()
        end
      end
    end
  )

  root.ItemText = root:CreateFontString(nil, "OVERLAY", "GameTooltipText")
  root.ItemText:SetHeight(16)
  root.ItemText:SetPoint("TOPLEFT", root, "TOPLEFT")
  root.ItemText:SetPoint("TOPRIGHT", root.RemoveButton, "TOPLEFT")
  root.ItemText:SetText("Item goes here")

  root.DetailText = root:CreateFontString(nil, "OVERLAY", "GameTooltipText")
  root.DetailText:SetHeight(16)
  root.DetailText:SetPoint("BOTTOMLEFT", root, "BOTTOMLEFT")
  root.DetailText:SetPoint("TOPRIGHT", root.RollButton, "TOPLEFT", 0, -8)
  root.DetailText:SetText("Winner goes here")

  root.TimeText = root:CreateFontString(nil, "OVERLAY", "GameTooltipText")
  root.TimeText:SetHeight(16)
  root.TimeText:SetPoint("TOPLEFT", root.ItemText, "BOTTOMLEFT")
  root.TimeText:SetPoint("BOTTOMLEFT", root.DetailText, "TOPLEFT")
  root.TimeText:SetPoint("BOTTOMRIGHT", root.DetailText, "TOPRIGHT")
  root.TimeText:SetText("Time goes here")

  function root:Track(item)
    self.Item = item
    if item then
      self.ItemText:SetText(item.Link)
      if item.Winner and item.Winner ~= "x" then
        local winnerMember = QUICKEPGP.GUILD:GetMemberInfo(item.Winner, true)
        if winnerMember then
          self.DetailText:SetText(QUICKEPGP.colorByClass(item.Winner, winnerMember.InvariantClass))
        else
          self.DetailText:SetText(item.Winner)
        end
        self.RollButton:SetText("Revert")
      else
        self.RollButton:SetText("Roll")
        self.DetailText:SetText(item.Winner == "x" and "|cFF646464Everyone Passed|r" or "")
      end
      self:UpdateTime()
      self:Show()
    else
      self:Hide()
    end
  end

  function root:UpdateTime()
    if self.Item then
      local seconds = math.max(0, self.Item.Expiration - GetServerTime())
      local hours = math.floor(seconds / (60 * 60))
      local minutes = math.floor(seconds / 60) - (hours * 60)
      local color
      if seconds > 5400 then
        color = "|cFF00FF00"
      elseif seconds > 3600 then
        color = "|cFFFFFFFF"
      elseif seconds > 1800 then
        color = "|cFFFFFF00"
      else
        color = "|cFFFF0000"
      end

      if seconds == 0 and hours == 0 then
        self.TimeText:SetText("Expired!|r")
      else
        self.TimeText:SetText(string.format("%s%d:%02d remaining|r", color, hours, minutes))
      end
    end
  end

  return root
end

local function UpdateTimes()
  if QuickEPGPMasterLootFrame:IsShown() then
    for i = 1, #QuickEPGPMasterLootFrame.Tracked do
      QuickEPGPMasterLootFrame.Tracked[i]:UpdateTime()
    end
  end
end

local function UpdateTracked()
  local count = #QUICKEPGP.Items.Array
  local existingRows = #QuickEPGPMasterLootFrame.Tracked

  for i = count + 1, existingRows do
    QuickEPGPMasterLootFrame.Tracked[i]:Hide()
  end

  for i = existingRows + 1, count do
    local row = CreateTrackingRow(QuickEPGPMasterLootFrame.Tracked.ScrollChild, i % 2 == 0)
    QuickEPGPMasterLootFrame.Tracked[i] = row
    if i == 1 then
      row:SetPoint("TOPLEFT", QuickEPGPMasterLootFrame.Tracked.ScrollChild, "TOPLEFT")
      row:SetPoint("TOPRIGHT", QuickEPGPMasterLootFrame.Tracked.ScrollChild, "TOPRIGHT")
    else
      row:SetPoint("TOPLEFT", QuickEPGPMasterLootFrame.Tracked[i - 1], "BOTTOMLEFT")
      row:SetPoint("TOPRIGHT", QuickEPGPMasterLootFrame.Tracked[i - 1], "BOTTOMRIGHT")
    end
  end

  for i = 1, count do
    local row = QuickEPGPMasterLootFrame.Tracked[i]
    row:Show()
    row:Track(QUICKEPGP.Items.Array[i])
  end

  QuickEPGPMasterLootFrame.Tracked.ScrollChild:SetHeight(48 * count)
end

QUICKEPGP.openMasterFrame = function()
  if not QuickEPGPMasterLootFrame then
    QuickEPGPMasterLootFrame = CreateFrame("Frame", "QuickEPGPMasterLootFrame", UIParent)
    QuickEPGPMasterLootFrame:SetFrameStrata("DIALOG")
    QuickEPGPMasterLootFrame:SetSize(QUICKEPGP_OPTIONS.MasterFrame.Width, QUICKEPGP_OPTIONS.MasterFrame.Height)
    QuickEPGPMasterLootFrame:SetPoint(
      QUICKEPGP_OPTIONS.MasterFrame.Point,
      UIParent,
      QUICKEPGP_OPTIONS.MasterFrame.Point,
      QUICKEPGP_OPTIONS.MasterFrame.X,
      QUICKEPGP_OPTIONS.MasterFrame.Y
    )
    QuickEPGPMasterLootFrame:SetClampedToScreen(true)
    QuickEPGPMasterLootFrame:EnableMouse(true)
    QuickEPGPMasterLootFrame:SetToplevel(true)
    QuickEPGPMasterLootFrame:SetMovable(true)
    QuickEPGPMasterLootFrame:SetResizable(true)
    QuickEPGPMasterLootFrame:SetMinResize(300, 175)
    QuickEPGPMasterLootFrame:RegisterForDrag("LeftButton")
    QuickEPGPMasterLootFrame:SetBackdrop(
      {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", -- 131071
        tile = true,
        tileSize = 16
      }
    )
    QuickEPGPMasterLootFrame:SetScript(
      "OnDragStart",
      function(self)
        self:StartMoving()
      end
    )
    QuickEPGPMasterLootFrame:SetScript(
      "OnDragStop",
      function(self)
        self:StopMovingOrSizing()
        local point, _, _, x, y = self:GetPoint(1)
        QUICKEPGP_OPTIONS.MasterFrame.X = x
        QUICKEPGP_OPTIONS.MasterFrame.Y = y
        QUICKEPGP_OPTIONS.MasterFrame.Point = point
      end
    )
    QuickEPGPMasterLootFrame:SetScript(
      "OnSizeChanged",
      function(self)
        if self.Tracked then
          self.Tracked.ScrollChild:SetWidth(self.Tracked.ScrollFrame:GetWidth())
        end
        QUICKEPGP_OPTIONS.MasterFrame.Width = self:GetWidth()
        QUICKEPGP_OPTIONS.MasterFrame.Height = self:GetHeight()
      end
    )

    local resizeButton = CreateFrame("Button", nil, QuickEPGPMasterLootFrame)
    resizeButton:SetSize(16, 16)
    resizeButton:SetPoint("BOTTOMRIGHT")
    resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")

    resizeButton:SetScript(
      "OnMouseDown",
      function()
        QuickEPGPMasterLootFrame:StartSizing("BOTTOMRIGHT")
        QuickEPGPMasterLootFrame:SetUserPlaced(true)
      end
    )

    resizeButton:SetScript(
      "OnMouseUp",
      function()
        QuickEPGPMasterLootFrame:StopMovingOrSizing()
      end
    )
    local padding = 4

    local closeButton = CreateFrame("Button", nil, QuickEPGPMasterLootFrame, "UIPanelButtonTemplate")
    closeButton:SetText("X")
    closeButton:SetPoint("TOPRIGHT", QuickEPGPMasterLootFrame, "TOPRIGHT", -padding, -padding)
    closeButton:SetScript(
      "OnClick",
      function()
        QuickEPGPMasterLootFrame:Hide()
      end
    )

    local dropper = CreateFrame("Frame", nil, QuickEPGPMasterLootFrame)
    QuickEPGPMasterLootFrame.Dropper = dropper
    dropper:SetSize(64, 64)
    dropper:SetPoint("TOP", closeButton, "BOTTOM", 0, -padding)
    dropper:SetPoint("RIGHT", closeButton, "RIGHT")
    dropper:SetBackdrop(
      {
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        tile = true,
        tileSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
      }
    )
    dropper:SetScript(
      "OnMouseUp",
      function()
        if IsControlKeyDown() then
          if QuickEPGPMasterLootFrame.Item then
            DressUpItemLink(QuickEPGPMasterLootFrame.Item)
          end
        else
          local type, itemId, itemLink = GetCursorInfo()

          if type == "item" and itemId and itemLink then
            QUICKEPGP.startRolling(itemId, itemLink)
            ClearCursor()
          end
        end
      end
    )
    dropper.Texture = dropper:CreateTexture(nil, "BACKGROUND")
    dropper.Texture:SetAllPoints()
    dropper:SetScript(
      "OnEnter",
      function(self)
        if QuickEPGPMasterLootFrame.Item then
          GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
          GameTooltip:SetHyperlink(QuickEPGPMasterLootFrame.Item)
          GameTooltip:Show()
        end
      end
    )
    dropper:SetScript(
      "OnLeave",
      function(_)
        GameTooltip:Hide()
      end
    )

    local dropText = QuickEPGPMasterLootFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    dropper.Text = dropText
    dropText:SetSize(64, 64)
    dropText:SetPoint("TOPLEFT", dropper, "TOPLEFT", padding, -padding)
    dropText:SetTextColor(1, 1, 1, 1)
    dropText:SetText("DROP HERE TO START ROLL")

    local endButton = CreateFrame("Button", nil, QuickEPGPMasterLootFrame, "UIPanelButtonTemplate")
    endButton:SetText("END")
    endButton:SetPoint("TOP", dropper, "BOTTOM", 0, -padding)
    endButton:SetPoint("LEFT", dropper, "LEFT")
    endButton:SetPoint("RIGHT", dropper, "RIGHT")
    endButton:SetScript(
      "OnClick",
      function()
        QUICKEPGP.ROLLING:EndRolling(false)
      end
    )

    local cancelButton = CreateFrame("Button", nil, QuickEPGPMasterLootFrame, "UIPanelButtonTemplate")
    cancelButton:SetText("CANCEL")
    cancelButton:SetPoint("TOP", endButton, "BOTTOM", 0, -padding)
    cancelButton:SetPoint("LEFT", endButton, "LEFT")
    cancelButton:SetPoint("RIGHT", endButton, "RIGHT")
    cancelButton:SetScript(
      "OnClick",
      function()
        QUICKEPGP.ROLLING:EndRolling(true)
      end
    )

    local toggleManualButton = CreateFrame("Button", nil, QuickEPGPMasterLootFrame, "UIPanelButtonTemplate")
    toggleManualButton:SetText("Manual")
    toggleManualButton:SetPoint("BOTTOM", 0, padding)
    toggleManualButton:SetPoint("LEFT", dropper, "LEFT")
    toggleManualButton:SetPoint("RIGHT", dropper, "RIGHT")
    toggleManualButton:SetScript(
      "OnClick",
      function()
        if QuickEPGPMasterLootFrame.Manual:IsShown() then
          QuickEPGPMasterLootFrame.Manual:Hide()
          --QuickEPGPMasterLootFrame:SetWidth(72)
          QuickEPGPMasterLootFrame.Tracked:Show()
          toggleManualButton:SetText("Manual")
        else
          QuickEPGPMasterLootFrame.Manual:Show()
          --QuickEPGPMasterLootFrame:SetWidth(300)
          QuickEPGPMasterLootFrame.Tracked:Hide()
          toggleManualButton:SetText("Tracked")
        end
      end
    )

    local manualFrame = CreateFrame("Frame", nil, QuickEPGPMasterLootFrame)
    QuickEPGPMasterLootFrame.Manual = manualFrame
    manualFrame:SetPoint("RIGHT", dropper, "LEFT", -padding, -padding)
    manualFrame:SetPoint("LEFT", padding, padding)
    manualFrame:SetPoint("TOP", -padding, -padding)
    manualFrame:SetPoint("BOTTOM", padding, padding)
    manualFrame:SetBackdrop(
      {
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        tile = true,
        tileSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
      }
    )

    local manualHeader = manualFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    manualHeader:SetPoint("TOPLEFT", manualFrame, "TOPLEFT", padding * 2, -padding * 2)
    manualHeader:SetTextColor(1, 1, 1, 1)
    manualHeader:SetText("MANUAL EDIT:\n\nPlayer:")

    local nameBox = CreateFrame("EditBox", nil, manualFrame, "InputBoxTemplate")
    manualFrame.NameBox = nameBox
    nameBox:SetFontObject(ChatFontNormal)
    nameBox:ClearAllPoints() --bugfix
    nameBox:SetPoint("TOPLEFT", manualHeader, "BOTTOMLEFT", 0, -padding)
    nameBox:SetPoint("BOTTOMRIGHT", manualHeader, "BOTTOMRIGHT", 0, -padding - 22)
    nameBox:SetAutoFocus(false)

    local targetButton = CreateFrame("Button", nil, manualFrame, "UIPanelButtonTemplate")
    targetButton:SetPoint("TOP", nameBox, "TOP")
    targetButton:SetPoint("BOTTOM", nameBox, "BOTTOM")
    targetButton:SetPoint("LEFT", nameBox, "RIGHT")
    targetButton:SetText("Target")
    targetButton:SetScript(
      "OnClick",
      function()
        QuickEPGPMasterLootFrame.Manual.NameBox:SetText(UnitName("target"))
      end
    )

    local valueHeader = manualFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    valueHeader:SetPoint("TOP", nameBox, "BOTTOM", 0, 0)
    valueHeader:SetPoint("LEFT", manualHeader, "LEFT", 0, 0)
    valueHeader:SetTextColor(1, 1, 1, 1)
    valueHeader:SetText("Amount:")

    local gpCheckBox = CreateFrame("CheckButton", "MLGPCheckbox", manualFrame, "UIRadioButtonTemplate")
    manualFrame.GPBox = gpCheckBox
    gpCheckBox:SetPoint("TOP", valueHeader, "BOTTOM", -padding, -padding)
    gpCheckBox:SetPoint("RIGHT", manualFrame, -padding - padding - 16, -padding)
    gpCheckBox:SetChecked(true)
    _G[gpCheckBox:GetName() .. "Text"]:SetText("GP")
    gpCheckBox:HookScript(
      "OnClick",
      function(self)
        QuickEPGPMasterLootFrame.Manual.EPBox:SetChecked(not self:GetChecked())
      end
    )

    local epCheckBox = CreateFrame("CheckButton", "MLEPCheckbox", manualFrame, "UIRadioButtonTemplate")
    manualFrame.EPBox = epCheckBox
    epCheckBox:SetPoint("TOPRIGHT", gpCheckBox, "TOPLEFT", -padding - 16, 0)
    _G[epCheckBox:GetName() .. "Text"]:SetText("EP")
    epCheckBox:HookScript(
      "OnClick",
      function(self)
        QuickEPGPMasterLootFrame.Manual.GPBox:SetChecked(not self:GetChecked())
      end
    )

    local valueBox = CreateFrame("EditBox", nil, manualFrame, "InputBoxTemplate")
    manualFrame.ValueBox = valueBox
    valueBox:SetFontObject(ChatFontNormal)
    valueBox:ClearAllPoints() --bugfix
    valueBox:SetPoint("TOP", epCheckBox, "TOP")
    valueBox:SetPoint("BOTTOM", epCheckBox, "BOTTOM")
    valueBox:SetPoint("RIGHT", epCheckBox, "LEFT", -padding, 0)
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
    addButton:SetPoint("TOPLEFT", valueBox, "BOTTOMLEFT", 0, -padding)
    addButton:SetScript(
      "OnClick",
      function()
        ManualModifyEPGP(false)
      end
    )

    local removeButton = CreateFrame("Button", nil, manualFrame, "UIPanelButtonTemplate")
    removeButton:SetText("Remove")
    removeButton:SetSize(90, 22)
    removeButton:SetPoint("TOPLEFT", addButton, "TOPRIGHT", padding, 0)
    removeButton:SetScript(
      "OnClick",
      function()
        ManualModifyEPGP(true)
      end
    )

    local massValueHeader = manualFrame:CreateFontString(nil, "OVERLAY", "GameTooltipText")
    massValueHeader:SetPoint("TOP", addButton, "BOTTOM", 0, 0)
    massValueHeader:SetPoint("LEFT", manualHeader, "LEFT", 0, 0)
    massValueHeader:SetTextColor(1, 1, 1, 1)
    massValueHeader:SetText("Mass EP Amount:")

    local massAddButton = CreateFrame("Button", nil, manualFrame, "UIPanelButtonTemplate")
    massAddButton:SetText("Mass Change")
    massAddButton:SetSize(90, 22)
    massAddButton:SetPoint("TOP", massValueHeader, "BOTTOM", -padding, -padding)
    massAddButton:SetPoint("RIGHT", manualFrame, -padding - padding - 16, -padding)
    massAddButton:SetScript(
      "OnClick",
      function()
        QUICKEPGP.RaidReward(QuickEPGPMasterLootFrame.Manual.MassValueBox:GetNumber(), "manual edit")
      end
    )

    local massValueBox = CreateFrame("EditBox", nil, manualFrame, "InputBoxTemplate")
    manualFrame.MassValueBox = massValueBox
    massValueBox:SetFontObject(ChatFontNormal)
    massValueBox:ClearAllPoints() --bugfix
    massValueBox:SetPoint("TOP", massAddButton, "TOP")
    massValueBox:SetPoint("BOTTOM", massAddButton, "BOTTOM")
    massValueBox:SetPoint("RIGHT", massAddButton, "LEFT", -padding, 0)
    massValueBox:SetPoint("LEFT", valueBox, "LEFT", 0, 0)
    massValueBox:SetAutoFocus(false)
    massValueBox:SetNumeric()
    massValueBox:SetNumber(0)

    manualFrame:Hide()

    QuickEPGPMasterLootFrame.Tracked = CreateFrame("Frame", nil, QuickEPGPMasterLootFrame)
    QuickEPGPMasterLootFrame.Tracked:SetPoint("RIGHT", dropper, "LEFT", -padding, -padding)
    QuickEPGPMasterLootFrame.Tracked:SetPoint("LEFT", padding, padding)
    QuickEPGPMasterLootFrame.Tracked:SetPoint("TOP", -padding, -padding)
    QuickEPGPMasterLootFrame.Tracked:SetPoint("BOTTOM", padding, padding)
    QuickEPGPMasterLootFrame.Tracked:SetBackdrop(
      {
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        tile = true,
        tileSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
      }
    )

    local trackedRoot = QuickEPGPMasterLootFrame.Tracked
    local scrollFrame =
      CreateFrame("ScrollFrame", "EPGPMasterLootScrollFrame", trackedRoot, "UIPanelScrollFrameTemplate")
    local scrollChild = CreateFrame("Frame")
    trackedRoot.ScrollFrame = scrollFrame
    trackedRoot.ScrollChild = scrollChild
    trackedRoot:SetScript("OnShow", UpdateTracked)
    scrollFrame:SetScrollChild(scrollChild)
    scrollFrame:SetPoint("TOPLEFT", 6, -4)
    scrollFrame:SetPoint("BOTTOMRIGHT", -26, 4)
    scrollChild:SetSize(scrollFrame:GetWidth(), 48)

    function QuickEPGPMasterLootFrame:SetItem(itemLink, icon)
      self.Item = itemLink
      self.Dropper.Texture:SetTexture(icon)
      if icon then
        self.Dropper.Text:Hide()
      else
        self.Dropper.Text:Show()
      end
    end
    QUICKEPGP.LIBS:ScheduleRepeatingTimer(UpdateTimes, 60)
    QUICKEPGP.Items:AddChangeHandler(UpdateTracked)
  end

  QuickEPGPMasterLootFrame:Show()
  UpdateTracked()
  UpdateTimes()
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
