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

local delay = 1
local lastUpdate = GetTime()
local function onUpdate()
  if (loaded) then
    local now = GetTime()
    if (QUICKEPGP.count(officerNoteUpdateTable) > 0) then
      delay = 0.250
    else
      delay = min(delay * 2, 60)
    end

    if (now - lastUpdate >= delay) then
      lastUpdate = now
      print("updating")
      for name, epgpTable in pairs(officerNoteUpdateTable) do
        if (QUICKEPGP.count(epgpTable) > 0) then
          local index, epgp = next(epgpTable)
          if (epgp ~= nil) then
            epgpTable[index] = nil
            if (QUICKEPGP.count(officerNoteUpdateTable[name]) <= 0) then
              officerNoteUpdateTable[name] = nil
            end
            local ep = (QUICKEPGP.calculateChange(name, epgp[1], "EP") or QUICKEPGP.MINIMUM_EP)
            local gp = (QUICKEPGP.calculateChange(name, epgp[2], "GP") or QUICKEPGP.MINIMUM_GP)
            GuildRosterSetOfficerNote(QUICKEPGP.guildMemberIndex(name), ep .. "," .. gp)
          end
        end
        break
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
  if index > 0 then
    name = name:sub(1, index - 1)
  end

  name =
    name:gsub(
    "(%a)([%w_']*)",
    function(first, rest)
      return first:upper() .. rest:lower()
    end
  )
  return name
end

QUICKEPGP.SafeSetOfficerNote = function(name, dep, dgp)
  if (not officerNoteUpdateTable[name]) then
    officerNoteUpdateTable[name] = {}
  end
  print(name .. " : " .. (dep or 0) .. " , " .. (dgp or 0))
  tinsert(officerNoteUpdateTable[name], {dep, dgp})
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
