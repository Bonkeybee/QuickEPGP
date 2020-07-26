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
            QUICKEPGP.toggleRollFrame()
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

  local f = CreateFrame("frame")
  f:RegisterEvent("GUILD_ROSTER_UPDATE")
  f:SetScript(
    "OnEvent",
    function(_, event, _, _)
      if (event == "GUILD_ROSTER_UPDATE") then
        QUICKEPGP.MinimapButton.text = QUICKEPGP.guildMemberPR(UnitName("player"), true)
      end
    end
  )
end
