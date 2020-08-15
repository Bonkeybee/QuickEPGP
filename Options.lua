QUICKEPGP.OPTIONS_FRAME = CreateFrame("Frame")

QUICKEPGP.SOUNDNAMES = {
  [1] = "None",
  [2] = "What can I do for ya?",
  [3] = "Hey! Listen!",
  [4] = "What are you buyin'?",
  [5] = "An awesome choice, stranger!"
}

QUICKEPGP.SOUNDS = {
  [1] = nil,
  [2] = "Interface\\AddOns\\QuickEPGP\\Sounds\\whatcanidoforya.ogg",
  [3] = "Interface\\AddOns\\QuickEPGP\\Sounds\\heylisten.ogg",
  [4] = "Interface\\AddOns\\QuickEPGP\\Sounds\\whatareyoubuyin.ogg",
  [5] = "Interface\\AddOns\\QuickEPGP\\Sounds\\anawesomechoice.ogg"
}

local LOOT_NAMES = {}

for i = 0, 5 do
  LOOT_NAMES[i] = ITEM_QUALITY_COLORS[i].hex .. _G["ITEM_QUALITY" .. i .. "_DESC"] .. "|r"
end

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
          set = function(_, val)
            if val then
              QUICKEPGP.MinimapIcon:Show(QUICKEPGP_ADDON_NAME)
              QUICKEPGP_OPTIONS.MINIMAP.hide = false
            else
              QUICKEPGP.MinimapIcon:Hide(QUICKEPGP_ADDON_NAME)
              QUICKEPGP_OPTIONS.MINIMAP.hide = true
            end
          end,
          get = function(_)
            return not QUICKEPGP_OPTIONS.MINIMAP.hide
          end
        },
        rollSound = {
          name = "Starting Rolls Sound",
          type = "select",
          order = 3,
          values = QUICKEPGP.SOUNDNAMES,
          set = function(_, val)
            local soundFile = QUICKEPGP.SOUNDS[val]
            if soundFile then
              PlaySoundFile(soundFile, "Master")
            end
            QUICKEPGP_OPTIONS.ROLLING.openSound = val
          end,
          get = function(_)
            return QUICKEPGP_OPTIONS.ROLLING.openSound
          end
        },
        winSound = {
          name = "Won Roll Sound",
          type = "select",
          order = 4,
          values = QUICKEPGP.SOUNDNAMES,
          set = function(_, val)
            local soundFile = QUICKEPGP.SOUNDS[val]
            if soundFile then
              PlaySoundFile(soundFile, "Master")
            end
            QUICKEPGP_OPTIONS.ROLLING.winSound = val
          end,
          get = function(_)
            return QUICKEPGP_OPTIONS.ROLLING.winSound
          end
        },
        tooltips = {
          name = "Show GP in tooltips",
          type = "toggle",
          order = 2,
          set = function(_, val)
            QUICKEPGP_OPTIONS.TOOLTIP.enabled = val
          end,
          get = function(_)
            return QUICKEPGP_OPTIONS.TOOLTIP.enabled
          end
        }
      }
    },
    looting = {
      name = "Looting",
      type = "group",
      order = 2,
      args = {
        break1 = {
          order = 1,
          name = "General Settings",
          type = "header"
        },
        enable = {
          order = 3,
          name = "Enable",
          type = "toggle",
          set = function(_, val)
            QUICKEPGP_OPTIONS.LOOTING.enabled = val
          end,
          get = function(_)
            return QUICKEPGP_OPTIONS.LOOTING.enabled
          end
        },
        safe = {
          order = 4,
          name = "Safe Mode",
          desc = "will only autoloot when it's safe to do so",
          type = "toggle",
          set = function(_, val)
            QUICKEPGP_OPTIONS.LOOTING.safe = val
          end,
          get = function(_)
            return QUICKEPGP_OPTIONS.LOOTING.safe
          end
        },
        break2 = {
          order = 5,
          name = "Masterloot Settings",
          type = "header"
        },
        automaster = {
          order = 7,
          name = "Auto-Masterloot",
          desc = "enables masterloot when entering a raid instance",
          type = "toggle",
          set = function(_, val)
            QUICKEPGP_OPTIONS.LOOTING.automaster = val
          end,
          get = function(_)
            return QUICKEPGP_OPTIONS.LOOTING.automaster
          end
        },
        masterthreshold = {
          order = 8,
          name = "Masterloot Threshold",
          desc = "rarity threshold to set masterloot to",
          type = "select",
          values = LOOT_NAMES,
          set = function(_, val)
            QUICKEPGP_OPTIONS.LOOTING.masterthreshold = val
            QUICKEPGP.setMasterLootThreshold()
          end,
          get = function(_)
            return QUICKEPGP_OPTIONS.LOOTING.masterthreshold
          end
        },
        autotrack = {
          order = 9,
          name = "Auto-Track loot",
          desc = "Automatically add Bind on Pickup loot to the tracker in the master loot window.",
          type = "toggle",
          set = function(_, val)
            QUICKEPGP_OPTIONS.LOOTING.autotrack = val
          end,
          get = function()
            return QUICKEPGP_OPTIONS.LOOTING.autotrack
          end
        },
        break3 = {
          order = 10,
          name = "Masterloot Settings (Equipment)",
          type = "header"
        },
        equiplootee = {
          order = 11,
          name = "Equip Lootee",
          desc = "who to automatically send equippable items to",
          type = "select",
          values = {
            [1] = "Master Looter",
            [2] = "Main Assist",
            [3] = "Character"
          },
          set = function(_, val)
            QUICKEPGP_OPTIONS.LOOTING.equiplootee = val
          end,
          get = function(_)
            return QUICKEPGP_OPTIONS.LOOTING.equiplootee
          end
        },
        equiplooteechar = {
          order = 12,
          name = "Equip Lootee",
          desc = "who to automatically send equippable items to",
          type = "input",
          hidden = function()
            if (QUICKEPGP_OPTIONS.LOOTING.equiplootee ~= 3) then
              return true
            else
              return false
            end
          end,
          set = function(_, val)
            QUICKEPGP_OPTIONS.LOOTING.equiplooteechar = val
          end,
          get = function(_)
            return QUICKEPGP_OPTIONS.LOOTING.equiplooteechar
          end
        },
        equiprarity = {
          order = 13,
          name = "Equip Rarity",
          desc = "rarity threshold to apply equippable item looting behavior to",
          type = "select",
          values = LOOT_NAMES,
          set = function(_, val)
            QUICKEPGP_OPTIONS.LOOTING.equiprarity = val
          end,
          get = function(_)
            return QUICKEPGP_OPTIONS.LOOTING.equiprarity
          end
        },
        break4 = {
          order = 14,
          name = "Masterloot Settings (Other)",
          type = "header"
        },
        otherlootee = {
          order = 16,
          name = "Other Lootee",
          desc = "who to automatically send other items to",
          type = "select",
          values = {
            [1] = "Master Looter",
            [2] = "Main Assist",
            [3] = "Character"
          },
          set = function(_, val)
            QUICKEPGP_OPTIONS.LOOTING.otherlootee = val
          end,
          get = function(_)
            return QUICKEPGP_OPTIONS.LOOTING.otherlootee
          end
        },
        otherlooteechar = {
          order = 17,
          name = "Other Lootee Character",
          desc = "who to automatically send other items to",
          type = "input",
          hidden = function()
            if (QUICKEPGP_OPTIONS.LOOTING.otherlootee ~= 3) then
              return true
            else
              return false
            end
          end,
          set = function(_, val)
            QUICKEPGP_OPTIONS.LOOTING.otherlooteechar = val
          end,
          get = function(_)
            return QUICKEPGP_OPTIONS.LOOTING.otherlooteechar
          end
        },
        otherrarity = {
          order = 18,
          name = "Other Rarity",
          desc = "rarity threshold to apply other item looting behavior to",
          type = "select",
          values = LOOT_NAMES,
          set = function(_, val)
            QUICKEPGP_OPTIONS.LOOTING.otherrarity = val
          end,
          get = function(_)
            return QUICKEPGP_OPTIONS.LOOTING.otherrarity
          end
        }
      }
    }
  }
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
  QUICKEPGP_OPTIONS.LOOTING.automaster = default(QUICKEPGP_OPTIONS.LOOTING.automaster, false)
  QUICKEPGP_OPTIONS.LOOTING.autotrack = default(QUICKEPGP_OPTIONS.LOOTING.autotrack, true)
  QUICKEPGP_OPTIONS.LOOTING.masterthreshold = default(QUICKEPGP_OPTIONS.LOOTING.masterthreshold, 2)
  QUICKEPGP_OPTIONS.ROLLING = default(QUICKEPGP_OPTIONS.ROLLING, {})
  QUICKEPGP_OPTIONS.ROLLING.sound = default(QUICKEPGP_OPTIONS.ROLLING.sound, true)
  QUICKEPGP_OPTIONS.ROLLING.openSound =
    default(QUICKEPGP_OPTIONS.ROLLING.openSound, QUICKEPGP_OPTIONS.ROLLING.sound and 4 or 1)
  QUICKEPGP_OPTIONS.ROLLING.winSound =
    default(QUICKEPGP_OPTIONS.ROLLING.winSound, QUICKEPGP_OPTIONS.ROLLING.sound and 5 or 1)
  QUICKEPGP_OPTIONS.MINIMAP = default(QUICKEPGP_OPTIONS.MINIMAP, {hide = false})
  QUICKEPGP_OPTIONS.TOOLTIP = default(QUICKEPGP_OPTIONS.tooltips, {})
  QUICKEPGP_OPTIONS.TOOLTIP.enabled = default(QUICKEPGP_OPTIONS.TOOLTIP.enabled, true)
  QUICKEPGP_OPTIONS.MasterFrame = default(QUICKEPGP_OPTIONS.MasterFrame, {})
  QUICKEPGP_OPTIONS.MasterFrame.X = default(QUICKEPGP_OPTIONS.MasterFrame.X, 0)
  QUICKEPGP_OPTIONS.MasterFrame.Y = default(QUICKEPGP_OPTIONS.MasterFrame.Y, 0)
  QUICKEPGP_OPTIONS.MasterFrame.Point = default(QUICKEPGP_OPTIONS.MasterFrame.Point, "CENTER")
  QUICKEPGP_OPTIONS.RollFrame = default(QUICKEPGP_OPTIONS.RollFrame, {})
  QUICKEPGP_OPTIONS.RollFrame.X = default(QUICKEPGP_OPTIONS.RollFrame.X, 0)
  QUICKEPGP_OPTIONS.RollFrame.Y = default(QUICKEPGP_OPTIONS.RollFrame.Y, 0)
  QUICKEPGP_OPTIONS.RollFrame.Point = default(QUICKEPGP_OPTIONS.RollFrame.Point, "CENTER")
  QUICKEPGP_OPTIONS.RaidStandings = default(QUICKEPGP_OPTIONS.RaidStandings, {X = 0, Y = 0, Point = "CENTER"})
  return QUICKEPGP_OPTIONS
end

local hooked = false
local doNotRun = false
QUICKEPGP.InterfaceOptionsFrame_OpenToCategory_Fix = function(panel)
  if InCombatLockdown() then
    return
  end
  if (doNotRun) then
    doNotRun = false
    return
  end
  local cat = _G["INTERFACEOPTIONS_ADDONCATEGORIES"]
  local panelName
  if (type(panel) == "string") then
    for _, p in pairs(cat) do
      if p.name == panel then
        panelName = p.parent or panel
        break
      end
    end
  else
    for _, p in pairs(cat) do
      if p == panel then
        panelName = p.parent or panel.name
        break
      end
    end
  end
  if not panelName then
    return
  end
  local noncollapsedHeaders = {}
  local shownpanels = 0
  local mypanel
  for _, p in ipairs(cat) do
    if not p.parent or noncollapsedHeaders[p.parent] then
      if p.name == panelName then
        p.collapsed = true
        local t = {}
        t.element = p
        InterfaceOptionsListButton_ToggleSubCategories(t)
        noncollapsedHeaders[p.name] = true
        mypanel = shownpanels + 1
      end
      if not p.collapsed then
        noncollapsedHeaders[p.name] = true
      end
      shownpanels = shownpanels + 1
    end
  end
  local _, Smax = InterfaceOptionsFrameAddOnsListScrollBar:GetMinMaxValues()
  InterfaceOptionsFrameAddOnsListScrollBar:SetValue((Smax / (shownpanels - 15)) * (mypanel - 2))
  doNotRun = true
  InterfaceOptionsFrame_OpenToCategory(panel)
end
if not hooked then
  hooksecurefunc(
    "InterfaceOptionsFrame_OpenToCategory",
    function(panel)
      return QUICKEPGP.InterfaceOptionsFrame_OpenToCategory_Fix(panel)
    end
  )
  hooked = true
end

QUICKEPGP.OPTIONS_FRAME:RegisterEvent("ADDON_LOADED")
QUICKEPGP.OPTIONS_FRAME:RegisterEvent("PLAYER_LOGOUT")
QUICKEPGP.OPTIONS_FRAME:SetScript("OnEvent", onEvent)
