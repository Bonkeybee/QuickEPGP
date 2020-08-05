do
  local ldb = LibStub("LibDataBroker-1.1")
  QUICKEPGP.MinimapButton =
    ldb:NewDataObject(
    QUICKEPGP_ADDON_NAME,
    {
      type = "data source",
      icon = "Interface\\GuildFrame\\GuildLogo-NoLogo",
      OnClick = function(_, button)
        if button == "RightButton" then
          QUICKEPGP.InterfaceOptionsFrame_OpenToCategory_Fix(QUICKEPGP.menu)
        elseif button == "LeftButton" then
          if IsAltKeyDown() then
            if CanEditOfficerNote() then
              QUICKEPGP.toggleMasterFrame()
            end
          elseif IsShiftKeyDown() then
            QUICKEPGP:ToggleRollFrame()
          else
            QUICKEPGP.RaidStandings:ToggleFrame()
          end
        end
      end,
      OnTooltipShow = function(tooltip)
        if not tooltip or not tooltip.AddLine then
          return
        end
        tooltip:AddLine(QUICKEPGP_ADDON_NAME, 1, 1, 1)

        tooltip:AddLine(QUICKEPGP.getEPGPPRMessage(), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)

        tooltip:AddLine(" ")
        tooltip:AddLine(GRAY_FONT_COLOR_CODE .. "Left Click:|r Show raid standings")
        tooltip:AddLine(GRAY_FONT_COLOR_CODE .. "Shift + Left Click:|r Show roll window")
        if CanEditOfficerNote() then
          tooltip:AddLine(GRAY_FONT_COLOR_CODE .. "Alt + Left Click:|r Show loot master window")
        end
        tooltip:AddLine(GRAY_FONT_COLOR_CODE .. "Right Click:|r Show Options")
      end
    }
  )

  local function Init()
    local member = QUICKEPGP.GUILD:GetMemberInfo("player", true)
    if member then
      local function SetText()
        QUICKEPGP.MinimapButton.text = string.format("%.2f", member.EP / member.GP)
      end

      SetText()
      member:AddEventCallback(QUICKEPGP_MEMBER_EVENTS.UPDATED, SetText)
      QUICKEPGP.LIBS:ScheduleRepeatingTimer(
        function()
          member:TryRefresh()
        end,
        30
      )

      return true
    end
  end

  if not Init() then
    local timerId
    local function RepeatInit()
      if Init() then
        QUICKEPGP.LIBS:CancelTimer(timerId)
      end
    end
    timerId = QUICKEPGP.LIBS:ScheduleRepeatingTimer(RepeatInit, 5)
  end
end
