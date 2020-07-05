QUICKEPGP.OPTIONS_FRAME = CreateFrame("Frame")
local MODULE_NAME = "QuickEPGP-Options"

local options = {
  type = "group",
  args = {
    looting = {
      name = "Looting",
      type = "group",
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
    },
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