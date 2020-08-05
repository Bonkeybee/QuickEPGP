local DELIMITER = ";"

function QUICKEPGP:CloseRollFrame()
  if QuickEPGProllFrame then
    QuickEPGProllFrame:Hide()
  end
end

function QUICKEPGP:OpenRollFrame(automatic)
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
  rollFrame:SetBackdrop(
    {
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", -- 131071
      tile = true,
      tileSize = 16
    }
  )
  local width = 231
  rollFrame:SetPoint(
    QUICKEPGP_OPTIONS.RollFrame.Point,
    UIParent,
    QUICKEPGP_OPTIONS.RollFrame.Point,
    QUICKEPGP_OPTIONS.RollFrame.X,
    QUICKEPGP_OPTIONS.RollFrame.Y
  )
  rollFrame:SetSize(width, 46)
  rollFrame:SetClampedToScreen(true)
  rollFrame:EnableMouse(true)
  rollFrame:SetToplevel(true)
  rollFrame:SetMovable(true)
  rollFrame:RegisterForDrag("LeftButton")
  rollFrame:SetScript(
    "OnDragStart",
    function(self)
      self:StartMoving()
    end
  )
  rollFrame:SetScript(
    "OnDragStop",
    function(self)
      self:StopMovingOrSizing()
      local point, _, _, x, y = self:GetPoint(1)
      QUICKEPGP_OPTIONS.RollFrame.X = x
      QUICKEPGP_OPTIONS.RollFrame.Y = y
      QUICKEPGP_OPTIONS.RollFrame.Point = point
    end
  )

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
  pictureFrame:SetScript(
    "OnDragStart",
    function(_)
      QuickEPGProllFrame:StartMoving()
    end
  )
  pictureFrame:SetScript(
    "OnDragStop",
    function(_)
      QuickEPGProllFrame:StopMovingOrSizing()
      local point, _, _, x, y = QuickEPGProllFrame:GetPoint(1)
      QUICKEPGP_OPTIONS.RollFrame.X = x
      QUICKEPGP_OPTIONS.RollFrame.Y = y
      QUICKEPGP_OPTIONS.RollFrame.Point = point
    end
  )
  pictureFrame:SetScript(
    "OnEnter",
    function(self)
      if QuickEPGProllFrame.Item then
        GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT")
        GameTooltip:SetHyperlink(QuickEPGProllFrame.Item)
        GameTooltip:Show()
      end
    end
  )
  pictureFrame:SetScript(
    "OnLeave",
    function(_)
      GameTooltip:Hide()
    end
  )
  pictureFrame:SetScript(
    "OnMouseUp",
    function()
      if QuickEPGProllFrame.Item and IsControlKeyDown() then
        DressUpItemLink(QuickEPGProllFrame.Item)
      end
    end
  )
  local pictureTexture = pictureFrame:CreateTexture(nil, "BACKGROUND")
  pictureTexture:SetAllPoints()
  pictureFrame.Texture = pictureTexture
  rollFrame.Picture = pictureFrame

  local needButton = CreateFrame("Button", nil, rollFrame, "UIPanelButtonTemplate")
  needButton:SetSize(100, 42)
  needButton:SetText("NEED")
  needButton:SetPoint("BOTTOMLEFT", rollFrame, "BOTTOMLEFT", 44, 3)
  needButton:Show()
  needButton:SetScript(
    "OnClick",
    function()
      QuickEPGProllFrame.IsPassing = false
      QuickEPGProllFrame.IsNeeding = true
      QUICKEPGP.LIBS:SendCommMessage(
        QUICKEPGP.ROLLING.MODULE_NAME,
        "RN" .. DELIMITER .. UnitName("player"),
        "RAID",
        nil,
        "ALERT"
      )
    end
  )

  local passButton = CreateFrame("Button", nil, rollFrame, "UIPanelButtonTemplate")
  passButton:SetSize(50, 42)
  passButton:SetText("PASS")
  passButton:SetPoint("BOTTOMLEFT", rollFrame, "BOTTOMLEFT", 144, 3)
  passButton:Show()
  passButton:SetScript(
    "OnClick",
    function()
      QuickEPGProllFrame.IsPassing = true
      QuickEPGProllFrame.IsNeeding = false
      QUICKEPGP.LIBS:SendCommMessage(
        QUICKEPGP.ROLLING.MODULE_NAME,
        "RP" .. DELIMITER .. UnitName("player"),
        "RAID",
        nil,
        "ALERT"
      )
    end
  )

  local closeButton = CreateFrame("Button", nil, rollFrame, "UIPanelButtonTemplate")
  closeButton:SetSize(25, 42)
  closeButton:SetText("X")
  closeButton:SetPoint("BOTTOMLEFT", rollFrame, "BOTTOMLEFT", 194, 3)
  closeButton:Show()
  closeButton:SetScript(
    "OnClick",
    function()
      QUICKEPGP:CloseRollFrame()
    end
  )

  function rollFrame:SetItem(itemLink, icon)
    self.Item = itemLink
    self.IsNeeding = false
    self.IsPassing = false
    if itemLink then
      local str
      if (self.IsNeeding) then
        str = "|cFF00FF00Needing|r"
      elseif (self.IsPassing) then
        str = "|cFFFF0000Passing|r"
      else
        str = "|cFFFFFF00Rolling|r"
      end
      local cost = QUICKEPGP.getItemGP(QUICKEPGP.getItemId(itemLink))
      self.Title:SetText(str .. " on " .. itemLink .. " |cFFFFFF00(" .. cost .. " GP)|r")
      self.Picture.Texture:SetTexture(icon)
    else
      self.Title:SetText(" ")
      self.Picture.Texture:SetTexture(nil)
    end
  end
end

function QUICKEPGP:ToggleRollFrame()
  if QuickEPGProllFrame and QuickEPGProllFrame:IsShown() then
    self:CloseRollFrame()
  else
    self:OpenRollFrame()
  end
end
