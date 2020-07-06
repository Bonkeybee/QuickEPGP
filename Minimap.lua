do
    local ldb = LibStub("LibDataBroker-1.1")
    QUICKEPGP.MinimapButton = ldb:NewDataObject(QUICKEPGP_ADDON_NAME, {
        type = "data source",
        icon = "Interface\\GuildFrame\\GuildLogo-NoLogo",
        OnClick = function(self, button)
            if button == "RightButton" then
              QUICKEPGP.InterfaceOptionsFrame_OpenToCategory_Fix(QUICKEPGP.menu)
            else
              if IsShiftKeyDown() then
                QUICKEPGP.toggleMasterFrame()
              else
                QUICKEPGP.toggleRollFrame()
              end
            end
        end,
        OnTooltipShow = function(tooltip)
            if not tooltip or not tooltip.AddLine then return end
            tooltip:AddLine(QUICKEPGP_ADDON_NAME, 1, 1, 1)

            local player = UnitName("player")
            local ep = QUICKEPGP.guildMemberEP(player)
            local gp = QUICKEPGP.guildMemberGP(player)
            if ep and gp then
			        tooltip:AddLine(string.format("Your PR is %.2f (%d ep / %d gp)", ep / gp, ep, gp), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1)
            end

            tooltip:AddLine(" ")
            tooltip:AddLine(GRAY_FONT_COLOR_CODE.."Left Click:|r Toggle roll window")
            tooltip:AddLine(GRAY_FONT_COLOR_CODE.."Shift + Left Click:|r Toggle loot master window")
            tooltip:AddLine(GRAY_FONT_COLOR_CODE.."Right Click:|r Show Options")
        end,
    })
end