QUICKEPGP.UTILITY = CreateFrame("Frame")
local loaded = false

local officerNoteUpdateTable = {}

-- ############################################################
-- ##### LOCAL FUNCTIONS ######################################
-- ############################################################

local function onEvent(_, event)
  if (event == "ADDON_LOADED" and not loaded) then
    loaded = true
    QUICKEPGP:InitializeTooltip()
    QUICKEPGP.Items:Initialize()
  end
end

local delay = 0.250
local lastUpdate = 0
local lastIndex = nil
local function onUpdate()
  if (loaded) then
    local now = GetTime()
    local name, delta = next(officerNoteUpdateTable, lastIndex)

    if name and delta and now - lastUpdate >= delay then
      local member = QUICKEPGP.GUILD:GetMemberInfo(name)

      if not member then
        officerNoteUpdateTable[name] = nil -- remove non-guild members
        lastIndex = nil
      elseif not member.OldEP and not member.OldGP then
        officerNoteUpdateTable[name] = nil
        lastIndex = nil
        if delta.EP ~= 0 or delta.GP ~= 0 then
          local ep = member:CalculateChange(delta.EP, "EP") or QUICKEPGP.MINIMUM_EP
          local gp = member:CalculateChange(delta.GP, "GP") or QUICKEPGP.MINIMUM_GP
          member:OverrideEpGp(ep, gp)
          GuildRosterSetOfficerNote(member.Id, ep .. "," .. gp)
          lastUpdate = now
        end
      else
        lastIndex = name -- Can't update this member yet. Move on to the next one.
      end
    end
  end
end

-- ############################################################
-- ##### GLOBAL FUNCTIONS #####################################
-- ############################################################

QUICKEPGP.isInRaidInstance = function()
  local _, instanceType, _, difficultyName = GetInstanceInfo()
  if (instanceType == "raid") then
    if (difficultyName == "40 Player" or difficultyName == "20 Player") then
      return true
    end
  end
  return false
end

QUICKEPGP.colorByClass = function(name, class)
  local _, _, _, hex = GetClassColor(class)
  return "|c" .. hex .. name .. "|r"
end

QUICKEPGP.isMe = function(name)
  return name == UnitName("player")
end

QUICKEPGP.itemIdFromLink = function(itemLink)
  if itemLink and string.find(itemLink, "^|c.*|r$") then
    local _, itemId, _ = strsplit(":", itemLink)
    return tonumber(itemId)
  end
end

QUICKEPGP.round = function(number, decimals)
  if (number == nil) then
    number = 0
  end
  if (decimals == nil) then
    decimals = 0
  end
  return (("%%.%df"):format(decimals)):format(number)
end

QUICKEPGP.count = function(t)
  local c = 0
  if (t == nil) then
    return c
  end
  if (type(t) ~= "table") then
    return c
  end
  for _, _ in pairs(t) do
    c = c + 1
  end
  return c
end

QUICKEPGP.getItemId = function(itemLink)
  if (itemLink) then
    return select(3, strfind(itemLink, ":(%d+):"))
  end
  return nil
end

QUICKEPGP.getCharacterString = function(level, class, name)
  if (name) then
    local str = ""
    if (level or class) then
      str = str .. "("
    end
    if (level) then
      str = str .. level
    end
    if (class) then
      str = str .. strupper(strsub(class, 1, 4))
    end
    if (level or class) then
      str = str .. ") "
    end
    return str .. name
  end
  return nil
end

QUICKEPGP.getSimpleCharacterName = function(name, tolower)
  local simpleName = strsplit("-", name)
  if (tolower) then
    simpleName = strlower(simpleName)
  end
  return simpleName
end

function QUICKEPGP.NormalizeName(name)
  local normalized = UnitName(name)

  if normalized then
    return normalized
  end

  local index = name:find("%-")
  if index and index > 0 then
    name = name:sub(1, index - 1)
  end

  local f = string.sub(name, 1, 1)
  local r = string.sub(name, 2, #name)
  return f:upper() .. r:lower()
end

QUICKEPGP.SafeSetOfficerNote = function(name, dep, dgp)
  local delta = officerNoteUpdateTable[name]

  if delta then
    delta.EP = delta.EP + (dep or 0)
    delta.GP = delta.GP + (dgp or 0)
  else
    officerNoteUpdateTable[name] = {EP = dep or 0, GP = dgp or 0}
  end
end

QUICKEPGP.pluralize = function(single, plural, number)
  if (number == 1) then
    return single
  else
    return plural
  end
end

QUICKEPGP.info = function(str1, str2)
  local str = ""
  if (str1) then
    str = str .. "|cFFFFFF00" .. str1 .. "|r"
  end
  if (str2) then
    str = str .. "|cFFFFFFFF" .. str2 .. "|r"
  end
  print(str)
end

QUICKEPGP.error = function(str)
  print("|cFFFF0000" .. str .. "|r")
end

QUICKEPGP.spairs = function(t, order)
  local keys = {}
  for k in pairs(t) do
    keys[#keys + 1] = k
  end

  if order then
    table.sort(
      keys,
      function(a, b)
        return order(t, a, b)
      end
    )
  else
    table.sort(keys)
  end

  local i = 0
  return function()
    i = i + 1
    if keys[i] then
      return keys[i], t[keys[i]]
    end
  end
end

QUICKEPGP.UTILITY:RegisterEvent("ADDON_LOADED")
QUICKEPGP.UTILITY:SetScript("OnEvent", onEvent)
QUICKEPGP.UTILITY:SetScript("OnUpdate", onUpdate)
