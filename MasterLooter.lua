local function CreateTrackingRow(parent, scroller)
  local root = CreateFrame("Frame", nil, parent)
  root:SetSize(scroller:GetWidth(), scroller:GetHeight() / 3)

  root.ItemText = root:CreateFontString(nil, "OVERLAY", "GameTooltipText")
  root.ItemText:SetSize(root:GetWidth() - 60, root:GetHeight() / 2)
  root.ItemText:SetPoint("TOPLEFT", root, "TOPLEFT")
  root.ItemText:SetText("Item goes here")

  root.DetailText = root:CreateFontString(nil, "OVERLAY", "GameTooltipText")
  root.DetailText:SetSize(root:GetWidth() - 60, root:GetHeight() / 2)
  root.DetailText:SetPoint("TOP", root.ItemText, "BOTTOM")
  root.DetailText:SetText("Winner or time goes here")

  root.RemoveButton = CreateFrame("Button", nil, root, "UIPanelButtonTemplate")
  root.RemoveButton:SetSize(60, root:GetHeight() / 2)
  root.RemoveButton:SetPoint("TOPRIGHT", root, "TOPRIGHT")
  root.RemoveButton:SetText("Remove")
  root.RemoveButton:SetScript(
    "OnClick",
    function()
      if root.Item then
        QUICKEPGP.Items:Untrack(root.Item)
      end
    end
  )

  root.RollButton = CreateFrame("Button", nil, root, "UIPanelButtonTemplate")
  root.RollButton:SetSize(60, root:GetHeight() / 2)
  root.RollButton:SetPoint("TOP", root.RemoveButton, "BOTTOM")
  root.RollButton:SetText("Roll")
  root.RollButton:SetScript(
    "OnClick",
    function()
      if root.Item then
        if root.Item.Winner then
          root.Item:RevertWinner()
        else
          root.Item:StartRolling()
        end
      end
    end
  )

  function root:Track(item)
    self.Item = item
    if item then
      self.ItemText:SetText(item.Link)
      if item.Winner then
        local winnerMember = QUICKEPGP.GUILD:GetMemberInfo(item.Winner, true)
        if winnerMember then
          self.DetailText:SetText(QUICKEPGP.colorByClass(item.Winner, winnerMember.InvariantClass))
        else
          self.DetailText:SetText(item.Winner)
        end
        self.RollButton:SetText("Revert")
      else
        self.RollButton:SetText("Roll")
        self:UpdateTime()
      end
      self:Show()
    else
      self:Hide()
    end
  end

  function root:UpdateTime()
    if self.Item and not self.Item.Winner then
      local seconds = self.Item.Expiration - GetServerTime()
      local hours = math.floor(seconds / (60 * 60))
      local minutes = math.floor(seconds / 60) - (hours * 60)
      self.DetailText:SetText(hours .. ":" .. minutes .. " remaining")
    end
  end

  return root
end

local function UpdateTimes()
  if QuickEPGPMasterLootFrame:IsShown() then
    for i = 1, 3 do
      QuickEPGPMasterLootFrame.Tracked["Row" .. i]:UpdateTime()
    end
  end
end

local function UpdateTracked()
  local count = #QUICKEPGP.Items.Array
  FauxScrollFrame_Update(
    QuickEPGPMasterLootFrame.Tracked.Scroller,
    count,
    3,
    QuickEPGPMasterLootFrame.Tracked.Row1:GetHeight()
  )
  for i = 1, 3 do
    local lineplusoffset = i + FauxScrollFrame_GetOffset(QuickEPGPMasterLootFrame.Tracked.Scroller)
    local row = QuickEPGPMasterLootFrame.Tracked["Row" .. i]
    if lineplusoffset <= count then
      row:Track(QUICKEPGP.Items.Array[lineplusoffset])
    else
      row:Track(nil)
    end
  end
end

QUICKEPGP.openMasterFrame = function()
  if not QuickEPGPMasterLootFrame then
    QuickEPGPMasterLootFrame = CreateFrame("Frame", "QuickEPGPMasterLootFrame", UIParent)
    QuickEPGPMasterLootFrame:SetFrameStrata("DIALOG")
    QuickEPGPMasterLootFrame:SetSize(300, 150)
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

    local padding = 4
    local dropper = CreateFrame("Frame", nil, QuickEPGPMasterLootFrame)
    QuickEPGPMasterLootFrame.Dropper = dropper
    dropper:SetSize(64, 64)
    dropper:SetPoint("TOPRIGHT", QuickEPGPMasterLootFrame, "TOPRIGHT", -padding, -padding)
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

    local trackScroll = CreateFrame("ScrollFrame", nil, QuickEPGPMasterLootFrame.Tracked, "FauxScrollFrameTemplate")
    QuickEPGPMasterLootFrame.Tracked.Scroller = trackScroll
    trackScroll:SetPoint("TOPLEFT", 6, -4)
    trackScroll:SetPoint("BOTTOMRIGHT", -26, 4)
    trackScroll:SetScript("OnShow", UpdateTracked)
    trackScroll:SetScript(
      "OnVerticalScroll",
      function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, 16, UpdateTracked)
      end
    )

    QuickEPGPMasterLootFrame.Tracked.Row1 = CreateTrackingRow(QuickEPGPMasterLootFrame.Tracked, trackScroll)
    QuickEPGPMasterLootFrame.Tracked.Row2 = CreateTrackingRow(QuickEPGPMasterLootFrame.Tracked, trackScroll)
    QuickEPGPMasterLootFrame.Tracked.Row3 = CreateTrackingRow(QuickEPGPMasterLootFrame.Tracked, trackScroll)

    QuickEPGPMasterLootFrame.Tracked.Row1:SetPoint("TOP", QuickEPGPMasterLootFrame.Tracked.Scroller, "TOP")
    QuickEPGPMasterLootFrame.Tracked.Row2:SetPoint("TOP", QuickEPGPMasterLootFrame.Tracked.Row1, "BOTTOM")
    QuickEPGPMasterLootFrame.Tracked.Row3:SetPoint("TOP", QuickEPGPMasterLootFrame.Tracked.Row2, "BOTTOM")

    QuickEPGPMasterLootFrame.Tracked.Row2:SetBackdrop(
      {
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", -- 131071
        tile = true,
        tileSize = 16
      }
    )

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
    UpdateTracked()
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
