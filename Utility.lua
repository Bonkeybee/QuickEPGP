QUICKEPGP.UTILITY = CreateFrame("Frame")
local loaded = false
local DELIMITER = ","

local officerNoteUpdateTable = {}

-- ############################################################
-- ##### LOCAL FUNCTIONS ######################################
-- ############################################################

local function onEvent(_, event)
  if (event == "ADDON_LOADED") then
    loaded = true
  end
end

local lastUpdate = GetTime()
local work = {}
local function onUpdate()
  if (loaded) then
    local now = GetTime()
    local delay = 1
    if (QUICKEPGP.count(officerNoteUpdateTable) > 0) then
      delay = 0.1
    end

    if (now - lastUpdate >= delay) then
      lastUpdate = now
      if (QUICKEPGP.count(work) > 0) then
        for name, epgp in pairs(work) do
          if (QUICKEPGP.guildMemberEP(name) == epgp[1] and QUICKEPGP.guildMemberGP(name) == epgp[2]) then
            work[name] = nil
          end
        end
      else
        for name, epgpTable in pairs(officerNoteUpdateTable) do
          if (QUICKEPGP.count(epgpTable) > 0) then
            local index, epgp = next(epgpTable)
            if (epgp ~= nil) then
              epgpTable[index] = nil
              if (QUICKEPGP.count(officerNoteUpdateTable[name]) <= 0) then
                officerNoteUpdateTable[name] = nil
              end
              ep = QUICKEPGP.calculateChange(name, epgp[2], "EP")
              gp = QUICKEPGP.calculateChange(name, epgp[3], "GP")
              work[name] = {ep, gp}
              GuildRosterSetOfficerNote(epgp[1], ep..","..gp)
            end
          end
        end
      end
    end
  end
end

-- ############################################################
-- ##### GLOBAL FUNCTIONS #####################################
-- ############################################################

QUICKEPGP.isMe = function(name)
  return name == UnitName("player")
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
      str = str.."("
    end
    if (level) then
      str = str..level
    end
    if (class) then
      str = str..strupper(strsub(class, 1, 4))
    end
    if (level or class) then
      str = str..") "
    end
    return str..name
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

QUICKEPGP.SafeSetOfficerNote = function(index, name, dep, dgp)
  if (not officerNoteUpdateTable[name]) then
    officerNoteUpdateTable[name] = {}
  end
  tinsert(officerNoteUpdateTable[name], {index, dep, dgp})
end

QUICKEPGP.camel = function(str)
  return str:gsub("(%l)(%w*)", function(a, b) return string.upper(a)..b end)
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
    str = str.."|cFFFFFF00"..str1.."|r"
  end
  if (str2) then
    str = str.."|cFFFFFFFF"..str2.."|r"
  end
  print(str)
end

QUICKEPGP.error = function(str)
  print("|cFFFF0000"..str.."|r")
end

QUICKEPGP.UTILITY:RegisterEvent("ADDON_LOADED")
QUICKEPGP.UTILITY:SetScript("OnEvent", onEvent)
QUICKEPGP.UTILITY:SetScript("OnUpdate", onUpdate)
