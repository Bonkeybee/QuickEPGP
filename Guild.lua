QUICKEPGP.GUILD = CreateFrame("Frame")
QUICKEPGP.GUILD.Members = {}

QUICKEPGP_MEMBER_EVENTS = {
  LOST_CONFIDENCE = "LOST_CONFIDENCE",
  UPDATED = "UPDATED"
}

-- ############################################################
-- ##### LOCAL FUNCTIONS ######################################
-- ############################################################

local Member = {}

function Member:new(name)
  return setmetatable(
    {Confident = false, Name = name, EP = QUICKEPGP.MINIMUM_EP, GP = QUICKEPGP.MINIMUM_GP},
    {__index = self}
  )
end

function Member:Update(id, level, class, officerNote, invariantClass)
  self.Id = id
  self.Level = level
  self.Class = class
  self.InvariantClass = invariantClass

  local ep, gp, _ = strsplit(",", officerNote)
  ep = tonumber(ep) or QUICKEPGP.MINIMUM_EP
  gp = tonumber(gp) or QUICKEPGP.MINIMUM_GP

  if (ep ~= self.OldEP or gp ~= self.OldGP) then
    self.EP = ep
    self.GP = gp
    self.OldEP = nil
    self.OldGP = nil
  end

  self.Confident = true
  self:RaiseEvent(QUICKEPGP_MEMBER_EVENTS.UPDATED)
end

function Member:TryRefresh()
  if self.Confident then
    return true
  end

  if (self.Id) then
    local name, _, _, level, class, _, _, officerNote, _, _, invariantClass = GetGuildRosterInfo(self.Id)

    if name == self.Name then
      self:Update(self.Id, level, class, officerNote, invariantClass)
      return true
    end
  end

  return false
end

function Member:GetEpGpPrMessage()
  return string.format("%.2f PR (%d ep / %d gp)", self.EP / self.GP, self.EP, self.GP)
end

function Member:OverrideEpGp(ep, gp)
  self.OldEP = self.OldEP or self.EP
  self.OldGP = self.OldGP or self.GP
  self.EP = tonumber(ep)
  self.GP = tonumber(gp)
end

function Member:CalculateChange(value, type)
  if type == "EP" then
    return max(self.EP + (value or 0), QUICKEPGP.MINIMUM_EP)
  elseif type == "GP" then
    return max(self.GP + (value or 0), QUICKEPGP.MINIMUM_GP)
  end
end

function Member:AddEventCallback(event, callback)
  local callbacks = self[event]
  if not callbacks then
    callbacks = {}
    self[event] = callbacks
  end
  callbacks[callback] = callback
end

function Member:RemoveEventCallback(event, callback)
  local callbacks = self[event]
  if callbacks then
    callbacks[callback] = nil
  end
end

function Member:RaiseEvent(event, ...)
  local callbacks = self[event]
  if callbacks then
    for callback in pairs(callbacks) do
      callback(...)
    end
  end
end

local function onEvent(_, event)
  if (event == "GUILD_ROSTER_UPDATE") then
    for _, member in pairs(QUICKEPGP.GUILD.Members) do
      member.Confident = false
      member:RaiseEvent(QUICKEPGP_MEMBER_EVENTS.LOST_CONFIDENCE)
    end
  end
end

-- ############################################################
-- ##### GLOBAL FUNCTIONS #####################################
-- ############################################################

function QUICKEPGP.GUILD:RefreshAll()
  for i = 1, GetNumGuildMembers() do
    local name, _, _, level, class, _, _, officerNote, _, _, invariantClass = GetGuildRosterInfo(i)

    if name then
      name = strsplit("-", name)
      local member = self.Members[name]
      if not member then
        member = Member:new(name)
        self.Members[name] = member
      end
      member:Update(i, level, class, officerNote, invariantClass)
    end
  end
end

function QUICKEPGP.GUILD:GetMemberInfo(name, silent)
  local normalizedName = QUICKEPGP.NormalizeName(name)

  local member = self.Members[normalizedName]

  if not member then
    -- scan not run or member invited after last scan
    self:RefreshAll()
    member = self.Members[normalizedName]
    if not member and not silent then
      QUICKEPGP.error(format("%s is not a guild member", (normalizedName or "nil")))
    end
    return member
  end

  if not member:TryRefresh() then
    -- Couldn't refresh using the existing id. Refresh all entries before returning the member object.
    self:RefreshAll()
  end

  return member
end

QUICKEPGP.guildMemberIndex = function(name, silent)
  local member = QUICKEPGP.GUILD:GetMemberInfo(name, silent)
  if member then
    return member.Id
  elseif not silent then
    QUICKEPGP.error("Cannot get guild member " .. (name or "") .. " index")
  end
end
QUICKEPGP.guildMemberLevel = function(name, silent)
  local member = QUICKEPGP.GUILD:GetMemberInfo(name, silent)
  if member then
    return member.Level
  elseif (not silent) then
    QUICKEPGP.error("Cannot get guild member " .. (name or "") .. " level")
  end
end
QUICKEPGP.guildMemberClass = function(name, silent)
  local member = QUICKEPGP.GUILD:GetMemberInfo(name, silent)
  if (member) then
    return member.Class
  elseif (not silent) then
    QUICKEPGP.error("Cannot get guild member " .. (name or "") .. " class")
  end
end
QUICKEPGP.guildMemberEP = function(name, silent)
  local member = QUICKEPGP.GUILD:GetMemberInfo(name, silent)
  if (member) then
    return member.EP
  elseif (not silent) then
    QUICKEPGP.error("Cannot get guild member " .. (name or "") .. " EP")
  end
end
QUICKEPGP.guildMemberGP = function(name, silent)
  local member = QUICKEPGP.GUILD:GetMemberInfo(name, silent)
  if (member) then
    return member.GP
  elseif (not silent) then
    QUICKEPGP.error("Cannot get guild member " .. (name or "") .. " GP")
  end
end
QUICKEPGP.guildMemberPR = function(name, silent, gp)
  local member = QUICKEPGP.GUILD:GetMemberInfo(name, silent)
  if (member) then
    return QUICKEPGP.round(member.EP / (member.GP + (gp or 0)), 2)
  elseif (not silent) then
    QUICKEPGP.error("Cannot get guild member " .. (name or "") .. " PR")
  end
end

QUICKEPGP.GUILD:RegisterEvent("GUILD_ROSTER_UPDATE")
QUICKEPGP.GUILD:SetScript("OnEvent", onEvent)
