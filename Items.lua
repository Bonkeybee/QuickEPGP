local MODULE_NAME = "QEPGP-Items"

QUICKEPGP.Items = CreateFrame("Frame")
QUICKEPGP.Items.Array = {}

local function IsLootMaster()
  local method, partyId, _ = GetLootMethod()
  return method == "master" and partyId == 0
end

local function Share()
  local message = "A"

  for _, v in pairs(QUICKEPGP.Items.Array) do
    message = string.format("%s%s:%s:%s;", message, v.Id, v.Winner or "", v.Expiration)
  end

  QUICKEPGP.LIBS:SendCommMessage(MODULE_NAME, message, "RAID", nil, "BULK")
end

local function Serialize()
  if not QUICKEPGP.Items.Deserializing then
    QUICKEPGP.Items.Serializing = true
    QUICKEPGP_LOOT = {}
    for k, v in pairs(QUICKEPGP.Items.Array) do
      QUICKEPGP_LOOT[k] = {Id = v.Id, Winner = v.Winner, Expiration = v.Expiration}
    end
    QUICKEPGP.Items.Serializing = false
  end
end

local function NotifyChanged(serialize, share)
  if QUICKEPGP.Items.ChangeHandlers then
    for callback in pairs(QUICKEPGP.Items.ChangeHandlers) do
      callback()
    end
  end
  if serialize then
    Serialize()
  end
  if share then
    QUICKEPGP.Items.PendingShare = true
  end
end

local function Deserialize()
  if QUICKEPGP_LOOT and not QUICKEPGP.Items.Serializing then
    QUICKEPGP.Items.Deserializing = true
    QUICKEPGP.Items.Array = {}
    for _, v in pairs(QUICKEPGP_LOOT) do
      if v and v.Id then
        QUICKEPGP.Items:Track(v.Id, v.Expiration, v.Winner, true)
      end
    end
    NotifyChanged(false, false)
    QUICKEPGP.Items.Deserializing = false
  end
end

function QUICKEPGP.Items:AddChangeHandler(callback)
  if not self.ChangeHandlers then
    self.ChangeHandlers = {}
  end
  self.ChangeHandlers[callback] = callback
end

function QUICKEPGP.Items:RemoveChangeHandler(callback)
  if self.ChangeHandlers then
    self.ChangeHandlers[callback] = nil
  end
end

function QUICKEPGP.Items:TrackFromBagSlot(bagId, slotId)
  print("Not implemented.", bagId, slotId)
end

function QUICKEPGP.Items:Track(itemIdOrLink, expiration, winner, skipNotify, onlyIfBoP)
  local itemInfo = Item:CreateFromItemID(tonumber(itemIdOrLink) or QUICKEPGP.itemIdFromLink(itemIdOrLink))
  itemInfo:ContinueOnItemLoad(
    function()
      if itemInfo:IsItemEmpty() then
        QUICKEPGP.error("Item with id " .. itemIdOrLink .. " does not exist.")
        return
      end

      local id = itemInfo:GetItemID()
      local _, link, _, _, _, _, _, _, _, icon, _, _, _, bindType = GetItemInfo(id)

      if onlyIfBoP and bindType ~= 1 then
        return
      end

      expiration = expiration or (GetServerTime() + 7200)

      -- Ensure tracked items are unique wrt item id and expiration time.
      local unique = true
      repeat
        for i = 1, #self.Array do
          local existing = self.Array[i]
          if existing.Id == id and existing.Expiration == expiration then
            expiration = expiration + 1
            unique = false
            break
          end
        end
      until unique

      local item = {
        Expiration = expiration,
        Link = link,
        Id = id,
        Icon = icon,
        Winner = winner
      }

      function item:GetWinner()
        return self.Winner
      end

      function item:SetWinner(name)
        local changed = false
        if name and name:len() > 0 and name ~= self.Winner then
          self.Winner = name
          changed = true
        elseif self.Winner then
          self.Winner = nil
          changed = true
        end
        if changed then
          NotifyChanged(true, true)
        end
      end

      function item:RevertWinner()
        if self.Winner then
          local gp = QUICKEPGP.getItemGP(self.Id)
          if gp then
            QUICKEPGP.modifyEPGP(self.Winner, nil, 0 - gp, self.Link)
            self:SetWinner()
          end
        end
      end

      function item:StartRolling()
        QUICKEPGP.startRolling(self.Id, self.Link)
        QUICKEPGP.ROLLING.TrackedItem = self
      end

      self.Array[#self.Array + 1] = item

      table.sort(
        self.Array,
        function(a, b)
          return a.Expiration < b.Expiration
        end
      )

      if not skipNotify then
        NotifyChanged(true, true)
      end
    end
  )
end

local function FindRef(table, id, expiration)
  for _, v in pairs(table) do
    if v.Id == id and v.Expiration == expiration then
      return v
    end
  end
end

function QUICKEPGP.Items:TrackOrUpdate(id, winner, expiration, skipNotify)
  id = tonumber(id)
  expiration = tonumber(expiration)
  if winner and winner:len() == 0 then
    winner = nil
  end
  if id then
    local existing = FindRef(self.Array, id, expiration)
    if existing then
      if skipNotify then
        existing.Winner = winner
      else
        existing:SetWinner(winner)
      end
    else
      QUICKEPGP.Items:Track(id, expiration, winner, skipNotify)
    end
  end
end

function QUICKEPGP.Items:Untrack(item, skipNotify)
  for i = 1, #self.Array do
    if item == self.Array[i] then
      local nextIndex = i
      repeat
        self.Array[nextIndex] = self.Array[nextIndex + 1]
        nextIndex = nextIndex + 1
      until not self.Array[nextIndex]
      if not skipNotify then
        NotifyChanged(true, true)
      end
      break
    end
  end
end

function QUICKEPGP.Items:UntrackById(id, expiration, skipNotify)
  for i = 1, #self.Array do
    local item = self.Array[i]
    if item.Id == id and item.Expiration == expiration then
      local nextIndex = i
      repeat
        self.Array[nextIndex] = self.Array[nextIndex + 1]
        nextIndex = nextIndex + 1
      until not self.Array[nextIndex]
      if not skipNotify then
        NotifyChanged(true, true)
      end
      break
    end
  end
end

local function Receive(prefix, message, _, sender)
  if prefix == MODULE_NAME and not UnitIsUnit(sender, "player") and message:len() > 0 then
    local prefix2 = string.sub(message, 1, 1)
    if prefix2 == "A" then
      local entries = {strsplit(";", string.sub(message, 2))}

      local oldItems = QUICKEPGP.Items.Array
      QUICKEPGP.Items.Array = {}

      for _, v in pairs(entries) do
        local id, winner, expiration = strsplit(":", v)
        id = tonumber(id)
        expiration = tonumber(expiration)
        if winner and winner:len() == 0 then
          winner = nil
        end
        if id then
          local existing = FindRef(oldItems, id, expiration)
          if existing then
            existing.Winner = winner
            QUICKEPGP.Items.Array[#QUICKEPGP.Items.Array + 1] = existing
          else
            QUICKEPGP.Items:Track(id, expiration, winner, true)
          end
        end
      end

      table.sort(
        QUICKEPGP.Items.Array,
        function(a, b)
          return a.Expiration < b.Expiration
        end
      )

      NotifyChanged(true, false)
    elseif prefix2 == "+" then
      local id, winner, expiration = strsplit(":", string.sub(message, 2))
      QUICKEPGP.Items:TrackOrUpdate(id, winner, expiration, true)
      NotifyChanged(true, false)
    elseif prefix2 == "-" then
      local id, _, expiration = strsplit(":", string.sub(message, 2))
      QUICKEPGP.Items:UntrackById(id, expiration, true)
      NotifyChanged(true, false)
    end
  end
end

function QUICKEPGP.Items:OnEvent(event, ...)
  if QUICKEPGP_OPTIONS.LOOTING.autotrack and event == "CHAT_MSG_LOOT" and IsLootMaster() then
    local text, _, _, _, playerName2 = ...
    local member = QUICKEPGP.GUILD:GetMemberInfo(playerName2)
    if
      member and
        ((QUICKEPGP_OPTIONS.LOOTING.equiplootee == 1 and QUICKEPGP.isMasterLooter(member.Name)) or
          (QUICKEPGP_OPTIONS.LOOTING.equiplootee == 2 and QUICKEPGP.isMainAssist(member.Name)) or
          (QUICKEPGP_OPTIONS.LOOTING.equiplootee == 3 and QUICKEPGP_OPTIONS.LOOTING.equiplooteechar == member.Name))
     then
      local itemId = tonumber(text:match("|Hitem:(%d+):"))
      if itemId then
        self:Track(itemId, nil, nil, false, true)
      end
    end
  end
end

local function ProcessQueue()
  if QUICKEPGP.Items.PendingShare then
    QUICKEPGP.Items.PendingShare = false
    Share()
  end
end

function QUICKEPGP.Items:Initialize()
  Deserialize()

  local function RegisterSendAndReceive()
    local guild = GetGuildInfo("player")
    if guild then
      if CanEditOfficerNote() then
        QUICKEPGP.LIBS:RegisterComm(MODULE_NAME, Receive)
        QUICKEPGP.Items:RegisterEvent("CHAT_MSG_LOOT")
        QUICKEPGP.Items:SetScript("OnEvent", self.OnEvent)
        QUICKEPGP.LIBS:ScheduleRepeatingTimer(ProcessQueue, 3)
      end
      return true
    end
  end

  -- On initial login the player is "not in a guild". Retry the CanEditOfficerNote check on login until it works.
  -- Or until we've tried for a minute and still get no affirmative answer.
  QUICKEPGP:TryUntil(RegisterSendAndReceive, 5, 12)
end
