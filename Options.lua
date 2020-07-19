QUICKEPGP.OPTIONS_FRAME = CreateFrame("Frame")
local MODULE_NAME = "QuickEPGP-Options"

local options = {
  type = "group",
  args = {
    general = {
      name = "General",
      type = "group",
      order = 1,
      args = {
        minimap = {
          name = "Show Minimap Button",
          type = "toggle",
          order = 1,
          set = function(info, val)
            if val then
              QUICKEPGP.MinimapIcon:Show(QUICKEPGP_ADDON_NAME)
              QUICKEPGP_OPTIONS.MINIMAP.hide = false
            else
              QUICKEPGP.MinimapIcon:Hide(QUICKEPGP_ADDON_NAME)
              QUICKEPGP_OPTIONS.MINIMAP.hide = true
            end
          end,
          get = function(info) return not QUICKEPGP_OPTIONS.MINIMAP.hide end
        },
        rollSound = {
          name = "Starting Rolls Sound",
          type = "select",
          order = 3,
          values = QUICKEPGP.SOUNDNAMES,
          set = function(info, val)
            local soundFile = QUICKEPGP.SOUNDS[val]
            if soundFile then
              PlaySoundFile(soundFile, "Master")
            end
            QUICKEPGP_OPTIONS.ROLLING.openSound = val
          end,
          get = function(info) return QUICKEPGP_OPTIONS.ROLLING.openSound end
        },
        winSound = {
          name = "Won Roll Sound",
          type = "select",
          order = 4,
          values = QUICKEPGP.SOUNDNAMES,
          set = function(info, val)
            local soundFile = QUICKEPGP.SOUNDS[val]
            if soundFile then
              PlaySoundFile(soundFile, "Master")
            end
            QUICKEPGP_OPTIONS.ROLLING.winSound = val
          end,
          get = function(info) return QUICKEPGP_OPTIONS.ROLLING.winSound end
        },
        tooltips = {
          name = "Show GP in tooltips",
          type = "toggle",
          order = 2,
          set = function(info, val) QUICKEPGP_OPTIONS.TOOLTIP.enabled = val end,
          get = function(info) return QUICKEPGP_OPTIONS.TOOLTIP.enabled end
        }
      }
    },
    looting = {
      name = "Looting",
      type = "group",
      order = 2,
      args = {
        enable = {
          name = "Enable",
          type = "toggle",
          set = function(info, val) QUICKEPGP_OPTIONS.LOOTING.enabled = val end,
          get = function(info) return QUICKEPGP_OPTIONS.LOOTING.enabled end
        },
        safe = {
          name = "Safe Mode",
          desc = "will only autoloot when it's safe to do so",
          type = "toggle",
          set = function(info, val) QUICKEPGP_OPTIONS.LOOTING.safe = val end,
          get = function(info) return QUICKEPGP_OPTIONS.LOOTING.safe end
        },
        equiplootee = {
          name = "Equip Lootee",
          desc = "who to automatically send equippable items to",
          type = "select",
          values = {
            [1] = "Master Looter",
            [2] = "Main Assist"
          },
          set = function(info, val) QUICKEPGP_OPTIONS.LOOTING.equiplootee = val end,
          get = function(info) return QUICKEPGP_OPTIONS.LOOTING.equiplootee end
        },
        equiprarity = {
          name = "Equip Rarity",
          desc = "rarity threshold to apply equippable item looting behavior to",
          type = "select",
          values = {
            [2] = "|cff1eff00Uncommon|r",
            [3] = "|cff0070ddRare|r",
            [4] = "|cffa335eeEpic|r",
            [5] = "|cffff8000Legendary|r"
          },
          set = function(info, val) QUICKEPGP_OPTIONS.LOOTING.equiprarity = val end,
          get = function(info) return QUICKEPGP_OPTIONS.LOOTING.equiprarity end
        },
        otherlootee = {
          name = "Other Lootee",
          desc = "who to automatically send other items to",
          type = "select",
          values = {
            [1] = "Master Looter",
            [2] = "Main Assist"
          },
          set = function(info, val) QUICKEPGP_OPTIONS.LOOTING.otherlootee = val end,
          get = function(info) return QUICKEPGP_OPTIONS.LOOTING.otherlootee end
        },
        otherrarity = {
          name = "Other Rarity",
          desc = "rarity threshold to apply equippable item looting behavior to",
          type = "select",
          values = {
            [2] = "|cff1eff00Uncommon|r",
            [3] = "|cff0070ddRare|r",
            [4] = "|cffa335eeEpic|r",
            [5] = "|cffff8000Legendary|r"
          },
          set = function(info, val) QUICKEPGP_OPTIONS.LOOTING.otherrarity = val end,
          get = function(info) return QUICKEPGP_OPTIONS.LOOTING.otherrarity end
        },
      }
    }
  },
}
LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable(QUICKEPGP_ADDON_NAME, options, SLASH_EPGP1)
QUICKEPGP.menu = LibStub("AceConfigDialog-3.0"):AddToBlizOptions(QUICKEPGP_ADDON_NAME, QUICKEPGP_ADDON_NAME)

-- ############################################################
-- ##### LOCAL FUNCTIONS ######################################
-- ############################################################

local function default(value, default)
  if (value == nil) then
    value = default
    return value
  end
  return value
end

local function onEvent(_, event)
  if (event == "ADDON_LOADED") then
    QUICKEPGP_OPTIONS = QUICKEPGP.DefaultConfig(QUICKEPGP_OPTIONS)

    if not QUICKEPGP.MinimapIcon then
      QUICKEPGP.MinimapIcon = LibStub("LibDBIcon-1.0")
      QUICKEPGP.MinimapIcon:Register(QUICKEPGP_ADDON_NAME, QUICKEPGP.MinimapButton, QUICKEPGP_OPTIONS.MINIMAP)
    end

  end
end

-- ############################################################
-- ##### GLOBAL FUNCTIONS #####################################
-- ############################################################

QUICKEPGP.DefaultConfig = function(QUICKEPGP_OPTIONS)
  QUICKEPGP_OPTIONS = default(QUICKEPGP_OPTIONS, {})
  QUICKEPGP_OPTIONS.LOOTING = default(QUICKEPGP_OPTIONS.LOOTING, {})
  QUICKEPGP_OPTIONS.LOOTING.enabled = default(QUICKEPGP_OPTIONS.LOOTING.enabled, false)
  QUICKEPGP_OPTIONS.LOOTING.safe = default(QUICKEPGP_OPTIONS.LOOTING.safe, true)
  QUICKEPGP_OPTIONS.LOOTING.equiplootee = default(QUICKEPGP_OPTIONS.LOOTING.equiplootee, 1)
  QUICKEPGP_OPTIONS.LOOTING.equiprarity = default(QUICKEPGP_OPTIONS.LOOTING.equiprarity, 3)
  QUICKEPGP_OPTIONS.LOOTING.otherlootee = default(QUICKEPGP_OPTIONS.LOOTING.otherlootee, 2)
  QUICKEPGP_OPTIONS.LOOTING.otherrarity = default(QUICKEPGP_OPTIONS.LOOTING.otherrarity, 1)
  QUICKEPGP_OPTIONS.ROLLING = default(QUICKEPGP_OPTIONS.ROLLING, {})
  QUICKEPGP_OPTIONS.ROLLING.sound = default(QUICKEPGP_OPTIONS.ROLLING.sound, true)
  QUICKEPGP_OPTIONS.MINIMAP = default(QUICKEPGP_OPTIONS.MINIMAP, {hide = false})
  QUICKEPGP_OPTIONS.MasterFrame = default(QUICKEPGP_OPTIONS.MasterFrame, {})
  QUICKEPGP_OPTIONS.MasterFrame.X = default(QUICKEPGP_OPTIONS.MasterFrame.X, 0)
  QUICKEPGP_OPTIONS.MasterFrame.Y = default(QUICKEPGP_OPTIONS.MasterFrame.Y, 0)
  QUICKEPGP_OPTIONS.MasterFrame.Point = default(QUICKEPGP_OPTIONS.MasterFrame.Point, "CENTER")
  QUICKEPGP_OPTIONS.RollFrame = default(QUICKEPGP_OPTIONS.RollFrame, {})
  QUICKEPGP_OPTIONS.RollFrame.X = default(QUICKEPGP_OPTIONS.RollFrame.X, 0)
  QUICKEPGP_OPTIONS.RollFrame.Y = default(QUICKEPGP_OPTIONS.RollFrame.Y, 0)
  QUICKEPGP_OPTIONS.RollFrame.Point = default(QUICKEPGP_OPTIONS.RollFrame.Point, "CENTER")
  QUICKEPGP_OPTIONS.TOOLTIP = default(QUICKEPGP_OPTIONS.tooltips, {})
  QUICKEPGP_OPTIONS.TOOLTIP.enabled = default(QUICKEPGP_OPTIONS.TOOLTIP.enabled, true)
  QUICKEPGP_OPTIONS.ROLLING.openSound = default(QUICKEPGP_OPTIONS.ROLLING.openSound, QUICKEPGP_OPTIONS.ROLLING.sound and "WhatAreYouBuyin" or "None")
  QUICKEPGP_OPTIONS.ROLLING.winSound = default(QUICKEPGP_OPTIONS.ROLLING.winSound, QUICKEPGP_OPTIONS.ROLLING.sound and "AnAwesomeChoice" or "None")
  return QUICKEPGP_OPTIONS
end

local hooked = false
local doNotRun = false
QUICKEPGP.InterfaceOptionsFrame_OpenToCategory_Fix = function(panel)
  if InCombatLockdown() then return end
  if (doNotRun) then
    doNotRun = false
    return
  end
  local cat = _G['INTERFACEOPTIONS_ADDONCATEGORIES']
  local panelName;
  if ( type(panel) == "string" ) then
    for i, p in pairs(cat) do
      if p.name == panel then
        panelName = p.parent or panel
        break
      end
    end
  else
    for i, p in pairs(cat) do
      if p == panel then
        panelName = p.parent or panel.name
        break
      end
    end
  end
  if not panelName then return end
  local noncollapsedHeaders = {}
  local shownpanels = 0
  local mypanel
  for i, panel in ipairs(cat) do
    if not panel.parent or noncollapsedHeaders[panel.parent] then
      if panel.name == panelName then
        panel.collapsed = true
        local t = {}
        t.element = panel
        InterfaceOptionsListButton_ToggleSubCategories(t)
        noncollapsedHeaders[panel.name] = true
        mypanel = shownpanels + 1
      end
      if not panel.collapsed then
        noncollapsedHeaders[panel.name] = true
      end
      shownpanels = shownpanels + 1
    end
  end
  local Smin, Smax = InterfaceOptionsFrameAddOnsListScrollBar:GetMinMaxValues()
  InterfaceOptionsFrameAddOnsListScrollBar:SetValue((Smax / (shownpanels - 15)) * (mypanel - 2))
  doNotRun = true
  InterfaceOptionsFrame_OpenToCategory(panel)
end
if not hooked then
  hooksecurefunc("InterfaceOptionsFrame_OpenToCategory", function(panel) return QUICKEPGP.InterfaceOptionsFrame_OpenToCategory_Fix(panel) end)
  hooked = true
end

QUICKEPGP.OPTIONS_FRAME:RegisterEvent("ADDON_LOADED")
QUICKEPGP.OPTIONS_FRAME:RegisterEvent("PLAYER_LOGOUT")
QUICKEPGP.OPTIONS_FRAME:SetScript("OnEvent", onEvent)
